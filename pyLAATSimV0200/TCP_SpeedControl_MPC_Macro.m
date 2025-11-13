function [w_opt,MPCSim] = TCP_SpeedControl_MPC_Macro(SimInfo,ObjAircraft,Settings,TFC,ttt)
%TCP_SpeedControl_MPC_Macro Formulates and solves the MPC optimization problem for speed control.
%   This function contains the core of the Model Predictive Control (MPC)
%   for the speed control policy. It uses the CasADi optimization framework
%   to solve a nonlinear optimal control problem.
%
%   The function performs these steps:
%   1. Defines the state variables (regional accumulations) and control
%      variables (speed control ratios `w_i`).
%   2. Formulates the system dynamics using the MFD-based model, where the
%      outflow `G(n)` is scaled by the control input `w_i`.
%   3. Defines the objective function, which aims to minimize a weighted sum
%      of the total network energy consumption (derived from the eLMFD) and
%      the control effort.
%   4. Sets up the constraints, including state bounds and control bounds.
%   5. Calls the IPOPT solver (via CasADi) to find the optimal sequence of
%      speed control ratios over the prediction horizon.
%   6. Returns the first control action from the optimal sequence to be
%      applied to the simulation.
%
%   This is a "macro" function as it operates entirely on the macroscopic,
%   aggregated model.
% Author: Yazan Safadi
% Date Created: 2025-02-09
%%
disp('[WARN] TCP_SpeedControl_MPC_Macro: Function is in testing phase and may need updates.');
import casadi.*
%% Setting for control problem
vMax = Settings.Aircraft.vm_range(2);
dT = Settings.TFC.dtMPC;
Np = Settings.TFC.Np;

% Assuming speed control is applied to the first two regions of the first flying layer.
% The indices might need to be more dynamic if controlling other layers.
region1_idx = 1;
region2_idx = 2;

nc1 = Settings.TFC.Ri(region1_idx).nci;
nc2 = Settings.TFC.Ri(region2_idx).nci;
n1max = 3*nc1;
n2max = 3*nc2;

nijt = [sum(reshape(TFC.Ri(region1_idx).nid(ttt/dT,:),2,[]),2)',sum(reshape(TFC.Ri(region2_idx).nid(ttt/dT,:),2,[]),2)'];
nit = [TFC.Ri(region1_idx).ni(ttt/dT), TFC.Ri(region2_idx).ni(ttt/dT)];
vit = [TFC.Ri(region1_idx).V(ttt/dT), TFC.Ri(region2_idx).V(ttt/dT)];
if vit(1)<1 || vit(1) >vMax
    vit (1) = vMax;
end
if vit(2)<1 || vit(2) >vMax
    vit (2) = vMax;
end
nt = sum(nit);

% Note: The logic for qijt seems to be for departure regions (layer 0).
% This might need review if it's intended to be coupled with flying layers.
qijt = [TFC.Ri(1).qinij(ttt/dT,1), TFC.Ri(1).qinij(ttt/dT,2),TFC.Ri(2).qinij(ttt/dT,1), TFC.Ri(2).qinij(ttt/dT,2)]./dT;
d11 = qijt(1);
d12 = qijt(2);
d21 = qijt(3);
d22 = qijt(4);
nc = nc1 + nc2;
x11T_max = inf; x11T_min = 0;
x12T_max = inf; x12T_min = 0;
x21T_max = inf; x21T_min = 0;
x22T_max = inf; x22T_min = 0;
x1T_max = n1max; x1T_min = 0;
x2T_max = n2max; x2T_min = 0;
xT_max = n1max + n2max; xT_min = 0;
uvij_max = Settings.TFC.uvij(2); uvij_min = Settings.TFC.uvij(1);
u_cont = [uvij_max,uvij_min,uvij_max,uvij_min,uvij_max,uvij_min,uvij_max,uvij_min];
xCon = [x11T_max,x12T_max,x21T_max,x22T_max,x1T_max,x2T_max,xT_max]';
%% Define States
x11T=SX.sym('x11T');
x12T=SX.sym('x12T');
x21T=SX.sym('x21T');
x22T=SX.sym('x22T');
x1T=SX.sym('x1T');
x2T=SX.sym('x2T');
xT=SX.sym('xT');
states = [
    x11T;
    x12T;
    x21T;
    x22T;
    x1T;
    x2T;
    xT;
    ];
