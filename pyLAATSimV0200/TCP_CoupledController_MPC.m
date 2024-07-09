function [TFC,ObjAircraft,SimInfo] = TCP_CoupledController_MPC(SimInfo,ObjAircraft,Settings,TFC,t)
t = SimInfo.t;
dtC = SimInfo.dtC;
dtS = SimInfo.dtS;
tf = SimInfo.tf;
%% Set Control states
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))
    [TFC] = UpdateControlState(TFC,t/dtC);
end
% %% Determine MPC Control Inputs
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC.CS))&&(Settings.TFC.TCP_CoupledController_MPC)
    % [ud_opt,ub_opt,MPCSim] = MPC_CoupledModel_2L2R_V2_LeM(SimInfo,ObjAircraft,Settings,TFC,t);
    [ud_opt,ub_opt,MPCSim] = MPC_CoupledModel_3L2R_V1(SimInfo,ObjAircraft,Settings,TFC,t);
    TFC.MPCSim(t/dtC) = MPCSim;
    TFC.CS(t/dtC).udidt = ud_opt;
    TFC.CS(t/dtC).ubijIOdt = ub_opt;
    TFC.CS(t/dtC).dtbqc = MPCSim.dtbqc;
    TFC.CS(t/dtC).NbqijIndt = MPCSim.NbqijIndt;
    TFC.CS(t/dtC).NbqijOutdt = MPCSim.NbqijOutdt;
    %     TFC.CS(t/dtC).dtbqc = zeros(6,6);
    %     TFC.CS(t/dtC).dtbqc(3,4) = MPCSim.dtbqc(1,2);
    %     TFC.CS(t/dtC).dtbqc(4,3) = MPCSim.dtbqc(2,1);
    % %     TFC.CS(t/dtC).NbqijIndt = zeros(6,6);
    %     TFC.CS(t/dtC).NbqijIndt(3,4) = MPCSim.NbqijIndt(1,2);
    %     TFC.CS(t/dtC).NbqijIndt(4,3) = MPCSim.NbqijIndt(2,1);
    % %     TFC.CS(t/dtC).NbqijOutdt = zeros(6,6);
    %     TFC.CS(t/dtC).NbqijOutdt(3,4) = MPCSim.NbqijOutdt(1,2);
    %     TFC.CS(t/dtC).NbqijOutdt(4,3) = MPCSim.NbqijOutdt(2,1);
    TFC.CS(t/dtC).NbqijIn = TFC.CS(t/dtC).NbqijIndt;
    TFC.CS(t/dtC).NbqijOut = TFC.CS(t/dtC).NbqijOutdt;
end
%% Set Queue Boundary state
if (t~=0)&&(~isempty(TFC.CS))&&(Settings.TFC.TCP_CoupledController_MPC)
    % [TFC,ObjAircraft,SimInfo] = ApplyBoundaryControlUp(TFC,t,dtC,SimInfo,ObjAircraft,Settings); % Going one layer Up
    % [TFC,ObjAircraft,SimInfo] = ApplyBoundaryControlUpShortestDistance(TFC,t,dtC,SimInfo,ObjAircraft,Settings); % Going one layer Up
    BoundaryUpPolicyStr = Settings.TFC.TCP_BoundaryUpPolicyStr; % MaxTL | MinTLDone | MinTLLeft | MaxTLLeft | FirstDeparted
    switch BoundaryUpPolicyStr
        case 'MaxTL' % Going one layer Up when the trip length is the longest.
            [TFC,ObjAircraft,SimInfo] = ApplyBoundaryControlUpMaxTL(TFC,t,dtC,SimInfo,ObjAircraft,Settings);
        case 'MinTLDone' % Minimum Distance travel so far, have enough 'battery' to stop, just now started his trip..
            [TFC,ObjAircraft,SimInfo] = ApplyBoundaryControlUpMinTLDone(TFC,t,dtC,SimInfo,ObjAircraft,Settings);
        case 'MinTLLeft' % Minimum Trip Length left first in queue, don't have a lot to travel, so we don't mind "delaying" him.
            [TFC,ObjAircraft,SimInfo] = ApplyBoundaryControlUpMinTLLeft(TFC,t,dtC,SimInfo,ObjAircraft,Settings);
        case 'MaxTLLeft' % Maximum Trip Length left first in queue, create more congested and conflict in the airspace.
            [TFC,ObjAircraft,SimInfo] = ApplyBoundaryControlUpMaxTLLeft(TFC,t,dtC,SimInfo,ObjAircraft,Settings);
        case 'FirstDeparted'
            [TFC,ObjAircraft,SimInfo] = ApplyBoundaryControlUp(TFC,t,dtC,SimInfo,ObjAircraft,Settings); % Going one layer Up
        otherwise % First Departed in the queue
            [TFC,ObjAircraft,SimInfo] = ApplyBoundaryControlUp(TFC,t,dtC,SimInfo,ObjAircraft,Settings); % Going one layer Up
    end
    %     warning('check MPC solution, in particular the Nin Nout values...')
    %     warning('check Simulation duration and values...')
