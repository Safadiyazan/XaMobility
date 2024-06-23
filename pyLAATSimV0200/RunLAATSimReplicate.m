function [TTS_Final] = RunLAATSimReplicate(SettingFileName,RepStr,Control,Omega,udimin,ubijmin,ControlStr)
%%
% clear all;
clearvars -except SettingFileName RepStr Control Omega udimin ubijmin ControlStr;
clc; close all; dbstop if error;
close all force; close all hidden;
load(['.\DataMAT_Rep\' SettingFileName])
SimInfo.RT.TCP_PostRunningTime = [];
SimInfo.RT.TFCRunningTime = [];
SimInfo.RT.SimStartTime = datetime;
disp(['Simuation started: Time=' datestr(SimInfo.RT.SimStartTime,'yyyy-mm-dd HH:MM:SS.FFF')])
% Open Directory
SimFilename = ['_Qin' sprintf('%0.0f',InflowRate*10) RepStr];
SimInfo.SimOutputDirStr = ['.\Outputs\SimOutput_' datestr(now,'yyyymmdd_hhMMss') SimFilename '\'];
if ~exist(SimInfo.SimOutputDirStr, 'dir')
    mkdir(SimInfo.SimOutputDirStr)
end
Settings.TFC = [];
if Control
    [Settings.TFC] = SettingTrafficControl(Settings);
else
    Settings.TFC.TCmode = 0;
end
if(~(isempty(Omega)))
    Settings.TFC.Omega = Omega;
end
if(~(isempty(udimin)))
    Settings.TFC.udi(1) = udimin;
end
if(~(isempty(ubijmin)))
    Settings.TFC.ubij(1) = ubijmin;
end
if(~(isempty(ControlStr)))
    Settings.TFC.TCP_BoundaryUpPolicyStr = ControlStr; % MaxTL | MinTLDone | MinTLLeft | MaxTLLeft | FirstDeparted
end
fwaitbar = waitbar(0,'Initalizing Aircraft');
clear tf; t_f = SimInfo.tf;
%% Simulation
% Start Simulation
for t=0:dtS:t_f
    waitbar(t/t_f,fwaitbar,{['Running Simulation  [t=' sprintf('%0.1f',t) '/' sprintf('%0.0f',t_f) ']']});
    SimInfo.t = t;
    %% Departures
    [SimInfo,ObjAircraft] = AircraftDepartures(SimInfo,ObjAircraft);
    %% TCP Pre-controller
    %     if (t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))
    %         [TFC,ObjAircraft] = TCPPre(SimInfo,ObjAircraft,Settings,TFC,t);
    %     end
    %% Controller + Motion
    [SimInfo,ObjAircraft] = AircraftController(SimInfo,ObjAircraft,Settings);
    %     [SimInfo,ObjAircraft] = AircraftMotion(aa,SimInfo,ObjAircraft,Settings);
    %% Arrival
    [SimInfo,ObjAircraft] = AircraftArrivals(SimInfo,ObjAircraft);
    %% Update SimInfo
    % Q - Maybe we can store this in the ObjAircraft?
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
    %% TCP Post-controller
    if (Settings.TFC.TCmode==1)%(t~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))
        SimInfo.RT.TCP_PostStartTime = datetime;
        [TFC,ObjAircraft,SimInfo] = TCP_Post(SimInfo,ObjAircraft,Settings,TFC,t);
        SimInfo.RT.TCP_PostEndTime = datetime;
        SimInfo.RT.TCP_PostRunningTime(end+1) = seconds(SimInfo.RT.TCP_PostEndTime-SimInfo.RT.TCP_PostStartTime);
        % TODO: Make Plotting during for the current k
        % PlotMotionPictureMFD(0,t,SimInfo,ObjAircraft,TFC,Settings)
    end
end
waitbar(1,fwaitbar,'Finishing Simulation');
clear t dtS dtM dtC t_f
% End Running Time
SimInfo.RT.SimEndTime = datetime;
SimInfo.RT.SimRunningTime = seconds(SimInfo.RT.SimEndTime-SimInfo.RT.SimStartTime);
SimInfo.RT.SimRunningTimeStr = datestr(SimInfo.RT.SimEndTime-SimInfo.RT.SimStartTime,'HH:MM:SS.FFF');%seconds(datetime(SimInfo.SimEndTime)-datetime(SimInfo.SimStartTime));
disp(['Simuation Ended: Time=' datestr(SimInfo.RT.SimEndTime,'yyyy-mm-dd HH:MM:SS.FFF')])
disp(['TFC RunningTime: Time=' num2str(sum(SimInfo.RT.TFCRunningTime)) ' [seconds]'])
disp(['TCP_Post RunningTime: Time=' num2str(sum(SimInfo.RT.TCP_PostRunningTime)) ' [seconds]'])
% toc
waitbar(1,fwaitbar,'Exporting Data');
%% Exporting and Plotting
% Export Workspace
close(fwaitbar)
save([SimInfo.SimOutputDirStr 'Results' SimFilename],'TFC','EC','-v7.3');
save([SimInfo.SimOutputDirStr 'Trajectories' SimFilename],'-v7.3'); clear SimFilename;
% ExportJSON(SimInfo,ObjAircraft,TFC,EC,Settings);
fwaitbar = waitbar(1,'Finishing Simulation');
% % Export Video
% PlotMotionPicture(30,SimInfo,ObjAircraft,TFC,Settings);
PlotMotionPicture_MFD(600,SimInfo,ObjAircraft,TFC,Settings);
waitbar(1,fwaitbar,'Done');
pause(0.1)
close(fwaitbar)
clear fwaitbar;
% % TODO: Export MFD Plots
TTS_Final = TFC.N.cumTTS(end)/3600;
end