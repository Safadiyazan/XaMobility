function [ud_opt,ub_opt,MPCSim] = MPC_CoupledModel_3L2R_V1(SimInfo,ObjAircraft,Settings,TFC,ttt)
%%
warning('TODO: only worked for DBC ISTTT25, should be updated as with LeM')
warning('TODO: Should be updated to Multi-layer!')
import casadi.*
% function [ud_opt,ub_opt,MPCSim] = MPC_CoupledModel_2R_V2(time,qit,qijt,ncr,nit,nijt,nqit,nqiht,bijt,ncrijt,T,N,Omega,fitGN11,fitGN22)
%% Setting for control problem
dT = Settings.TFC.dtMPC;
Np = Settings.TFC.Np;
n1max = 3*Settings.TFC.nci(3);
n2max = 3*Settings.TFC.nci(4);
% nijt = [sum(reshape(TFC.Ri(3).nih,2,3),2)',sum(reshape(TFC.Ri(4).nih,2,3),2)'];
n_regions = size(unique(cat(1,Settings.Airspace.Regions.B.ri)),1)/size(Settings.Airspace.Layers,2);
n_layers = size(unique(cat(1,Settings.Airspace.Regions.B.ri)),1)/(size(unique(cat(1,Settings.Airspace.Regions.B.ri)),1)/size(Settings.Airspace.Layers,2));
nijt = [sum(reshape(TFC.Ri(3).nid(ttt/dT,:),n_regions,n_layers),2)',sum(reshape(TFC.Ri(4).nid(ttt/dT,:),n_regions,n_layers),2)'];
nit = [TFC.Ri(3).ni(ttt/dT), TFC.Ri(4).ni(ttt/dT)];
% ndqit = [TFC.Ri(3).ndqi(ttt/dT), TFC.Ri(4).ndqi(ttt/dT)];
ndqit = [TFC.Ri(1).ndqi(ttt/dT), TFC.Ri(2).ndqi(ttt/dT)];
% nbqiht = [TFC.Ri(3).nbqi(ttt/dT), TFC.Ri(4).nbqi(ttt/dT)];
nbqiht = [TFC.Ri(5).nbqi(ttt/dT), TFC.Ri(6).nbqi(ttt/dT)];
qijt = [TFC.Ri(1).qinij(ttt/dT,1), TFC.Ri(1).qinij(ttt/dT,2),TFC.Ri(2).qinij(ttt/dT,1), TFC.Ri(2).qinij(ttt/dT,2)]./dT;
% qijt = [TFC.Ri(1).dij(ttt/dT,1), TFC.Ri(1).dij(ttt/dT,2),TFC.Ri(2).dij(ttt/dT,1), TFC.Ri(2).dij(ttt/dT,2)]./dT;
% disp([[TFC.Ri(1).qinij(ttt/dT,1), TFC.Ri(1).qinij(ttt/dT,2),TFC.Ri(2).qinij(ttt/dT,1), TFC.Ri(2).qinij(ttt/dT,2)];[TFC.Ri(1).dij(ttt/dT,1), TFC.Ri(1).dij(ttt/dT,2),TFC.Ri(2).dij(ttt/dT,1), TFC.Ri(2).dij(ttt/dT,2)]])
d11 = qijt(1);
d12 = qijt(2);
d21 = qijt(3);
d22 = qijt(4);
nc1 = Settings.TFC.nci(3);
nc2 = Settings.TFC.nci(4);
nc = nc1 + nc2;
x11T_max = inf; x11T_min = 0;
x12T_max = inf; x12T_min = 0;
x21T_max = inf; x21T_min = 0;
x22T_max = inf; x22T_min = 0;
x1T_max = n1max; x1T_min = 0;
x2T_max = n2max; x2T_min = 0;
x1DQ_max = nc1; x1DQ_min = 0; warning('double check queue constraints');
x2DQ_max = nc2; x2DQ_min = 0;
x12Q_max = 3*nc1; x12Q_min = 0;
x21Q_max = 3*nc2; x21Q_min = 0;
udi_max = Settings.TFC.udi(2); udi_min = Settings.TFC.udi(1);
ubij_max = Settings.TFC.ubij(2); ubij_min = Settings.TFC.ubij(1);
u_cont = [udi_max,udi_min,ubij_max,ubij_min,ubij_max,ubij_min];
xCon = [x11T_max,x12T_max,x21T_max,x22T_max,x1T_max,x2T_max,x1DQ_max,x2DQ_max,x12Q_max,x21Q_max]';
%% Define States
x11T=SX.sym('x11T');
x12T=SX.sym('x12T');
x21T=SX.sym('x21T');
x22T=SX.sym('x22T');
x1T=SX.sym('x1T');
x2T=SX.sym('x2T');
x1DQ=SX.sym('x1DQ');
x2DQ=SX.sym('x2DQ');
x12Q=SX.sym('x12Q');
x21Q=SX.sym('x21Q');
states = [
    x11T;
    x12T;
    x21T;
    x22T;
    x1T;
    x2T;
    x1DQ;
    x2DQ;
    x12Q;
    x21Q;
    ];