end
%% Change DepartTime
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))&&(Settings.TFC.TCP_CoupledController_MPC)
    [TFC,ObjAircraft,SimInfo] = ApplyDepartControl(TFC,t,dtC,SimInfo,ObjAircraft);
end
% if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))&&(Settings.TFC.TCP_CoupledController_MPC)
%     disp(['| t=' num2str(t)])
%     disp(Settings.TFC.nci)
%     disp(TFC.CS(t/dtC).nit)
%     disp(TFC.CS(t/dtC).udidt)
% %     disp(TFC.CS(t/dtC).ubijdt)
%     warning('ADD IN OUT CONCEPT!')
%     % disp(['| t=' num2str(t),' | nt=' num2str(TFC.N.n(t/dtC)), ' | vt=' num2str(TFC.N.V(t/dtC)), ' | uI=' num2str(TFC.CS(t/dtC).uIdt),' | dtI=' num2str(TFC.CS(t/dtC).dtIdt), ' |'])
% end
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
        if(ObjAircraft(InActiveAircraftID(aai)).AMI==3)||(ObjAircraft(InActiveAircraftID(aai)).AMI==4)
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
    else
        aai = aai + 1;
    end
end

end

%% Boundary Control Function

function [TFC,ObjAircraft,SimInfo] = ApplyBoundaryControlUpMaxTL(TFC,t,dtC,SimInfo,ObjAircraft,Settings) % Up Down
%  Set Queue Boundary state
Ri_Indexes = TFC.CS(end).ri;
clear aai;
LMactBQ = size(SimInfo.MactBQ,2);
aai = 1;
if(any(TFC.CS(end).NbqijOut>0,'all'))
    while aai<=LMactBQ
        CurrentRegion = mod(ObjAircraft(SimInfo.MactBQ(aai)).rit,10);
        NextRegion = mod(ObjAircraft(SimInfo.MactBQ(aai)).nextrit,10);
        % if(CurrentRegion==11)||(CurrentRegion==12)||(NextRegion==11)||(NextRegion==12)
        if(ObjAircraft(SimInfo.MactBQ(aai)).status == 11)
            if(ObjAircraft(SimInfo.MactBQ(aai)).ResumeTime(end)<=t)
                if(CurrentRegion)&&(NextRegion)
                    if(TFC.CS(end).NbqijOut(CurrentRegion,NextRegion)>=1)
                        TFC.CS(end).NbqijOut(CurrentRegion,NextRegion) = TFC.CS(end).NbqijOut(CurrentRegion,NextRegion) - 1;
                        ObjAircraft(SimInfo.MactBQ(aai)).ResumeTime(end) = t;
                    end
                end
            end
        end
        % end
        aai = aai + 1;
    end