n_states = length(states);
nijT_states = 4;
niT_states = 2;
%% Define Controllers
w1=SX.sym('w1');
w2=SX.sym('w2');
controls = [
    w1;
    w2;
    ];
n_controls = length(controls);
%% Functions
% sF = @(x,a,b) [a + (b + a) * (1./(1 + exp(-x)))];
G1 = Settings.TFC.Ri(region1_idx).funGn;
G2 = Settings.TFC.Ri(region2_idx).funGn;
% sG = @(Gdt) [min(10,max(0,(Gdt)))];
bij = @(xij,xi) [min(1,max(0,(xij/xi)))];
S1BQ = G1(nc1);
S2BQ = G2(nc2);
%==========================
Vn = Settings.TFC.Vn;
ECv = Settings.TFC.ECv;
ssECv = ECv(Settings.TFC.vECstar);
Vn1 = Settings.TFC.Ri(region1_idx).Vn;
ECv1 = Settings.TFC.Ri(region1_idx).ECv;
ssECv1 = Settings.TFC.Ri(region1_idx).ssECv;
Vn2 = Settings.TFC.Ri(region2_idx).Vn;
ECv2 = Settings.TFC.Ri(region2_idx).ECv;
ssECv2 = Settings.TFC.Ri(region2_idx).ssECv;
v1star = Settings.TFC.Ri(region1_idx).vECstar;
v2star = Settings.TFC.Ri(region2_idx).vECstar;
vmax = Settings.TFC.vECmax;
w1_max = min(vmax)/vmax; w1_min = min(min(v1star,vmax))/vmax; % Cap v1star at vmax
w2_max = min(vmax)/vmax; w2_min = min(min(v2star,vmax))/vmax; % Cap v2star at vmax
%==========================
%% Sigmoid function
% sF = @(x,a,b) [-a + (b + a) * (1./(1 + exp(-x)))];
% sF = @(a,b,x) [min(b,max(a,(x)))];
%%
rhs = [
    %-----dn11T----
    d11 + bij(x21T,x2T)*(G2(x2T))*w2  - bij(x11T,x1T)*(G1(x1T))*w1;
    %-----dn12T----
    d12 - bij(x12T,x1T)*(G1(x1T))*w1;
    %-----dn21T----
    d21 - bij(x21T,x2T)*(G2(x2T))*w2;
    %-----dn22T----
    d22 + bij(x12T,x1T)*(G1(x1T))*w1 - bij(x22T,x2T)*(G2(x2T))*w2;
    %-----dn1T----
    d11 + bij(x21T,x2T)*(G2(x2T))*w2 - bij(x11T,x1T)*(G1(x1T))*w1 + d12 - bij(x12T,x1T)*(G1(x1T))*w1;
    %-----dn2T----
    d21 - bij(x21T,x2T)*(G2(x2T))*w2 + d22 + bij(x12T,x1T)*(G1(x1T))*w1 - bij(x22T,x2T)*(G2(x2T))*w2;
    %-----dnT----
    d11 + bij(x21T,x2T)*(G2(x2T))*w2 - bij(x11T,x1T)*(G1(x1T))*w1 + d12 - bij(x12T,x1T)*(G1(x1T))*w1 + d21 - bij(x21T,x2T)*(G2(x2T))*w2 + d22 + bij(x12T,x1T)*(G1(x1T))*w1 - bij(x22T,x2T)*(G2(x2T))*w2;
    ];
