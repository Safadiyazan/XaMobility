function [TFC,ObjAircraft,SimInfo] = TCP_SpeedController_MPC(SimInfo,ObjAircraft,Settings,TFC,t)
t = SimInfo.t;
dtC = SimInfo.dtC;
dtS = SimInfo.dtS;
tf = SimInfo.tf;
%% Set Control states
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))
    [TFC] = UpdateControlState(TFC,t/dtC);
end
% %% Determine MPC Control Inputs
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))&&(Settings.TFC.TCP_SpeedController_MPC)
    [uV_opt,MPCSim] = MPC_SpeedModel_2L2R_V2(SimInfo,ObjAircraft,Settings,TFC,t);
    TFC.MPCSim(t/dtC) = MPCSim;
    TFC.CS(t/dtC).uV11dt = uV_opt(1);
    TFC.CS(t/dtC).uV12dt = uV_opt(2);
    TFC.CS(t/dtC).uV21dt = uV_opt(3);
    TFC.CS(t/dtC).uV22dt = uV_opt(4);
    TFC.CS(t/dtC).V11dt = uV_opt(1)*Settings.TFC.vECmax;
    TFC.CS(t/dtC).V12dt = uV_opt(2)*Settings.TFC.vECmax;
    TFC.CS(t/dtC).V21dt = uV_opt(3)*Settings.TFC.vECmax;
    TFC.CS(t/dtC).V22dt = uV_opt(4)*Settings.TFC.vECmax;
    TFC.CS(t/dtC).VmMat = [uV_opt(1),uV_opt(2);uV_opt(3),uV_opt(4)].*Settings.TFC.vECmax;
end
%% Change MaxSpeed
if (t~=0)&&(~isempty(TFC))&&(Settings.TFC.TCP_SpeedController_MPC)% &&(mod(t,dtC)==0)
    [TFC,ObjAircraft,SimInfo] = ApplySpeedControl(TFC,t,dtC,SimInfo,ObjAircraft,mean(Settings.Aircraft.vm_range));
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

%% Speed Control Function
function [TFC,ObjAircraft,SimInfo] = ApplySpeedControl(TFC,t,dtC,SimInfo,ObjAircraft,vm)
V11dt = TFC.CS(end).V11dt;
V12dt = TFC.CS(end).V12dt;
V21dt = TFC.CS(end).V21dt;
V22dt = TFC.CS(end).V22dt;
disp(['v11=' num2str(V11dt) ';']); disp(['v12=' num2str(V12dt) ';']); disp(['v21=' num2str(V21dt) ';']); disp(['v22=' num2str(V22dt) ';']);
LMact = size(SimInfo.Mact,2);
aai = 1;
while aai<=LMact
    if (ObjAircraft(SimInfo.Mact(aai)).rit == 11)&&(ObjAircraft(SimInfo.Mact(aai)).nextrit == 11)
        ObjAircraft(SimInfo.Mact(aai)).vm = V11dt;
    end
    if (ObjAircraft(SimInfo.Mact(aai)).rit == 11)&&(ObjAircraft(SimInfo.Mact(aai)).nextrit == 12)
        ObjAircraft(SimInfo.Mact(aai)).vm = V12dt;
    end
    if (ObjAircraft(SimInfo.Mact(aai)).rit == 12)&&(ObjAircraft(SimInfo.Mact(aai)).nextrit == 11)
        ObjAircraft(SimInfo.Mact(aai)).vm = V21dt;
    end
    if (ObjAircraft(SimInfo.Mact(aai)).rit == 12)&&(ObjAircraft(SimInfo.Mact(aai)).nextrit == 11)
        ObjAircraft(SimInfo.Mact(aai)).vm = V22dt;
    end
    aai = aai + 1;
end
end

