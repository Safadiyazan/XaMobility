function [TFC,ObjAircraft,SimInfo] = TCP_GatingController_MPC(SimInfo,ObjAircraft,Settings,TFC,t)
t = SimInfo.t;
dtC = SimInfo.dtC;
dtS = SimInfo.dtS;
tf = SimInfo.tf;
%% Set Control states
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))
    [TFC] = UpdateControlState(TFC,t/dtC);
end
%% Determine UI
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))&&(Settings.TFC.TCP_GatingController_MPC)
    [uI_opt,TFC] = MPC_GatingModel_1R_V1(SimInfo,ObjAircraft,Settings,TFC,t);
    TFC.CS(t/dtC).uIdt = (1-uI_opt(1));
    TFC.CS(t/dtC).dtIdt = min((dtC.*max(0, 1-uI_opt(1)) - mod(dtC.*max(0, 1-uI_opt(1)),dtS)), tf-t); 
    disp(['| t=' num2str(t),' | nt=' num2str(TFC.N.n(t/dtC)), ' | vt=' num2str(TFC.N.V(t/dtC)), ' | uI=' num2str(TFC.CS(t/dtC).uIdt),' | dtI=' num2str(TFC.CS(t/dtC).dtIdt), ' |'])
end
%% Change ApplyGatingControl (DepartTime)
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))&&(Settings.TFC.TCP_GatingController_MPC)
    [TFC,ObjAircraft,SimInfo] = ApplyGatingControl(TFC,t,dtC,SimInfo,ObjAircraft);
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

function [TFC,ObjAircraft,SimInfo] = ApplyGatingControl(TFC,t,dtC,SimInfo,ObjAircraft)
dtS = SimInfo.dtS;
if(TFC.CS(t/dtC).dtIdt>0)
LMque = size(SimInfo.Mque,2);
for aai=1:LMque
    if (t<=(ObjAircraft(SimInfo.Mque(aai)).tda)) && ((ObjAircraft(SimInfo.Mque(aai)).tda)<(t+dtC))
        if(TFC.CS(t/dtC).uIdt<1)
            ObjAircraft(SimInfo.Mque(aai)).tda = ObjAircraft(SimInfo.Mque(aai)).tda + TFC.CS(t/dtC).dtIdt;
            ObjAircraft(SimInfo.Mque(aai)).Curdd = TFC.CS(t/dtC).dtIdt;
            ObjAircraft(SimInfo.Mque(aai)).dd = ObjAircraft(SimInfo.Mque(aai)).tda - ObjAircraft(SimInfo.Mque(aai)).tdp;
        end
    end
end
InActiveAircraftID = SimInfo.Mina(all([( (t+dtS) < (cat(1,ObjAircraft(SimInfo.Mina).tda)) ) , ( (cat(1,ObjAircraft(SimInfo.Mina).tda)) < (t+dtC+dtS) )],2));
LMina = size(InActiveAircraftID,2);
aai = 1;
while aai<=LMina
    if (t<=(ObjAircraft(InActiveAircraftID(aai)).tda)) && ((ObjAircraft(InActiveAircraftID(aai)).tda)<(t+dtC))
        if(TFC.CS(t/dtC).dtIdt>0)
            ObjAircraft(InActiveAircraftID(aai)).status = 10;
            ObjAircraft(InActiveAircraftID(aai)).tda = ObjAircraft(InActiveAircraftID(aai)).tda  + TFC.CS(t/dtC).dtIdt;
            ObjAircraft(InActiveAircraftID(aai)).Curdd = TFC.CS(t/dtC).dtIdt;
            ObjAircraft(InActiveAircraftID(aai)).dd = ObjAircraft(InActiveAircraftID(aai)).tda - ObjAircraft(InActiveAircraftID(aai)).tdp;
            SimInfo.Mque = [SimInfo.Mque, ObjAircraft(InActiveAircraftID(aai)).id];
            SimInfo.Mina(ObjAircraft(InActiveAircraftID(aai)).id==SimInfo.Mina) = [];
            InActiveAircraftID(ObjAircraft(InActiveAircraftID(aai)).id==InActiveAircraftID) = [];
            LMina = LMina - 1;
            LMque = LMque + 1;
        else
            aai = aai + 1;
        end
    else
        aai = aai + 1;
    end
end
end
end