%%
f = Function('f',{states,controls},{rhs}); % nonlinear mapping function f(x,u)
U = SX.sym('U',n_controls,Np); % Decision variables (controls)
P = SX.sym('P',n_states + Np*(n_states+n_controls));
% parameters (which include the initial state and the reference along the
% predicted trajectory (reference states and reference controls))
X = SX.sym('X',n_states,(Np+1));
% A vector that represents the states over the optimization problem.
%%
obj = 0; % Objective function
g = [];  % constraints vector
Omega = Settings.TFC.Omega;
disp(['[DEBUG] TCP_SpeedControl_MPC_Macro Omega values: ', mat2str(Omega)]);
wE1 = 1;%Omega(1);
wE2 = 1;%Omega(2);
Q =  eye(n_states,n_states);
Q(1,1) = 0; % x11T;
Q(2,2) = 0; % x12T;
Q(3,3) = 0; % x21T;
Q(4,4) = 0; % x22T;
Q(5,5) = 0; % x1T;
Q(6,6) = 0; % x2T;
Q(7,7) = 0; % xT;
% Control weights
R =  zeros(n_controls,n_controls); % weighing matrices (controls)
R(1,1) = ECv1(v1star);% w1;
R(2,2) = ECv2(v2star);% w2;
%%
max_rate=0.1;
%% Objective function
st  = X(:,1); st_n1 = X(7,1); st_n2 = X(7,1); % initial state
g = [g;st-P(1:n_states)]; % initial condition constraints
h = dT;
for k = 1:Np
    st = X(:,k); st_n1 = X(5,1); st_n2 = X(6,1);  con = U(:,k);
    obj = obj+wE1*ECv1(Vn1(st_n1))+wE2*ECv2(Vn2(st_n2))+(st-P(((n_states+n_controls)*k-(n_controls-1)):((n_states+n_controls)*k+(-(n_controls-1)+(n_states-1)))))'*Q*(st-P(((n_states+n_controls)*k-(n_controls-1)):((n_states+n_controls)*k+(-(n_controls-1)+(n_states-1))))) + ...
        (con-P(((n_states+n_controls)*k+(n_states-n_controls+1)):((n_states+n_controls)*k+((n_states-n_controls+1)+(n_controls-1)))))'*R*(con-P(((n_states+n_controls)*k+(n_states-n_controls+1)):((n_states+n_controls)*k+((n_states-n_controls+1)+(n_controls-1))))) ; % calculate obj
    st_next = X(:,k+1);
    k1 = f(st, con);   % new 
    k2 = f(st + h/2*k1, con); % new
    k3 = f(st + h/2*k2, con); % new
    k4 = f(st + h*k3, con); % new
    st_next_RK4 = st + h/6*(k1 +2*k2 +2*k3 +k4); % new 
    g = [g;st_next-st_next_RK4]; % compute constraints % new
end
%%
% make the decision variable one column  vector
OPT_variables = [reshape(X,n_states*(Np+1),1);reshape(U,n_controls*Np,1)];
nlp_prob = struct('f', obj, 'x', OPT_variables, 'g', g, 'p', P);
opts = struct;
opts.ipopt.max_iter = 2000;
opts.ipopt.print_level =0;%0,3
opts.print_time = 0;
opts.ipopt.acceptable_tol =1e-8;
opts.ipopt.acceptable_obj_change_tol = 1e-6;
solver = nlpsol('solver', 'ipopt', nlp_prob,opts);
args = struct;

args.lbg(1:n_states*(Np+1)) =   -1e-6; % Equality constraints
args.ubg(1:n_states*(Np+1)) =   1e-6; % Equality constraints
% args.lbg(1:(n_states)*(Np+1)+(2*n_controls*(Np-1))) =   -1e-6 ; % Equality constraints
% args.ubg(1:(n_states)*(Np+1)+(2*n_controls*(Np-1))) =   1e-6  ; % Equality constraints

