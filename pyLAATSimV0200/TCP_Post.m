function [TFC,ObjAircraft,SimInfo] = TCP_Post(SimInfo,ObjAircraft,Settings,TFC,t)

if Settings.TFC.TCP_DepartureController_GC
    [TFC,ObjAircraft,SimInfo] = TCP_DepartureController_GC(SimInfo,ObjAircraft,Settings,TFC,t);
end
if Settings.TFC.TCP_BoundaryController_GC
    [TFC,ObjAircraft,SimInfo] = TCP_BoundaryController_GC(SimInfo,ObjAircraft,Settings,TFC,t);
end
if Settings.TFC.TCP_CoupledController_GC
    [TFC,ObjAircraft,SimInfo] = TCP_CoupledController_GC(SimInfo,ObjAircraft,Settings,TFC,t);
end
if Settings.TFC.TCP_CoupledController_MPC
    [TFC,ObjAircraft,SimInfo] = TCP_CoupledController_MPC(SimInfo,ObjAircraft,Settings,TFC,t);
end
if Settings.TFC.TCP_PreRouting
    [TFC,ObjAircraft,SimInfo] = TCP_PreRouting(SimInfo,ObjAircraft,Settings,TFC,t);
end
if Settings.TFC.TCP_RTRouting
    [TFC,ObjAircraft,SimInfo] = TCP_RTRouting(SimInfo,ObjAircraft,Settings,TFC,t);
end
if Settings.TFC.TCP_SpeedController_GC
    [TFC,ObjAircraft,SimInfo] = TCP_SpeedController_GC(SimInfo,ObjAircraft,Settings,TFC,t);
end
if Settings.TFC.TCP_SpeedController_MPC
    [TFC,ObjAircraft,SimInfo] = TCP_SpeedController_MPC(SimInfo,ObjAircraft,Settings,TFC,t);
end
if Settings.TFC.TCP_GatingController_MPC
    [TFC,ObjAircraft,SimInfo] = TCP_GatingController_MPC(SimInfo,ObjAircraft,Settings,TFC,t);
end
end