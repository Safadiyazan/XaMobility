%SettingTrafficControl Configures all settings related to traffic control.
%   This function serves as the central configuration point for all traffic
%   management strategies. It enables or disables traffic control and, if
%   enabled, loads all the necessary models and parameters for the selected
%   control policy.
%
%   The function performs the following steps:
%   1. Sets the `TCmode` flag to enable (1) or disable (0) traffic control.
%   2. If enabled, it calls `LoadMFDSettings` to load pre-calibrated MFD and
%      eLMFD models for the specified airspace configuration.
%   3. It then calls `SetTCPPolicy` to select the active control policy
%      (e.g., DBC, Speed Control) and controller type (e.g., GC, MPC), and
%      to configure the corresponding parameters like MPC weights.
%
% Inputs:
%   Settings - (struct) The main settings structure, containing airspace info.
%   UIRun    - (numeric) A flag indicating if the simulation is UI-driven (1) or not (0).
%
% Outputs:
%   TFC - (struct) The Traffic Flow Characteristics structure, now populated with control settings.
function [TFC] = SettingTrafficControl(Settings, UIRun)
if (UIRun==1)
    public_dir = './public';
else
    public_dir = '../public';
end
TFC.TCmode = 1;
TFC.dtC = 60;
if(TFC.TCmode)
    disp('[INFO] SettingTrafficControl: Traffic Control Mode is ON.');

    % Determine the number of layers and unique regions per layer from the airspace settings.
    all_regions = cat(1, Settings.Airspace.Regions.B);
    flying_regions = all_regions([all_regions.layer] > 0);
    uniqueRegionIndices = unique(mod([flying_regions.ri], Settings.Airspace.Regions.dzri));
    numLayers = numel(Settings.Airspace.Layers);

    % Load MFD functions based on the unique region indices
    [TFC] = LoadMFDSettings(TFC, Settings, public_dir, uniqueRegionIndices, numLayers);

    % Set the active TCP policy and its specific parameters (e.g., MPC weights)
    [TFC] = SetTCPPolicy(TFC);

else
    disp('[INFO] SettingTrafficControl: Traffic Control Mode is OFF.');
end
end