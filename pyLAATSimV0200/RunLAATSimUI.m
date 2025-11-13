%RunLAATSimUI Executes the LAAT simulation based on inputs from a User Interface.
%   This function is designed to be called by an external application (e.g., a
%   web server with a Flask API) to run a simulation scenario with parameters
%   provided by a user through a UI.
%
%   The function initializes and runs a full simulation, similar to RunLAATSim.m,
%   but it dynamically configures the settings based on the `NewSettings`
%   structure passed as an argument.
%
%   The simulation flow includes:
%   1. Dynamic Initialization: Configures airspace, aircraft, and simulation
%      parameters from the `NewSettings` input.
%   2. Main Loop: Iterates over time, handling aircraft departures, controller
%      logic, motion updates, arrivals, and data calculation (TFC and energy).
%   3. Post-Processing: Exports simulation results to a JSON file in a public
%      directory, which can then be fetched by the web application.
%
% Inputs:
%   InflowRate  - (numeric) The base rate of aircraft entering the simulation [aircraft/s].
%   NewSettings - (struct) A structure containing user-defined settings from the UI,
%                 including airspace dimensions, aircraft properties, and simulation parameters.
%   SceStr      - (string) A descriptive name for the scenario being run.
%
% Outputs:
%   scenarioName - (string) The filename of the generated JSON file containing the simulation results.
%
% Author: Yazan Safadi
% Date Created: 2024-03-05
function [scenarioName] = RunLAATSimUI(InflowRate,NewSettings,SceStr)
clc; close all; dbstop if error;
close all force; close all hidden;
disp('[INFO] Starting LAATSim Simulation (UI Mode)...');
UIRun = 1; % Flag to indicate a UI-based run (1)
SimInfo.RT.TCP_PostRunningTime = [];
SimInfo.RT.TFCRunningTime = [];
SimInfo.RT.SimStartTime = datetime;
disp(['[INFO] Simulation started at: ', datestr(SimInfo.RT.SimStartTime,'yyyy-mm-dd HH:MM:SS.FFF')]);
SimFilename = ['_Qin' sprintf('%0.0f',InflowRate) SceStr];
SimInfo.SimOutputDirStr = ['.\Outputs\SimOutput_' datestr(now,'yyyymmdd_hhMMss') SimFilename '\'];
%% Settings
% Configure simulation settings based on the NewSettings struct from the UI
disp('[INFO] Configuring simulation settings...');
if (~isempty(NewSettings))
    [Settings.Airspace] = SettingAirspace(double(NewSettings.Airspace.dx),double(NewSettings.Airspace.dy),double(NewSettings.Airspace.dz),NewSettings.Airspace.asStr,UIRun);
    [Settings.Aircraft] = SettingAircraft([double(NewSettings.Aircraft.VmaxMin);double(NewSettings.Aircraft.VmaxMax)],[double(NewSettings.Aircraft.RsMin);double(NewSettings.Aircraft.RsMax)]);
    [Settings.Sim] = SettingSimulation(double(NewSettings.Sim.Qin)/60,10);
    [Settings.TFC] = SettingTrafficControl(Settings, UIRun);
    disp(['Inflow aircraft/s:' double(NewSettings.Sim.Qin)/60])
else
    [Settings.Airspace] = SettingAirspace(1500,1500,90,'NYC',UIRun);
    [Settings.Aircraft] = SettingAircraft([10,30],[10,30]);
    [Settings.Sim] = SettingSimulation(InflowRate,10);
    [Settings.TFC] = SettingTrafficControl(Settings, UIRun);
end
disp('[INFO] Settings configured.');
%% Init Objects
SimInfo.Mina = []; SimInfo.Mque = []; SimInfo.Mact = []; SimInfo.Marr = []; SimInfo.MactBQ = [];
SimInfo.M = 1:1:Settings.Sim.M; SimInfo.cc = 0; % Initialize aircraft indices
dtS = Settings.Sim.dtsim; dtM = Settings.Sim.dtMFD; dtC = Settings.TFC.dtC; tf = Settings.Sim.tf;
SimInfo.dtS = dtS; SimInfo.dtM = dtM; SimInfo.dtC = dtC; SimInfo.tf = tf;
% Pre-allocate matrices for performance
SimInfo.pdt = (zeros((SimInfo.tf/SimInfo.dtS)+1,3*size(SimInfo.M,2))); SimInfo.vdt = (zeros((SimInfo.tf/SimInfo.dtS)+1,3*size(SimInfo.M,2))); SimInfo.statusdt = (zeros((SimInfo.tf/SimInfo.dtS)+1,size(SimInfo.M,2))); SimInfo.ridt = (zeros((SimInfo.tf/SimInfo.dtS)+1,size(SimInfo.M,2))); SimInfo.vmdt = (zeros((SimInfo.tf/SimInfo.dtS)+1,size(SimInfo.M,2)));
TFC = []; TFC.CS = []; TFC.EC = [];
TFC.EC.ECdt = zeros((SimInfo.tf/SimInfo.dtS)+1,size(SimInfo.M,2)); TFC.EC.sumECtdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); TFC.EC.sumECqdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); TFC.EC.avgECtdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); TFC.EC.avgECqdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1); TFC.EC.sumECdt = zeros((SimInfo.tf/SimInfo.dtS)+1,1);
%% Aircraft Creation
disp('[INFO] Initializing aircraft objects...');
[SimInfo,ObjAircraft] = InitAircraftObj(SimInfo,Settings);
%% Export Settings
% save([SimInfo.SimOutputDirStr 'Settings' SimFilename],'-v7.3');
disp('[INFO] Aircraft initialized.');
%% Simulation
disp('[INFO] Starting main simulation loop...');
% Main simulation loop
for t=0:dtS:tf
    disp(['[INFO] Simulating t = ', sprintf('%0.1f',t), '/', sprintf('%0.0f',tf), 's']);
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
    if (t~=0) % Calculate energy consumption for the current step
        [TFC.EC,ObjAircraft] = CalEC_AG(TFC.EC,SimInfo,ObjAircraft);
    end
    %% TFC
    if (t~=0)&&(mod(t,dtM)==0) % Calculate macroscopic traffic flow characteristics (MFD variables) at each aggregation interval
        SimInfo.RT.TFCStartTime = datetime;
        [TFC] = CalTFC_N(TFC,SimInfo,ObjAircraft,Settings);
        [TFC] = CalTFC_Ri(TFC,SimInfo,ObjAircraft,Settings);
        SimInfo.RT.TFCEndTime = datetime;
        SimInfo.RT.TFCRunningTime(end+1) = seconds(SimInfo.RT.TFCEndTime-SimInfo.RT.TFCStartTime);
    end
    if (Settings.TFC.TCmode==1)%(t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))
        SimInfo.RT.TCP_PostStartTime = datetime; % Apply traffic control policies
        [TFC,ObjAircraft,SimInfo] = TCP_Post(SimInfo,ObjAircraft,Settings,TFC,t);
        SimInfo.RT.TCP_PostEndTime = datetime;
        SimInfo.RT.TCP_PostRunningTime(end+1) = seconds(SimInfo.RT.TCP_PostEndTime-SimInfo.RT.TCP_PostStartTime);
        % TODO: Make Plotting during for the current k
        % PlotMotionPictureMFD(0,t,SimInfo,ObjAircraft,TFC,Settings)
    end