% Adjust control bounds to enforce the constraint on the difference between consecutive control inputs
jjj=(1);
args.lbx(jjj:n_states:n_states*(Np+1),1) = x11T_min; %state x11 lower bound
args.ubx(jjj:n_states:n_states*(Np+1),1) = x11T_max; %state x11 upper bound
jjj=jjj+1;
args.lbx(jjj:n_states:n_states*(Np+1),1) = x12T_min; %state x12 lower bound
args.ubx(jjj:n_states:n_states*(Np+1),1) = x12T_max; %state x12 upper bound
jjj=jjj+1;
args.lbx(jjj:n_states:n_states*(Np+1),1) = x21T_min; %state x21 lower bound
args.ubx(jjj:n_states:n_states*(Np+1),1) = x21T_max; %state x21 upper bound
jjj=jjj+1;
args.lbx(jjj:n_states:n_states*(Np+1),1) = x22T_min; %state x22 lower bound
args.ubx(jjj:n_states:n_states*(Np+1),1) = x22T_max; %state x22 upper bound
jjj=jjj+1;
args.lbx(jjj:n_states:n_states*(Np+1),1) = x1T_min; %state x1 lower bound
args.ubx(jjj:n_states:n_states*(Np+1),1) = x1T_max; %state x1 upper bound
jjj=jjj+1;
args.lbx(jjj:n_states:n_states*(Np+1),1) = x2T_min; %state x2 lower bound
args.ubx(jjj:n_states:n_states*(Np+1),1) = x2T_max; %state x2 upper bound
jjj=jjj+1;
args.lbx(jjj:n_states:n_states*(Np+1),1) = xT_min; %state xT lower bound
args.ubx(jjj:n_states:n_states*(Np+1),1) = xT_max; %state xT upper bound
% Control bounds
jjj=1;
args.lbx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = w1_min; %uV11 lower bound
args.ubx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = w1_max; %uV11 upper bound
jjj=jjj+1;
args.lbx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = w2_min; %uV12 lower bound
args.ubx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = w2_max; %uV12 upper bound
clear jjj
%----------------------------------------------
% ALL OF THE ABOVE IS JUST A PROBLEM SET UP
%%
% Plot Simulation
% PlotMFDCurve(n1max,n2max,G1,G2,nc1,nc2,0,0,vit(1),vit(2),dT,Np)
% PlotState(0,Np,dT,nit(1),nit(2),G1(nit(1)),G2(nit(2)),vit(1),vit(2),[],[],[],[],ttt)
% THE SIMULATION LOOP SHOULD START FROM HERE
%-------------------------------------------
t0 = 0;
% x0 = [nijt nit]'; % initial condition.
x0 = [nijt nit nt]'; % initial condition.
xx(:,1) = x0; % xx contains the history of states
t(1) = t0;
u0 = ones(Np,n_controls);        % control inputs for each robot
X0 = repmat(x0,1,Np+1)'; % initialization of the states decision variables
sim_tim = Np*dT; % Maximum simulation time
% Start MPC
% DontStart=0;
% if(DontStart)
mpciter = 0;
xx1 = [];
u_cl=[];
% the main simulaton loop... it works as long as the error is greater
% than 10^-6 and the number of mpc steps is less than its maximum
% value.
main_loop = tic;
while(mpciter < sim_tim / dT) % new - condition for ending the loop
    current_time = mpciter*dT;  %new - get the current time
    %----------------------------------------------------------------------
    args.p(1:n_states) = x0; % initial condition of the robot posture
    for k = 1:Np %new - set the reference to track
        t_predict = current_time + (k-1)*dT; % predicted time instant
        %         x_ref = [zeros(size(nijt)) ncr];
        x_ref = [zeros(size(nijt)) zeros(size(nit)) zeros(size(nt))];
        u_ref = ones(1,n_controls);
        args.p(((n_states+n_controls)*k-(n_controls-1)):((n_states+n_controls)*k+(-(n_controls-1)+(n_states-1)))) = [x_ref];
        args.p(((n_states+n_controls)*k+(n_states-n_controls+1)):((n_states+n_controls)*k+((n_states-n_controls+1)+(n_controls-1)))) = [u_ref];
    end
    %----------------------------------------------------------------------
    % initial value of the optimization variables
    args.x0  = [reshape(X0',n_states*(Np+1),1);reshape(u0',n_controls*Np,1)];
    sol = solver('x0', args.x0, 'lbx', args.lbx, 'ubx', args.ubx,...
        'lbg', args.lbg, 'ubg', args.ubg,'p',args.p);
    u = reshape(full(sol.x(n_states*(Np+1)+1:end))',n_controls,Np)'; % get controls only from the solution
    xx1(:,1:n_states,mpciter+1)= reshape(full(sol.x(1:n_states*(Np+1)))',n_states,Np+1)'; % get solution TRAJECTORY
    u_cl= [u_cl ; u(1,:)];
    t(mpciter+1) = t0;
    % Apply the control and shift the solution
    [t0, x0, u0] = shift(dT, t0, x0, u,f);
    x0 = XVerification(x0,xCon);
    xx(:,mpciter+2) = x0;
    X0 = reshape(full(sol.x(1:n_states*(Np+1)))',n_states,Np+1)'; % get solution TRAJECTORY
    % Shift trajectory to initialize the next step
    X0 = [X0(2:end,:);X0(end,:)];
    mpciter = mpciter + 1;
end;
PlotState(mpciter,Np,dT,xx(5,:),xx(6,:),G1(xx(5,:)),G2(xx(6,:)),Vn1(xx(5,:)),Vn2(xx(6,:)),u_cl(:,1),u_cl(:,2),ttt,Settings);
MPCSim.G1 = G1(xx(5,:));
MPCSim.G2 = G2(xx(6,:));
MPCSim.n1 = xx(5,:);
MPCSim.n2 = xx(6,:);
MPCSim.n = xx(7,:);
MPCSim.w1 = u_cl(:,1);
MPCSim.w2 = u_cl(:,2);
MPCSim.Q = Q;
MPCSim.R = R;
MPCSim.u_cont = u_cont;
main_loop_time = toc(main_loop);
average_mpc_time = main_loop_time/(mpciter+1);
w_opt = u_cl(1,:);
%% Calulcate Objective function results
% Q.*(xx(:,1)-[0,0,0,0,nc1,nc2,0,0,0,0]).^2 + R.*((u_cl(1,:)-1)^2);
% MPCSim.Jk0 = sum(Q.*((xx(:,1)-[0,0,0,0,nc1,nc2,0,0,0,0]').^2),'all') + sum(R.*((u_cl(1,:)-1).^2),'all');
% MPCSim.Jk0uw = sum(((xx(:,1)-[0,0,0,0,nc1,nc2,0,0,0,0]').^2),'all') + sum(((u_cl(1,:)-1).^2),'all');clc;
disp(['[INFO] t=', num2str(ttt), 's | TCP_SpeedControl_MPC_Macro: w_opt = [', num2str(w_opt), '], V_act = [', num2str(w_opt.*vmax), '] m/s']);

end
 
function [x] = Smooth(xa)
if mod(xa,1)<0.1
    x = xa - mod(xa,1);
else
    x = xa - mod(xa,1) + 1;
end
end

function [t0, x0, u0] = shift(T, t0, x0, u,f)
st = x0;
con = u(1,:)';
% f_value = f(st,con);
% st = st+ (T*f_value);
% x0 = full(st);
h = T;
k1 = f(st, con);   % new
k2 = f(st + h/2*k1, con); % new
k3 = f(st + h/2*k2, con); % new
k4 = f(st + h*k3, con); % new
st_RK4=st + h/6*(k1 +2*k2 +2*k3 +k4); % new
x0 = full(st_RK4);
t0 = t0 + T;
u0 = [u(2:size(u,1),:);u(size(u,1),:)];
end

function [x_out] = XVerification(x_in,xCon)
x_out = x_in;
if(sum(sum(isnan(x_in))))
    x_out(isnan(x_in)) = 0;
end
if(sum(sum((x_in<0))))
    x_out(x_in<0) = 0;
end
x_out(x_in>xCon)=xCon(x_in>xCon);
end

function [] = ArrangeFigure(XLabel,YLabel,XLim,YLim,BolLegend,BolHold)
xlabel(XLabel,'FontUnits','points','interpreter','latex','FontSize',10,'FontName','Times')
ylabel(YLabel,'FontUnits','points','interpreter','latex','FontSize',10,'FontName','Times')
if XLim==0, xlim auto; else, xlim(XLim); end
if YLim==0, ylim auto; else, ylim(YLim); end
set(findall(gcf,'type','axes'),'FontUnits','points','ticklabelinterpreter','latex','FontSize',10,'FontName','Times')
set(findall(gcf,'type','legend'),'FontUnits','points','interpreter','latex','FontSize',10,'FontName','Times')
set(findall(gcf,'type','line'),'LineWidth',2)
set(findall(gcf,'type','Stair'),'LineWidth',2)
set(findall(gcf,'type','line'),'MarkerSize',4)
set(findall(gcf,'type','line'),'MarkerFaceColor','auto')
set(gcf,'Color','White');
set(gca,'Color','White');
if BolHold==0, hold off; else, hold on; end
%if BolLegend==0, legend off; else, legend on; end
screen_size = get(0, 'ScreenSize');
set(gcf, 'Position',[50 50 50+0.9*screen_size(3) 150+(9/16)*0.9*screen_size(4)]);
end

function [] = PlotMFDCurve(n1jam,n2jam,fG1,fG2,n1ref,n2ref,G1cr,G2cr,Vn1,Vn2,dt,tf)
figure(1); clf;
figure(1)
subplot(2,5,1)
plot(0:1:n1jam,fG1(0:1:n1jam),'k-','DisplayName','$G_{1}(n_{1})$'); hold on;
plot([n1ref n1ref],[0 G1cr],'r--')
ArrangeFigure('$n_{1}~[\mathrm{aircraft}]$','$G_{1}(n_{1})~[\mathrm{aircraft}/\mathrm{s}]$',[0 n1jam],0,0,1)
subplot(2,5,6)
plot(0:1:n2jam,fG2(0:1:n2jam),'k-','DisplayName','$G_{2}(n_{2})$'); hold on;
plot([n2ref n2ref],[0 G2cr],'r--')
ArrangeFigure('$n_{2}~[\mathrm{aircraft}]$','$G_{2}(n_{2})~[\mathrm{aircraft}/\mathrm{s}]$',[0 n2jam],0,0,1)
subplot(2,5,2)
plot([0 (tf)*dt],[n1ref n1ref],'r--')
ArrangeFigure('control step','$n_{1}~[\mathrm{aircraft}]$',[0 (tf)*dt],0,0,1)
subplot(2,5,7)
plot([0 (tf)*dt],[n2ref n2ref],'r--')
ArrangeFigure('control step','$n_{2}~[\mathrm{aircraft}]$',[0 (tf)*dt],0,0,1)
subplot(2,5,3)
plot([0 (tf)*dt],[Vn1 Vn1],'r--')
ArrangeFigure('control step','$v_{1}~[\mathrm{m}/\mathrm{s}]$',[0 (tf)*dt],0,0,1)
subplot(2,5,8)
plot([0 (tf)*dt],[Vn2 Vn2],'r--')
ArrangeFigure('control step','$v_{2}~[\mathrm{m}/\mathrm{s}]$',[0 (tf)*dt],0,0,1)
end

function [] = PlotState(tt,tf,dt,n1t,n2t,G1t,G2t,v1t,v2t,uV1t,uV2t,time,Settings)
figure(1)
sgtitle(['$\Delta_{k}=' num2str(tt*dt) '~[\mathrm{s}], \, n_{1}(t)=' num2str(round(n1t(end))) '~[\mathrm{aircraft}], \, n_{2}(t)=' num2str(round(n2t(end))) '~[\mathrm{aircraft}], \, t_{\mathrm{s}}=' num2str(round(time)) '~[\mathrm{s}]$'],'FontUnits','points','interpreter','latex','FontSize',10,'FontName','Times')
subplot(2,5,1)
plot(n1t(end),G1t(end),'b*')
ArrangeFigure('$n_{1}~[\mathrm{aircraft}]$','$G_{1}(n_{1})~[\mathrm{aircraft}/\mathrm{s}]$',0,0,0,1)
subplot(2,5,6)
plot(n2t(end),G2t(end),'b*')
ArrangeFigure('$n_{2}~[\mathrm{aircraft}]$','$G_{2}(n_{2})~[\mathrm{aircraft}/\mathrm{s}]$',0,0,0,1)
subplot(2,5,2)
plot([0:1:tt].*dt, n1t,'b--*')
ArrangeFigure('control step','$n_{1}~[\mathrm{aircraft}]$',[0 (tf)*dt],[0 1.2*max(n1t)],0,1)
subplot(2,5,7)
plot([0:1:tt].*dt,n2t,'b--*')
ArrangeFigure('control step','$n_{2}~[\mathrm{aircraft}]$',[0 (tf)*dt],[0 1.2*max(n2t)],0,1)
if(tt~=0)
    subplot(2,5,3)
    plot([0:1:tt].*dt, v1t,'b--*')
    ArrangeFigure('control step','$v_{1}~[\mathrm{m/s}]$',[0 (tf)*dt],[0, Settings.Aircraft.vm_range(2)],0,1)
    subplot(2,5,8)
    plot([0:1:tt].*dt,v2t,'b--*')
    ArrangeFigure('control step','$v_{2}~[\mathrm{m/s}]$',[0 (tf)*dt],[0, Settings.Aircraft.vm_range(2)],0,1)
    subplot(2,5,4)
    stairs([0:1:(tt)].*dt,[uV1t;uV1t(end)],['--o'])
    ArrangeFigure('control step','$w_{1}~[-]$',[0 (tf)*dt],[0 1],0,0)
    subplot(2,5,5)
    plot(n1t(end),v1t(end),'b*')
    ArrangeFigure('$n_{1}~[\mathrm{aircraft}]$','$v_{1}~[\mathrm{m/s}]$',0,[0, Settings.Aircraft.vm_range(2)],0,1)
    subplot(2,5,9)
    stairs([0:1:(tt)].*dt,[uV2t;uV2t(end)],['--o'])
    ArrangeFigure('control step','$w_{2}~[-]$',[0 (tf)*dt],[0 1],0,0)
    subplot(2,5,10)
    plot(n2t(end),v2t(end),'b*')
    ArrangeFigure('$n_{2}~[\mathrm{aircraft}]$','$v_{2}~[\mathrm{m/s}]$',0,[0, Settings.Aircraft.vm_range(2)],0,1)
end
end