%% Departure Control Function
function [TFC,ObjAircraft,SimInfo] = ApplyDepartControl(TFC,t,dtC,SimInfo,ObjAircraft)
dtS = SimInfo.dtS;
dtC = SimInfo.dtC;
tf = SimInfo.tf;
% TFC.CS(t/dtC).dtdepc = zeros(size(TFC.CS(t/dtC).udidt));
TFC.CS(t/dtC).dtdepc = min((dtC.*max(0, 1-TFC.CS(t/dtC).udidt) - mod(dtC.*max(0, 1-TFC.CS(t/dtC).udidt),dtS)), tf-t);
LMque = size(SimInfo.Mque,2);
for aai=1:LMque
    if (t<=(ObjAircraft(SimInfo.Mque(aai)).tda)) && ((ObjAircraft(SimInfo.Mque(aai)).tda)<(t+dtC))
        %         if(TFC.CS(t/dtC).udidt(ObjAircraft(SimInfo.Mque(aai)).rio == TFC.CS(t/dtC).ri)<1)
        if(TFC.CS(t/dtC).dtdepc(ObjAircraft(SimInfo.Mque(aai)).rio == TFC.CS(t/dtC).ri)>0)
            %             TFC.CS(t/dtC).dtdepc((ObjAircraft(SimInfo.Mque(aai)).rio == TFC.CS(t/dtC).ri)) = (1-TFC.CS(t/dtC).udidt(ObjAircraft(SimInfo.Mque(aai)).rio == TFC.CS(t/dtC).ri))*dtC;
            ObjAircraft(SimInfo.Mque(aai)).tda = ObjAircraft(SimInfo.Mque(aai)).tda + TFC.CS(t/dtC).dtdepc(ObjAircraft(SimInfo.Mque(aai)).rio == TFC.CS(t/dtC).ri);
            ObjAircraft(SimInfo.Mque(aai)).Curdd = TFC.CS(t/dtC).dtdepc(ObjAircraft(SimInfo.Mque(aai)).rio == TFC.CS(t/dtC).ri);
            ObjAircraft(SimInfo.Mque(aai)).dd = ObjAircraft(SimInfo.Mque(aai)).tda - ObjAircraft(SimInfo.Mque(aai)).tdp;
        end
    end
end
InActiveAircraftID = SimInfo.Mina(all([( (t+dtS) < (cat(1,ObjAircraft(SimInfo.Mina).tda)) ) , ( (cat(1,ObjAircraft(SimInfo.Mina).tda)) < (t+dtC+dtS) )],2));
LMina = size(InActiveAircraftID,2);
aai = 1;
while aai<=LMina
    if (t<=(ObjAircraft(InActiveAircraftID(aai)).tda)) && ((ObjAircraft(InActiveAircraftID(aai)).tda)<(t+dtC))
        %         if(TFC.CS(t/dtC).udidt(ObjAircraft(InActiveAircraftID(aai)).rio == TFC.CS(t/dtC).ri)<1)
        if(TFC.CS(t/dtC).dtdepc(ObjAircraft(InActiveAircraftID(aai)).rio == TFC.CS(t/dtC).ri)>0)
            %             TFC.CS(t/dtC).dtdepc((ObjAircraft(InActiveAircraftID(aai)).rio == TFC.CS(t/dtC).ri)) = (1-TFC.CS(t/dtC).udidt(ObjAircraft(InActiveAircraftID(aai)).rio == TFC.CS(t/dtC).ri))*dtC;
            %ObjAircraft(InActiveAircraftID(aai)).status = 10;
            ObjAircraft(InActiveAircraftID(aai)).tda = ObjAircraft(InActiveAircraftID(aai)).tda + TFC.CS(t/dtC).dtdepc(ObjAircraft(InActiveAircraftID(aai)).rio == TFC.CS(t/dtC).ri);
            ObjAircraft(InActiveAircraftID(aai)).Curdd = TFC.CS(t/dtC).dtdepc(ObjAircraft(InActiveAircraftID(aai)).rio == TFC.CS(t/dtC).ri);
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