end
clear aai;
LMact = size(SimInfo.Mact,2);
[~,MaxTLIndex] = sort(cat(1,ObjAircraft(SimInfo.Mact(:)).tl_total),'descend');
aai = 1;
if(any(TFC.CS(end).NbqijIn>0,'all'))
    while aai<=LMact
        aaiSP = MaxTLIndex(aai);
        % if(ObjAircraft(SimInfo.Mact(aaiSP)).AircraftModelIndex~=3)
        % if((ObjAircraft(SimInfo.Mact(aai)).rit==11)||(ObjAircraft(SimInfo.Mact(aai)).rit==12))&&((ObjAircraft(SimInfo.Mact(aai)).nextrit==11)||(ObjAircraft(SimInfo.Mact(aai)).nextrit==12))
        CurrentRegion = mod(ObjAircraft(SimInfo.Mact(aaiSP)).rit,10);
        NextRegion = mod(ObjAircraft(SimInfo.Mact(aaiSP)).nextrit,10);
        if(ObjAircraft(SimInfo.Mact(aaiSP)).status == 1)
            if(CurrentRegion)&&(NextRegion)
                if(TFC.CS(end).NbqijIn(CurrentRegion,NextRegion)>=1)
                    if (isempty(ObjAircraft(SimInfo.Mact(aaiSP)).LastStopBoundary)||any(ObjAircraft(SimInfo.Mact(aaiSP)).LastStopBoundary ~= [CurrentRegion,NextRegion]))
                        ObjAircraft(SimInfo.Mact(aaiSP)).status = 11;
                        ObjAircraft(SimInfo.Mact(aaiSP)).BQ = 1;
                        SimInfo.MactBQ = [SimInfo.MactBQ, ObjAircraft(SimInfo.Mact(aaiSP)).id];
                        TFC.CS(end).NbqijIn(CurrentRegion,NextRegion) = TFC.CS(end).NbqijIn(CurrentRegion,NextRegion) - 1;
                        ObjAircraft(SimInfo.Mact(aaiSP)).LastStopBoundary = [CurrentRegion,NextRegion];
                        ObjAircraft(SimInfo.Mact(aaiSP)).StopBoundary = [ObjAircraft(SimInfo.Mact(aaiSP)).StopBoundary; CurrentRegion,NextRegion];
                        ObjAircraft(SimInfo.Mact(aaiSP)).StopTime = [ObjAircraft(SimInfo.Mact(aaiSP)).StopTime; t];
                        ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime = [ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime; t + TFC.CS(end).dtbqc(CurrentRegion,NextRegion)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).HoveringTime = ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime - ObjAircraft(SimInfo.Mact(aaiSP)).StopTime;
                        ObjAircraft(SimInfo.Mact(aaiSP)).CurHoveringTime = ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime(end) - ObjAircraft(SimInfo.Mact(aaiSP)).StopTime(end);
                        %                 zWP1 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3)+(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        [~,tempRi1] = max(ObjAircraft(SimInfo.Mact(aaiSP)).rit==cat(1,Settings.Airspace.Regions.B.ri));
                        zWP1 = Settings.Airspace.Regions.B(tempRi1).center(3)+(Settings.Airspace.Regions.B(tempRi1).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        % zWP1 = Settings.Airspace.dz2-ObjAircraft(SimInfo.Mact(aaiSP)).ra;
                        newWPdown = [ObjAircraft(SimInfo.Mact(aaiSP)).pt(1:2),zWP1]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aaiSP)).wp = [ObjAircraft(SimInfo.Mact(aaiSP)).wp(1:ObjAircraft(SimInfo.Mact(aaiSP)).wpCR,:);newWPdown;ObjAircraft(SimInfo.Mact(aaiSP)).wp(ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+1:end,:)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).wpTR = ObjAircraft(SimInfo.Mact(aaiSP)).wpTR + 1;
                        %                 zWP2 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        [~,tempRi2] = max(ObjAircraft(SimInfo.Mact(aaiSP)).rit==cat(1,Settings.Airspace.Regions.B.ri));
                        zWP2 = Settings.Airspace.Regions.B(tempRi2).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        % zWP2 = Settings.Airspace.dz1+ObjAircraft(SimInfo.Mact(aaiSP)).ra;
                        newWPup = [ObjAircraft(SimInfo.Mact(aaiSP)).pt(1:2),zWP2];%ObjAircraft(SimInfo.Mact(aai)).pt(3)]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aaiSP)).wp = [ObjAircraft(SimInfo.Mact(aaiSP)).wp(1:ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+1,:);newWPup;ObjAircraft(SimInfo.Mact(aaiSP)).wp(ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+2:end,:)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).wpTR = ObjAircraft(SimInfo.Mact(aaiSP)).wpTR + 1;
                    end
                end
            end
        end
        % end
        aai = aai + 1;
    end
end
end

