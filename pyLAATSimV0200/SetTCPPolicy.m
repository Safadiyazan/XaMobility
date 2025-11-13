%SetTCPPolicy Configures the active Traffic Control Policy (TCP) for the simulation.
%   This function acts as a high-level switch to select which traffic
%   management strategy will be active during a simulation run. It sets flags
%   and parameters within the TFC (Traffic Flow Characteristics) structure
%   that are used by other functions to dispatch the correct control logic.
%
%   The function defines:
%   1. The active policy type (e.g., Departure/Boundary Control, Speed Control).
%   2. The controller type (e.g., Greedy Controller, Model Predictive Control).
%   3. The specific weighting strategy for MPC, if applicable.
%
% Inputs:
%   TFC - (struct) The main Traffic Flow Characteristics data structure.
%
% Outputs:
%   TFC - (struct) The updated TFC structure with policy flags and parameters set.
function [TFC] = SetTCPPolicy(TFC)

% --- Define Active TCP Policy ---
% Policy 1: Departure/Boundary Control (DBC)
% Policy 2: Speed Control
% Policy 3: Route Guidance
% Controller: 1-GC, 2-MPC
TFC.TCPolicy = 1;
TFC.TCPolicy_Controller = 2;

% --- Set Controller Flags ---
TFC.TCP_DBController_GC = (TFC.TCPolicy == 1) && (TFC.TCPolicy_Controller == 1);
TFC.TCP_DBController_MPC = (TFC.TCPolicy == 1) && (TFC.TCPolicy_Controller == 2);
TFC.TCP_SpeedController_GC = (TFC.TCPolicy == 2) && (TFC.TCPolicy_Controller == 1);
TFC.TCP_SpeedController_MPC = (TFC.TCPolicy == 2) && (TFC.TCPolicy_Controller == 2);
TFC.TCP_RouteGuidance_GC = (TFC.TCPolicy == 3) && (TFC.TCPolicy_Controller == 1);
TFC.TCP_RouteGuidance_MPC = (TFC.TCPolicy == 3) && (TFC.TCPolicy_Controller == 2);
if TFC.TCP_RouteGuidance_GC || TFC.TCP_RouteGuidance_MPC
    error('TODO: Route Guidance is still under developement')
end

% --- Common Controller Settings ---
TFC.TCP_BoundaryUpPolicyStr = 'FirstDeparted'; % MaxTL | MinTLDone | MinTLLeft | MaxTLLeft | FirstDeparted
TFC.MPCSim = [];

% --- MPC General Settings ---
TFC.dtMPC = TFC.dtC;
TFC.Np = 5;
TFC.NMPC = TFC.dtMPC * TFC.Np;

% --- MPC Weighting Strategy ---
% Select the weighting strategy for MPC controllers.
% Options: 'DBC', 'DC', 'BC', 'POESpeed', 'POSpeed', 'PESpeed', 'MPCSpeed', etc.
WeightingStrategy = 'DBC';
if TFC.TCP_DBController_MPC
    if ismember(WeightingStrategy, {'DBC', 'DC', 'BC'})
        disp('[INFO] Setting Weight Match Control Strategy')
    else
        error('[INFO] Setting Weight Does Not Match Control Strategy')
    end
end
if TFC.TCP_SpeedController_MPC
    if ismember(WeightingStrategy, {'POESpeed', 'POSpeed', 'PESpeed', 'MPCSpeed'})
        disp('[INFO] Setting Weight Match Control Strategy')
    else
        error('[INFO] Setting Weight Does Not Match Control Strategy')
    end
end

disp(['[INFO] SetTCPPolicy: Active TCP Policy: ', num2str(TFC.TCPolicy)]);
disp(['[INFO] SetTCPPolicy: MPC Weighting Strategy: ', WeightingStrategy]);

% --- Configure MPC Weights based on Strategy ---
if TFC.TCP_DBController_MPC || TFC.TCP_SpeedController_MPC
    TFC = SetMPCWeights(TFC, WeightingStrategy);
end

TFC.udi = [0,1];
TFC.ubij = [0,1];
TFC.uvij = [0,1];

end

function TFC = SetMPCWeights(TFC, StrCase)
% Extracts critical densities for the first two regions for weighting
% This is now generalized for any number of regions in the first layer.
numRegions = numel(TFC.nci) / (numel(TFC.Ri) / numel(unique(mod([TFC.Ri.ri], 100)))); % Simplified way to get regions per layer

% Assuming MPC works on the first layer's regions for now.
% This can be adapted if MPC needs to control multiple layers.
nc1 = TFC.Ri(1).nci; % First region of the first layer
nc2 = TFC.Ri(2).nci; % Second region of the first layer
nc = nc1 + nc2;

