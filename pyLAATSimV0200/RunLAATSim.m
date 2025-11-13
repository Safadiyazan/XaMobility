%RunLAATSim Executes the LAAT (Low-Altitude Air Transport) simulation.
%   This script serves as the main entry point for running a simulation scenario.
%   It initializes the simulation environment, settings, and objects, then
%   iterates through time to simulate aircraft movements, control strategies,
%   and data collection.
%
%   This function is configured to run a specific scenario from a script,
%   as opposed to the UI-driven RunLAATSimUI.m.
%
%   The simulation flow includes:
%   1. Initialization: Sets up airspace, aircraft, simulation, and traffic control parameters.
%   2. Main Loop: Iterates over time, handling aircraft departures, controller
%      logic, motion updates, arrivals, and data calculation (TFC and energy).
%   3. Post-Processing: Exports simulation results to JSON and generates a
%      motion picture of the simulation.
%
% Inputs:
%   InflowRate - (numeric) The base rate of aircraft entering the simulation [aircraft/s].
%   SceStr     - (string) A descriptive name for the scenario being run.
%   asStr      - (string) A string identifier for the airspace configuration (e.g., 'NYC', 'SF').
% Outputs:
%   None.
%
% Example:
%   RunLAATSim(10/60, 'Scenario1', 'NYC');
%
% Notes:
%   Ensure that the input parameters are valid and correspond to the
%   expected formats for the simulation to run correctly.
% Author: Yazan Safadi
% Date Created: 2023-02-08
function [] = RunLAATSim(InflowRate,SceStr,asStr)
%%
clc; close all; dbstop if error;
close all force; close all hidden; % Close all figures before starting
fwaitbar = waitbar(0,'Starting Simulation');
UIRun = 0; % Flag to indicate a script-based run (0) vs. a UI-based run (1)
SimInfo.RT.TCP_PostRunningTime = [];
SimInfo.RT.TFCRunningTime = [];
SimInfo.RT.SimStartTime = datetime;
disp(['[INFO] Simulation started at: ', datestr(SimInfo.RT.SimStartTime,'yyyy-mm-dd HH:MM:SS.FFF')]);
SimFilename = [SceStr];
SimInfo.SimOutputDirStr = ['.\Outputs\SimOutput_' datestr(now,'yyyymmdd_hhMMss') '_' SimFilename '\']; % Output directory for this simulation run
if ~exist(SimInfo.SimOutputDirStr, 'dir')
    mkdir(SimInfo.SimOutputDirStr)
end
%% Settings
waitbar(0,fwaitbar,'Determining Settings');
[Settings.Airspace] = SettingAirspace(1500,1500,90,asStr,UIRun); % 20*60*30/3.6,20*60*30/3.6
Settings.Airspace.as = 1;
[Settings.Aircraft] = SettingAircraft([20,20],[10,10]);
[Settings.Sim] = SettingSimulation(InflowRate,10);
[Settings.TFC] = SettingTrafficControl(Settings,UIRun);
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
waitbar(0,fwaitbar,'Initializing Aircraft');
[SimInfo,ObjAircraft] = InitAircraftObj(SimInfo,Settings);
%% Export Settings
close(fwaitbar)
save([SimInfo.SimOutputDirStr 'Settings' SimFilename],'-v7.3');
fwaitbar = waitbar(0,'Initializing Aircraft');
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
waitbar(1,fwaitbar,'Finishing Simulation');
clear t dtS dtM dtC tf
SimInfo.RT.SimEndTime = datetime;
SimInfo.RT.SimRunningTime = seconds(SimInfo.RT.SimEndTime-SimInfo.RT.SimStartTime);
SimInfo.RT.SimRunningTimeStr = datestr(SimInfo.RT.SimEndTime-SimInfo.RT.SimStartTime,'HH:MM:SS.FFF');
disp(['[INFO] Simulation ended at: ', datestr(SimInfo.RT.SimEndTime,'yyyy-mm-dd HH:MM:SS.FFF')]);
disp(['[INFO] Total TFC Running Time: ', num2str(sum(SimInfo.RT.TFCRunningTime)), ' seconds.']);
disp(['[INFO] Total TCP_Post Running Time: ', num2str(sum(SimInfo.RT.TCP_PostRunningTime)), ' seconds.']);
waitbar(1,fwaitbar,'Exporting Data');
%% Exporting and Plotting
% Export Workspace
close(fwaitbar)
ExportJSON(['../public/Outputs/' 'SimOutput_' SimFilename],SimInfo,ObjAircraft,TFC,Settings)
save([SimInfo.SimOutputDirStr 'Trajectories' '_' SimFilename],'-v7.3'); clear SimFilename;
fwaitbar = waitbar(1,'Finishing Simulation');
% % Export Video
PlotMotionPicture(60,SimInfo,ObjAircraft,TFC,Settings);
waitbar(1,fwaitbar,'Done');
pause(0.1)
close(fwaitbar)
clear fwaitbar;
end