function [TFC] = CalTFC_Ri(TFC,SimInfo,ObjAircraft,Settings)
%%
dtS = SimInfo.dtS;
dtM = SimInfo.dtM;
t = SimInfo.t;
Airspace = Settings.Airspace;
%% MFD data anaylsis
tk0 = ((t-dtM)/dtM)*(dtM/dtS)+1;
tk1 = (t/dtM)*(dtM/dtS)+1;
tdt = [(tk0-1)*dtS:dtS:(tk1-1)*dtS]';
Ri = cat(1,Airspace.Regions.B.ri);
%% Status Matrices
% Check who was active in the last time period
StatusActivedt = double(SimInfo.statusdt(tk0:tk1,:)==1);
ActiveAircraft = unique([1:size(SimInfo.statusdt,2)].*(StatusActivedt))';
ActiveAircraft(ActiveAircraft==0) = [];
RegionActivedt = StatusActivedt.*SimInfo.ridt(tk0:tk1,:);
clear StatusActivedt
% Check who was inactive in the last time period
StatusInActivedt = double(SimInfo.statusdt(tk0:tk1,:)==0);
InActiveAircraft = unique([1:size(SimInfo.statusdt,2)].*(StatusInActivedt))';
InActiveAircraft(InActiveAircraft==0) = [];
RegionInActivedt = StatusInActivedt.*SimInfo.ridt(tk0:tk1,:);
clear StatusInActivedt
% Check who is queued in departure
StatusDepQueueddt = double(SimInfo.statusdt(tk0:tk1,:)==10);
DepQueueAircraft = unique([1:size(SimInfo.statusdt,2)].*(StatusDepQueueddt))';
DepQueueAircraft(DepQueueAircraft==0) = [];
RegionDepQueuedt = StatusDepQueueddt.*SimInfo.ridt(tk0:tk1,:);
clear StatusDepQueueddt
% Check who is queued in boundary
StatusBouQueueddt = double(SimInfo.statusdt(tk0:tk1,:)==11);
BouQueueAircraft = unique([1:size(SimInfo.statusdt,2)].*(StatusBouQueueddt))';
BouQueueAircraft(BouQueueAircraft==0) = [];
RegionBouQueuedt = StatusBouQueueddt.*SimInfo.ridt(tk0:tk1,:);
clear StatusBouQueueddt
%%
% i = 1;
uniRi = unique(Ri);
for i=1:size(uniRi,1)
    TFC.Ri(i).ri = uniRi(i);
    Current_RiActiveAircraftdt = double(RegionActivedt == uniRi(i));
    ActiveAircraftRi = unique([1:size(SimInfo.statusdt,2)].*Current_RiActiveAircraftdt)';
    ActiveAircraftRi(ActiveAircraftRi==0) = [];
    Status_Current_RiActiveAircraftdt = Current_RiActiveAircraftdt(:,ActiveAircraftRi);
    pdt_Current_ActiveAircraftdt = SimInfo.pdt(tk0:tk1,reshape([3*ActiveAircraftRi(:)-2,3*ActiveAircraftRi(:)-1,3*ActiveAircraftRi(:)]',[],1)');
    %%
    nT = size(ActiveAircraftRi,2);
    n = sum(Status_Current_RiActiveAircraftdt(end,:));
    nexit = nT-n;
    %% nij matrix accumulation according to regions
    [Risortted, Riorder] = sort(uniRi);
    ActiveAircraftRitk = ActiveAircraftRi(Status_Current_RiActiveAircraftdt(end,:)==1);
    % Calculate noi
    ActiveAircraftRiriotk = cat(1,ObjAircraft(ActiveAircraftRitk).rio);
    ActiveAircraftRiriocountstk = hist(ActiveAircraftRiriotk,Risortted);
    noi(Riorder) = ActiveAircraftRiriocountstk;
    % Calculate noiT
    ActiveAircraftRirio = cat(1,ObjAircraft(ActiveAircraftRi).rio);
    ActiveAircraftRiriocounts = hist(ActiveAircraftRirio,Risortted);
    noiT(Riorder) = ActiveAircraftRiriocounts;
    % Calculate nid
    ActiveAircraftRiridtk = cat(1,ObjAircraft(ActiveAircraftRitk).rid);
    ActiveAircraftRiridcountstk = hist(ActiveAircraftRiridtk,Risortted);
    nid(Riorder) = ActiveAircraftRiridcountstk;
    % Calculate nidT
    ActiveAircraftRirid = cat(1,ObjAircraft(ActiveAircraftRi).rid);
    ActiveAircraftRiridcounts = hist(ActiveAircraftRirid,Risortted);
    nidT(Riorder) = ActiveAircraftRiridcounts;
    % Calculate nih
    ActiveAircraftRirihtk = cat(1,ObjAircraft(ActiveAircraftRitk).nextrit);
    ActiveAircraftRirihcountstk = hist(ActiveAircraftRirihtk,Risortted);
    nih(Riorder) = ActiveAircraftRirihcountstk;
    % Calculate nihT
    ActiveAircraftRirih = cat(1,ObjAircraft(ActiveAircraftRi).nextrit);
    ActiveAircraftRirihcounts = hist(ActiveAircraftRirih,Risortted);
    nihT(Riorder) = ActiveAircraftRirihcounts;
    %% Calculate Aircraft Enterance and Exitted Times.
    time_Change_RiActiveAircraftdt = [tdt(1:end)].*[zeros(1,size(Status_Current_RiActiveAircraftdt,2));diff(Status_Current_RiActiveAircraftdt)];
    EnterAircraftRi = [max(time_Change_RiActiveAircraftdt,[],1)'];
    EnterAircraftRi = max(t-dtM+dtS,EnterAircraftRi);
    ExitAircraftRi = [-min(time_Change_RiActiveAircraftdt,[],1)'];
    ExitAircraftRi(ExitAircraftRi==0) = Inf;
    ExitAircraftRi = min((t+dtS).*ones(size(EnterAircraftRi)),ExitAircraftRi);
    %% Check each Aircraft Travel Time Travel Distance Trip Length and Number of aircraft exitted
    TravelTimeAircraft = ExitAircraftRi-EnterAircraftRi;
    WaitingTimeAircraft = cat(1,ObjAircraft(ActiveAircraftRi(cat(1,ObjAircraft(ActiveAircraftRi).rio)==uniRi(i))).Safdd);
    diffdxyz = repelem(Status_Current_RiActiveAircraftdt,1,3).*[zeros(1,size(pdt_Current_ActiveAircraftdt,2));diff(pdt_Current_ActiveAircraftdt)];
    TravelDistanceAircraft =  vecnorm(reshape(sum(diffdxyz),3,[]));
    AverageSpeedAircraft = TravelDistanceAircraft./TravelTimeAircraft';
    NexitAircraft =  [ExitAircraftRi~=(t+dtS)]';
    % Cleanning Double or Short Trip.
    ExcCond = and((TravelDistanceAircraft<=4*cat(1,ObjAircraft(ActiveAircraftRi).ra)'),or((TravelTimeAircraft<5)',(AverageSpeedAircraft<5)));
    if any(ExcCond)
        ExcludedAircraft = ExcCond;
        NexitAircraft(ExcludedAircraft) = 0;
        %TravelTimeAircraft(ExcludedAircraft) = 0;
        TravelDistanceAircraft(ExcludedAircraft) = 0;
        AverageSpeedAircraft(ExcludedAircraft) = 0;
    else
        ExcludedAircraft = zeros(size(AverageSpeedAircraft));
    end
    %if (sum(NexitAircraft)~=nexit); warning('detected short trip'); end
    TripLengthAircraft = TravelDistanceAircraft(NexitAircraft);
    %% Departure Queue in region
    Current_RiDepQueueAircraftdt = double(RegionDepQueuedt == uniRi(i));
    DepQueueAircraftRi = unique([1:size(SimInfo.statusdt,2)].*Current_RiDepQueueAircraftdt)';
    DepQueueAircraftRi(DepQueueAircraftRi==0) = [];
    Status_Current_RiDepQueueAircraftdt = Current_RiDepQueueAircraftdt(:,DepQueueAircraftRi);
    ndqT = size(DepQueueAircraftRi,2);
    ndq = sum(Status_Current_RiDepQueueAircraftdt(end,:));
    DepartureDelayTimeAircraft = cat(1,ObjAircraft(DepQueueAircraftRi).dd);
    CurDepartureDelayTimeAircraft = cat(1,ObjAircraft(DepQueueAircraftRi(cat(1,ObjAircraft(DepQueueAircraftRi).rio)==uniRi(i))).Curdd);
    % Calculate delay time according to status
    time_Change_DQAircraftdt = [tdt(1:end)].*[zeros(1,size(Status_Current_RiDepQueueAircraftdt,2));diff(Status_Current_RiDepQueueAircraftdt)];
    DQEnterAircraft = [max(time_Change_DQAircraftdt,[],1)'];
    DQEnterAircraft = max(t-dtM+dtS,DQEnterAircraft);
    DQExitAircraft = [-min(time_Change_DQAircraftdt,[],1)'];
    DQExitAircraft(DQExitAircraft==0) = Inf;
    DQExitAircraft = min((t+dtS).*ones(size(DQEnterAircraft)),DQExitAircraft);
    DQTimeAircraft = DQExitAircraft-DQEnterAircraft;
    TFC.Ri(i).TDQT(t/dtM) = sum(DQTimeAircraft);
    %% Boundary Queue in region
    % TODO: Double check neighboring and values.
    Current_RiBouQueueAircraftdt = double(RegionBouQueuedt == uniRi(i));
    BouQueueAircraftRi = unique([1:size(SimInfo.statusdt,2)].*Current_RiBouQueueAircraftdt)';
    BouQueueAircraftRi(BouQueueAircraftRi==0) = [];
    Status_Current_RiBouQueueAircraftdt = Current_RiBouQueueAircraftdt(:,BouQueueAircraftRi);
    nbqiT = size(BouQueueAircraftRi,2);
    nbqi = sum(Status_Current_RiBouQueueAircraftdt(end,:));
    if ~(isempty(BouQueueAircraftRi))
        Test =1 ;
    end
    % Calculate nbqihT
    StopBoundaries = cat(1,ObjAircraft(BouQueueAircraftRi).LastStopBoundary);
    if ~(isempty(StopBoundaries))
        BouQueueAircraftRirih = StopBoundaries(StopBoundaries(:,1) == uniRi(i),2);
    else
        BouQueueAircraftRirih = [];
    end
    BouQueueAircraftRirihcounts = hist(BouQueueAircraftRirih,Risortted);
    nbqihT(Riorder) = BouQueueAircraftRirihcounts;
    % Calculate nbqih
    BouQueueAircraftRitk = BouQueueAircraftRi(Status_Current_RiBouQueueAircraftdt(end,:)==1);
    StopBoundariestk = cat(1,ObjAircraft(BouQueueAircraftRitk).LastStopBoundary);
    if ~(isempty(StopBoundariestk))
        BouQueueAircraftRirihtk = StopBoundariestk(StopBoundariestk(:,1) == uniRi(i),2);
    else
        BouQueueAircraftRirihtk = [];
    end
    BouQueueAircraftRirihcountstk = hist(BouQueueAircraftRirihtk,Risortted);
    nbqih(Riorder) = BouQueueAircraftRirihcountstk;
    % Delays
    if ~(isempty(StopBoundaries))
        BoundaryDelayTimeAircraft = cat(1,ObjAircraft(BouQueueAircraftRi(StopBoundaries(:,1) == uniRi(i))).CurHoveringTime);
    else
        BoundaryDelayTimeAircraft = cat(1,ObjAircraft(BouQueueAircraftRi).CurHoveringTime);
    end
    % Calculate delay time according to status
    time_Change_BQAircraftdt = [tdt(1:end)].*[zeros(1,size(Status_Current_RiBouQueueAircraftdt,2));diff(Status_Current_RiBouQueueAircraftdt)];
    BQEnterAircraft = [max(time_Change_BQAircraftdt,[],1)'];
    BQEnterAircraft = max(t-dtM+dtS,BQEnterAircraft);
    BQExitAircraft = [-min(time_Change_BQAircraftdt,[],1)'];
    BQExitAircraft(BQExitAircraft==0) = Inf;
    BQExitAircraft = min((t+dtS).*ones(size(BQEnterAircraft)),BQExitAircraft);
    BQTimeAircraft = BQExitAircraft-BQEnterAircraft;
    TFC.Ri(i).TBQT(t/dtM) = sum(BQTimeAircraft);
    %% dij matrix demand according to regions
    Current_RiInActiveAircraftdt = double(RegionInActivedt == uniRi(i));
    InActiveAircraftRi = unique([1:size(SimInfo.statusdt,2)].*Current_RiInActiveAircraftdt)';
    InActiveAircraftRi(InActiveAircraftRi==0) = [];
    dij_InActiveAircraftRi = InActiveAircraftRi(all([( (t+dtS) < (cat(1,ObjAircraft(InActiveAircraftRi).tda)) ) , ( (cat(1,ObjAircraft(InActiveAircraftRi).tda)) < (t+dtM+dtS) )],2));
    di = size(dij_InActiveAircraftRi,2);
    % Calculate qinij
    dijActiveAircraftRirid = cat(1,ObjAircraft(dij_InActiveAircraftRi).rid);
    dijActiveAircraftRiridcounts = hist(dijActiveAircraftRirid,Risortted);
    dij(Riorder) = dijActiveAircraftRiridcounts;
    %% qinij matrix inflow according to regions
    Qin_InActiveAircraftRi = InActiveAircraftRi(all([( (t+dtS) < (cat(1,ObjAircraft(InActiveAircraftRi).tdp)) ) , ( (cat(1,ObjAircraft(InActiveAircraftRi).tdp)) < (t+dtM+dtS) )],2));
    qini = size(Qin_InActiveAircraftRi,2);
    % Calculate qinij
    QInActiveAircraftRirid = cat(1,ObjAircraft(Qin_InActiveAircraftRi).rid);
    QInActiveAircraftRiridcounts = hist(QInActiveAircraftRirid,Risortted);
    qinij(Riorder) = QInActiveAircraftRiridcounts;
    %% Calculate TFC variables and insert in TFC Object
    % number of aircrafts
    TFC.Ri(i).ni(t/dtM) = n;
    TFC.Ri(i).nT(t/dtM) = nT;
    TFC.Ri(i).nexit(t/dtM) = sum(NexitAircraft);%nexit;
    TFC.Ri(i).nexcluded(t/dtM) = sum(ExcludedAircraft);
    TFC.Ri(i).ndqi(t/dtM) = ndq;
    TFC.Ri(i).ndqiT(t/dtM) = ndqT;
    TFC.Ri(i).nbqi(t/dtM) = nbqi;
    TFC.Ri(i).nbqiT(t/dtM) = nbqiT;
    TFC.Ri(i).nbqih(t/dtM,:) = nbqih;
    TFC.Ri(i).nbqihT(t/dtM,:) = nbqihT;
    % nij matrix
    TFC.Ri(i).noi(t/dtM,:) = noi;
    TFC.Ri(i).noiT(t/dtM,:) = noiT;
    TFC.Ri(i).nid(t/dtM,:) = nid;
    TFC.Ri(i).nidT(t/dtM,:) = nidT;
    TFC.Ri(i).nih(t/dtM,:) = nih;
    TFC.Ri(i).nihT(t/dtM,:) = nihT;
    % dij qij matrix
    TFC.Ri(i).di(t/dtM) = di;
    TFC.Ri(i).qini(t/dtM) = qini;
    TFC.Ri(i).dij(t/dtM,:) = dij;
    TFC.Ri(i).qinij(t/dtM,:) = qinij;
    % outflow - Calculate statsitics
    TFC.Ri(i).G(t/dtM) = nexit/dtM;
    % Travel time - Calculate statsitics
    TFC.Ri(i).TTT(t/dtM) = sum(TravelTimeAircraft);
    TFC.Ri(i).sta.ATT(t/dtM) = sum(TravelTimeAircraft)/nT;
    TFC.Ri(i).sta.StdTTT(t/dtM) = std(TravelTimeAircraft);
    TFC.Ri(i).sta.VarTTT(t/dtM) = var(TravelTimeAircraft);
    TFC.Ri(i).sta.MeanTTT(t/dtM) = mean(TravelTimeAircraft);
    TFC.Ri(i).sta.MedianTTT(t/dtM) = median(TravelTimeAircraft);
    TFC.Ri(i).sta.ModeTTT(t/dtM) = mode(TravelTimeAircraft);
    % Travel distance - Calculate statsitics
    TFC.Ri(i).TTD(t/dtM) = sum(TravelDistanceAircraft);
    TFC.Ri(i).sta.ATD(t/dtM) = sum(TravelDistanceAircraft)/nT;
    TFC.Ri(i).sta.StdTTD(t/dtM) = std(TravelDistanceAircraft);
    TFC.Ri(i).sta.VarTTD(t/dtM) = var(TravelDistanceAircraft);
    TFC.Ri(i).sta.MeanTTD(t/dtM) = mean(TravelDistanceAircraft);
    TFC.Ri(i).sta.MedianTTD(t/dtM) = median(TravelDistanceAircraft);
    TFC.Ri(i).sta.ModeTTD(t/dtM) = mode(TravelDistanceAircraft);
    % Trip length - Calculate statsitics
    TFC.Ri(i).TL(t/dtM) = sum(TripLengthAircraft);
    TFC.Ri(i).ATL(t/dtM) = sum(TripLengthAircraft)/nexit;
    TFC.Ri(i).sta.StdTL(t/dtM) = std(TripLengthAircraft);
    TFC.Ri(i).sta.VarTL(t/dtM) = var(TripLengthAircraft);
    TFC.Ri(i).sta.MeanTL(t/dtM) = mean(TripLengthAircraft);
    TFC.Ri(i).sta.MedianTL(t/dtM) = median(TripLengthAircraft);
    TFC.Ri(i).sta.ModeTL(t/dtM) = mode(TripLengthAircraft);
    % Average Speed - Calculate statsitics
    TFC.Ri(i).V(t/dtM) = TFC.Ri(i).TTD(t/dtM)/TFC.Ri(i).TTT(t/dtM);
    TFC.Ri(i).sta.AS(t/dtM) = sum(AverageSpeedAircraft)/nT;
    TFC.Ri(i).sta.StdAS(t/dtM) = std(AverageSpeedAircraft);
    TFC.Ri(i).sta.VarAS(t/dtM) = var(AverageSpeedAircraft);
    TFC.Ri(i).sta.MeanAS(t/dtM) = mean(AverageSpeedAircraft);
    TFC.Ri(i).sta.MedianAS(t/dtM) = median(AverageSpeedAircraft);
    TFC.Ri(i).sta.ModeAS(t/dtM) = mode(AverageSpeedAircraft);
    % Density - Calculate statsitics
    TFC.Ri(i).K(t/dtM) = TFC.Ri(i).TTT(t/dtM)/(dtM*Airspace.Space);
    % Flow - Calculate statsitics
    TFC.Ri(i).Q(t/dtM) = TFC.Ri(i).TTD(t/dtM)/(dtM*Airspace.Space);
    % % total time spent
    TFC.Ri(i).TWT(t/dtM) = sum(WaitingTimeAircraft);
    TFC.Ri(i).TDDT(t/dtM) = sum(CurDepartureDelayTimeAircraft);
    TFC.Ri(i).TBDT(t/dtM) = sum(BoundaryDelayTimeAircraft);
    TFC.Ri(i).TTS_Old(t/dtM) = TFC.Ri(i).TTT(t/dtM) + TFC.Ri(i).TDDT(t/dtM) + TFC.Ri(i).TBDT(t/dtM) + TFC.Ri(i).TWT(t/dtM);
    TFC.Ri(i).TTS(t/dtM) = TFC.Ri(i).TTT(t/dtM) + TFC.Ri(i).TDQT(t/dtM) + TFC.Ri(i).TBQT(t/dtM);
    TFC.Ri(i).cumTTS = cumsum(TFC.Ri(i).TTS);
    % Production
    TFC.Ri(i).Pn(t/dtM) = TFC.Ri(i).G(t/dtM)*TFC.Ri(i).ATL(t/dtM);
    TFC.Ri(i).Ps(t/dtM) = TFC.Ri(i).TTD(t/dtM)/(dtM);
    % ========================================================================
    % Energy
    TFC.EC.Ri(i).ECt(t/dtM) = sum(TFC.EC.ECdt(tk0:tk1,:).*Current_RiActiveAircraftdt,'all');
    TFC.EC.Ri(i).ECdq(t/dtM) = sum(TFC.EC.ECdt(tk0:tk1,:).*Current_RiDepQueueAircraftdt,'all');
    TFC.EC.Ri(i).ECbq(t/dtM) = sum(TFC.EC.ECdt(tk0:tk1,:).*Current_RiBouQueueAircraftdt,'all');
    TFC.EC.Ri(i).EC(t/dtM) = TFC.EC.Ri(i).ECt(t/dtM)+TFC.EC.Ri(i).ECdq(t/dtM)+TFC.EC.Ri(i).ECbq(t/dtM);
    TFC.EC.Ri(i).ECt_TTD(t/dtM) = TFC.EC.Ri(i).ECt(t/dtM)/TFC.Ri(i).TTD(t/dtM);
    TFC.EC.Ri(i).ECt_TTT(t/dtM) = TFC.EC.Ri(i).ECt(t/dtM)/TFC.Ri(i).TTT(t/dtM);
    TFC.EC.Ri(i).ECt_N(t/dtM) = TFC.EC.Ri(i).ECt(t/dtM)./TFC.Ri(i).ni(t/dtM);
    TFC.EC.Ri(i).ECt_G(t/dtM) = TFC.EC.Ri(i).ECt(t/dtM)./TFC.Ri(i).G(t/dtM);
    %% Calculate lij(t)
    %% Calculate m_ij
    %% Calculate n_ihj^q
    %% Calculate o_ihj, o_ii
    %% Calculate theta_ihj, alpha_ii
    %% Calculate o_ihj^q, o_ih^q
    %% Calculate n_ihj^q, n_ih^q
end
%             if (TravelDistanceUAV(mm)<=4*UavTeam.Uav(UAVFlyingNdtUnique(mm)).ra)&&((TravelTimeUAV(mm))<5 || ((TravelDistanceUAV(mm)/TravelTimeUAV(mm))<5))
%                 NexitUAV(mm) = 0;
%                 TravelDistanceUAV(mm) = 0;
%                 %UAVnotincluded(ii) = UAVnotincluded(ii) + 1;
%             end
% %     end
%     if (tf == dtSim*Tsf)
%         %% Planned travel time
%         UAVTravelTimePlanned = zeros(M,1);
%         UAVTravelTime = zeros(M,1);
%         UAVDelay = zeros(M,1);
%         for ii=1:M
%             UAVTravelTimePlanned(ii) = norm(UavTeam.Uav(ii).HomePos - UavTeam.Uav(ii).DesPos)/UavTeam.Uav(ii).vmax;
%             UAVTravelTime(ii) = UavTeam.Uav(ii).ArriveTime - UavTeam.Uav(ii).DepartTimePlanned + dtSim;
%             UAVDelay(ii) = UAVTravelTime(ii)-UAVTravelTimePlanned(ii);
%         end
%         clear ii
%         TFC.Ri(i).Delay =  UAVDelay;
%         TFC.Ri(i).MeanDelay =  mean(UAVDelay);
%         TFC.Ri(i).StdDelay =  std(UAVDelay);
%         TFC.Ri(i).TotalDelay =  sum(UAVDelay);
%     end
% end
% if (tf == dtSim*Tsf)
%     global SimOutputDirStr
%     SimOutputMFDDirStr = [SimOutputDirStr 'Regions\'];
%     if ~exist(SimOutputMFDDirStr, 'dir')
%         mkdir(SimOutputMFDDirStr)
%     end
%     save([SimOutputMFDDirStr 'MFD_M' num2str(M) '_Network'],'-v7.3');
% end
end

