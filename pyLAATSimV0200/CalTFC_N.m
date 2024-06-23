function [TFC] = CalTFC_N(TFC,SimInfo,ObjAircraft,Settings)
%%
dtS = SimInfo.dtS;
dtM = SimInfo.dtM;
t = SimInfo.t;
Airspace = Settings.Airspace;
%% MFD data anaylsis
tk0 = ((t-dtM)/dtM)*(dtM/dtS)+1;
tk1 = (t/dtM)*(dtM/dtS)+1;
tdt = [(tk0-1)*dtS:dtS:(tk1-1)*dtS]';
%%
% Check who was active in the last time period
StatusActivedt = double(SimInfo.statusdt(tk0:tk1,:)==1);
ActiveAircraft = unique([1:size(SimInfo.statusdt,2)].*(StatusActivedt))';
ActiveAircraft(ActiveAircraft==0) = [];
Status_Current_ActiveAircraftdt = StatusActivedt(:,ActiveAircraft);
pdt_Current_ActiveAircraftdt = SimInfo.pdt(tk0:tk1,reshape([3*ActiveAircraft(:)-2,3*ActiveAircraft(:)-1,3*ActiveAircraft(:)]',[],1)');
%% Check who is queued in departure
StatusDepQueueddt = double(SimInfo.statusdt(tk0:tk1,:)==10);
DepQueueAircraft = unique([1:size(SimInfo.statusdt,2)].*(StatusDepQueueddt))';
DepQueueAircraft(DepQueueAircraft==0) = [];
Status_Current_DepQueueAircraftdt = StatusDepQueueddt(:,DepQueueAircraft);
% clear StatusDepQueueddt
ndqT = size(DepQueueAircraft,2); % total queued aircraf in this time period
ndq = sum(Status_Current_DepQueueAircraftdt(end,:)); % Accumulation
CurDepartureDelayTimeAircraft = cat(1,ObjAircraft(DepQueueAircraft).Curdd);
time_Change_DQAircraftdt = [tdt(1:end)].*[zeros(1,size(Status_Current_DepQueueAircraftdt,2));diff(Status_Current_DepQueueAircraftdt)];
DQEnterAircraft = [max(time_Change_DQAircraftdt,[],1)'];
DQEnterAircraft = max(t-dtM+dtS,DQEnterAircraft);
DQExitAircraft = [-min(time_Change_DQAircraftdt,[],1)'];
DQExitAircraft(DQExitAircraft==0) = Inf;
DQExitAircraft = min((t+dtS).*ones(size(DQEnterAircraft)),DQExitAircraft);
DQTimeAircraft = DQExitAircraft-DQEnterAircraft;
TFC.N.TDQT(t/dtM) = sum(DQTimeAircraft);
%% Check who is queued in boundary
StatusBouQueueddt = double(SimInfo.statusdt(tk0:tk1,:)==11);
BouQueueAircraft = unique([1:size(SimInfo.statusdt,2)].*(StatusBouQueueddt))';
BouQueueAircraft(BouQueueAircraft==0) = [];
Status_Current_BouQueueAircraftdt = StatusBouQueueddt(:,BouQueueAircraft);
% clear StatusBouQueueddt
nbqT = size(BouQueueAircraft,2);
nbq = sum(Status_Current_BouQueueAircraftdt(end,:));
BoundaryDelayTimeAircraft = cat(1,ObjAircraft(BouQueueAircraft).CurHoveringTime);
time_Change_BQAircraftdt = [tdt(1:end)].*[zeros(1,size(Status_Current_BouQueueAircraftdt,2));diff(Status_Current_BouQueueAircraftdt)];
BQEnterAircraft = [max(time_Change_BQAircraftdt,[],1)'];
BQEnterAircraft = max(t-dtM+dtS,BQEnterAircraft);
BQExitAircraft = [-min(time_Change_BQAircraftdt,[],1)'];
BQExitAircraft(BQExitAircraft==0) = Inf;
BQExitAircraft = min((t+dtS).*ones(size(BQEnterAircraft)),BQExitAircraft);
BQTimeAircraft = BQExitAircraft-BQEnterAircraft;
TFC.N.TBQT(t/dtM) = sum(BQTimeAircraft);
%%
nT = size(ActiveAircraft,2); % total aircraf in this time period
n = sum(Status_Current_ActiveAircraftdt(end,:)); % Accumulation
nexit = nT-n;
%%
time_Change_ActiveAircraftdt = [tdt(1:end)].*[zeros(1,size(Status_Current_ActiveAircraftdt,2));diff(Status_Current_ActiveAircraftdt)];
EnterAircraft = [max(time_Change_ActiveAircraftdt,[],1)'];
EnterAircraft = max(t-dtM+dtS,EnterAircraft);
ExitAircraft = [-min(time_Change_ActiveAircraftdt,[],1)'];
ExitAircraft(ExitAircraft==0) = Inf;
ExitAircraft = min((t+dtS).*ones(size(EnterAircraft)),ExitAircraft);
%% Check each UAV TT TD Nexit
% Travel time
TravelTimeAircraft = ExitAircraft-EnterAircraft;
WaitingTimeAircraft = cat(1,ObjAircraft(ActiveAircraft).Safdd);
QueueAircraft = [WaitingTimeAircraft>0]';
% Travel Distance
diffdxyz = repelem(Status_Current_ActiveAircraftdt,1,3).*[zeros(1,size(pdt_Current_ActiveAircraftdt,2));diff(pdt_Current_ActiveAircraftdt)];
TravelDistanceAircraft =  vecnorm(reshape(sum(diffdxyz),3,[]));
% Speed Aircraft
AverageSpeedAircraft = TravelDistanceAircraft./TravelTimeAircraft';
% Which aircraft exitted
NexitAircraft =  [ExitAircraft~=(t+dtS)]';
% Cleanning Double or Short Trip.
    ExcCond = and((TravelDistanceAircraft<=4*cat(1,ObjAircraft(ActiveAircraft).ra)'),or((TravelTimeAircraft<5)',(AverageSpeedAircraft<5)));
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
% Travel time - Calculate statsitics
TFC.N.TTT(t/dtM) = sum(TravelTimeAircraft);
TFC.N.sta.ATT(t/dtM) = sum(TravelTimeAircraft)/nT;
TFC.N.sta.StdTTT(t/dtM) = std(TravelTimeAircraft);
TFC.N.sta.VarTTT(t/dtM) = var(TravelTimeAircraft);
TFC.N.sta.MeanTTT(t/dtM) = mean(TravelTimeAircraft);
TFC.N.sta.MedianTTT(t/dtM) = median(TravelTimeAircraft);
TFC.N.sta.ModeTTT(t/dtM) = mode(TravelTimeAircraft);
% Travel distance - Calculate statsitics
TFC.N.TTD(t/dtM) = sum(TravelDistanceAircraft);
TFC.N.sta.ATD(t/dtM) = sum(TravelDistanceAircraft)/nT;
TFC.N.sta.StdTTD(t/dtM) = std(TravelDistanceAircraft);
TFC.N.sta.VarTTD(t/dtM) = var(TravelDistanceAircraft);
TFC.N.sta.MeanTTD(t/dtM) = mean(TravelDistanceAircraft);
TFC.N.sta.MedianTTD(t/dtM) = median(TravelDistanceAircraft);
TFC.N.sta.ModeTTD(t/dtM) = mode(TravelDistanceAircraft);
% Trip length - Calculate statsitics
TFC.N.TL(t/dtM) = sum(TripLengthAircraft);
TFC.N.ATL(t/dtM) = sum(TripLengthAircraft)/nexit;
TFC.N.sta.StdTL(t/dtM) = std(TripLengthAircraft);
TFC.N.sta.VarTL(t/dtM) = var(TripLengthAircraft);
TFC.N.sta.MeanTL(t/dtM) = mean(TripLengthAircraft);
TFC.N.sta.MedianTL(t/dtM) = median(TripLengthAircraft);
TFC.N.sta.ModeTL(t/dtM) = mode(TripLengthAircraft);
% Average Speed - Calculate statsitics

TFC.N.V(t/dtM) = TFC.N.TTD(t/dtM)/TFC.N.TTT(t/dtM);
TFC.N.sta.AS(t/dtM) = sum(AverageSpeedAircraft)/nT;
TFC.N.sta.StdAS(t/dtM) = std(AverageSpeedAircraft);
TFC.N.sta.VarAS(t/dtM) = var(AverageSpeedAircraft);
TFC.N.sta.MeanAS(t/dtM) = mean(AverageSpeedAircraft);
TFC.N.sta.MedianAS(t/dtM) = median(AverageSpeedAircraft);
TFC.N.sta.ModeAS(t/dtM) = mode(AverageSpeedAircraft);
% Density - Calculate statsitics
TFC.N.K(t/dtM) = TFC.N.TTT(t/dtM)/(dtM*Airspace.Space);
% Flow - Calculate statsitics
TFC.N.Q(t/dtM) = TFC.N.TTD(t/dtM)/(dtM*Airspace.Space);
% number of aircrafts
TFC.N.n(t/dtM) = n;
TFC.N.nT(t/dtM) = nT;
TFC.N.nexit(t/dtM) = nexit;
TFC.N.nsqT(t/dtM) = sum(QueueAircraft);
TFC.N.ndqT(t/dtM) = ndqT; % Including safety queues.
TFC.N.ndq(t/dtM) = ndq; % Including safety queues.
TFC.N.nbqT(t/dtM) = nbqT;
TFC.N.nbq(t/dtM) = nbq;
% outflow - Calculate statsitics
TFC.N.G(t/dtM) = nexit/dtM;
% % total time spent
TFC.N.TWT(t/dtM) = sum(WaitingTimeAircraft);
TFC.N.TDDT(t/dtM) = sum(CurDepartureDelayTimeAircraft);
TFC.N.TBDT(t/dtM) = sum(BoundaryDelayTimeAircraft);
TFC.N.TTS_Old(t/dtM) = TFC.N.TTT(t/dtM) + TFC.N.TDDT(t/dtM) + TFC.N.TBDT(t/dtM) + TFC.N.TWT(t/dtM);
TFC.N.TTS(t/dtM) = TFC.N.TTT(t/dtM) + TFC.N.TDQT(t/dtM) + TFC.N.TBQT(t/dtM);
TFC.N.cumTTS = cumsum(TFC.N.TTS);
% Production
TFC.N.Pn(t/dtM) = TFC.N.G(t/dtM)*TFC.N.ATL(t/dtM);
TFC.N.Ps(t/dtM) = TFC.N.TTD(t/dtM)/(dtM);
% ========================================================================
% Energy
TFC.EC.N.ECt(t/dtM) = sum(TFC.EC.sumECtdt(tk0:tk1));
TFC.EC.N.ECq(t/dtM) = sum(TFC.EC.sumECqdt(tk0:tk1));
TFC.EC.N.ECdq(t/dtM) = sum(TFC.EC.ECdt(tk0:tk1,:).*StatusDepQueueddt,'all');
TFC.EC.N.ECbq(t/dtM) = sum(TFC.EC.ECdt(tk0:tk1,:).*StatusBouQueueddt,'all');
TFC.EC.N.EC(t/dtM) = sum(TFC.EC.sumECdt(tk0:tk1));
TFC.EC.N.ECt_TTD(t/dtM) = TFC.EC.N.ECt(t/dtM)/TFC.N.TTD(t/dtM);
TFC.EC.N.ECt_TTT(t/dtM) = TFC.EC.N.ECt(t/dtM)/TFC.N.TTT(t/dtM);
TFC.EC.N.ECt_N(t/dtM) = TFC.EC.N.ECt(t/dtM)./TFC.N.n(t/dtM);
TFC.EC.N.ECt_G(t/dtM) = TFC.EC.N.ECt(t/dtM)./TFC.N.G(t/dtM);
clear StatusDepQueueddt StatusBouQueueddt
% TFC.EC.N.ECq(t/dtM) = sum(TFC.EC.ECdt(tk0:tk1,DepQueueAircraft),'all');
% TFC.EC.N.EC(t/dtM) = sum(TFC.EC.ECdt(tk0:tk1,ActiveAircraft),'all');
% [TFC.EC.EC_Std,TFC.EC.EC_Mean,TFC.EC.EC_Var] = CalStd(TFC.EC.ECdt,dtM,dtS);
% TFC.EC.N.EC_Std(t/dtM) = TFC.EC.N.EC_Std(ts:te);
% TFC.EC.N.EC_Mean(t/dtM) = TFC.EC.N.EC_Mean(ts:te);
% TFC.EC.N.EC_Var(t/dtM) = TFC.EC.N.EC_Var(ts:te);
% ========================================================================
% MIS
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
%         TFC.N.Delay =  UAVDelay;
%         TFC.N.MeanDelay =  mean(UAVDelay);
%         TFC.N.StdDelay =  std(UAVDelay);
%         TFC.N.TotalDelay =  sum(UAVDelay);
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

