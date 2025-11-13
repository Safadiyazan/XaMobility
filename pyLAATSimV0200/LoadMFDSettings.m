function [TFC] = LoadMFDSettings(TFC, Settings, public_dir, regionIndices, numLayers)
%LoadMFDSettings Loads pre-calibrated MFD and eLMFD model parameters.
%   This function loads functional forms and critical parameters for the
%   Macroscopic Fundamental Diagram (MFD) and Energy MFD (eLMFD) from
%   pre-saved .mat files. These parameters are essential for the model-based
%   controllers (e.g., MPC) to predict airspace dynamics.
%
%   The function loads:
%   1. Network-wide MFD: Loads the `G(n)` (Outflow-Accumulation) function and
%      critical points (`nc`, `njam`, `Gm`) for the entire airspace.
%   2. Region-specific MFDs: For each defined region type, it loads the
%      corresponding `G(n)` and `V(n)` (Speed-Accumulation) functions.
%   3. Energy Models (eLMFD): Loads the `E(V)` (Energy-Speed) function and
%      its critical points (`vECstar`).
%
%   These functions and parameters are stored in the `TFC` structure for use
%   by the traffic control modules.
numRegions = numel(regionIndices);

disp(['[INFO] LoadMFDSettings: Loading MFD data for ', num2str(numLayers), ' layer(s) and ', num2str(numRegions), ' unique region(s) per layer with indices: [', num2str(regionIndices), '].']);
% --- Load Network-Wide MFD ---
networkMFDFile = [public_dir, '/MFD_mat_data/MFD_VTOL_Func_N_Ide6_1Hr.mat'];
if exist(networkMFDFile, 'file')
    load(networkMFDFile, 'Func');
    TFC.funGN = Func.Gn;
    TFC.nc = Func.nG_star;
    TFC.njam = Func.nG_min;
    TFC.Gm = TFC.funGN(Func.nG_star);
    TFC.ECv = @(x)((20./Func.ECvAlpha(1)).*(exp(-x./Func.ECvAlpha(3))+Func.ECvAlpha(2)));
    TFC.Vn = @(x)((Func.VnAlpha(6)./Func.VnAlpha(1)).*(exp(-Func.VnAlpha(2).*((x./Func.VnAlpha(5)).^Func.VnAlpha(3)))+Func.VnAlpha(4)));
    TFC.vECstar = round(1.2*Func.vEC_min,1);
    TFC.vECmin = round(1.2*Func.vEC_star,1);
    TFC.vECmax = mean(Settings.Aircraft.vm_range);
    TFC.ssECv = TFC.ECv(TFC.vECstar);
    disp('[INFO] LoadMFDSettings: Network-wide MFD data loaded.');
else
    error('LoadMFDSettings: Network MFD file not found: %s', networkMFDFile);
end

% --- Load Region-Specific MFDs ---
TFC.Ri = struct('funGn', {}, 'nci', {}, 'njam', {}, 'Gmi', {}, 'ECv', {}, 'Vn', {}, 'vECstar', {}, 'ssECv', {}, 'ri', {});
nci_vec = [];

for layer = 1:numLayers
    for i = 1:length(regionIndices)
        regionTypeID = regionIndices(i);
        
        % The file name corresponds to the region's type ID (e.g., 1 for center, 2 for periphery)
        regionMFDFile = [public_dir, '/MFD_mat_data/MFD_VTOL_Func_Ri', num2str(regionTypeID), '_Ide6_1Hr.mat'];
        
        if exist(regionMFDFile, 'file')
            load(regionMFDFile, 'Func');
            regionIndex = (layer-1)*numRegions + i;
            TFC.Ri(regionIndex).ri = layer * Settings.Airspace.Regions.dzri + regionTypeID;
            TFC.Ri(regionIndex).funGn = Func.Gn;
            TFC.Ri(regionIndex).nci = Func.nG_star;
            TFC.Ri(regionIndex).njam = Func.nG_min;
            TFC.Ri(regionIndex).Gmi = TFC.Ri(regionIndex).funGn(Func.nG_star);
            TFC.Ri(regionIndex).ECv = @(x)((20./Func.ECvAlpha(1)).*(exp(-x./Func.ECvAlpha(3))+Func.ECvAlpha(2)));
            TFC.Ri(regionIndex).Vn = @(x)((Func.VnAlpha(6)./Func.VnAlpha(1)).*(exp(-Func.VnAlpha(2).*((x./Func.VnAlpha(5)).^Func.VnAlpha(3)))+Func.VnAlpha(4)));
            TFC.Ri(regionIndex).vECstar = round(1.2*Func.vEC_min,1);
            TFC.Ri(regionIndex).ssECv = TFC.Ri(regionIndex).ECv(TFC.Ri(regionIndex).vECstar);
            nci_vec(end+1) = Func.nG_star;
            disp(['[INFO] LoadMFDSettings: MFD data for Layer ', num2str(layer), ', Region Type ID ', num2str(regionTypeID), ' loaded.']);
        else
            error('LoadMFDSettings: MFD file for Region Type ID %d not found: %s.', regionTypeID, regionMFDFile);
        end
    end
end

% Consolidate critical densities for easier access
TFC.nci = nci_vec;

end
