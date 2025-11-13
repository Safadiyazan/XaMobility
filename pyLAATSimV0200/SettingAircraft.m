%SettingAircraft Configures the global aircraft parameters for the simulation.
%   This function defines the physical and operational characteristics that
%   will be used to initialize the individual aircraft objects. It sets the
%   allowable ranges for key parameters.
%
%   The function sets:
%   - `rs_range`: The range of possible safety radii for aircraft [m].
%   - `vm_range`: The range of possible maximum speeds for aircraft [m/s].
%   - `Gainfactor_*`: Multipliers for the safety and avoidance radii.
%   - `Bat_*`: Parameters for the battery/energy model.
%
% Inputs:
%   Vmax - (vector) A 2-element vector specifying the [min, max] range for maximum velocity [m/s].
%   Rs   - (vector) A 2-element vector specifying the [min, max] range for safety radius [m].
%
% Outputs:
%   Aircraft - (struct) A structure containing the global aircraft settings.
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