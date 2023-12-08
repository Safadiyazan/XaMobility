function [Aircraft] = SettingAircraft()
Aircraft.rs_range = [10;20];% Safety radius [m]
gr = 1.8;
Aircraft.Gainfactor_rs = gr; % [?]
Aircraft.Gainfactor_ra = gr; % [?]
Aircraft.vm_range = [10;30];% Maximum speed [m/s]
% AircraftS.gain_range = [2,2,2;2,2,2];%  % Control gain [?]
%% Battery
Aircraft.Bat_max = 69.5; %Battery capacity 250 [kJ] = 69.5 [Watt per hour]
Aircraft.Bat_limit = Aircraft.Bat_max*0.2; %Safety factor for battery
%% TODO: Priority settings
end