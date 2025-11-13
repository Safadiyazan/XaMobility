function [TFC,ObjAircraft,SimInfo] = TCP_SpeedControl_GC_Micro(SimInfo,ObjAircraft,Settings,TFC,t)
t = SimInfo.t;
dtC = SimInfo.dtC;
dtS = SimInfo.dtS;
tf = SimInfo.tf;
%% Set Control states
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))
    [TFC] = UpdateControlState(TFC,t/dtC);
end
% %% Determine GC Control Inputs
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))&&(Settings.TFC.TCP_SpeedController_GC)
    % [w_opt,TFC] = GC_SpeedControl_Gn_1L2R_j(SimInfo,ObjAircraft,Settings,TFC,t);
    [w_opt,TFC] = GC_SpeedControl_Ev_1L2R_j(SimInfo,ObjAircraft,Settings,TFC,t);
    % [w_opt,TFC] = GC_SpeedControl_1L2R_ij_1L(SimInfo,ObjAircraft,Settings,TFC,t);
    % [w_opt,TFC] = GC_SpeedControl_1L2R_ij_2L(SimInfo,ObjAircraft,Settings,TFC,t);
    % [w_opt,TFC] = GC_SpeedControl_2L2R_i(SimInfo,ObjAircraft,Settings,TFC,t);
    % [w_opt,TFC] = GC_SpeedControl_2L2R_ij(SimInfo,ObjAircraft,Settings,TFC,t);
end
%% Change MaxSpeed
if (t~=0)&&(~isempty(TFC.CS))&&(Settings.TFC.TCP_SpeedController_GC)% &&(mod(t,dtC)==0)
    [TFC,ObjAircraft,SimInfo] = ApplySpeedControl_1L2R_i(TFC,t,dtC,SimInfo,ObjAircraft,mean(Settings.Aircraft.vm_range));
    % [TFC,ObjAircraft,SimInfo] = ApplySpeedControl_1L2R_ij_1L(TFC,t,dtC,SimInfo,ObjAircraft,mean(Settings.Aircraft.vm_range));
    % [TFC,ObjAircraft,SimInfo] = ApplySpeedControl_1L2R_ij_2L(TFC,t,dtC,SimInfo,ObjAircraft,mean(Settings.Aircraft.vm_range));
    % [TFC,ObjAircraft,SimInfo] = ApplySpeedControl_2L2R_i(TFC,t,dtC,SimInfo,ObjAircraft,mean(Settings.Aircraft.vm_range));
    % [TFC,ObjAircraft,SimInfo] = ApplySpeedControl_2L2R_ij(TFC,t,dtC,SimInfo,ObjAircraft,mean(Settings.Aircraft.vm_range));
end
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))&&(Settings.TFC.TCP_SpeedController_GC)
    disp(['[INFO] t=', num2str(t), 's | TCP_SpeedControl_GC_Micro:']);
    disp(['  > Vm cmd: {', num2str(TFC.CS(end).Vmdt), '} [m/s]']);
    disp(['  > Active aircraft with Vm != 20: ', num2str(sum(cat(1,ObjAircraft(SimInfo.statusdt(t/dtS,:)==1).vm)~=20))]);
    disp(['  > Cumulative TTS: ', num2str(TFC.N.cumTTS(end)/3600), ' [hr]']);
    disp(['  > Avg network speed: ', num2str(TFC.N.V(end)), ' [m/s]']);
end
end

%% Additional Function
function [TFC] = UpdateControlState(TFC,k)
ri = cat(1,TFC.Ri(:).ri)';
TFC.CS(k).ri = ri;
ni = cat(1,TFC.Ri(:).ni)';
TFC.CS(k).nit = ni(end,:);
ndqi = cat(1,TFC.Ri(:).ndqi)';
TFC.CS(k).ndqit = ndqi(end,:);
G = cat(1,TFC.Ri(:).G)';
TFC.CS(k).Git = G(end,:);
end


%% Speed Control Function - Get w greedy

function [w_opt,TFC] = GC_SpeedControl_Gn_1L2R_j(SimInfo,ObjAircraft,Settings,TFC,t)
dtC = Settings.TFC.dtC;
% Assuming speed control is applied to the first two regions of the first flying layer.
region1_idx = 1;
region2_idx = 2;

