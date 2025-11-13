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