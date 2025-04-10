%{
    Function: SettingAircraft
    Description: Configures the aircraft settings based on the provided
                 maximum velocity and turn radius.

    Inputs:
        - Vmax: Maximum velocity of the aircraft (numeric).
        - Rs: Turn radius of the aircraft (numeric).

    Outputs:
        - Aircraft: A structure containing the configured aircraft settings.

    Usage:
        [Aircraft] = SettingAircraft(Vmax, Rs);

%}
% Author: Yazan Safadi
% Date Created: 2023-02-08
function [Aircraft] = SettingAircraft(Vmax,Rs)
Aircraft.rs_range = [Rs(1);Rs(2)];% Safety radius [m]
gr = 1.8;
Aircraft.Gainfactor_rs = gr; % [?]
Aircraft.Gainfactor_ra = gr; % [?]
Aircraft.vm_range = [Vmax(1);Vmax(2)];% Maximum speed [m/s]
%% Battery
Aircraft.Bat_max = 69.5; %Battery capacity 250 [kJ] = 69.5 [Watt per hour]
Aircraft.Bat_limit = Aircraft.Bat_max*0.2; %Safety factor for battery
end