%% Boundary Control Function
function [TFC,ObjAircraft,SimInfo] = ApplyBoundaryControlUp(TFC,t,dtC,SimInfo,ObjAircraft,Settings) % Up Down
%  Set Queue Boundary state
Ri_Indexes = TFC.CS(end).ri;
clear aai;
LMactBQ = size(SimInfo.MactBQ,2);
aai = 1;
% if(any(TFC.CS(end).NbqijOut>0,'all'))
while aai<=LMactBQ
    CurrentRegion = mod(ObjAircraft(SimInfo.MactBQ(aai)).rit,10);
    NextRegion = mod(ObjAircraft(SimInfo.MactBQ(aai)).nextrit,10);
    % if(CurrentRegion==11)||(CurrentRegion==12)||(NextRegion==11)||(NextRegion==12)
    if(ObjAircraft(SimInfo.MactBQ(aai)).status == 11)
        if(ObjAircraft(SimInfo.MactBQ(aai)).ResumeTime(end)<=t)
            if(CurrentRegion)&&(NextRegion)
                % if(TFC.CS(end).NbqijOut(CurrentRegion,NextRegion)>=1)
                    % TFC.CS(end).NbqijOut(CurrentRegion,NextRegion) = TFC.CS(end).NbqijOut(CurrentRegion,NextRegion) - 1;
                    ObjAircraft(SimInfo.MactBQ(aai)).ResumeTime(end) = t;
                % end
            end
        end
    end
    % end
    aai = aai + 1;
end
% end
clear aai;
LMact = size(SimInfo.Mact,2);
aai = 1;
if(any(TFC.CS(end).NbqijIn>0,'all'))
    while aai<=LMact
        % if((ObjAircraft(SimInfo.Mact(aai)).rit==11)||(ObjAircraft(SimInfo.Mact(aai)).rit==12))&&((ObjAircraft(SimInfo.Mact(aai)).nextrit==11)||(ObjAircraft(SimInfo.Mact(aai)).nextrit==12))
        CurrentRegion = mod(ObjAircraft(SimInfo.Mact(aai)).rit,10);
        NextRegion = mod(ObjAircraft(SimInfo.Mact(aai)).nextrit,10);
        if(ObjAircraft(SimInfo.Mact(aai)).status == 1)
            if(CurrentRegion)&&(NextRegion)
                if(TFC.CS(end).NbqijIn(CurrentRegion,NextRegion)>=1)
                    if (isempty(ObjAircraft(SimInfo.Mact(aai)).LastStopBoundary)||any(ObjAircraft(SimInfo.Mact(aai)).LastStopBoundary ~= [CurrentRegion,NextRegion]))
                        ObjAircraft(SimInfo.Mact(aai)).status = 11;
                        ObjAircraft(SimInfo.Mact(aai)).BQ = 1;
                        SimInfo.MactBQ = [SimInfo.MactBQ, ObjAircraft(SimInfo.Mact(aai)).id];
                        TFC.CS(end).NbqijIn(CurrentRegion,NextRegion) = TFC.CS(end).NbqijIn(CurrentRegion,NextRegion) - 1;
                        ObjAircraft(SimInfo.Mact(aai)).LastStopBoundary = [CurrentRegion,NextRegion];
                        ObjAircraft(SimInfo.Mact(aai)).StopBoundary = [ObjAircraft(SimInfo.Mact(aai)).StopBoundary; CurrentRegion,NextRegion];
                        ObjAircraft(SimInfo.Mact(aai)).StopTime = [ObjAircraft(SimInfo.Mact(aai)).StopTime; t];
                        ObjAircraft(SimInfo.Mact(aai)).ResumeTime = [ObjAircraft(SimInfo.Mact(aai)).ResumeTime; t + TFC.CS(end).dtbqc(CurrentRegion,NextRegion)];
                        ObjAircraft(SimInfo.Mact(aai)).HoveringTime = ObjAircraft(SimInfo.Mact(aai)).ResumeTime - ObjAircraft(SimInfo.Mact(aai)).StopTime;
                        ObjAircraft(SimInfo.Mact(aai)).CurHoveringTime = ObjAircraft(SimInfo.Mact(aai)).ResumeTime(end) - ObjAircraft(SimInfo.Mact(aai)).StopTime(end);
                        %                 zWP1 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3)+(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        [~,tempRi1] = max(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri));
                        %                     zWP1 = Settings.Airspace.Regions.B(tempRi1).center(3)+(Settings.Airspace.Regions.B(tempRi1).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        zWP1 = Settings.Airspace.dz2-ObjAircraft(SimInfo.Mact(aai)).ra;
                        newWPdown = [ObjAircraft(SimInfo.Mact(aai)).pt(1:2),zWP1]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aai)).wp = [ObjAircraft(SimInfo.Mact(aai)).wp(1:ObjAircraft(SimInfo.Mact(aai)).wpCR,:);newWPdown;ObjAircraft(SimInfo.Mact(aai)).wp(ObjAircraft(SimInfo.Mact(aai)).wpCR+1:end,:)];
                        ObjAircraft(SimInfo.Mact(aai)).wpTR = ObjAircraft(SimInfo.Mact(aai)).wpTR + 1;
                        %                 zWP2 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        [~,tempRi2] = max(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri));
                        %                     zWP2 = Settings.Airspace.Regions.B(tempRi2).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        zWP2 = Settings.Airspace.dz1+ObjAircraft(SimInfo.Mact(aai)).ra;
                        newWPup = [ObjAircraft(SimInfo.Mact(aai)).pt(1:2),zWP2];%ObjAircraft(SimInfo.Mact(aai)).pt(3)]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aai)).wp = [ObjAircraft(SimInfo.Mact(aai)).wp(1:ObjAircraft(SimInfo.Mact(aai)).wpCR+1,:);newWPup;ObjAircraft(SimInfo.Mact(aai)).wp(ObjAircraft(SimInfo.Mact(aai)).wpCR+2:end,:)];
                        ObjAircraft(SimInfo.Mact(aai)).wpTR = ObjAircraft(SimInfo.Mact(aai)).wpTR + 1;
                    end
                end
            end
        end
        % end
        aai = aai + 1;
    end
