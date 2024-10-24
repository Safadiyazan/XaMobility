function [SimInfo] = UpdateSimInfo(SimInfo,ObjAircraft)
t = SimInfo.t;
dtS = SimInfo.dtS;
%% Uncertainty error
randomRowVector = -[100,100,10].* (2 * rand(size(ObjAircraft, 2), 3) - 1);
statusMatrix = [cat(1,[ObjAircraft.status])',cat(1,[ObjAircraft.status])',cat(1,[ObjAircraft.status])'];
pt_error = reshape((statusMatrix==1)',1,[]).*reshape(randomRowVector',1,[]);
if(any(pt_error>0))
    disp('error active');
end
if(any(statusMatrix==2))
    disp('error active');
end
%%
SimInfo.pdt(round(t/(dtS))+1,:) = cat(1,[ObjAircraft.pt])-pt_error;
SimInfo.vdt(round(t/(dtS))+1,:) = cat(1,[ObjAircraft.vt]);
SimInfo.statusdt(round(t/(dtS))+1,:) = cat(1,[ObjAircraft.status]);
%% Regions index
SimInfo.ridt(round(t/(dtS))+1,:) = cat(1,[ObjAircraft.rit]);
end