function [TFC,ObjAircraft,SimInfo] = ApplyBoundaryControlUpMinTLDone(TFC,t,dtC,SimInfo,ObjAircraft,Settings) % Up Down
%  Set Queue Boundary state
Ri_Indexes = TFC.CS(end).ri;
clear aai;
LMactBQ = size(SimInfo.MactBQ,2);
aai = 1;
if(any(TFC.CS(end).NbqijOut>0,'all'))
    while aai<=LMactBQ
        CurrentRegion = mod(ObjAircraft(SimInfo.MactBQ(aai)).rit,10);
        NextRegion = mod(ObjAircraft(SimInfo.MactBQ(aai)).nextrit,10);
        % if(CurrentRegion==11)||(CurrentRegion==12)||(NextRegion==11)||(NextRegion==12)
        if(ObjAircraft(SimInfo.MactBQ(aai)).status == 11)
            if(ObjAircraft(SimInfo.MactBQ(aai)).ResumeTime(end)<=t)
                if(CurrentRegion)&&(NextRegion)
                    if(TFC.CS(end).NbqijOut(CurrentRegion,NextRegion)>=1)
                        TFC.CS(end).NbqijOut(CurrentRegion,NextRegion) = TFC.CS(end).NbqijOut(CurrentRegion,NextRegion) - 1;
                        ObjAircraft(SimInfo.MactBQ(aai)).ResumeTime(end) = t;
                    end
                end
            end
        end
        % end
        aai = aai + 1;
    end
end
clear aai;
LMact = size(SimInfo.Mact,2);
[~,MinTLDoneIndex] = sort(cat(1,ObjAircraft(SimInfo.Mact(:)).tl_done),'ascend');
aai = 1;
if(any(TFC.CS(end).NbqijIn>0,'all'))
    while aai<=LMact
        aaiSP = MinTLDoneIndex(aai);
        % if((ObjAircraft(SimInfo.Mact(aai)).rit==11)||(ObjAircraft(SimInfo.Mact(aai)).rit==12))&&((ObjAircraft(SimInfo.Mact(aai)).nextrit==11)||(ObjAircraft(SimInfo.Mact(aai)).nextrit==12))
        CurrentRegion = mod(ObjAircraft(SimInfo.Mact(aaiSP)).rit,10);
        NextRegion = mod(ObjAircraft(SimInfo.Mact(aaiSP)).nextrit,10);
        if(ObjAircraft(SimInfo.Mact(aaiSP)).status == 1)
            if(CurrentRegion)&&(NextRegion)
                if(TFC.CS(end).NbqijIn(CurrentRegion,NextRegion)>=1)
                    if (isempty(ObjAircraft(SimInfo.Mact(aaiSP)).LastStopBoundary)||any(ObjAircraft(SimInfo.Mact(aaiSP)).LastStopBoundary ~= [CurrentRegion,NextRegion]))
                        ObjAircraft(SimInfo.Mact(aaiSP)).status = 11;
                        ObjAircraft(SimInfo.Mact(aaiSP)).BQ = 1;
                        SimInfo.MactBQ = [SimInfo.MactBQ, ObjAircraft(SimInfo.Mact(aaiSP)).id];
                        TFC.CS(end).NbqijIn(CurrentRegion,NextRegion) = TFC.CS(end).NbqijIn(CurrentRegion,NextRegion) - 1;
                        ObjAircraft(SimInfo.Mact(aaiSP)).LastStopBoundary = [CurrentRegion,NextRegion];
                        ObjAircraft(SimInfo.Mact(aaiSP)).StopBoundary = [ObjAircraft(SimInfo.Mact(aaiSP)).StopBoundary; CurrentRegion,NextRegion];
                        ObjAircraft(SimInfo.Mact(aaiSP)).StopTime = [ObjAircraft(SimInfo.Mact(aaiSP)).StopTime; t];
                        ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime = [ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime; t + TFC.CS(end).dtbqc(CurrentRegion,NextRegion)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).HoveringTime = ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime - ObjAircraft(SimInfo.Mact(aaiSP)).StopTime;
                        ObjAircraft(SimInfo.Mact(aaiSP)).CurHoveringTime = ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime(end) - ObjAircraft(SimInfo.Mact(aaiSP)).StopTime(end);
                        %                 zWP1 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3)+(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        [~,tempRi1] = max(ObjAircraft(SimInfo.Mact(aaiSP)).rit==cat(1,Settings.Airspace.Regions.B.ri));
                        zWP1 = Settings.Airspace.Regions.B(tempRi1).center(3)+(Settings.Airspace.Regions.B(tempRi1).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        % zWP1 = Settings.Airspace.dz2-ObjAircraft(SimInfo.Mact(aaiSP)).ra;
                        newWPdown = [ObjAircraft(SimInfo.Mact(aaiSP)).pt(1:2),zWP1]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aaiSP)).wp = [ObjAircraft(SimInfo.Mact(aaiSP)).wp(1:ObjAircraft(SimInfo.Mact(aaiSP)).wpCR,:);newWPdown;ObjAircraft(SimInfo.Mact(aaiSP)).wp(ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+1:end,:)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).wpTR = ObjAircraft(SimInfo.Mact(aaiSP)).wpTR + 1;
                        %                 zWP2 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        [~,tempRi2] = max(ObjAircraft(SimInfo.Mact(aaiSP)).rit==cat(1,Settings.Airspace.Regions.B.ri));
                        zWP2 = Settings.Airspace.Regions.B(tempRi2).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        % zWP2 = Settings.Airspace.dz1+ObjAircraft(SimInfo.Mact(aaiSP)).ra;
                        newWPup = [ObjAircraft(SimInfo.Mact(aaiSP)).pt(1:2),zWP2];%ObjAircraft(SimInfo.Mact(aai)).pt(3)]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aaiSP)).wp = [ObjAircraft(SimInfo.Mact(aaiSP)).wp(1:ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+1,:);newWPup;ObjAircraft(SimInfo.Mact(aaiSP)).wp(ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+2:end,:)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).wpTR = ObjAircraft(SimInfo.Mact(aaiSP)).wpTR + 1;
                    end
                end
            end
        end
        % end
        aai = aai + 1;
    end
