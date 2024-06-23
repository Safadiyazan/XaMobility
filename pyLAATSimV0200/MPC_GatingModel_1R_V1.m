function [uI_opt,TFC] = MPC_GatingModel_1R_V1(SimInfo,ObjAircraft,Settings,TFC,ttt)
%%
import casadi.*
%% Current state
nt = TFC.N.n(end);
vt = TFC.N.V(end);
vstar = Settings.TFC.vECstar;
vmin = Settings.TFC.vECmin;
% ECt = TFC.N.ECv;
%% Setting for control problem
T = Settings.TFC.dtC;
dRi = cat(1,TFC.Ri(:).di);
dN = dRi(:,end);
d = sum(dN)/T;
ncn = Settings.TFC.ncn;
N = Settings.TFC.Np;
nmax = 6000;
xT_max = nmax; xT_min = 0;
uI_max = 1; uI_min = 0;
xCon = [xT_max]';
%% Define States
xT=SX.sym('xT');
states = [
    xT;
    ];
n_states = length(states);
%% Define Controllers
uI=SX.sym('uI');
controls = [
    uI;
    ];
n_controls = length(controls);
nI_controls = 1;
%% Functions
Gn = Settings.TFC.Gn;
Vn = Settings.TFC.Vn;
ECv = Settings.TFC.ECv;
ssECv = ECv(Settings.TFC.vECstar);
%%
rhs = [
%-----dnT----
d*uI - Gn(xT);
];
%%
f = Function('f',{states,controls},{rhs}); % nonlinear mapping function f(x,u)
U = SX.sym('U',n_controls,N); % Decision variables (controls)
P = SX.sym('P',n_states + N*(n_states+n_controls));
% parameters (which include the initial state and the reference along the
% predicted trajectory (reference states and reference controls))
X = SX.sym('X',n_states,(N+1));
% A vector that represents the states over the optimization problem.
%%
obj = 0; % Objective function
g = [];  % constraints vector
% EC weights
wE =  eye(n_states,n_states);
wE = 0;%1;
% State weights
Q =  eye(n_states,n_states);
Q(1,1) = 1/ncn;%0;% ssECv/ncn^2; % 0; % 1/ncn % n;
% Control weights
R =  eye(n_controls,n_controls); % weighing matrices (controls)
R(1,1) = ssECv;%ncn;%ssECv; % uI
%% Objective function
st  = X(:,1); % initial state
g = [g;st-P(1:n_states)]; % initial condition constraints
h = T;
for k = 1:N
    st = X(:,k);  con = U(:,k);
    obj = obj+wE*ECv(Vn(st))+(st-P(((n_states+n_controls)*k-(n_controls-1)):((n_states+n_controls)*k+(-(n_controls-1)+(n_states-1)))))'*Q*(st-P(((n_states+n_controls)*k-(n_controls-1)):((n_states+n_controls)*k+(-(n_controls-1)+(n_states-1))))) + ...
        (con-P(((n_states+n_controls)*k+(n_states-n_controls+1)):((n_states+n_controls)*k+((n_states-n_controls+1)+(n_controls-1)))))'*R*(con-P(((n_states+n_controls)*k+(n_states-n_controls+1)):((n_states+n_controls)*k+((n_states-n_controls+1)+(n_controls-1))))) ; % calculate obj
    st_next = X(:,k+1);
    f_value = f(st,con);
    st_next_euler = st + (T*f_value);
    g = [g;st_next-st_next_euler]; % compute constraints
