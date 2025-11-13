function [TFC,ObjAircraft,SimInfo] = TCP_DBControl_GC_Micro(SimInfo,ObjAircraft,Settings,TFC,t)
%TCP_DBControl_GC_Micro Implements the Greedy Controller for Departure and Boundary Control.
%   This function applies a simple, reactive, threshold-based control logic
%   for managing traffic flow. It is known as a "Greedy Controller" (GC)
%   because it makes decisions based only on the current state without
%   predicting future evolution.
%
%   The control logic is as follows:
%   1. Departure Control: For each region, if the current accumulation `n_i`
%      is greater than or equal to the critical accumulation `n_ci`, the
%      departure rate for that region is set to zero. Otherwise, it is
%      set to the maximum.
%   2. Boundary Control: For each pair of regions (i, j), if the destination
%      region `j` is congested (`n_j >= n_cj`), the transfer of aircraft
%      from `i` to `j` is halted.
%
%   This function calls helper functions to determine the control inputs and
%   then applies them by either delaying departures or creating boundary queues.
%
% Inputs:
%   SimInfo     - (struct) Current simulation information.
%   ObjAircraft - (struct) Array of aircraft objects.
%   Settings    - (struct) Simulation settings.
%   TFC         - (struct) Current Traffic Flow Characteristics data.
%   t           - (numeric) The current simulation time.
% Author: Yazan Safadi
% Date Created: 2023-09-20
t = SimInfo.t;
dtC = SimInfo.dtC;
dtS = SimInfo.dtS;
tf = SimInfo.tf;
%% Validation of Airspace Setting
if (Settings.TFC.TCPolicy == 1) && (ismember(Settings.Airspace.asStr, {'Subset'}))
    error('[INFO] Airspace setting of subset does not support DBC Controller case')
end
%% Set Control states
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))
    [TFC] = UpdateControlState(TFC,t/dtC);
end
% %% Determine MPC Control Inputs
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC.CS))&&(Settings.TFC.TCP_DBController_GC)
    % Determine Departure Control based on region density
    [TFC] = DetermineUdi(TFC, t/dtC, TFC.CS(t/dtC).nit, Settings.TFC.nci, 1, 0);
    % Determine Boundary Control based on destination region density
    [TFC] = DetermineUbij(TFC, t/dtC, TFC.CS(t/dtC).nit, Settings.TFC.nci, 1, 0);
    % Determine number of aircraft to hold/release from boundary queues
    [TFC] = DetermineBoundaryQueueFlow(TFC, SimInfo, ObjAircraft, Settings, t/dtC);

    % --- DEBUG DISPLAY ---
    k = t/dtC;
    disp(['[INFO] t=', num2str(t), 's | TCP_DBControl_GC_Micro:']);
    disp(['  > Region Accumulations (nit):   [', num2str(TFC.CS(k).nit), ']']);
    disp(['  > Critical Accumulations (nci):     [', num2str(Settings.TFC.nci), ']']);
    disp(['  > Departure Control (udidt):    [', num2str(TFC.CS(k).udidt), ']']);
    disp('  > Boundary Control (ubijdt):');
    disp(TFC.CS(k).ubijdt);
    disp('  > Boundary Queue In (NbqijIn):');
    disp(TFC.CS(k).NbqijIn);
    disp('  > Boundary Queue Out (NbqijOut):');
    disp(TFC.CS(k).NbqijOut);
end
%% Set Queue Boundary state
if (t~=0)&&(~isempty(TFC.CS))&&(Settings.TFC.TCP_DBController_GC)
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
    %     disp('[DEBUG] TCP_DBControl_GC_Micro: Check MPC solution, especially Nin/Nout values.');
    %     disp('[DEBUG] TCP_DBControl_GC_Micro: Check simulation duration and values.');
end
%% Change DepartTime
if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))&&(Settings.TFC.TCP_DBController_GC)
    [TFC,ObjAircraft,SimInfo] = ApplyDepartControl(TFC,t,dtC,SimInfo,ObjAircraft);