end
end

function [TFC,ObjAircraft,SimInfo] = ApplyBoundaryControlUpMinTLLeft(TFC,t,dtC,SimInfo,ObjAircraft,Settings) % Up Down
%  Set Queue Boundary state
Ri_Indexes = TFC.CS(end).ri;
clear aai;
LMactBQ = size(SimInfo.MactBQ,2);
aai = 1;
if(any(TFC.CS(end).NbqijOut>0,'all'))
    while aai<=LMactBQ
        CurrentRegion = mod(ObjAircraft(SimInfo.MactBQ(aai)).rit,10);
        NextRegion = mod(ObjAircraft(SimInfo.MactBQ(aai)).nextrit,10);
        % if(CurrentRegion==11)||(CurrentRegion==12)||(NextRegion==11)||(NextRegion==12)
        if(ObjAircraft(SimInfo.MactBQ(aai)).status == 11)
            if(ObjAircraft(SimInfo.MactBQ(aai)).ResumeTime(end)<=t)
                if(CurrentRegion)&&(NextRegion)
                    if(TFC.CS(end).NbqijOut(CurrentRegion,NextRegion)>=1)
                        TFC.CS(end).NbqijOut(CurrentRegion,NextRegion) = TFC.CS(end).NbqijOut(CurrentRegion,NextRegion) - 1;
                        ObjAircraft(SimInfo.MactBQ(aai)).ResumeTime(end) = t;
                    end
                end
            end
        end
        % end
        aai = aai + 1;
    end