end
end

function [TFC,ObjAircraft,SimInfo] = ApplyBoundaryControlUp_Old(TFC,t,dtC,SimInfo,ObjAircraft,Settings) % Up Down
%  Set Queue Boundary state
Ri_Indexes = TFC.CS(end).ri;
clear aai;
LMactBQ = size(SimInfo.MactBQ,2);
aai = 1;
if(any(TFC.CS(end).NbqijOut>0,'all'))
    while aai<=LMactBQ
        CurrentRegion = ObjAircraft(SimInfo.MactBQ(aai)).rit;
        NextRegion = ObjAircraft(SimInfo.MactBQ(aai)).nextrit;
        if(ObjAircraft(SimInfo.MactBQ(aai)).status == 11)
            if(TFC.CS(end).NbqijOut(CurrentRegion == Ri_Indexes,NextRegion == Ri_Indexes)>=1)
                TFC.CS(end).NbqijOut(CurrentRegion == Ri_Indexes,NextRegion == Ri_Indexes) = TFC.CS(end).NbqijOut(CurrentRegion == Ri_Indexes,NextRegion == Ri_Indexes) - 1;
                ObjAircraft(SimInfo.MactBQ(aai)).ResumeTime(end) = t;
            end
        end
        aai = aai + 1;
    end