end
% if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))&&(Settings.TFC.TCP_DBController_MPC)
%     disp(['| t=' num2str(t)])
%     disp(Settings.TFC.nci)
%     disp(TFC.CS(t/dtC).nit)
%     disp(TFC.CS(t/dtC).udidt)
%     disp('[DEBUG] TFC.CS.ubijdt');
%     disp('[WARN] TCP_DBControl_GC_Micro: ADD IN OUT CONCEPT!');
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
%% Greedy Control Logic Functions
function [TFC] = DetermineUdi(TFC, k, nit, nci, udimax, udimin)
% Determines the departure control input (udi) for each region.
% If a region's accumulation (nit) is at or above its critical density (nci),
% the departure control is set to udimin (0) to restrict new entries.
udidt = ones(1, size(nit, 2)) * udimax;
udidt(nit >= nci) = udimin;
TFC.CS(k).udidt = udidt;
end

function [TFC] = DetermineUbij(TFC, k, nit, nci, ubijmax, ubijmin)
% Determines the boundary control input (ubij) between regions.
% If a destination region 'j' is congested, transfers from any region 'i' to 'j' are restricted.
ubijdt = ones(size(nit, 2), size(nit, 2)) * ubijmax;
ubijdt(:, nit >= nci) = ubijmin; % Restrict flow into congested regions
ubijdt(1:size(ubijdt, 1)+1:end) = 1; % Allow internal flow within a region
TFC.CS(k).ubijdt = ubijdt;
end

function [TFC] = DetermineBoundaryQueueFlow(TFC, SimInfo, ObjAircraft, Settings, k)
% Determines the number of aircraft to hold (NbqijIn) and release (NbqijOut).

num_regions = numel(TFC.CS(k).ri);
NbqijIn = zeros(num_regions, num_regions);
NbqijOut = zeros(num_regions, num_regions);
dtbqc = zeros(num_regions, num_regions);

ubijdt = TFC.CS(k).ubijdt;
ri_indices = TFC.CS(k).ri;

% Calculate NbqijIn (aircraft to hold)
for aa = 1:length(SimInfo.Mact)
    aircraft_id = SimInfo.Mact(aa);
    if ObjAircraft(aircraft_id).status == 1 % Is flying
        current_ri = ObjAircraft(aircraft_id).rit;
        next_ri = ObjAircraft(aircraft_id).nextrit;

        if current_ri > 0 && next_ri > 0 && current_ri ~= next_ri
            idx_i = find(ri_indices == current_ri, 1);
            idx_j = find(ri_indices == next_ri, 1);

            if ~isempty(idx_i) && ~isempty(idx_j) && ubijdt(idx_i, idx_j) == 0
                % Aircraft is approaching a congested boundary, so increment the count to hold it.
                NbqijIn(idx_i, idx_j) = NbqijIn(idx_i, idx_j) + 1;
            end
        end
    end
end

% Calculate NbqijOut (aircraft to release)
for i = 1:num_regions
    for j = 1:num_regions
        if i ~= j && ubijdt(i, j) == 1 % If transfer is allowed
            % Release aircraft based on destination region's production rate
            G_j = Settings.TFC.Ri(j).funGn(TFC.CS(k).nit(j));
            NbqijOut(i, j) = floor(G_j * Settings.TFC.dtC); % Release up to what can be handled in the next step
        end
    end
end