n_states = length(states);
nijT_states = 4;
niT_states = 2;
niDQ_states = 2;
nijQ_states = 2;
%% Define Controllers
ud1=SX.sym('ud1');
ud2=SX.sym('ud2');
ub12I=SX.sym('ub12I');
ub21I=SX.sym('ub21I');
ub12O=SX.sym('ub12O');
ub21O=SX.sym('ub21O');
controls = [
    ud1;
    ud2;
    ub12I;
    ub21I;
    ub12O;
    ub21O;
    ];
n_controls = length(controls);
nd_controls = 2;
nb_controls = 4;
%% Functions
% sF = @(x,a,b) [a + (b + a) * (1./(1 + exp(-x)))];
G1 = Settings.TFC.funGNRi11;
G2 = Settings.TFC.funGNRi12;
% sG = @(Gdt) [min(10,max(0,(Gdt)))];
bij = @(xij,xi) [min(1,max(0,(xij/xi)))];
S1BQ = G1(nc1);
S2BQ = G2(nc2);
%% Sigmoid function
% sF = @(x,a,b) [-a + (b + a) * (1./(1 + exp(-x)))];
% sF = @(a,b,x) [min(b,max(a,(x)))];
%%
rhs = [
    %-----dn11T----
    % d11*ud1 + bij(x21T,x2T)*(G2(x2T))*ub21I + bij(x21T,x2T)*S2BQ*ub21O - bij(x11T,x1T)*(G1(x1T));
    d11*ud1 + bij(x21T,x2T)*(G2(x2T))*ub21I + bij(x21T,x2T)*(G2(x21Q))*ub21O - bij(x11T,x1T)*(G1(x1T));
    %-----dn12T----
    d12*ud1 - bij(x12T,x1T)*(G1(x1T))*ub12I;
    %-----dn21T----
    d21*ud2 - bij(x21T,x2T)*(G2(x2T))*ub21I;
    %-----dn22T----
    % d22*ud2 + bij(x12T,x1T)*(G1(x1T))*ub12I + bij(x12T,x1T)*S1BQ*ub12O - bij(x22T,x2T)*(G2(x2T));
    d22*ud2 + bij(x12T,x1T)*(G1(x1T))*ub12I + bij(x12T,x1T)*(G1(x12Q))*ub12O - bij(x22T,x2T)*(G2(x2T));
    %-----dn1T----
    % d11*ud1 + bij(x21T,x2T)*(G2(x2T))*ub21I + bij(x21T,x2T)*S2BQ*ub21O - bij(x11T,x1T)*(G1(x1T)) + d12*ud1 - bij(x12T,x1T)*(G1(x1T))*ub12I;
    d11*ud1 + bij(x21T,x2T)*(G2(x2T))*ub21I + bij(x21T,x2T)*(G2(x21Q))*ub21O - bij(x11T,x1T)*(G1(x1T)) + d12*ud1 - bij(x12T,x1T)*(G1(x1T))*ub12I;
    %-----dn2T----
    % d21*ud2 - bij(x21T,x2T)*(G2(x2T))*ub21I + d22*ud2 + bij(x12T,x1T)*(G1(x1T))*ub12I + bij(x12T,x1T)*S1BQ*ub12O - bij(x22T,x2T)*(G2(x2T));
    d21*ud2 - bij(x21T,x2T)*(G2(x2T))*ub21I + d22*ud2 + bij(x12T,x1T)*(G1(x1T))*ub12I + bij(x12T,x1T)*(G1(x12Q))*ub12O - bij(x22T,x2T)*(G2(x2T));
    %-----dn1DQ----
    (d11+d12)*(1-ud1);
    %-----dn2DQ----
    (d22+d21)*(1-ud2);
    %-----dn12Q----
    % bij(x12T,x1T)*(G1(x1T))*(1-ub12I) - bij(x12T,x1T)*S1BQ*ub12O;
    bij(x12T,x1T)*(G1(x1T))*(1-ub12I) - bij(x12T,x1T)*(G1(x12Q))*ub12O;
    %-----dn21Q----
    % bij(x21T,x2T)*(G2(x2T))*(1-ub21I) - bij(x21T,x2T)*S2BQ*ub21O;
    bij(x21T,x2T)*(G2(x2T))*(1-ub21I) - bij(x21T,x2T)*(G2(x21Q))*ub21O;
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
% Settings.TFC.Omega = [WnijT, Wni, Wndqi, Wnbqih, Wud, WubIN, WubOUT];
Omega = Settings.TFC.Omega;
Q =  eye(n_states,n_states);
Q(1,1) = Omega(1);%1/nc;% Omega.WnijT(1); % x11T;
Q(2,2) = Omega(2);%1/nc;% Omega.WnijT(2); % x12T;
Q(3,3) = Omega(3);%1/nc;% Omega.WnijT(3); % x21T;
Q(4,4) = Omega(4);%1/nc;% Omega.WnijT(4); % x22T;
Q(5,5) = Omega(5);%1/nc1;% Omega.WniT(1); % x1T;
Q(6,6) = Omega(6);%1/nc2;%Omega.WniT(2); % x2T;
Q(7,7) = Omega(7);%0; %Omega.WniDQ(1); % x1DQ;
Q(8,8) = Omega(8);%0; %Omega.WniDQ(2); % x2DQ;
Q(9,9) = Omega(9);%0; %Omega.WnijQ(1); % x12Q;
Q(10,10) = Omega(10);%0; %Omega.WnijQ(2); % x21Q;
% Control weights
R =  zeros(n_controls,n_controls); % weighing matrices (controls)
R(1,1) = Omega(11);%nc; %Omega.Wud(1); % ud1;
R(2,2) = Omega(12);%nc; %Omega.Wud(2); % ud2;
R(3,3) = Omega(13);%nc; %Omega.Wub(1); % ub12I;
R(4,4) = Omega(14);%nc; %Omega.Wub(2); % ub21I;
R(5,5) = Omega(15);%nc; %Omega.Wub(3); % ub12O;
R(6,6) = Omega(16);%nc; %Omega.Wub(4); % ub21O;
%%
max_rate=0.1;
%% Objective function
st  = X(:,1); % initial state
g = [g;st-P(1:n_states)]; % initial condition constraints
h = dT;
for k = 1:Np
    st = X(:,k);  con = U(:,k);
    obj = obj+(st-P(((n_states+n_controls)*k-(n_controls-1)):((n_states+n_controls)*k+(-(n_controls-1)+(n_states-1)))))'*Q*(st-P(((n_states+n_controls)*k-(n_controls-1)):((n_states+n_controls)*k+(-(n_controls-1)+(n_states-1))))) + ...
        (con-P(((n_states+n_controls)*k+(n_states-n_controls+1)):((n_states+n_controls)*k+((n_states-n_controls+1)+(n_controls-1)))))'*R*(con-P(((n_states+n_controls)*k+(n_states-n_controls+1)):((n_states+n_controls)*k+((n_states-n_controls+1)+(n_controls-1))))) ; % calculate obj
    st_next = X(:,k+1);
    % f_value = f(st,con);
    % st_next_euler = st+ (dT*f_value);
    % g = [g;st_next-st_next_euler]; % compute constraints
    k1 = f(st, con);   % new 
    k2 = f(st + h/2*k1, con); % new
    k3 = f(st + h/2*k2, con); % new
    k4 = f(st + h*k3, con); % new
    st_next_RK4=st +h/6*(k1 +2*k2 +2*k3 +k4); % new 
    g = [g;st_next-st_next_RK4]; % compute constraints % new
end
% for k = 1:Np-1
%     g = [g; U(:, k+1) - U(:, k) - max_rate; U(:, k) - U(:, k+1) - max_rate];
% end
%%
% make the decision variable one column  vector
OPT_variables = [reshape(X,n_states*(Np+1),1);reshape(U,n_controls*Np,1)];
nlp_prob = struct('f', obj, 'x', OPT_variables, 'g', g, 'p', P);
opts = struct;
opts.ipopt.max_iter = 100; warning('double check max iter');
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
args.lbx(jjj:n_states:n_states*(Np+1),1) = x1DQ_min; %state xiq1 lower bound
args.ubx(jjj:n_states:n_states*(Np+1),1) = x1DQ_max; %state xiq1 upper bound
jjj=jjj+1;
args.lbx(jjj:n_states:n_states*(Np+1),1) = x2DQ_min; %state xiq2 lower bound
args.ubx(jjj:n_states:n_states*(Np+1),1) = x2DQ_max; %state xiq2 upper bound
jjj=jjj+1;
args.lbx(jjj:n_states:n_states*(Np+1),1) = x12Q_min; %state xiq1 lower bound
args.ubx(jjj:n_states:n_states*(Np+1),1) = x12Q_max; %state xiq1 upper bound
jjj=jjj+1;
args.lbx(jjj:n_states:n_states*(Np+1),1) = x21Q_min; %state xiq2 lower bound
args.ubx(jjj:n_states:n_states*(Np+1),1) = x21Q_max; %state xiq2 upper bound
clear jjj
% Control bounds
jjj=1;
args.lbx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = udi_min; %ud1 lower bound
args.ubx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = udi_max; %ud1 upper bound
jjj=jjj+1;
args.lbx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = udi_min; %ud2 lower bound
args.ubx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = udi_max; %ud2 upper bound
jjj=jjj+1;
args.lbx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = ubij_min; %ub12I lower bound
args.ubx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = ubij_max; %ub12I upper bound
jjj=jjj+1;
args.lbx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = ubij_min; %ub21I lower bound
args.ubx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = ubij_max; %ub21I upper bound
jjj=jjj+1;
args.lbx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = ubij_min; %ub12O lower bound
args.ubx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = ubij_max; %ub12O upper bound
jjj=jjj+1;
args.lbx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = ubij_min; %ub21O lower bound
args.ubx(n_states*(Np+1)+jjj:n_controls:n_states*(Np+1)+n_controls*Np,1) = ubij_max; %ub21O upper bound
clear jjj

%----------------------------------------------
% ALL OF THE ABOVE IS JUST A PROBLEM SET UP
%%
% Plot Simulation
% PlotMFDCurve(n1max,n2max,G1,G2,nc1,nc2,0,0,dT,Np)
% PlotState(0,Np,dT,nit(1),nit(2),G1(nit(1)),G2(nit(2)),[],[],[],[],[],[],ttt)
% THE SIMULATION LOOP SHOULD START FROM HERE
%-------------------------------------------
t0 = 0;
% x0 = [nijt nit]'; % initial condition.
x0 = [nijt nit ndqit nbqiht]'; % initial condition.
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
        x_ref = [zeros(size(nijt)) nc1 nc2 zeros(size(ndqit)) zeros(size(nbqiht))];
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
% PlotState(mpciter,Np,dT,xx(5,:),xx(6,:),G1(xx(5,:)),G2(xx(6,:)),u_cl(:,1),u_cl(:,2),u_cl(:,3),u_cl(:,4),u_cl(:,5),u_cl(:,6),ttt);
MPCSim.G1 = G1(xx(5,:));
MPCSim.G2 = G2(xx(6,:));
MPCSim.n1 = xx(5,:);
MPCSim.n2 = xx(6,:);
MPCSim.ndq1 = xx(7,:);
MPCSim.ndq2 = xx(8,:);
MPCSim.nbq12 = xx(9,:);
MPCSim.nbq21 = xx(10,:);
MPCSim.ud1 = u_cl(:,1);
MPCSim.ud2 = u_cl(:,2);
MPCSim.ub12I = u_cl(:,3);
MPCSim.ub21I = u_cl(:,4);
MPCSim.ub12O = u_cl(:,5);
MPCSim.ub21O = u_cl(:,6);
MPCSim.Q = Q;
MPCSim.R = R;
MPCSim.u_cont = u_cont;
main_loop_time = toc(main_loop);
average_mpc_time = main_loop_time/(mpciter+1);
u_opt = u_cl(:,:);
% end
% ud_opt=u_opt(1,1:2);
% ud_opt = [0.5 + (1-0.5) * rand,0.5 + (1-0.5) * rand];
ud_opt = [rand,rand];
% ub_opt=u_opt(1,3:6);
% ub_opt = [0.5 + (1-0.5) * rand,0.5 + (1-0.5) * rand,0.5 + (1-0.5) * rand,0.5 + (1-0.5) * rand];
ub_opt = [rand,rand,rand,rand];
%% Calulcate Objective function results
% Q.*(xx(:,1)-[0,0,0,0,nc1,nc2,0,0,0,0]).^2 + R.*((u_cl(1,:)-1)^2);
% MPCSim.Jk0 = sum(Q.*((xx(:,1)-[0,0,0,0,nc1,nc2,0,0,0,0]').^2),'all') + sum(R.*((u_cl(1,:)-1).^2),'all');
% MPCSim.Jk0uw = sum(((xx(:,1)-[0,0,0,0,nc1,nc2,0,0,0,0]').^2),'all') + sum(((u_cl(1,:)-1).^2),'all');
%% Calculate NbqIn NbqOut
NbqijIndt = zeros(2,2);
NbqijIndtNew = zeros(2,2);
NbqijOutdt = zeros(2,2);
ubijdt = ub_opt(1,:); % [ub12I,ub21I,ub12O,ub21O] % mean(ub_opt,1);
NbqijIndt(1,2) = Smooth((1-ub_opt(1))*bij(nijt(2),nit(1))*G1(nit(1))*dT);
NbqijIndt(2,1) = Smooth((1-ub_opt(2))*bij(nijt(3),nit(2))*G2(nit(2))*dT);
% disp('(NbqijIndt)=')
% disp(NbqijIndt)    
% NbqijOutdt(1,2) = Smooth((ub_opt(3))*bij(nijt(2),nit(1))*(S1BQ)*dT);
NbqijOutdt(1,2) = Smooth((ub_opt(3))*bij(nijt(2),nit(1))*(G1(nbqiht(1)))*dT);
% NbqijOutdt(2,1) = Smooth((ub_opt(4))*bij(nijt(3),nit(2))*(S2BQ)*dT);
NbqijOutdt(2,1) = Smooth((ub_opt(4))*bij(nijt(3),nit(2))*(G2(nbqiht(2)))*dT);
% disp('(NbqijOutdt)=')
% disp(NbqijOutdt)
dtbqc = dT.*(NbqijIndt>=1);%min((dtC.*max(0, 1-ubijdt) - mod(dtC.*max(0, 1-ubijdt),Ts)), Tsf*Ts-time);
MPCSim.dtbqc = dtbqc;
MPCSim.NbqijIndt = NbqijIndt;
MPCSim.NbqijOutdt = NbqijOutdt;
clc;
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

function [] = PlotMFDCurve(n1jam,n2jam,fG1,fG2,n1ref,n2ref,G1cr,G2cr,dt,tf)
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
end

function [] = PlotState(tt,tf,dt,n1t,n2t,G1t,G2t,ud1t,ud2t,ub12It,ub21It,ub12Ot,ub21Ot,time)
figure(1)
sgtitle(['$\Delta_{k}=' num2str(tt*dt) '~[\mathrm{s}], \, n_{1}(t)=' num2str(round(n1t(end))) '~[\mathrm{aircraft}], \, n_{2}(t)=' num2str(round(n2t(end))) '~[\mathrm{aircraft}], \, t_{\mathrm{s}}=' num2str(round(time)) '~[\mathrm{s}]$'],'FontUnits','points','interpreter','latex','FontSize',10,'FontName','Times')
subplot(2,5,1)
plot(n1t(end),G1t(end),'b*')
subplot(2,5,6)
plot(n2t(end),G2t(end),'b*')
subplot(2,5,2)
plot([0:1:tt].*dt, n1t,'b--*')
ArrangeFigure('control step','$n_{1}~[\mathrm{aircraft}]$',[0 (tf)*dt],[0 1.2*max(n1t)],0,1)
subplot(2,5,7)
plot([0:1:tt].*dt,n2t,'b--*')
ArrangeFigure('control step','$n_{2}~[\mathrm{aircraft}]$',[0 (tf)*dt],[0 1.2*max(n2t)],0,1)
if(tt~=0)
    subplot(2,5,3)
    stairs([0:1:(tt)].*dt,[ud1t;ud1t(end)],['--o'],'color','r')
    ArrangeFigure('control step','$u_{\mathrm{d},1}~[-]$',[0 (tf)*dt],[0 1],0,0)
    subplot(2,5,4)
    stairs([0:1:(tt)].*dt,[ub12It;ub12It(end)],['--o'])
    ArrangeFigure('control step','$u^{I}_{\mathrm{b},12}~[-]$',[0 (tf)*dt],[0 1],0,0)
    subplot(2,5,5)
    stairs([0:1:(tt)].*dt,[ub12Ot;ub12Ot(end)],['--o'])
    ArrangeFigure('control step','$u^{O}_{\mathrm{b},12}~[-]$',[0 (tf)*dt],[0 1],0,0)
    subplot(2,5,8)
    stairs([0:1:(tt)].*dt,[ud2t;ud2t(end)],['--o'],'color','r')
    ArrangeFigure('control step','$u_{\mathrm{d},2}~[-]$',[0 (tf)*dt],[0 1],0,0)
    subplot(2,5,9)
    stairs([0:1:(tt)].*dt,[ub21It;ub21It(end)],['--o'])
    ArrangeFigure('control step','$u^{I}_{\mathrm{b},21}~[-]$',[0 (tf)*dt],[0 1],0,0)
    subplot(2,5,10)
    stairs([0:1:(tt)].*dt,[ub21Ot;ub21Ot(end)],['--o'])
    ArrangeFigure('control step','$u^{O}_{\mathrm{b},21}~[-]$',[0 (tf)*dt],[0 1],0,0)
end
end