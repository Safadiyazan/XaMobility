function [] = RunLAATSim_Ped(InflowRate,SceStr)
%%
clc; close all; dbstop if error;
close all force; close all hidden;
fwaitbar = waitbar(0,'Starting Simulation');
SimInfo.RT.TCP_PostRunningTime = [];
SimInfo.RT.TFCRunningTime = [];
SimInfo.RT.SimStartTime = datetime;
disp(['Simuation started: Time=' datestr(SimInfo.RT.SimStartTime,'yyyy-mm-dd HH:MM:SS.FFF')])
SimFilename = ['_Qin' sprintf('%0.0f',InflowRate*10) SceStr];
SimInfo.SimOutputDirStr = ['.\Outputs\SimOutput_' datestr(now,'yyyymmdd_hhMMss') SimFilename '\'];
if ~exist(SimInfo.SimOutputDirStr, 'dir')
    mkdir(SimInfo.SimOutputDirStr)
end
%% Settings
waitbar(0,fwaitbar,'Determining Setting');
[Settings.Airspace] = SettingAirspace(150,150,0); % 20*60*30/3.6,20*60*30/3.6
Settings.Airspace.as = 0;
[Settings.Ped] = SettingPed([0.5,1.5],[1,3]);
[Settings.Sim] = SettingSimulation(InflowRate,60);
% [Settings.TFC] = SettingTrafficControl(Settings);
%% Init Objects
SimInfo.Mina = []; SimInfo.Mque = []; SimInfo.Mact = []; SimInfo.Marr = []; SimInfo.MactBQ = [];
SimInfo.M = 1:1:Settings.Sim.M; SimInfo.cc = 0;
dtS = Settings.Sim.dtsim; dtM = Settings.Sim.dtMFD; dtC = Settings.Sim.dtMFD; tf = Settings.Sim.tf;
SimInfo.dtS = dtS; SimInfo.dtM = dtM; SimInfo.dtC = dtC; SimInfo.tf = tf;
SimInfo.pdt = (zeros((SimInfo.tf/SimInfo.dtS)+1,3*size(SimInfo.M,2))); SimInfo.vdt = (zeros((SimInfo.tf/SimInfo.dtS)+1,3*size(SimInfo.M,2))); SimInfo.statusdt = (zeros((SimInfo.tf/SimInfo.dtS)+1,size(SimInfo.M,2))); SimInfo.ridt = (zeros((SimInfo.tf/SimInfo.dtS)+1,size(SimInfo.M,2)));
TFC = []; TFC.CS = []; TFC.EC = []; 
TFC.EC.ECdt = zeros((SimInfo.tf/SimInfo.dtS)+1,size(SimInfo.M,2)); TFC.EC.sumECtdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); TFC.EC.sumECqdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); TFC.EC.avgECtdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); TFC.EC.avgECqdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); TFC.EC.sumECdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1);
%% Aircraft Creation
waitbar(0,fwaitbar,'Initalizing Aircraft');
[SimInfo,ObjAircraft] = InitPedObj(SimInfo,Settings);
%% Export Settings
close(fwaitbar)
% save([SimInfo.SimOutputDirStr 'Settings' SimFilename],'-v7.3');
fwaitbar = waitbar(0,'Initalizing Aircraft');
%% Simulation
% Start Simulation
for t=0:dtS:tf
    waitbar(t/tf,fwaitbar,{['Running Simulation  [t=' sprintf('%0.1f',t) '/' sprintf('%0.0f',tf) ']']});
    SimInfo.t = t;
    %% Departures
    [SimInfo,ObjAircraft] = PedDepartures(SimInfo,ObjAircraft);
    %% TCP Pre-controller
    %     if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))
    %         [TFC,ObjAircraft] = TCPPre(SimInfo,ObjAircraft,Settings,TFC,t);
    %     end
    %% Controller + Motion
    [SimInfo,ObjAircraft] = PedController(SimInfo,ObjAircraft,Settings);
    %     [SimInfo,ObjAircraft] = AircraftMotion(aa,SimInfo,ObjAircraft,Settings);
    %% Arrival
    [SimInfo,ObjAircraft] = PedArrivals(SimInfo,ObjAircraft);
    %% Update SimInfo
    % Q - Maybe we can store this in the ObjAircraft?
    [SimInfo] = UpdateSimInfo(SimInfo,ObjAircraft);
    % %% Energy Conspution
    % if (t~=0)
    %     [TFC.EC,ObjAircraft] = CalEC_AG(TFC.EC,SimInfo,ObjAircraft);
    % end
    % %% TFC
    % if (t~=0)&&(mod(t,dtM)==0)
    %     SimInfo.RT.TFCStartTime = datetime;
    %     [TFC] = CalTFC_N(TFC,SimInfo,ObjAircraft,Settings);
    %     [TFC] = CalTFC_Ri(TFC,SimInfo,ObjAircraft,Settings);
    %     SimInfo.RT.TFCEndTime = datetime;
    %     SimInfo.RT.TFCRunningTime(end+1) = seconds(SimInfo.RT.TFCEndTime-SimInfo.RT.TFCStartTime);
    % end
    % %% TCP Post-controller
    % if (Settings.TFC.TCmode==1)%(t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))
    % SimInfo.RT.TCP_PostStartTime = datetime;
    % [TFC,ObjAircraft,SimInfo] = TCP_Post(SimInfo,ObjAircraft,Settings,TFC,t);
    % SimInfo.RT.TCP_PostEndTime = datetime;
    % SimInfo.RT.TCP_PostRunningTime(end+1) = seconds(SimInfo.RT.TCP_PostEndTime-SimInfo.RT.TCP_PostStartTime);
    % % TODO: Make Plotting during for the current k
    % % PlotMotionPictureMFD(0,t,SimInfo,ObjAircraft,TFC,Settings)
    % end
