function [] = RunLAATSim(InflowRate,SceStr,asStr)
%%
clc; close all; dbstop if error;
close all force; close all hidden;
fwaitbar = waitbar(0,'Starting Simulation');
SimInfo.RT.TCP_PostRunningTime = [];
SimInfo.RT.TFCRunningTime = [];
SimInfo.RT.SimStartTime = datetime;
disp(['Simuation started: Time=' datestr(SimInfo.RT.SimStartTime,'yyyy-mm-dd HH:MM:SS.FFF')])
SimFilename = [SceStr];
SimInfo.SimOutputDirStr = ['.\Outputs\SimOutput_' datestr(now,'yyyymmdd_hhMMss') '_' SimFilename '\'];
if ~exist(SimInfo.SimOutputDirStr, 'dir')
    mkdir(SimInfo.SimOutputDirStr)
end
%% Settings
waitbar(0,fwaitbar,'Determining Setting');
[Settings.Airspace] = SettingAirspace(1500,1500,90,asStr); % 20*60*30/3.6,20*60*30/3.6
[Settings.Aircraft] = SettingAircraft([20,20],[10,10]);
[Settings.Sim] = SettingSimulation(InflowRate,10);
%% Init Objects
SimInfo.Mina = []; SimInfo.Mque = []; SimInfo.Mact = []; SimInfo.Marr = []; SimInfo.MactBQ = [];
SimInfo.M = 1:1:Settings.Sim.M; SimInfo.cc = 0;
dtS = Settings.Sim.dtsim; dtM = Settings.Sim.dtMFD; tf = Settings.Sim.tf;
SimInfo.dtS = dtS; SimInfo.dtM = dtM; SimInfo.tf = tf;
SimInfo.pdt = (zeros((SimInfo.tf/SimInfo.dtS)+1,3*size(SimInfo.M,2))); SimInfo.vdt = (zeros((SimInfo.tf/SimInfo.dtS)+1,3*size(SimInfo.M,2))); SimInfo.statusdt = (zeros((SimInfo.tf/SimInfo.dtS)+1,size(SimInfo.M,2))); SimInfo.ridt = (zeros((SimInfo.tf/SimInfo.dtS)+1,size(SimInfo.M,2)));
TFC = []; TFC.CS = []; TFC.EC = []; 
TFC.EC.ECdt = zeros((SimInfo.tf/SimInfo.dtS)+1,size(SimInfo.M,2)); TFC.EC.sumECtdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); TFC.EC.sumECqdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); TFC.EC.avgECtdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); TFC.EC.avgECqdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); TFC.EC.sumECdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1);
%% Aircraft Creation
waitbar(0,fwaitbar,'Initalizing Aircraft');
[SimInfo,ObjAircraft] = InitAircraftObj(SimInfo,Settings);
%% Export Settings
close(fwaitbar)
fwaitbar = waitbar(0,'Initalizing Aircraft');
%% Simulation
% Start Simulation
for t=0:dtS:tf
    waitbar(t/tf,fwaitbar,{['Running Simulation  [t=' sprintf('%0.1f',t) '/' sprintf('%0.0f',tf) ']']});
    SimInfo.t = t;
    %% Departures
    [SimInfo,ObjAircraft] = AircraftDepartures(SimInfo,ObjAircraft);
    %% Controller + Motion
    [SimInfo,ObjAircraft] = AircraftController(SimInfo,ObjAircraft,Settings);
    %     [SimInfo,ObjAircraft] = AircraftMotion(aa,SimInfo,ObjAircraft,Settings);
    %% Arrival
    [SimInfo,ObjAircraft] = AircraftArrivals(SimInfo,ObjAircraft);
    %% Update SimInfo
    [SimInfo] = UpdateSimInfo(SimInfo,ObjAircraft);
    %% Energy Conspution
    if (t~=0)
        [TFC.EC,ObjAircraft] = CalEC_AG(TFC.EC,SimInfo,ObjAircraft);
    end
    %% TFC
    if (t~=0)&&(mod(t,dtM)==0)
        SimInfo.RT.TFCStartTime = datetime;
        [TFC] = CalTFC_N(TFC,SimInfo,ObjAircraft,Settings);
        [TFC] = CalTFC_Ri(TFC,SimInfo,ObjAircraft,Settings);
        SimInfo.RT.TFCEndTime = datetime;
        SimInfo.RT.TFCRunningTime(end+1) = seconds(SimInfo.RT.TFCEndTime-SimInfo.RT.TFCStartTime);
    end
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
ExportJSON([SimInfo.SimOutputDirStr 'Results' '_' SimFilename],SimInfo,ObjAircraft,TFC,Settings)
save([SimInfo.SimOutputDirStr 'Trajectories' '_' SimFilename],'-v7.3'); clear SimFilename;
fwaitbar = waitbar(1,'Finishing Simulation');
% % Export Video
PlotMotionPicture(60,SimInfo,ObjAircraft,TFC,Settings);
waitbar(1,fwaitbar,'Done');
pause(0.1)
close(fwaitbar)
clear fwaitbar;
end