TFC.CS(k).NbqijIn = NbqijIn;
TFC.CS(k).NbqijOut = NbqijOut;
TFC.CS(k).dtbqc = dtbqc; % Set holding time (can be refined later)
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
                        [~,tempRi1] = max(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri));
                        zWP1 = Settings.Airspace.Regions.B(tempRi1).center(3)+(Settings.Airspace.Regions.B(tempRi1).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        % zWP1 = Settings.Airspace.dz2-ObjAircraft(SimInfo.Mact(aaiSP)).ra;
                        newWPdown = [ObjAircraft(SimInfo.Mact(aaiSP)).pt(1:2),zWP1]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aaiSP)).wp = [ObjAircraft(SimInfo.Mact(aaiSP)).wp(1:ObjAircraft(SimInfo.Mact(aaiSP)).wpCR,:);newWPdown;ObjAircraft(SimInfo.Mact(aaiSP)).wp(ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+1:end,:)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).wpTR = ObjAircraft(SimInfo.Mact(aaiSP)).wpTR + 1;
                        %                 zWP2 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        [~,tempRi2] = max(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri));
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
                        [~,tempRi1] = max(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri));
                        zWP1 = Settings.Airspace.Regions.B(tempRi1).center(3)+(Settings.Airspace.Regions.B(tempRi1).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        % zWP1 = Settings.Airspace.dz2-ObjAircraft(SimInfo.Mact(aaiSP)).ra;
                        newWPdown = [ObjAircraft(SimInfo.Mact(aaiSP)).pt(1:2),zWP1]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aaiSP)).wp = [ObjAircraft(SimInfo.Mact(aaiSP)).wp(1:ObjAircraft(SimInfo.Mact(aaiSP)).wpCR,:);newWPdown;ObjAircraft(SimInfo.Mact(aaiSP)).wp(ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+1:end,:)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).wpTR = ObjAircraft(SimInfo.Mact(aaiSP)).wpTR + 1;
                        %                 zWP2 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        [~,tempRi2] = max(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri));
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
                        [~,tempRi1] = max(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri));
                        zWP1 = Settings.Airspace.Regions.B(tempRi1).center(3)+(Settings.Airspace.Regions.B(tempRi1).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        % zWP1 = Settings.Airspace.dz2-ObjAircraft(SimInfo.Mact(aaiSP)).ra;
                        newWPdown = [ObjAircraft(SimInfo.Mact(aaiSP)).pt(1:2),zWP1]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aaiSP)).wp = [ObjAircraft(SimInfo.Mact(aaiSP)).wp(1:ObjAircraft(SimInfo.Mact(aaiSP)).wpCR,:);newWPdown;ObjAircraft(SimInfo.Mact(aaiSP)).wp(ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+1:end,:)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).wpTR = ObjAircraft(SimInfo.Mact(aaiSP)).wpTR + 1;
                        %                 zWP2 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        [~,tempRi2] = max(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri));
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
                        [~,tempRi1] = max(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri));
                        zWP1 = Settings.Airspace.Regions.B(tempRi1).center(3)+(Settings.Airspace.Regions.B(tempRi1).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        % zWP1 = Settings.Airspace.dz2-ObjAircraft(SimInfo.Mact(aaiSP)).ra;
                        newWPdown = [ObjAircraft(SimInfo.Mact(aaiSP)).pt(1:2),zWP1]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aaiSP)).wp = [ObjAircraft(SimInfo.Mact(aaiSP)).wp(1:ObjAircraft(SimInfo.Mact(aaiSP)).wpCR,:);newWPdown;ObjAircraft(SimInfo.Mact(aaiSP)).wp(ObjAircraft(SimInfo.Mact(aaiSP)).wpCR+1:end,:)];
                        ObjAircraft(SimInfo.Mact(aaiSP)).wpTR = ObjAircraft(SimInfo.Mact(aaiSP)).wpTR + 1;
                        %                 zWP2 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        [~,tempRi2] = max(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri));
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
                        zWP1 = Settings.Airspace.Regions.B(tempRi1).center(3)+(Settings.Airspace.Regions.B(tempRi1).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).ra;
                        % zWP1 = Settings.Airspace.dz2-ObjAircraft(SimInfo.Mact(aai)).ra;
                        newWPdown = [ObjAircraft(SimInfo.Mact(aai)).pt(1:2),zWP1]; % fptrd fpt pt
                        ObjAircraft(SimInfo.Mact(aai)).wp = [ObjAircraft(SimInfo.Mact(aai)).wp(1:ObjAircraft(SimInfo.Mact(aai)).wpCR,:);newWPdown;ObjAircraft(SimInfo.Mact(aai)).wp(ObjAircraft(SimInfo.Mact(aai)).wpCR+1:end,:)];
                        ObjAircraft(SimInfo.Mact(aai)).wpTR = ObjAircraft(SimInfo.Mact(aai)).wpTR + 1;
                        %                 zWP2 = Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        [~,tempRi2] = max(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri));
                        zWP2 = Settings.Airspace.Regions.B(tempRi2).center(3);%-(Settings.Airspace.Regions.B(CurrentRegion==cat(1,Settings.Airspace.Regions.B.ri)).ssize(3)/2)+ObjAircraft(SimInfo.Mact(aai)).rs;
                        % zWP2 = Settings.Airspace.dz1+ObjAircraft(SimInfo.Mact(aai)).ra;
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