ssECv1 = TFC.Ri(1).ssECv; % First region of the first layer
ssECv2 = TFC.Ri(2).ssECv; % Second region of the first layer

switch StrCase
    case 'DBC'
        % a = [0.6211    0.3789         0]; % V3 DC
        % a = [0.4539         0    0.5461]; % V3 BC
        % a = [0.4379    0.1374    0.4247]; % V3 DBC
        % a = [0.7406    0.2594         0]; % V4 DC
        % a = [0.5495         0    0.4505]; % V4 BC
        a = [0.2742    0.1631    0.5627]; % V4 DBC
        nc1 = 33.6753;%TFC.nci(3);
        nc2 = 135.9900;%TFC.nci(4);
        nc = nc1 + nc2;
        WnijT = a(1).*[1/nc,1/nc,1/nc,1/nc]./4 ; % 4 values
        Wni = [0,0]; % 2 values
        Wndqi = [0,0]; % 2 values
        Wnbqih = [0,0]; % 2 values
        Wud = a(2).*[nc1,nc2]; % 2 values
        WubIN = a(3).*[nc,nc]; % 2 values
        WubOUT = a(3).*[nc,nc]; % 2 values
        TFC.Omega = [WnijT, Wni, Wndqi, Wnbqih, Wud, WubIN, WubOUT];
    case 'DC'
        a = [0.7406    0.2594         0]; % V4 DC
        nc1 = 33.6753;%TFC.nci(3);
        nc2 = 135.9900;%TFC.nci(4);
        nc = nc1 + nc2;
        WnijT = a(1).*[1/nc,1/nc,1/nc,1/nc]./4 ; % 4 values
        Wni = [0,0]; % 2 values
        Wndqi = [0,0]; % 2 values
        Wnbqih = [0,0]; % 2 values
        Wud = a(2).*[nc1,nc2]; % 2 values
        WubIN = a(3).*[nc,nc]; % 2 values
        WubOUT = a(3).*[nc,nc]; % 2 values
        TFC.Omega = [WnijT, Wni, Wndqi, Wnbqih, Wud, WubIN, WubOUT];
    case 'BC'
        a = [0.5495         0    0.4505]; % V4 BC
        nc1 = 33.6753;%TFC.nci(3);
        nc2 = 135.9900;%TFC.nci(4);
        nc = nc1 + nc2;
        WnijT = a(1).*[1/nc,1/nc,1/nc,1/nc]./4 ; % 4 values
        Wni = [0,0]; % 2 values
        Wndqi = [0,0]; % 2 values
        Wnbqih = [0,0]; % 2 values
        Wud = a(2).*[nc1,nc2]; % 2 values
        WubIN = a(3).*[nc,nc]; % 2 values
        WubOUT = a(3).*[nc,nc]; % 2 values
        TFC.Omega = [WnijT, Wni, Wndqi, Wnbqih, Wud, WubIN, WubOUT];
    case 'MPCSpeed'
        a = [1/3, 1/3, 1/3];
        wEi = a(1) * [1, 1];
        Wni = a(2) * [ssECv1/((nc1)^2), ssECv2/((nc2)^2)];
        TFC.Omega = [wEi, Wni, zeros(1,4)];

    case 'POESpeed'
        a = [0.1699, 0.3430, 0.4871]; % POE Optimal
        wEi = a(1) * [1, 1];
        Wni = a(2) * [ssECv1/((nc1)^2), ssECv2/((nc2)^2)];
        WuV = a(3) * [ssECv1, ssECv1, ssECv2, ssECv2];
        TFC.Omega = [wEi, Wni, WuV];

    case 'POSpeed'
        a = [0, 0.5466, 0.4534]; % PO Optimal
        wEi = a(1) * [1, 1];
        Wni = a(2) * [ssECv1/((nc1)^2), ssECv2/((nc2)^2)];
        WuV = a(3) * [ssECv1, ssECv1, ssECv2, ssECv2];
        TFC.Omega = [wEi, Wni, WuV];

    case 'PESpeed'
        a = [0.2585, 0, 0.7415]; % PE Optimal
        wEi = a(1) * [1, 1];
        Wni = a(2) * [ssECv1/((nc1)^2), ssECv2/((nc2)^2)];
        WuV = a(3) * [ssECv1, ssECv1, ssECv2, ssECv2];
        TFC.Omega = [wEi, Wni, WuV];

    otherwise
        warning('SetMPCWeights: Omega case "%s" not recognized. Using default weights.', StrCase);
        TFC.Omega = ones(1, 16); % Default fallback
end
disp(['[INFO] SetMPCWeights: MPC Omega weights configured for case: ', StrCase]);
end