n1t = [TFC.Ri(region1_idx).ni(t/dtC)];
n2t = [TFC.Ri(region2_idx).ni(t/dtC)];
v1t = [TFC.Ri(region1_idx).V(t/dtC)];
v2t = [TFC.Ri(region2_idx).V(t/dtC)];
%==========================
nc1 = Settings.TFC.Ri(region1_idx).nci;
Vn1 = Settings.TFC.Ri(region1_idx).Vn;
ECv1 = Settings.TFC.Ri(region1_idx).ECv;
v1star = Settings.TFC.Ri(region1_idx).vECstar;
ssECv1 = Settings.TFC.Ri(region1_idx).ssECv;
nc2 = Settings.TFC.Ri(region2_idx).nci;
Vn2 = Settings.TFC.Ri(region2_idx).Vn;
ECv2 = Settings.TFC.Ri(region2_idx).ECv;
v2star = Settings.TFC.Ri(region2_idx).vECstar;
ssECv2 = Settings.TFC.Ri(region2_idx).ssECv;
vmax = Settings.TFC.vECmax;
%==========================
w1_max = min(vmax)/vmax; w1_min = min(v1star)/vmax;
w2_max = min(vmax)/vmax; w2_min = min(v2star)/vmax;
% Setup strategy
if ((n1t<nc1) && (n2t<nc2))
    w1dt = w1_max;
    w2dt = w2_max;
end
if ((n1t>=nc1) && (n2t<nc2))
    w1dt = w1_max;
    w2dt = w2_min;
end
if ((n1t<nc1) && (n2t>=nc2))
    w1dt = w1_min;
    w2dt = w2_max;
end
if ((n1t>=nc1) && (n2t>=nc2))
    w1dt = w1_min;
    w2dt = w2_min;
end
TFC.CS(t/dtC).w1dt = w1dt;
TFC.CS(t/dtC).w2dt = w2dt;
TFC.CS(t/dtC).Vmdt = max(0,min(vmax,round(vmax.*[w1dt, w2dt])));
w_opt = [w1dt, w2dt];
end

function [w_opt,TFC] = GC_SpeedControl_En_1L2R_j(SimInfo,ObjAircraft,Settings,TFC,t)
dtC = Settings.TFC.dtC;
% Assuming speed control is applied to the first two regions of the first flying layer.
region1_idx = 1;
region2_idx = 2;

n1t = [TFC.Ri(region1_idx).ni(t/dtC)];
n2t = [TFC.Ri(region2_idx).ni(t/dtC)];
v1t = [TFC.Ri(region1_idx).V(t/dtC)];
v2t = [TFC.Ri(region2_idx).V(t/dtC)];
e1t = TFC.EC.Ri(region1_idx).EC(end);
e2t = TFC.EC.Ri(region2_idx).EC(end);
%==========================
nc1 = Settings.TFC.Ri(region1_idx).nci;
Vn1 = Settings.TFC.Ri(region1_idx).Vn;
ECv1 = Settings.TFC.Ri(region1_idx).ECv;
v1star = Settings.TFC.Ri(region1_idx).vECstar;
E1star = ECv1(v1star/1.2);
nE1star = 21;
nc2 = Settings.TFC.Ri(region2_idx).nci;
Vn2 = Settings.TFC.Ri(region2_idx).Vn;
ECv2 = Settings.TFC.Ri(region2_idx).ECv;
v2star = Settings.TFC.Ri(region2_idx).vECstar;
E2star = ECv2(v2star/1.2);
nE2star = 56;
vmax = Settings.TFC.vECmax;
%==========================
w1_max = min(vmax)/vmax; w1_min = min(v1star)/vmax;
w2_max = min(vmax)/vmax; w2_min = min(v2star)/vmax;
% Setup strategy
if ((n1t<nE1star) && (n2t<nE2star))
    w1dt = w1_max;
    w2dt = w2_max;
end
if ((n1t>=nE1star) && (n2t<nE2star))
    w1dt = w1_max;
    w2dt = w2_min;
end
if ((n1t<nE1star) && (n2t>=nE2star))
    w1dt = w1_min;
    w2dt = w2_max;
end
if ((n1t>=nE1star) && (n2t>=nE2star))
    w1dt = w1_min;
    w2dt = w2_min;
end
TFC.CS(t/dtC).w1dt = w1dt;
TFC.CS(t/dtC).w2dt = w2dt;
TFC.CS(t/dtC).Vmdt = max(0,min(vmax,round(vmax.*[w1dt, w2dt])));
w_opt = [w1dt, w2dt];
end