end
% % Add constraints for collision avoidance
% obs_x = 0.5; % meters
% obs_y = 0.5; % meters
% obs_diam = 0.3; % meters
% for k = 1:N+1   % box constraints due to the map margins
%     g = [g ; -sqrt((X(1,k)-obs_x)^2+(X(2,k)-obs_y)^2) + (rob_diam/2 + obs_diam/2)];
% end
%%
% make the decision variable one column  vector
OPT_variables = [reshape(X,n_states*(N+1),1);reshape(U,n_controls*N,1)];
nlp_prob = struct('f', obj, 'x', OPT_variables, 'g', g, 'p', P);
opts = struct;
opts.ipopt.max_iter = 2000;
opts.ipopt.print_level =0;%0,3
opts.print_time = 0;
opts.ipopt.acceptable_tol =1e-8;
opts.ipopt.acceptable_obj_change_tol = 1e-6;
solver = nlpsol('solver', 'ipopt', nlp_prob,opts);
%%
args = struct;
args.lbg(1:n_states*(N+1)) =   -1e-20 ; % Equality constraints
args.ubg(1:n_states*(N+1)) =   1e-20  ; % Equality constraints
jjj=(1);
args.lbx(jjj:n_states:n_states*(N+1),1) = xT_min; %state x11 lower bound
args.ubx(jjj:n_states:n_states*(N+1),1) = xT_max; %state x11 upper bound
clear jjj
% Control bounds
jjj=1;
args.lbx(n_states*(N+1)+jjj:n_controls:n_states*(N+1)+n_controls*N,1) = uI_min; %ud1 lower bound
args.ubx(n_states*(N+1)+jjj:n_controls:n_states*(N+1)+n_controls*N,1) = uI_max; %ud1 upper bound
clear jjj
%----------------------------------------------
% ALL OF THE ABOVE IS JUST A PROBLEM SET UP
%%
% Plot Simulation
PlotMFDCurve(nmax,Gn,Vn,ncn,Gn(ncn),vstar,Vn(vstar),T,N)
PlotState(0,N,T,nt,Gn(nt),Vn(nt),[],[],ttt)
% THE SIMULATION LOOP SHOULD START FROM HERE
%-------------------------------------------
t0 = 0;
x0 = [nt]'; % initial condition.
xx(:,1) = x0; % xx contains the history of states
t(1) = t0;
u0 = ones(N,n_controls);        % control inputs for each robot
X0 = repmat(x0,1,N+1)'; % initialization of the states decision variables
sim_tim = N*T; % Maximum simulation time
% Start MPC
mpciter = 0;
xx1 = [];
u_cl=[];
% the main simulaton loop... it works as long as the error is greater
% than 10^-6 and the number of mpc steps is less than its maximum
% value.
main_loop = tic;
while(mpciter < sim_tim / T) % new - condition for ending the loop
    current_time = mpciter*T;  %new - get the current time
    %----------------------------------------------------------------------
    args.p(1:n_states) = x0; % initial condition of the robot posture
    for k = 1:N %new - set the reference to track
        t_predict = current_time + (k-1)*T; % predicted time instant
