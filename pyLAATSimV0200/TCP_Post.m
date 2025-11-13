%TCP_Post Dispatches the active Traffic Control Policy (TCP) logic.
%   This function acts as a router or dispatcher for the various traffic
%   control modules. At each control step, it checks which control policy
%   is active (based on flags set in `Settings.TFC`) and calls the
%   corresponding function to compute and apply the control actions.
%
%   It can dispatch to different controllers, such as:
%   - `TCP_CoupledController_*`: For integrated control strategies.
%   - `TCP_RouteGuidance_*`: For dynamic routing strategies.
%   - `TCP_SpeedControl_*`: For speed regulation strategies.
%
% Inputs:
%   SimInfo     - (struct) Current simulation information.
%   ObjAircraft - (struct) Array of aircraft objects.
%   Settings    - (struct) Simulation settings, including TCP flags.
%   TFC         - (struct) Current Traffic Flow Characteristics data.
%   t           - (numeric) The current simulation time.
% Author: Yazan Safadi
% Date Created: 2023-03-23
function [TFC,ObjAircraft,SimInfo] = TCP_Post(SimInfo,ObjAircraft,Settings,TFC,t)
if Settings.TFC.TCP_DBController_GC
    disp(['[INFO] t=', num2str(t), 's - Activating TCP_DBControl_GC_Micro']);
    [TFC,ObjAircraft,SimInfo] = TCP_DBControl_GC_Micro(SimInfo,ObjAircraft,Settings,TFC,t);
end
if Settings.TFC.TCP_DBController_MPC
    disp(['[INFO] t=', num2str(t), 's - Activating TCP_DBControl_MPC_Micro']);
    [TFC,ObjAircraft,SimInfo] = TCP_DBControl_MPC_Micro(SimInfo,ObjAircraft,Settings,TFC,t);
end
if Settings.TFC.TCP_RouteGuidance_GC || Settings.TFC.TCP_RouteGuidance_MPC
    disp(['[INFO] t=', num2str(t), 's - Activating TCP_RouteGuidance_GC']);
    [TFC,ObjAircraft,SimInfo] = TCP_RouteGuidance_GC_Micro(SimInfo,ObjAircraft,Settings,TFC,t);
end
if Settings.TFC.TCP_SpeedController_GC
    disp(['[INFO] t=', num2str(t), 's - Activating TCP_SpeedController_GC']);
    [TFC,ObjAircraft,SimInfo] = TCP_SpeedControl_GC_Micro(SimInfo,ObjAircraft,Settings,TFC,t);
end
if Settings.TFC.TCP_SpeedController_MPC
    disp(['[INFO] t=', num2str(t), 's - Activating TCP_SpeedController_MPC']);
    [TFC,ObjAircraft,SimInfo] = TCP_SpeedControl_MPC_Micro(SimInfo,ObjAircraft,Settings,TFC,t);
end
end