end
clear aai;
LMact = size(SimInfo.Mact,2);
[~,MinTLLeftIndex] = sort(cat(1,ObjAircraft(SimInfo.Mact(:)).tl_left),'ascend');
aai = 1;
if(any(TFC.CS(end).NbqijIn>0,'all'))
    while aai<=LMact
        aaiSP = MinTLLeftIndex(aai);
        % if((ObjAircraft(SimInfo.Mact(aai)).rit==11)||(ObjAircraft(SimInfo.Mact(aai)).rit==12))&&((ObjAircraft(SimInfo.Mact(aai)).nextrit==11)||(ObjAircraft(SimInfo.Mact(aai)).nextrit==12))
        CurrentRegion = mod(ObjAircraft(SimInfo.Mact(aaiSP)).rit,10);
        NextRegion = mod(ObjAircraft(SimInfo.Mact(aaiSP)).nextrit,10);
        if(ObjAircraft(SimInfo.Mact(aaiSP)).status == 1)
            if(CurrentRegion)&&(NextRegion)
                if(TFC.CS(end).NbqijIn(CurrentRegion,NextRegion)>=1)
                    if (isempty(ObjAircraft(SimInfo.Mact(aaiSP)).LastStopBoundary)||any(ObjAircraft(SimInfo.Mact(aaiSP)).LastStopBoundary ~= [CurrentRegion,NextRegion]))
                        ObjAircraft(SimInfo.Mact(aaiSP)).status = 11;
                        ObjAircraft(SimInfo.Mact(aaiSP)).BQ = 1;
                        SimInfo.MactBQ = [SimInfo.MactBQ, ObjAircraft(SimInfo.Mact(aaiSP)).id];
                        TFC.CS(end).NbqijIn(CurrentRegion,NextRegion) = TFC.CS(end).NbqijIn(CurrentRegion,NextRegion) - 1;
                        ObjAircraft(SimInfo.Mact(aaiSP)).LastStopBoundary = [CurrentRegion,NextRegion];
                        ObjAircraft(SimInfo.Mact(aaiSP)).StopBoundary = [ObjAircraft(SimInfo.Mact(aaiSP)).StopBoundary; CurrentRegion,NextRegion];
                        ObjAircraft(SimInfo.Mact(aaiSP)).StopTime = [ObjAircraft(SimInfo.Mact(aaiSP)).StopTime; t];
                        ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime = [ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime; t + TFC.CS(end).dtbqc(CurrentRegion,NextRegion)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).HoveringTime = ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime - ObjAircraft(SimInfo.Mact(aaiSP)).StopTime;
                        ObjAircraft(SimInfo.Mact(aaiSP)).CurHoveringTime = ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime(end) - ObjAircraft(SimInfo.Mact(aaiSP)).StopTime(end);
                        %                 zWP1 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3)+(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        [~,tempRi1] = max(ObjAircraft(SimInfo.Mact(aaiSP)).rit==cat(1,Settings.Airspace.Regions.B.ri));
                        zWP1 = Settings.Airspace.Regions.B(tempRi1).center(3)+(Settings.Airspace.Regions.B(tempRi1).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        % zWP1 = Settings.Airspace.dz2-ObjAircraft(SimInfo.Mact(aaiSP)).ra;
                        newWPdown = [ObjAircraft(SimInfo.Mact(aaiSP)).pt(1:2),zWP1]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aaiSP)).wp = [ObjAircraft(SimInfo.Mact(aaiSP)).wp(1:ObjAircraft(SimInfo.Mact(aaiSP)).wpCR,:);newWPdown;ObjAircraft(SimInfo.Mact(aaiSP)).wp(ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+1:end,:)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).wpTR = ObjAircraft(SimInfo.Mact(aaiSP)).wpTR + 1;
                        %                 zWP2 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        [~,tempRi2] = max(ObjAircraft(SimInfo.Mact(aaiSP)).rit==cat(1,Settings.Airspace.Regions.B.ri));
                        zWP2 = Settings.Airspace.Regions.B(tempRi2).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        % zWP2 = Settings.Airspace.dz1+ObjAircraft(SimInfo.Mact(aaiSP)).ra;
                        newWPup = [ObjAircraft(SimInfo.Mact(aaiSP)).pt(1:2),zWP2];%ObjAircraft(SimInfo.Mact(aai)).pt(3)]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aaiSP)).wp = [ObjAircraft(SimInfo.Mact(aaiSP)).wp(1:ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+1,:);newWPup;ObjAircraft(SimInfo.Mact(aaiSP)).wp(ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+2:end,:)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).wpTR = ObjAircraft(SimInfo.Mact(aaiSP)).wpTR + 1;
                    end
                end
            end
        end
        % end
        aai = aai + 1;
    end
end
end