%         x_ref = [zeros(size(nijt)) ncr];
        x_ref = [ncn];
        u_ref = ones(1,n_controls);
        args.p(((n_states+n_controls)*k-(n_controls-1)):((n_states+n_controls)*k+(-(n_controls-1)+(n_states-1)))) = [x_ref];
        args.p(((n_states+n_controls)*k+(n_states-n_controls+1)):((n_states+n_controls)*k+((n_states-n_controls+1)+(n_controls-1)))) = [u_ref];
    end
    %----------------------------------------------------------------------
    % initial value of the optimization variables
    args.x0  = [reshape(X0',n_states*(N+1),1);reshape(u0',n_controls*N,1)];
    sol = solver('x0', args.x0, 'lbx', args.lbx, 'ubx', args.ubx,...
        'lbg', args.lbg, 'ubg', args.ubg,'p',args.p);
    u = reshape(full(sol.x(n_states*(N+1)+1:end))',n_controls,N)'; % get controls only from the solution
    xx1(:,1:n_states,mpciter+1)= reshape(full(sol.x(1:n_states*(N+1)))',n_states,N+1)'; % get solution TRAJECTORY
    u_cl= [u_cl ; u(1,:)];
    t(mpciter+1) = t0;
    % Apply the control and shift the solution
    [t0, x0, u0] = shift(T, t0, x0, u,f);
    x0 = XVerification(x0,xCon);
    xx(:,mpciter+2) = x0;
    X0 = reshape(full(sol.x(1:n_states*(N+1)))',n_states,N+1)'; % get solution TRAJECTORY
    % Shift trajectory to initialize the next step
    X0 = [X0(2:end,:);X0(end,:)];    
    mpciter = mpciter + 1;
end;
PlotState(mpciter,N,T,xx(1,:),Gn(xx(1,:)),Vn(xx(1,:)),u_cl(:,1),[],ttt)
TFC.MPCSim = [];
TFC.MPCSim.Gn = Gn(xx(1,:));
TFC.MPCSim.Vn = Vn(xx(1,:));
TFC.MPCSim.ECv = ECv(Vn(xx(1,:)));
TFC.MPCSim.nt = xx(1,:);
TFC.MPCSim.uI = u_cl(:,1);
main_loop_time = toc(main_loop);
average_mpc_time = main_loop_time/(mpciter+1);
u_opt = u_cl(:,:);
uI_opt=u_opt(:,1);
end

function [t0, x0, u0] = shift(T, t0, x0, u,f)
% if(isnan(x0))
%     warning('x0 have nan')
%     x0(isnan(x0)) = 0;
% end
% if(min(x0)<0)
%     warning('x0 have negative')
%     x0(x0<0) = 0;
% end
st = x0;
con = u(1,:)';
f_value = f(st,con);
st = st+ (T*f_value);
x0 = full(st);
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

function [] = PlotMFDCurve(njam,fG,fV,nref,Gcr,vref,Vcr,dt,tf)
    figure(1); clf;
    figure(1)
    subplot(2,3,1)
    plot(0:1:njam,fG(0:1:njam),'k-','DisplayName','$G(n)$'); hold on;
    plot([nref nref],[0 Gcr],'r--')
    subplot(2,3,4)
    plot(0:1:njam,fV(0:1:njam),'k-','DisplayName','$G(n)$'); hold on;
%     plot([vref vref],[0 Vcr],'r--')
    ArrangeFigure('$n~[\mathrm{aircraft}]$','$V(n)~[\mathrm{m}/\mathrm{s}]$',[0 njam],0,0,1)
    subplot(2,3,2)
    plot([0 (tf)*dt],[nref nref],'r--')
    ArrangeFigure('control step','$n~[\mathrm{aircraft}]$',[0 (tf)*dt],0,0,1)
    subplot(2,3,5)
    plot([0 (tf)*dt],[vref vref],'r--')
    ArrangeFigure('control step','$v~[\mathrm{m}/\mathrm{s}]$',[0 (tf)*dt],0,0,1)
end

function [] = PlotState(tt,tf,dt,nt,Gt,Vn,uIt,uVt,t)
    figure(1)
    sgtitle(['$\Delta_{k}=' num2str(tt*dt) '~[\mathrm{s}], \, n(t)=' num2str(round(nt(end))) '~[\mathrm{aircraft}], \, v(t)=' num2str(round(Vn(end))) '~[\mathrm{m}/\mathrm{s}], \, t_{\mathrm{s}}=' num2str(t) '~[\mathrm{s}]$'],'FontUnits','points','interpreter','latex','FontSize',10,'FontName','Times')
    subplot(2,3,1)
    plot(nt(end),Gt(end),'b*')
    subplot(2,3,4)
    plot(nt(end),Vn(end),'b*')
    subplot(2,3,2)
    plot([0:1:tt].*dt, nt,'b--*')
    ArrangeFigure('control step','$n~[\mathrm{aircraft}]$',[0 (tf)*dt],[0 1.2*max(nt)],0,1)
    subplot(2,3,5)
    plot([0:1:tt].*dt, Vn,'b--*')
    ArrangeFigure('control step','$v~[\mathrm{m}/\mathrm{s}]$',[0 (tf)*dt],[0 1.2*max(Vn)],0,1)
    if(tt~=0)
    subplot(2,3,3)
    stairs([0:1:(tt)].*dt,[uIt;uIt(end)],['--o'],'color','r')
    ArrangeFigure('control step','$u_{\mathrm{I}}~[-]$',[0 (tf)*dt],[0 1],0,0)
    subplot(2,3,6)
%     stairs([0:1:(tt)].*dt,[uVt;uVt(end)],['--o'],'color','r')
    ArrangeFigure('control step','$u_{\mathrm{V}}~[-]$',[0 (tf)*dt],[0 1],0,0)
    end
end