end
waitbar(1,fwaitbar,'Finishing Simulation');
clear t dtS dtM dtC tf
SimInfo.RT.SimEndTime = datetime;
SimInfo.RT.SimRunningTime = seconds(SimInfo.RT.SimEndTime-SimInfo.RT.SimStartTime);
SimInfo.RT.SimRunningTimeStr = datestr(SimInfo.RT.SimEndTime-SimInfo.RT.SimStartTime,'HH:MM:SS.FFF');%seconds(datetime(SimInfo.SimEndTime)-datetime(SimInfo.SimStartTime));
disp(['Simuation Ended: Time=' datestr(SimInfo.RT.SimEndTime,'yyyy-mm-dd HH:MM:SS.FFF')])
disp(['TFC RunningTime: Time=' num2str(sum(SimInfo.RT.TFCRunningTime)) ' [seconds]'])
disp(['TCP_Post RunningTime: Time=' num2str(sum(SimInfo.RT.TCP_PostRunningTime)) ' [seconds]'])
waitbar(1,fwaitbar,'Exporting Data');
%% Exporting and Plotting
% Export Workspace
close(fwaitbar)
% save([SimInfo.SimOutputDirStr 'Results' SimFilename],'TFC','TFC.EC','-v7.3');
ExportJSON([SimInfo.SimOutputDirStr 'Results' SimFilename],SimInfo,ObjAircraft,TFC,Settings)
save([SimInfo.SimOutputDirStr 'Trajectories' SimFilename],'-v7.3'); clear SimFilename;
% ExportJSON(SimInfo,ObjAircraft,TFC,TFC.EC,Settings);
fwaitbar = waitbar(1,'Finishing Simulation');
% % Export Video
PlotMotionPicture(15,SimInfo,ObjAircraft,TFC,Settings);
% PlotMotionPicture_MFD(60,SimInfo,ObjAircraft,TFC,Settings);
waitbar(1,fwaitbar,'Done');
pause(0.1)
close(fwaitbar)
clear fwaitbar;
% % TODO: Export MFD Plots
end