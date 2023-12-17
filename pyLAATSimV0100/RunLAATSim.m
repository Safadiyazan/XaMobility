function [scenarioName] = RunLAATSim(InflowRate,NewSettings,SceStr)
clc; close all; dbstop if error;
close all force; close all hidden;
disp(['Starting Simulation']);
SimInfo.RT.TCP_PostRunningTime = [];
SimInfo.RT.TFCRunningTime = [];
SimInfo.RT.SimStartTime = datetime;
disp(['Simuation started: Time=' datestr(SimInfo.RT.SimStartTime,'yyyy-mm-dd HH:MM:SS.FFF')])
SimFilename = ['_Qin' sprintf('%0.0f',InflowRate*10) SceStr];
SimInfo.SimOutputDirStr = ['.\Outputs\SimOutput_' datestr(now,'yyyymmdd_hhMMss') SimFilename '\'];
% if ~exist(SimInfo.SimOutputDirStr, 'dir')
%    mkdir(SimInfo.SimOutputDirStr)
% end
%% Settings
disp(['Determining Setting']);
if (~isempty(NewSettings))
    [Settings.Airspace] = SettingAirspace(double(NewSettings.Airspace.dx),double(NewSettings.Airspace.dy),double(NewSettings.Airspace.dz));
    Settings.Airspace.as = NewSettings.Airspace.as;
    [Settings.Aircraft] = SettingAircraft([double(NewSettings.Aircraft.VmaxMin);double(NewSettings.Aircraft.VmaxMax)],[double(NewSettings.Aircraft.RsMin);double(NewSettings.Aircraft.RsMax)]);
    [Settings.Sim] = SettingSimulation(double(NewSettings.Sim.Qin));
else
    [Settings.Airspace] = SettingAirspace(500,500,80);
    Settings.Airspace.as = 1;
    [Settings.Aircraft] = SettingAircraft([10,30],[10,30]);
    [Settings.Sim] = SettingSimulation(0.1);
end
%% Init Objects
SimInfo.Mina = []; SimInfo.Mque = []; SimInfo.Mact = []; SimInfo.Marr = []; SimInfo.MactBQ = [];
SimInfo.M = 1:1:Settings.Sim.M; SimInfo.cc = 0;
dtS = Settings.Sim.dtsim; dtM = Settings.Sim.dtMFD; tf = Settings.Sim.tf;
SimInfo.dtS = dtS; SimInfo.dtM = dtM; SimInfo.tf = tf;
SimInfo.pdt = (zeros((SimInfo.tf/SimInfo.dtS)+1,3*size(SimInfo.M,2))); SimInfo.vdt = (zeros((SimInfo.tf/SimInfo.dtS)+1,3*size(SimInfo.M,2))); SimInfo.statusdt = (zeros((SimInfo.tf/SimInfo.dtS)+1,size(SimInfo.M,2))); SimInfo.ridt = (zeros((SimInfo.tf/SimInfo.dtS)+1,size(SimInfo.M,2)));
TFC = []; EC = []; EC.ECdt = zeros((SimInfo.tf/SimInfo.dtS)+1,size(SimInfo.M,2)); EC.sumECtdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); EC.sumECqdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); EC.avgECtdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); EC.avgECqdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); EC.sumECdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1);
%% Aircraft Creation
disp(['Initalizing Aircraft']);
[SimInfo,ObjAircraft] = InitAircraftObj(SimInfo,Settings);
%% Export Settings
% save([SimInfo.SimOutputDirStr 'Settings' SimFilename],'-v7.3');
disp(['Initalizing Aircraft']);
%% Simulation
% Start Simulation
for t=0:dtS:tf
    disp(['Running Simulation  [t=' sprintf('%0.1f',t) '/' sprintf('%0.0f',tf) ']'])
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
        [EC,ObjAircraft] = CalEC_AG(EC,SimInfo,ObjAircraft);
    end
    %% TFC
    if (t~=0)&&(mod(t,dtM)==0)
        SimInfo.RT.TFCStartTime = datetime;
        [TFC,EC] = CalTFC_N(TFC,EC,SimInfo,ObjAircraft,Settings);
        [TFC,EC] = CalTFC_Ri(TFC,EC,SimInfo,ObjAircraft,Settings);
        SimInfo.RT.TFCEndTime = datetime;
        SimInfo.RT.TFCRunningTime(end+1) = seconds(SimInfo.RT.TFCEndTime-SimInfo.RT.TFCStartTime);
    end
end
disp(['Finishing Simulation'])
clear t dtS dtM dtC tf
SimInfo.RT.SimEndTime = datetime;
SimInfo.RT.SimRunningTime = seconds(SimInfo.RT.SimEndTime-SimInfo.RT.SimStartTime);
SimInfo.RT.SimRunningTimeStr = datestr(SimInfo.RT.SimEndTime-SimInfo.RT.SimStartTime,'HH:MM:SS.FFF');%seconds(datetime(SimInfo.SimEndTime)-datetime(SimInfo.SimStartTime));
disp(['Simuation Ended: Time=' datestr(SimInfo.RT.SimEndTime,'yyyy-mm-dd HH:MM:SS.FFF')])
disp(['TFC RunningTime: Time=' num2str(sum(SimInfo.RT.TFCRunningTime)) ' [seconds]'])
disp(['TCP_Post RunningTime: Time=' num2str(sum(SimInfo.RT.TCP_PostRunningTime)) ' [seconds]'])
disp(['Exporting Data'])
%% Exporting and Plotting
% Export Workspace
% save([SimInfo.SimOutputDirStr 'Results' SimFilename],'TFC','EC','-v7.3');
% save([SimInfo.SimOutputDirStr 'Trajectories' SimFilename],'-v7.3'); clear SimFilename;
scenarioName = ExportJSON(SceStr,SimInfo,ObjAircraft,TFC,EC,Settings);
disp(scenarioName)
disp(['Finishing Simulation'])
% % Export Video
% PlotMotionPicture(30,SimInfo,ObjAircraft,TFC,Settings);
TTS_Final = TFC.N.cumTTS(end)/3600;
end