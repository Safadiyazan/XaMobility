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