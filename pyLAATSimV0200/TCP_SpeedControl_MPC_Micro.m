function [TFC,ObjAircraft,SimInfo] = TCP_SpeedControl_MPC_Micro(SimInfo,ObjAircraft,Settings,TFC,t)
t = SimInfo.t;
dtC = SimInfo.dtC;
dtS = SimInfo.dtS;
tf = SimInfo.tf;
%% Set Control states
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))
    [TFC] = UpdateControlState(TFC,t/dtC);
end
% %% Determine MPC Control Inputs
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))&&(Settings.TFC.TCP_SpeedController_MPC)
    [w_opt,MPCSim] = TCP_SpeedControl_MPC_Macro(SimInfo,ObjAircraft,Settings,TFC,t);
    vmG = max(Settings.Aircraft.vm_range);
    TFC.CS(t/dtC).w1dt = w_opt(1);
    TFC.CS(t/dtC).w2dt = w_opt(2);
    TFC.MPCSim(t/dtC) = MPCSim;
    Settings.TFC.vECmax = vmG;
    TFC.CS(t/dtC).v1dt = max(0,min(vmG,round(w_opt(1)*Settings.TFC.vECmax)));
    TFC.CS(t/dtC).v2dt = max(0,min(vmG,round(w_opt(2)*Settings.TFC.vECmax)));
    TFC.CS(t/dtC).Vmdt = max(0,min(vmG,round(w_opt.*Settings.TFC.vECmax)));
end
%% Change MaxSpeed
if (t~=0)&&(~isempty(TFC.CS))&&(Settings.TFC.TCP_SpeedController_MPC)
    [TFC,ObjAircraft,SimInfo] = ApplySpeedControl(TFC,t,dtC,SimInfo,ObjAircraft,mean(Settings.Aircraft.vm_range));
end
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))&&(Settings.TFC.TCP_SpeedController_MPC)
    disp(['[INFO] t=', num2str(t), 's | TCP_SpeedControl_MPC_Micro:']);
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

%% Speed Control Function
function [TFC,ObjAircraft,SimInfo] = ApplySpeedControl(TFC,t,dtC,SimInfo,ObjAircraft,vmG)
LMact = size(SimInfo.Mact,2);
% TODO: To make speed queue strctured.
aai = 1;
while aai<=LMact
    rit_a = mod(ObjAircraft(SimInfo.Mact(aai)).rit,10);
    if (rit_a == 1)
        val = ObjAircraft(SimInfo.Mact(aai)).vm_set * TFC.CS(end).w1dt;
        ObjAircraft(SimInfo.Mact(aai)).vm = max(0, min(vmG, round(val / 5) * 5));
    end
    if (rit_a == 2)
        val = ObjAircraft(SimInfo.Mact(aai)).vm_set * TFC.CS(end).w2dt;
        ObjAircraft(SimInfo.Mact(aai)).vm = max(0, min(vmG, round(val / 5) * 5));
    end
    if (rit_a == 0)
        ObjAircraft(SimInfo.Mact(aai)).vm = ObjAircraft(SimInfo.Mact(aai)).vm_set;
    end
    aai = aai + 1;
end
end