function [w_opt,TFC] = GC_SpeedControl_Ev_1L2R_j(SimInfo,ObjAircraft,Settings,TFC,t)
dtC = Settings.TFC.dtC;
% Assuming speed control is applied to the first two regions of the first flying layer.
region1_idx = 1;
region2_idx = 2;

n1t = [TFC.Ri(region1_idx).ni(t/dtC)];
n2t = [TFC.Ri(region2_idx).ni(t/dtC)];
v1t = [TFC.Ri(region1_idx).V(t/dtC)];
v2t = [TFC.Ri(region2_idx).V(t/dtC)];
%==========================
nc1 = Settings.TFC.Ri(region1_idx).nci;
Vn1 = Settings.TFC.Ri(region1_idx).Vn;
ECv1 = Settings.TFC.Ri(region1_idx).ECv;
v1star = Settings.TFC.Ri(region1_idx).vECstar;
v1min = Settings.TFC.Ri(region1_idx).vECstar/1.2; % Assuming vECmin is related to vECstar
ssECv1 = Settings.TFC.Ri(region1_idx).ssECv;
nc2 = Settings.TFC.Ri(region2_idx).nci;
Vn2 = Settings.TFC.Ri(region2_idx).Vn;
ECv2 = Settings.TFC.Ri(region2_idx).ECv;
v2star = Settings.TFC.Ri(region2_idx).vECstar;
v2min = Settings.TFC.Ri(region2_idx).vECstar/1.2; % Assuming vECmin is related to vECstar
ssECv2 = Settings.TFC.Ri(region2_idx).ssECv;
vmax = Settings.TFC.vECmax;
%==========================
w1_max = min(vmax)/vmax; w1_min = min(v1star)/vmax;
w2_max = min(vmax)/vmax; w2_min = min(v2star)/vmax;
% Setup strategy
if ((v1t>v1min) && (v2t>v2min))
    w1dt = w1_max;
    w2dt = w2_max;
end
if ((v1t<=v1min) && (v2t>v2min))
    w1dt = w1_max;
    w2dt = w2_min;
end
if ((v1t>v1min) && (v2t<=v2min))
    w1dt = w1_min;
    w2dt = w2_max;
end
if ((v1t<=v1min) && (v2t<=v2min))
    w1dt = w1_min;
    w2dt = w2_min;
end
TFC.CS(t/dtC).w1dt = w1dt;
TFC.CS(t/dtC).w2dt = w2dt;
TFC.CS(t/dtC).Vmdt = max(0,min(vmax,round(vmax.*[w1dt, w2dt])));
w_opt = [w1dt, w2dt];
end

