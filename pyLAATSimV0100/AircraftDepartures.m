function [SimInfo,ObjAircraft] = AircraftDepartures(SimInfo,ObjAircraft)
Mina = SimInfo.Mina;
Mque = SimInfo.Mque;
Mact = SimInfo.Mact;
dt = SimInfo.dtS;
t = SimInfo.t;
epsilon = 1.0000e-03;
aa = 1;
LMque = length(Mque);
while aa<=LMque
    if (ObjAircraft(Mque(aa)).tda - t) < epsilon
        ObjAircraft(Mque(aa)).ctd = 1;
        LMact = length(Mact);
        for aaj=1:LMact
            if norm(ObjAircraft(Mque(aa)).o-ObjAircraft(Mact(aaj)).pt) < (ObjAircraft(Mque(aa)).ra+ObjAircraft(Mact(aaj)).ra)
                ObjAircraft(Mque(aa)).status = 10;
                DesiredHeadway = dt;
                ObjAircraft(Mque(aa)).tda = t + DesiredHeadway - mod(t + DesiredHeadway,dt);
                ObjAircraft(Mque(aa)).Safdd = ObjAircraft(Mque(aa)).Safdd + DesiredHeadway;
                ObjAircraft(Mque(aa)).dd = ObjAircraft(Mque(aa)).tda - ObjAircraft(Mque(aa)).tdp;
                ObjAircraft(Mque(aa)).ctd = 0;
                break;
            end
        end
        clear aaj
        if (ObjAircraft(Mque(aa)).ctd)
            ObjAircraft(Mque(aa)).status = 1;
            Mact = [Mact, ObjAircraft(Mque(aa)).id];
            LMact = LMact + 1;
            Mque(ObjAircraft(Mque(aa)).id==Mque) = [];
            LMque = LMque - 1;
        else
            aa = aa + 1;
        end
    elseif (ObjAircraft(Mque(aa)).tdp - t) < epsilon
        ObjAircraft(Mque(aa)).status = 10;
        aa = aa + 1;
    else
        aa = aa + 1;
    end
end
clear aa
aa = 1;
LMina = length(Mina);
while aa<=LMina
    if (ObjAircraft(Mina(aa)).tda - t) < epsilon
        ObjAircraft(Mina(aa)).ctd = 1;
        LMact = length(Mact);
        for aaj=1:LMact
            if norm(ObjAircraft(Mina(aa)).o-ObjAircraft(aaj).pt) < (ObjAircraft(Mina(aa)).rs+ObjAircraft(Mact(aaj)).rs)
                ObjAircraft(Mina(aa)).status = 10;
                DesiredHeadway = dt;
                ObjAircraft(Mina(aa)).tda = t + DesiredHeadway - mod(t + DesiredHeadway,dt);
                ObjAircraft(Mina(aa)).Safdd = ObjAircraft(Mina(aa)).Safdd + DesiredHeadway;
                ObjAircraft(Mina(aa)).dd = ObjAircraft(Mina(aa)).tda - ObjAircraft(Mina(aa)).tdp;
                ObjAircraft(Mina(aa)).ctd = 0;
                break;
            end
        end
        clear aaj
        if (~isempty(Mina))&&(ObjAircraft(Mina(aa)).ctd)
            ObjAircraft(Mina(aa)).tda = t;
            ObjAircraft(Mina(aa)).status = 1;
            Mact = [Mact, ObjAircraft(Mina(aa)).id];
            LMact = LMact + 1;
            Mina(ObjAircraft(Mina(aa)).id==Mina) = [];
            LMina = LMina - 1;
        elseif(~ObjAircraft(Mina(aa)).ctd)
            Mque = [Mque, ObjAircraft(Mina(aa)).id];
            Mina(ObjAircraft(Mina(aa)).id==Mina) = [];
            LMina = LMina - 1;
        end
    elseif (ObjAircraft(Mina(aa)).tdp - t) < epsilon
        ObjAircraft(Mina(aa)).status = 10;
        aa = aa + 1;
    else
        aa = aa + 1;
    end
end
SimInfo.Mina = Mina;
SimInfo.Mque = Mque;
SimInfo.Mact = Mact;
end


