function [SimInfo] = UpdateSimInfo(SimInfo,ObjAircraft)
t = SimInfo.t;
dtS = SimInfo.dtS;
%%
SimInfo.pdt(round(t/(dtS))+1,:) = cat(1,[ObjAircraft.pt]);
SimInfo.vdt(round(t/(dtS))+1,:) = cat(1,[ObjAircraft.vt]);
SimInfo.statusdt(round(t/(dtS))+1,:) = cat(1,[ObjAircraft.status]);
%% Regions index
SimInfo.ridt(round(t/(dtS))+1,:) = cat(1,[ObjAircraft.rit]);
end