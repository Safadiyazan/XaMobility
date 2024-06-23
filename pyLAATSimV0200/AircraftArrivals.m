function [SimInfo,ObjAircraft] = AircraftArrivals(SimInfo,ObjAircraft)
Mact = SimInfo.Mact;
Marr = SimInfo.Marr;
t = SimInfo.t;
%%
aa = 1;
LMact = length(Mact);
LMarr = length(Marr);
while aa<=LMact
    epsilon_landing = ObjAircraft(Mact(aa)).rd; % ObjAircraft(Mact(aa)).ra
    epsilon_SwitchWaypoint = ObjAircraft(Mact(aa)).rd;
    epsilon_BoundaryControl = ObjAircraft(Mact(aa)).rd; % ObjAircraft(Mact(aa)).ra
    epsilon_PreRouting = 2*ObjAircraft(Mact(aa)).rd;
    if(ObjAircraft(Mact(aa)).status==1)
        if (ObjAircraft(Mact(aa)).wpCR<ObjAircraft(Mact(aa)).wpTR-1)&&(norm(ObjAircraft(Mact(aa)).pt-ObjAircraft(Mact(aa)).wp(ObjAircraft(Mact(aa)).wpCR+1,:)) <= epsilon_SwitchWaypoint)
            ObjAircraft(Mact(aa)).wpCR = ObjAircraft(Mact(aa)).wpCR + 1;
            ObjAircraft(Mact(aa)).wpta  = [ObjAircraft(Mact(aa)).wpta;t];
        end
        if (ObjAircraft(Mact(aa)).wpRouting)&&(ObjAircraft(Mact(aa)).wpCR<ObjAircraft(Mact(aa)).wpTR-1)&&(norm(ObjAircraft(Mact(aa)).pt-ObjAircraft(Mact(aa)).wp(ObjAircraft(Mact(aa)).wpCR+1,:)) <= epsilon_PreRouting)
            ObjAircraft(Mact(aa)).wpCR = ObjAircraft(Mact(aa)).wpCR + 1;
            ObjAircraft(Mact(aa)).wpta  = [ObjAircraft(Mact(aa)).wpta;t];
        end
        if (norm(ObjAircraft(Mact(aa)).pt-ObjAircraft(Mact(aa)).d) <= epsilon_landing)
            ObjAircraft(Mact(aa)).status = 2;
            ObjAircraft(Mact(aa)).vct   =  [0,0,0];
            ObjAircraft(Mact(aa)).vt   =  [0,0,0];
            ObjAircraft(Mact(aa)).taa = t;
            ObjAircraft(Mact(aa)).tt = ObjAircraft(Mact(aa)).taa - ObjAircraft(Mact(aa)).tda;
            %            TODO: ObjAircraft(Mact(aa)).tla =
            %            TODO: ObjAircraft(Mact(aa)).td =
            Marr = [Marr, ObjAircraft(Mact(aa)).id];
            LMarr = LMarr + 1;
            Mact(ObjAircraft(Mact(aa)).id==Mact) = [];
            LMact = LMact - 1;
        else
            aa = aa + 1;
        end
    elseif(ObjAircraft(Mact(aa)).status==11)
        if (norm(ObjAircraft(Mact(aa)).pt-ObjAircraft(Mact(aa)).wp(ObjAircraft(Mact(aa)).wpCR+1,:))<= epsilon_BoundaryControl)
            if((ObjAircraft(Mact(aa)).ResumeTime(end))<=t)
                ObjAircraft(Mact(aa)).status = 1;
                ObjAircraft(Mact(aa)).ResumeTime(end) = t;
                ObjAircraft(Mact(aa)).HoveringTime = ObjAircraft(Mact(aa)).ResumeTime - ObjAircraft(Mact(aa)).StopTime;
                ObjAircraft(Mact(aa)).CurHoveringTime = ObjAircraft(Mact(aa)).ResumeTime(end) - ObjAircraft(Mact(aa)).StopTime(end);
                SimInfo.MactBQ(ObjAircraft(Mact(aa)).id==SimInfo.MactBQ) = [];
            else
                aa = aa + 1;
            end
        else
            aa = aa + 1;
        end
    else
        error('index error')
    end
end
%%
SimInfo.Mact = Mact;
SimInfo.Marr = Marr;
end


