function [Sim] = SettingSimulation(InflowRate,tfStr)
%% simulation time step
Sim.dtsim=double(0.5); %step time(s) should be smaller then rs/vm
% if (SimS.dtsim>(min(2.*AircraftS.rs_range)/max(AircraftS.vm_range)))
%     error('Simulation time step is too small')
% end
%%
Sim.dtMFD=double(60);
%% final time
% SimS.tf = 30;
%% Inflow Profile
% TODO: warning('fix profiles according to SimS.tf')
% TODO: warning('Add empty airspace period')
Sim.InflowRate = InflowRate; %(aircraft/s)
InflowSetting = 1;%tfStr; %30; %[min]
switch InflowSetting
    case 1 % VIDEO
        Sim.switchtime = [0;10];%(min) ;20;30;40;50;60
        Sim.switchvalue = 18.*[12]./60./60;%(aircraft/hr) per OD 4;6;12;30;60
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    case 2
        % Test
        Sim.switchtime = [0;2];%(min)
        Sim.switchvalue = Sim.InflowRate.*[1];%(aircraft/s)
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    case 7
        % Greenshields
        Sim.switchtime = [0;1;2;3;4;5;6;7];%(min)
        Sim.switchvalue = Sim.InflowRate.*[0.2;0.5;0.8;1;0.8;0.5;0.2];%(aircraft/s)
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    case 10
        Sim.switchtime = [0;1;2;3;13;14;15;16;20].*0.5;%(min)
        Sim.switchvalue = Sim.InflowRate.*[0.2;0.5;0.8;1;0.8;0.5;0.2;0];%(aircraft/s)
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    case 15
        Sim.switchtime = [[0:1:10]';11+9;[(9+12):1:(9+21)]';45]./3;%(min)
        Sim.switchvalue = Sim.InflowRate.*[[0.1:0.1:1]';1;[1:-0.1:0.1]';0];%(aircraft/s)
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    case 20
        % Testing % ISTTT25
        Sim.switchtime = [0;1;2;3;13;14;15;16;20];%(min)
        Sim.switchvalue = Sim.InflowRate.*[0.2;0.5;0.8;1;0.8;0.5;0.2;0];%(aircraft/s)
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
%     case 60
%         % Better Inflow for future papers
%         Sim.switchtime = [0;5;10;15;45;50;55;60];%(min)
%         Sim.switchvalue = Sim.InflowRate.*[0.2;0.5;0.8;1;0.8;0.5;0.2];%(aircraft/s)
%         Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    case 30
        Sim.switchtime = [[0:1:10]';11+9;[(9+12):1:(9+21)]'];%(min)
        Sim.switchvalue = Sim.InflowRate.*[[0.1:0.1:1]';1;[1:-0.1:0.1]'];%(aircraft/s)
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    case 60
        Sim.switchtime = 2.*[[0:1:10]';11+9;[(9+12):1:(9+21)]'];%(min)
        Sim.switchvalue = Sim.InflowRate.*[[0.1:0.1:1]';1;[1:-0.1:0.1]'];%(aircraft/s)
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    case 90
        % TRB Paper \ Journal
        Sim.switchtime = [0;30;60;90];%(min)
        Sim.switchvalue = Sim.InflowRate.*[0.5;1.0;0.5];%(veh/s)
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    otherwise
        error('error in Inflow Profile')
end
Sim.tf = Sim.switchtime(end)*60; %[s]
Sim.Qin_avg = sum(Sim.switchvalue.*diff(Sim.switchtime))./Sim.switchtime(end);
disp(['Average inflow rate = ' num2str(Sim.Qin_avg) '[aircraft/s]'])
%% inflow_settings
warning('double check inflow settings')
% TODO: warning('make uniformly arrival')
Sim.AircraftNum = diff(Sim.switchtime*60).*Sim.switchvalue;
Sim.AircraftCumNum = cumsum(Sim.AircraftNum);
%
cellsnum = diff(Sim.switchtime)*60/Sim.dtsim;
Sim.AircraftNumdtSim = [];
for sp=1:size(Sim.switchtime,1)-1
    Sim.AircraftNumdtSim = [Sim.AircraftNumdtSim; ones(ceil(cellsnum(sp)),1)*Sim.switchvalue(sp)*Sim.dtsim];
end
clear sp cellsnum
Sim.AircraftCumNumdtSim = cumsum(Sim.AircraftNumdtSim);
%%
Sim.M = floor(Sim.AircraftCumNum(end));
end