% function [w_opt] = GC_SpeedControl_1L2R_ij_1L(SimInfo,ObjAircraft,Settings,TFC,t)
% % [wij_opt,MPCSim] = GC_SpeedModel_1L2R_V2(SimInfo,ObjAircraft,Settings,TFC,t);
% % TFC.MPCSim(t/dtC) = MPCSim;
% % TFC.CS(t/dtC).uV11dt = uV_opt(1);
% % TFC.CS(t/dtC).uV12dt = uV_opt(2);
% % TFC.CS(t/dtC).uV21dt = uV_opt(3);
% % TFC.CS(t/dtC).uV22dt = uV_opt(4);
% % TFC.CS(t/dtC).V11dt = max(0,min(vmG,round(uV_opt(1)*Settings.TFC.vECmax)));
% % TFC.CS(t/dtC).V12dt = max(0,min(vmG,round(uV_opt(2)*Settings.TFC.vECmax)));
% % TFC.CS(t/dtC).V21dt = max(0,min(vmG,round(uV_opt(3)*Settings.TFC.vECmax)));
% % TFC.CS(t/dtC).V22dt = max(0,min(vmG,round(uV_opt(4)*Settings.TFC.vECmax)));
% % TFC.CS(t/dtC).Vmdt = max(0,min(vmG,round(uV_opt.*Settings.TFC.vECmax)));
% dtC = Settings.TFC.dtC;
% n1t = [TFC.Ri(3).ni(t/dtC)];
% n2t = [TFC.Ri(4).ni(t/dtC)];
% v1t = [TFC.Ri(3).V(t/dtC)];
% v2t = [TFC.Ri(4).V(t/dtC)];
% %==========================
% nc1 = 0.9*Settings.TFC.nci(3);
% Vn1 = Settings.TFC.Vn11;
% ECv1 = Settings.TFC.ECv11;
% v1star = Settings.TFC.vECstar11;
% ssECv1 = ECv1(v1star);
% nc2 = 0.9*Settings.TFC.nci(4);
% Vn2 = Settings.TFC.Vn12;
% ECv2 = Settings.TFC.ECv12;
% v2star = Settings.TFC.vECstar12;
% ssECv2 = ECv2(v2star);
% vmax = Settings.TFC.vECmax;
% %==========================
% w1_max = min(vmax)/vmax; w1_min = min(v1star)/vmax;
% w2_max = min(vmax)/vmax; w2_min = min(v2star)/vmax;
% % Setup strategy
% for i=1:1:length(region_index)
%     for j=1:1:length(region_index)
%         if (i~=j)
%             if nit(j) >= nci(j)
%                 wij(i,j) = wij_min(i,j);
%             else
%                 wij(i,j) = wij_max(i,j);
%             end
%         else
%             wij(i,j) = wij_max(i,j);
%         end
%     end
% end
% 
% TFC.CS(t/dtC).w1dt = w1dt;
% TFC.CS(t/dtC).w2dt = w2dt;
% TFC.CS(t/dtC).Vmdt = max(0,min(vmax,round(vmax.*[w1dt, w2dt])));
% w_opt = [w1dt, w2dt];
% end
% function [w_opt] = GC_SpeedControl_2L2R_i(SimInfo,ObjAircraft,Settings,TFC,t)
% end
% function [w_opt] = GC_SpeedControl_2L2R_ij(SimInfo,ObjAircraft,Settings,TFC,t)
%     % [wij_opt,MPCSim] = GC_SpeedModel_2L2R_V2(SimInfo,ObjAircraft,Settings,TFC,t);
%     % TFC.CS(t/dtC).wij = wij_opt;
%     % TFC.CS(t/dtC).Vmdt = max(0,min(vmG,round(TFC.CS(t/dtC).wij.*Settings.TFC.vECmax)));
%     % TFC.CS(t/dtC).Vmdt_1_1 = TFC.CS(t/dtC).Vmdt(1);
%     % TFC.CS(t/dtC).Vmdt_1_11 = TFC.CS(t/dtC).Vmdt(2);
%     % TFC.CS(t/dtC).Vmdt_2_2 = TFC.CS(t/dtC).Vmdt(3);
%     % TFC.CS(t/dtC).Vmdt_2_12 = TFC.CS(t/dtC).Vmdt(4);
%     % TFC.CS(t/dtC).Vmdt_11_1 = TFC.CS(t/dtC).Vmdt(5);
%     % TFC.CS(t/dtC).Vmdt_11_11= TFC.CS(t/dtC).Vmdt(6);
%     % TFC.CS(t/dtC).Vmdt_11_12 = TFC.CS(t/dtC).Vmdt(7);
%     % TFC.CS(t/dtC).Vmdt_12_2 =  TFC.CS(t/dtC).Vmdt(8);
%     % TFC.CS(t/dtC).Vmdt_12_11 = TFC.CS(t/dtC).Vmdt(9);
%     % TFC.CS(t/dtC).Vmdt_12_12 = TFC.CS(t/dtC).Vmdt(10);
% end
%% Speed Control Function - Apply
function [TFC,ObjAircraft,SimInfo] = ApplySpeedControl_1L2R_i(TFC,t,dtC,SimInfo,ObjAircraft,vm)
vmG = 20;
LMact = size(SimInfo.Mact,2);
% LMSpeed = size(SimInfo.MSpeed,2);
% TODO: To make speed queue strctured.
aai = 1;
while aai<=LMact
    rit_a = mod(ObjAircraft(SimInfo.Mact(aai)).rit,10);
    if (rit_a == 1)
        ObjAircraft(SimInfo.Mact(aai)).vm = max(0,min(vmG,round(ObjAircraft(SimInfo.Mact(aai)).vm_set*TFC.CS(end).w1dt)));
    end
    if (rit_a == 2)
        ObjAircraft(SimInfo.Mact(aai)).vm = max(0,min(vmG,round(ObjAircraft(SimInfo.Mact(aai)).vm_set*TFC.CS(end).w2dt)));
    end
    if (rit_a == 0)
        ObjAircraft(SimInfo.Mact(aai)).vm = ObjAircraft(SimInfo.Mact(aai)).vm_set;
    end
    aai = aai + 1;
end
end