end
clear aai;
LMact = size(SimInfo.Mact,2);
aai = 1;
if(any(TFC.CS(end).NbqijIn>0,'all'))
    while aai<=LMact
        CurrentRegion = ObjAircraft(SimInfo.Mact(aai)).rit;
        NextRegion = ObjAircraft(SimInfo.Mact(aai)).nextrit;
        if(ObjAircraft(SimInfo.Mact(aai)).status == 1)
            if(TFC.CS(end).NbqijIn(CurrentRegion == Ri_Indexes,NextRegion == Ri_Indexes)>=1)
                if (isempty(ObjAircraft(SimInfo.Mact(aai)).LastStopBoundary)||any(ObjAircraft(SimInfo.Mact(aai)).LastStopBoundary ~= [CurrentRegion,NextRegion]))
                    ObjAircraft(SimInfo.Mact(aai)).status = 11;
                    ObjAircraft(SimInfo.Mact(aai)).BQ = 1;
                    SimInfo.MactBQ = [SimInfo.MactBQ, ObjAircraft(SimInfo.Mact(aai)).id];
                    TFC.CS(end).NbqijIn(CurrentRegion == Ri_Indexes,NextRegion == Ri_Indexes) = TFC.CS(end).NbqijIn(CurrentRegion == Ri_Indexes,NextRegion == Ri_Indexes) - 1;
                    ObjAircraft(SimInfo.Mact(aai)).LastStopBoundary = [CurrentRegion,NextRegion];
                    ObjAircraft(SimInfo.Mact(aai)).StopBoundary = [ObjAircraft(SimInfo.Mact(aai)).StopBoundary; CurrentRegion,NextRegion];
                    ObjAircraft(SimInfo.Mact(aai)).StopTime = [ObjAircraft(SimInfo.Mact(aai)).StopTime; t];
                    ObjAircraft(SimInfo.Mact(aai)).ResumeTime = [ObjAircraft(SimInfo.Mact(aai)).ResumeTime; t + TFC.CS(end).dtbqc(CurrentRegion == Ri_Indexes,NextRegion == Ri_Indexes)];
                    ObjAircraft(SimInfo.Mact(aai)).HoveringTime = ObjAircraft(SimInfo.Mact(aai)).ResumeTime - ObjAircraft(SimInfo.Mact(aai)).StopTime;
                    ObjAircraft(SimInfo.Mact(aai)).CurHoveringTime = ObjAircraft(SimInfo.Mact(aai)).ResumeTime(end) - ObjAircraft(SimInfo.Mact(aai)).StopTime(end);
                    %                 zWP1 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3)+(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                    [~,tempRi1] = max(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri));
                    zWP1 = Settings.Airspace.Regions.B(tempRi1).center(3)+(Settings.Airspace.Regions.B(tempRi1).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                    newWPdown = [ObjAircraft(SimInfo.Mact(aai)).pt(1:2),zWP1]; % fptrd fpt pt
                    ObjAircraft(SimInfo.Mact(aai)).wp = [ObjAircraft(SimInfo.Mact(aai)).wp(1:ObjAircraft(SimInfo.Mact(aai)).wpCR,:);newWPdown;ObjAircraft(SimInfo.Mact(aai)).wp(ObjAircraft(SimInfo.Mact(aai)).wpCR+1:end,:)];
                    ObjAircraft(SimInfo.Mact(aai)).wpTR = ObjAircraft(SimInfo.Mact(aai)).wpTR + 1;
                    %                 zWP2 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                    [~,tempRi2] = max(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri));
                    zWP2 = Settings.Airspace.Regions.B(tempRi2).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                    newWPup = [ObjAircraft(SimInfo.Mact(aai)).pt(1:2),zWP2];%ObjAircraft(SimInfo.Mact(aai)).pt(3)]; % fptrd fpt pt
                    ObjAircraft(SimInfo.Mact(aai)).wp = [ObjAircraft(SimInfo.Mact(aai)).wp(1:ObjAircraft(SimInfo.Mact(aai)).wpCR+1,:);newWPup;ObjAircraft(SimInfo.Mact(aai)).wp(ObjAircraft(SimInfo.Mact(aai)).wpCR+2:end,:)];
                    ObjAircraft(SimInfo.Mact(aai)).wpTR = ObjAircraft(SimInfo.Mact(aai)).wpTR + 1;
                end
            end
        end
        aai = aai + 1;
    end
end
end


