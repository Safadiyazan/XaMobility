% LoadVertiports - Loads vertiport data and computes related parameters.
%
% Syntax:
%   [VertiportOD, MaxXY, minDz1] = LoadVertiports(asStr, public_dir)
%
% Inputs:
%   asStr      - A string input specifying the configuration or data source.
%   public_dir - A string specifying the directory path to public data.
%
% Outputs:
%   VertiportOD - Output data structure or matrix containing vertiport information.
%   MaxXY       - Maximum X and Y coordinates of the loaded vertiports.
%   minDz1      - Minimum vertical displacement or related parameter.
%
% Description:
%   This function processes the input parameters to load vertiport data
%   from the specified directory and computes additional parameters such
%   as maximum X/Y coordinates and minimum vertical displacement.
%
% Author: Yazan Safadi
% Date Created: 2024-07-05
function [VertiportOD,MaxXY,minDz1] = LoadVertiports(asStr, public_dir)

switch asStr
    case 'NYC'
        jsonFilePath = [public_dir '/Vertiports/FixedVertiportsSettings_V2_NYC.json'];
        minDz1 = 400;
    case 'NYC-Archer-United'
        jsonFilePath = [public_dir '/Vertiports/FixedVertiportsSettings_V1_NYC_Archer_United.json'];
        minDz1 = 400;
    case 'SF'
        jsonFilePath = [public_dir '/Vertiports/FixedVertiportsSettings_V1_SF.json'];
        minDz1 = 40;
    case 'PAR'
        jsonFilePath = [public_dir '/Vertiports/FixedVertiportsSettings_V1_PAR.json'];
        minDz1 = 40;
    case 'HK'
        jsonFilePath = [public_dir '/Vertiports/FixedVertiportsSettings_V1_HK.json'];
        minDz1 = 40;
    case 'LI'
        jsonFilePath = [public_dir '/Vertiports/FixedVertiportsSettings_V4_LI.json'];
        minDz1 = 40;
    otherwise
        error('error in loading vertiport json')
end
jsonText = fileread(jsonFilePath);
vertiportData = jsondecode(jsonText);
for i=1:size(vertiportData)
    firstVertiport = vertiportData(i);
    VertiportOD(i,1:3) = [firstVertiport.neuDistances.east, firstVertiport.neuDistances.north, firstVertiport.height+2];
end
MaxXY = max(max(abs(VertiportOD(:,1))), max(abs(VertiportOD(:,2))));
MaxXY = 500*ceil(MaxXY/500);
end