function [TFC,ObjAircraft,SimInfo] = ApplyBoundaryControlUpMaxTLLeft(TFC,t,dtC,SimInfo,ObjAircraft,Settings) % Up Down
%  Set Queue Boundary state
Ri_Indexes = TFC.CS(end).ri;
clear aai;
LMactBQ = size(SimInfo.MactBQ,2);
aai = 1;
if(any(TFC.CS(end).NbqijOut>0,'all'))
    while aai<=LMactBQ
        CurrentRegion = mod(ObjAircraft(SimInfo.MactBQ(aai)).rit,10);
        NextRegion = mod(ObjAircraft(SimInfo.MactBQ(aai)).nextrit,10);
        % if(CurrentRegion==11)||(CurrentRegion==12)||(NextRegion==11)||(NextRegion==12)
        if(ObjAircraft(SimInfo.MactBQ(aai)).status == 11)
            if(ObjAircraft(SimInfo.MactBQ(aai)).ResumeTime(end)<=t)
                if(CurrentRegion)&&(NextRegion)
                    if(TFC.CS(end).NbqijOut(CurrentRegion,NextRegion)>=1)
                        TFC.CS(end).NbqijOut(CurrentRegion,NextRegion) = TFC.CS(end).NbqijOut(CurrentRegion,NextRegion) - 1;
                        ObjAircraft(SimInfo.MactBQ(aai)).ResumeTime(end) = t;
                    end
                end
            end
        end
        % end
        aai = aai + 1;
    end
end
clear aai;
LMact = size(SimInfo.Mact,2);
[~,MaxTLLeftIndex] = sort(cat(1,ObjAircraft(SimInfo.Mact(:)).tl_left),'descend');
aai = 1;
if(any(TFC.CS(end).NbqijIn>0,'all'))
    while aai<=LMact
        aaiSP = MaxTLLeftIndex(aai);
        % if((ObjAircraft(SimInfo.Mact(aai)).rit==11)||(ObjAircraft(SimInfo.Mact(aai)).rit==12))&&((ObjAircraft(SimInfo.Mact(aai)).nextrit==11)||(ObjAircraft(SimInfo.Mact(aai)).nextrit==12))
        CurrentRegion = mod(ObjAircraft(SimInfo.Mact(aaiSP)).rit,10);
        NextRegion = mod(ObjAircraft(SimInfo.Mact(aaiSP)).nextrit,10);
        if(ObjAircraft(SimInfo.Mact(aaiSP)).status == 1)
            if(CurrentRegion)&&(NextRegion)
                if(TFC.CS(end).NbqijIn(CurrentRegion,NextRegion)>=1)
                    if (isempty(ObjAircraft(SimInfo.Mact(aaiSP)).LastStopBoundary)||any(ObjAircraft(SimInfo.Mact(aaiSP)).LastStopBoundary ~= [CurrentRegion,NextRegion]))
                        ObjAircraft(SimInfo.Mact(aaiSP)).status = 11;
                        ObjAircraft(SimInfo.Mact(aaiSP)).BQ = 1;
                        SimInfo.MactBQ = [SimInfo.MactBQ, ObjAircraft(SimInfo.Mact(aaiSP)).id];
                        TFC.CS(end).NbqijIn(CurrentRegion,NextRegion) = TFC.CS(end).NbqijIn(CurrentRegion,NextRegion) - 1;
                        ObjAircraft(SimInfo.Mact(aaiSP)).LastStopBoundary = [CurrentRegion,NextRegion];
                        ObjAircraft(SimInfo.Mact(aaiSP)).StopBoundary = [ObjAircraft(SimInfo.Mact(aaiSP)).StopBoundary; CurrentRegion,NextRegion];
                        ObjAircraft(SimInfo.Mact(aaiSP)).StopTime = [ObjAircraft(SimInfo.Mact(aaiSP)).StopTime; t];
                        ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime = [ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime; t + TFC.CS(end).dtbqc(CurrentRegion,NextRegion)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).HoveringTime = ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime - ObjAircraft(SimInfo.Mact(aaiSP)).StopTime;
                        ObjAircraft(SimInfo.Mact(aaiSP)).CurHoveringTime = ObjAircraft(SimInfo.Mact(aaiSP)).ResumeTime(end) - ObjAircraft(SimInfo.Mact(aaiSP)).StopTime(end);
                        %                 zWP1 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3)+(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        [~,tempRi1] = max(ObjAircraft(SimInfo.Mact(aaiSP)).rit==cat(1,Settings.Airspace.Regions.B.ri));
                        zWP1 = Settings.Airspace.Regions.B(tempRi1).center(3)+(Settings.Airspace.Regions.B(tempRi1).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        % zWP1 = Settings.Airspace.dz2-ObjAircraft(SimInfo.Mact(aaiSP)).ra;
                        newWPdown = [ObjAircraft(SimInfo.Mact(aaiSP)).pt(1:2),zWP1]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aaiSP)).wp = [ObjAircraft(SimInfo.Mact(aaiSP)).wp(1:ObjAircraft(SimInfo.Mact(aaiSP)).wpCR,:);newWPdown;ObjAircraft(SimInfo.Mact(aaiSP)).wp(ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+1:end,:)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).wpTR = ObjAircraft(SimInfo.Mact(aaiSP)).wpTR + 1;
                        %                 zWP2 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        [~,tempRi2] = max(ObjAircraft(SimInfo.Mact(aaiSP)).rit==cat(1,Settings.Airspace.Regions.B.ri));
                        zWP2 = Settings.Airspace.Regions.B(tempRi2).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        % zWP2 = Settings.Airspace.dz1+ObjAircraft(SimInfo.Mact(aaiSP)).ra;
                        newWPup = [ObjAircraft(SimInfo.Mact(aaiSP)).pt(1:2),zWP2];%ObjAircraft(SimInfo.Mact(aai)).pt(3)]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aaiSP)).wp = [ObjAircraft(SimInfo.Mact(aaiSP)).wp(1:ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+1,:);newWPup;ObjAircraft(SimInfo.Mact(aaiSP)).wp(ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+2:end,:)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).wpTR = ObjAircraft(SimInfo.Mact(aaiSP)).wpTR + 1;
                    end
                end
            end
        end
        % end
        aai = aai + 1;
    end
