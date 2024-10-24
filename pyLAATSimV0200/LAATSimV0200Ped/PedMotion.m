function [SimInfo,ObjAircraft] = AircraftMotion(aa,SimInfo,ObjAircraft,Settings)
Ri = Settings.Airspace.Regions;
%%
% for aa=1:length(SimInfo.Mact)
dt = Settings.Sim.dtsim;
% TODO: Update pt vt vnt fpt according to time step (as matrix)
% ObjAircraft(SimInfo.Mact(aa)).vt = ObjAircraft(SimInfo.Mact(aa)).vt - dt.*ObjAircraft(SimInfo.Mact(aa)).vt*ObjAircraft(SimInfo.Mact(aa)).lgain + dt.*ObjAircraft(SimInfo.Mact(aa)).vct'*ObjAircraft(SimInfo.Mact(aa)).lgain;
% ObjAircraft(SimInfo.Mact(aa)).vnt = norm(ObjAircraft(SimInfo.Mact(aa)).vt);
% % Q- Should the pt will be calcauted before vt?
% ObjAircraft(SimInfo.Mact(aa)).pt = ObjAircraft(SimInfo.Mact(aa)).pt + ObjAircraft(SimInfo.Mact(aa)).vt.*SimS.dtsim; % V
% Skyhighway
ObjAircraft(SimInfo.Mact(aa)).pt = ObjAircraft(SimInfo.Mact(aa)).pt + dt.*ObjAircraft(SimInfo.Mact(aa)).vt; % V
ObjAircraft(SimInfo.Mact(aa)).vt = ObjAircraft(SimInfo.Mact(aa)).vt - dt.*ObjAircraft(SimInfo.Mact(aa)).vt*ObjAircraft(SimInfo.Mact(aa)).lgain + dt.*ObjAircraft(SimInfo.Mact(aa)).vct'*ObjAircraft(SimInfo.Mact(aa)).lgain;
ObjAircraft(SimInfo.Mact(aa)).vnt = norm(ObjAircraft(SimInfo.Mact(aa)).vt);
ObjAircraft(SimInfo.Mact(aa)).fpt = (ObjAircraft(SimInfo.Mact(aa)).pt) + (ObjAircraft(SimInfo.Mact(aa)).vt)*ObjAircraft(SimInfo.Mact(aa)).gain;
ObjAircraft(SimInfo.Mact(aa)).rit = max(0,Ri.B(all((abs(repmat(ObjAircraft(SimInfo.Mact(aa)).pt,Ri.n,1) - cat(1,Ri.B.center))) <= cat(1,Ri.B.ssize)./2,2)).ri);
% Next filter position with detection radius to know the next region.
ObjAircraft(SimInfo.Mact(aa)).fptrd = (ObjAircraft(SimInfo.Mact(aa)).pt) + ObjAircraft(SimInfo.Mact(aa)).rd.*((ObjAircraft(SimInfo.Mact(aa)).vt)/norm(ObjAircraft(SimInfo.Mact(aa)).vt));
ObjAircraft(SimInfo.Mact(aa)).nextrit = max(0,Ri.B(all((abs(repmat(ObjAircraft(SimInfo.Mact(aa)).fptrd,Ri.n,1) - cat(1,Ri.B.center))) < cat(1,Ri.B.ssize)./2,2)).ri);
if (~any(ObjAircraft(SimInfo.Mact(aa)).nextrit==cat(1,Settings.Airspace.Regions.B(:).ri)))
    ObjAircraft(SimInfo.Mact(aa)).fptrd = ObjAircraft(SimInfo.Mact(aa)).fpt;
    [~,indexFit] = max(all((abs(repmat(ObjAircraft(SimInfo.Mact(aa)).fptrd,Ri.n,1) - cat(1,Ri.B.center))) <= cat(1,Ri.B.ssize)./2,2));
    ObjAircraft(SimInfo.Mact(aa)).nextrit = max(0,Ri.B(indexFit).ri);
    if (~any(ObjAircraft(SimInfo.Mact(aa)).nextrit==cat(1,Settings.Airspace.Regions.B(:).ri)))
        ObjAircraft(SimInfo.Mact(aa)).nextrit = ObjAircraft(SimInfo.Mact(aa)).rit;
    end
end
% end
% TODO: Update travel time and travel distance
ObjAircraft(SimInfo.Mact(aa)).DfO = norm(ObjAircraft(SimInfo.Mact(aa)).o-ObjAircraft(SimInfo.Mact(aa)).pt);
ObjAircraft(SimInfo.Mact(aa)).DfD = norm(ObjAircraft(SimInfo.Mact(aa)).d-ObjAircraft(SimInfo.Mact(aa)).pt);
ObjAircraft(SimInfo.Mact(aa)).tl_total = sum(vecnorm(diff(ObjAircraft(SimInfo.Mact(aa)).wp(1:end,:))'));
ObjAircraft(SimInfo.Mact(aa)).tl_left = norm(ObjAircraft(SimInfo.Mact(aa)).wp(ObjAircraft(SimInfo.Mact(aa)).wpCR+1,:)-ObjAircraft(SimInfo.Mact(aa)).pt) + ((ObjAircraft(SimInfo.Mact(aa)).wpCR+1)~=ObjAircraft(SimInfo.Mact(aa)).wpTR)*sum(vecnorm(diff([ObjAircraft(SimInfo.Mact(aa)).wp(ObjAircraft(SimInfo.Mact(aa)).wpCR+1:end,:)])'));
ObjAircraft(SimInfo.Mact(aa)).tl_done = norm(ObjAircraft(SimInfo.Mact(aa)).wp(ObjAircraft(SimInfo.Mact(aa)).wpCR,:)-ObjAircraft(SimInfo.Mact(aa)).pt) + sum(vecnorm(diff([ObjAircraft(SimInfo.Mact(aa)).wp(1,:);ObjAircraft(SimInfo.Mact(aa)).wp(1:ObjAircraft(SimInfo.Mact(aa)).wpCR,:)])'));
% TODO: Update travel time and travel distance according to dtMFD
%%
% ObjAircraft(SimInfo.Mact(aa)).ptdt = [ObjAircraft(SimInfo.Mact(aa)).ptdt;ObjAircraft(SimInfo.Mact(aa)).pt];
% ObjAircraft(SimInfo.Mact(aa)).vtdt = [ObjAircraft(SimInfo.Mact(aa)).vtdt;ObjAircraft(SimInfo.Mact(aa)).vt];
% ObjAircraft(SimInfo.Mact(aa)).statusdt = [ObjAircraft(SimInfo.Mact(aa)).statusdt;ObjAircraft(SimInfo.Mact(aa)).status];
% ObjAircraft(SimInfo.Mact(aa)).ridt = [ObjAircraft(SimInfo.Mact(aa)).ridt;ObjAircraft(SimInfo.Mact(aa)).rit];
end