function [TFC,ObjAircraft,SimInfo] = ApplySpeedControl_1L2R_ij_1L(TFC,t,dtC,SimInfo,ObjAircraft,vm)
LMact = size(SimInfo.Mact,2);
% LMSpeed = size(SimInfo.MSpeed,2);
% TODO: To make speed queue strctured.
aai = 1;
while aai<=LMact
    rit_a = mod(ObjAircraft(SimInfo.Mact(aai)).rit,10);
    nextrit_a = mod(ObjAircraft(SimInfo.Mact(aai)).nextrit,10);
    if (rit_a == 1)&&(nextrit_a == 1)
        ObjAircraft(SimInfo.Mact(aai)).vm = max(0,min(vmG,round(ObjAircraft(SimInfo.Mact(aai)).vm_set*TFC.CS(end).w11dt)));
    end
    if (rit_a == 1)&&(nextrit_a == 2)
        ObjAircraft(SimInfo.Mact(aai)).vm = max(0,min(vmG,round(ObjAircraft(SimInfo.Mact(aai)).vm_set*TFC.CS(end).w12dt)));
    end
    if (rit_a == 2)&&(nextrit_a == 1)
        ObjAircraft(SimInfo.Mact(aai)).vm = max(0,min(vmG,round(ObjAircraft(SimInfo.Mact(aai)).vm_set*TFC.CS(end).w21dt)));
    end
    if (rit_a == 2)&&(nextrit_a == 2)
        ObjAircraft(SimInfo.Mact(aai)).vm = max(0,min(vmG,round(ObjAircraft(SimInfo.Mact(aai)).vm_set*TFC.CS(end).w22dt)));
    end
    aai = aai + 1;
end
end

function [TFC,ObjAircraft,SimInfo] = ApplySpeedControl_2L2R_ij(TFC,t,dtC,SimInfo,ObjAircraft,vm)
LMact = size(SimInfo.Mact,2);
% LMSpeed = size(SimInfo.MSpeed,2);
% TODO: To make speed queue strctured.
aai = 1;
while aai<=LMact
    rit_a = ObjAircraft(SimInfo.Mact(aai)).rit;%mod(ObjAircraft(SimInfo.Mact(aai)).rit,10);
    nextrit_a = ObjAircraft(SimInfo.Mact(aai)).nextrit;%mod(ObjAircraft(SimInfo.Mact(aai)).nextrit,10);
    if (rit_a == 1)&&(nextrit_a == 1) % takeoff
        ObjAircraft(SimInfo.Mact(aai)).vm = TFC.CS(end).Vmdt_1_1;
    end
    if (rit_a == 1)&&(nextrit_a == 11) % while Takeoff
        ObjAircraft(SimInfo.Mact(aai)).vm = TFC.CS(end).Vmdt_1_11;
    end
    if (rit_a == 2)&&(nextrit_a == 2) % takeoff
        ObjAircraft(SimInfo.Mact(aai)).vm = TFC.CS(end).Vmdt_2_2;
    end
    if (rit_a == 2)&&(nextrit_a == 12) % while takeoff
        ObjAircraft(SimInfo.Mact(aai)).vm = TFC.CS(end).Vmdt_2_12;
    end
    if (rit_a == 11)&&(nextrit_a == 11) % internal flying
        ObjAircraft(SimInfo.Mact(aai)).vm = TFC.CS(end).Vmdt_11_11;
    end
    if (rit_a == 11)&&(nextrit_a == 12) % transfering
        ObjAircraft(SimInfo.Mact(aai)).vm = TFC.CS(end).Vmdt_11_12;
    end
    if (rit_a == 11)&&(nextrit_a == 1) % Landing
        ObjAircraft(SimInfo.Mact(aai)).vm = TFC.CS(end).Vmdt_11_1;
    end
    if (rit_a == 12)&&(nextrit_a == 11) % transfering
        ObjAircraft(SimInfo.Mact(aai)).vm = TFC.CS(end).Vmdt_12_11;
    end
    if (rit_a == 12)&&(nextrit_a == 12) % internal flying
        ObjAircraft(SimInfo.Mact(aai)).vm = TFC.CS(end).Vmdt_12_12;
    end
    if (rit_a == 12)&&(nextrit_a == 2) % Landing
        ObjAircraft(SimInfo.Mact(aai)).vm = TFC.CS(end).Vmdt_12_2;
    end
    aai = aai + 1;
end
end