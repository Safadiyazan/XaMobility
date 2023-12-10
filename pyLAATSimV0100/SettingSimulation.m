function [Sim] = SettingSimulation(InflowRate)
Sim.dtsim=double(0.5); % (min) simulation time step
Sim.dtMFD=double(60); % (min)
Sim.InflowRate = InflowRate;
InflowSetting = 7; % (min)
switch InflowSetting
    case 2
        % Test
        Sim.switchtime = [0;2];%(min)
        Sim.switchvalue = Sim.InflowRate.*[1];%(aircraft/s)
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    case 7
        Sim.switchtime = [0;1;2;3;4;5;6;7];%(min)
        Sim.switchvalue = Sim.InflowRate.*[0.2;0.5;0.8;1;0.8;0.5;0.2];%(aircraft/s)
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    case 10
        Sim.switchtime = [0;1;2;3;13;14;15;16;20].*0.5;%(min)
        Sim.switchvalue = Sim.InflowRate.*[0.2;0.5;0.8;1;0.8;0.5;0.2;0];%(aircraft/s)
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    case 20
        Sim.switchtime = [0;1;2;3;13;14;15;16;20];%(min)
        Sim.switchvalue = Sim.InflowRate.*[0.2;0.5;0.8;1;0.8;0.5;0.2;0];%(aircraft/s)
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    case 30
        Sim.switchtime = [[0:1:10]';11+9;[(9+12):1:(9+21)]'];%(min)
        Sim.switchvalue = Sim.InflowRate.*[[0.1:0.1:1]';1;[1:-0.1:0.1]'];%(aircraft/s)
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    case 60
        Sim.switchtime = 2.*[[0:1:10]';11+9;[(9+12):1:(9+21)]'];%(min)
        Sim.switchvalue = Sim.InflowRate.*[[0.1:0.1:1]';1;[1:-0.1:0.1]'];%(aircraft/s)
        Sim.glowthrate = [zeros(size(Sim.switchvalue))];
    otherwise
        error('error in Inflow Profile')
end
Sim.tf = Sim.switchtime(end)*60; %[s]
Sim.Qin_avg = sum(Sim.switchvalue.*diff(Sim.switchtime))./Sim.switchtime(end);
disp(['Average inflow rate = ' num2str(Sim.Qin_avg) '[aircraft/s]'])
Sim.AircraftNum = diff(Sim.switchtime*60).*Sim.switchvalue;
Sim.AircraftCumNum = cumsum(Sim.AircraftNum);
cellsnum = diff(Sim.switchtime)*60/Sim.dtsim;
Sim.AircraftNumdtSim = [];
for sp=1:size(Sim.switchtime,1)-1
    Sim.AircraftNumdtSim = [Sim.AircraftNumdtSim; ones(ceil(cellsnum(sp)),1)*Sim.switchvalue(sp)*Sim.dtsim];
end
clear sp cellsnum
Sim.AircraftCumNumdtSim = cumsum(Sim.AircraftNumdtSim);
Sim.M = floor(Sim.AircraftCumNum(end));
end