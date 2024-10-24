function [SimInfo,ObjAircraft] = PedDepartures(SimInfo,ObjAircraft)
Mina = SimInfo.Mina;
Mque = SimInfo.Mque;
Mact = SimInfo.Mact;
dtS = SimInfo.dtS;
dtM = SimInfo.dtM;
t = SimInfo.t;
% %% Pre traffic control policy
% [TFC,ObjAircraft] = TCPPre(SimInfo,ObjAircraft,Settings,TFC,t);
%%
epsilon = 1.0000e-03;
aa = 1;
LMque = length(Mque);
while aa<=LMque
    if (ObjAircraft(Mque(aa)).tda - t) < epsilon
        ObjAircraft(Mque(aa)).ctd = 1;
        if (~isempty(Mact))
            Diffaaxyz = (ObjAircraft(Mque(aa)).pt.*ones(length(Mact),1) - cat(1,ObjAircraft(Mact).fpt));
            Distanceaa =  vecnorm(Diffaaxyz')';
            Vectorrd = cat(1,(ObjAircraft(Mact).rd)) + (ObjAircraft(Mque(aa)).rd).*ones(length(Mact),1);
            BolInrd = all([(0<Distanceaa),(Distanceaa<=Vectorrd)],2)';
            MactDetaa = cat(1,ObjAircraft(Mact(BolInrd)).id);
            LMact = length(MactDetaa);
            for aaj=1:LMact
                if norm(ObjAircraft(Mque(aa)).o-ObjAircraft(MactDetaa(aaj)).pt) < (ObjAircraft(Mque(aa)).ra+ObjAircraft(MactDetaa(aaj)).ra)
                    ObjAircraft(Mque(aa)).status = 10;
                    DesiredHeadway = dtS;
                    ObjAircraft(Mque(aa)).tda = t + DesiredHeadway - mod(t + DesiredHeadway,dtS);
                    ObjAircraft(Mque(aa)).Safdd = ObjAircraft(Mque(aa)).Safdd + DesiredHeadway;
                    ObjAircraft(Mque(aa)).dd = ObjAircraft(Mque(aa)).tda - ObjAircraft(Mque(aa)).tdp;
                    ObjAircraft(Mque(aa)).ctd = 0;
                    break;
                end
            end
        else
            LMact = 0;
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
% warning('TODO: change Mina to only in the next minute')
InActiveAircraftID = Mina(all([( (t+dtS) < (cat(1,ObjAircraft(Mina).tda)) ) , ( (cat(1,ObjAircraft(Mina).tda)) < (t+dtM+dtS) )],2));
LMina = size(InActiveAircraftID,2);
% LMina = length(Mina);
while aa<=LMina
    if (ObjAircraft(Mina(aa)).tda - t) < epsilon
        ObjAircraft(Mina(aa)).ctd = 1;
        if (~isempty(Mact))
            Diffaaxyz = (ObjAircraft(Mina(aa)).pt.*ones(length(Mact),1) - cat(1,ObjAircraft(Mact).fpt));
            Distanceaa =  vecnorm(Diffaaxyz')';
            Vectorrd = cat(1,(ObjAircraft(Mact).rd)) + (ObjAircraft(Mina(aa)).rd).*ones(length(Mact),1);
            BolInrd = all([(0<Distanceaa),(Distanceaa<=Vectorrd)],2)';
            MactDetaa = cat(1,ObjAircraft(Mact(BolInrd)).id);
            LMact = length(MactDetaa);
            for aaj=1:LMact
                if norm(ObjAircraft(Mina(aa)).o-ObjAircraft(MactDetaa(aaj)).pt) < (ObjAircraft(Mina(aa)).rs+ObjAircraft(MactDetaa(aaj)).rs)
                    ObjAircraft(Mina(aa)).status = 10;
                    DesiredHeadway = dtS;
                    ObjAircraft(Mina(aa)).tda = t + DesiredHeadway - mod(t + DesiredHeadway,dtS);
                    ObjAircraft(Mina(aa)).Safdd = ObjAircraft(Mina(aa)).Safdd + DesiredHeadway;
                    ObjAircraft(Mina(aa)).dd = ObjAircraft(Mina(aa)).tda - ObjAircraft(Mina(aa)).tdp;
                    ObjAircraft(Mina(aa)).ctd = 0;
                    break;
                end
            end
        else
            LMact = 0;
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
%% Update SimInfo
SimInfo.Mina = Mina;
SimInfo.Mque = Mque;
SimInfo.Mact = Mact;
end