end
end

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
            if(ObjAircraft(SimInfo.Mact(aai)).AMI==3)||(ObjAircraft(SimInfo.Mact(aai)).AMI==4)

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
                            % [~,tempRi1] = max(ObjAircraft(SimInfo.Mact(aai)).rit==cat(1,Settings.Airspace.Regions.B.ri));
                            zWP1 = Settings.Airspace.Layers(3).center(3);% Settings.Airspace.Regions.B(tempRi1).center(3)+(Settings.Airspace.Regions.B(tempRi1).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                            % zWP1 = Settings.Airspace.dz2-ObjAircraft(SimInfo.Mact(aai)).ra;
                            newWPdown = [ObjAircraft(SimInfo.Mact(aai)).pt(1:2),zWP1]; % fptrd fpt pt
                            ObjAircraft(SimInfo.Mact(aai)).wp = [ObjAircraft(SimInfo.Mact(aai)).wp(1:ObjAircraft(SimInfo.Mact(aai)).wpCR,:);newWPdown;ObjAircraft(SimInfo.Mact(aai)).wp(ObjAircraft(SimInfo.Mact(aai)).wpCR+1:end,:)];
                            ObjAircraft(SimInfo.Mact(aai)).wpTR = ObjAircraft(SimInfo.Mact(aai)).wpTR + 1;
                            %                 zWP2 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                            % [~,tempRi2] = max(ObjAircraft(SimInfo.Mact(aai)).rit==cat(1,Settings.Airspace.Regions.B.ri));
                            zWP2 = Settings.Airspace.Layers(2).center(3); %Settings.Airspace.Regions.B(tempRi2).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                            % zWP2 = Settings.Airspace.dz1+ObjAircraft(SimInfo.Mact(aai)).ra;
                            newWPup = [ObjAircraft(SimInfo.Mact(aai)).pt(1:2),zWP2];%ObjAircraft(SimInfo.Mact(aai)).pt(3)]; % fptrd fpt pt
                            ObjAircraft(SimInfo.Mact(aai)).wp = [ObjAircraft(SimInfo.Mact(aai)).wp(1:ObjAircraft(SimInfo.Mact(aai)).wpCR+1,:);newWPup;ObjAircraft(SimInfo.Mact(aai)).wp(ObjAircraft(SimInfo.Mact(aai)).wpCR+2:end,:)];
                            ObjAircraft(SimInfo.Mact(aai)).wpTR = ObjAircraft(SimInfo.Mact(aai)).wpTR + 1;
                        end
                    end
                end
            end
        end
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