end
disp('[INFO] Main simulation loop finished.');
clear t dtS dtM dtC tf
SimInfo.RT.SimEndTime = datetime;
SimInfo.RT.SimRunningTime = seconds(SimInfo.RT.SimEndTime-SimInfo.RT.SimStartTime);
SimInfo.RT.SimRunningTimeStr = datestr(SimInfo.RT.SimEndTime-SimInfo.RT.SimStartTime,'HH:MM:SS.FFF');%seconds(datetime(SimInfo.SimEndTime)-datetime(SimInfo.SimStartTime));
disp(['[INFO] Simulation ended at: ', datestr(SimInfo.RT.SimEndTime,'yyyy-mm-dd HH:MM:SS.FFF')]);
disp(['[INFO] Total TFC Running Time: ', num2str(sum(SimInfo.RT.TFCRunningTime)), ' seconds.']);
disp(['[INFO] Total TCP_Post Running Time: ', num2str(sum(SimInfo.RT.TCP_PostRunningTime)), ' seconds.']);
disp('[INFO] Exporting simulation data...');
%% Exporting and Plotting
% Export results to a JSON file in the public directory for the UI to access
scenarioName = ExportJSON(['./public/Outputs/' 'SimOutput_' SceStr],SimInfo,ObjAircraft,TFC,Settings);
disp(['[INFO] Scenario Name: ', scenarioName]);
disp('[INFO] Simulation finished.');
% % Export Video
TTS_Final = TFC.N.cumTTS(end)/3600;
end