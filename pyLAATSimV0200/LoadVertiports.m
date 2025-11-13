%LoadVertiports Loads vertiport location data from a JSON file.
%   This function reads a JSON file containing the coordinates and other
%   data for a set of vertiports corresponding to a specific urban area.
%   It is used to set up simulations where aircraft operate between
%   predefined vertiport locations.
%
%   The function performs the following steps:
%   1. Selects the appropriate JSON file based on the airspace string (`asStr`).
%   2. Reads and decodes the JSON file.
%   3. Extracts the East, North, and Up (height) coordinates for each vertiport.
%   4. Calculates the maximum X/Y extent of the vertiport network, which is
%      used to set the airspace dimensions.
%
% Inputs:
%   asStr      - (string) A string identifier for the airspace (e.g., 'NYC', 'SF').
%   public_dir - (string) The path to the public data directory.
%
% Outputs:
%   VertiportOD - (matrix) An N-by-3 matrix of vertiport coordinates [East, North, Up].
%   MaxXY       - (numeric) The maximum absolute coordinate value, used to size the airspace.
%   minDz1      - (numeric) The minimum flight altitude for the given airspace.
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
        disp(['[ERROR] LoadVertiports: Invalid asStr ''', asStr, '''. Error loading vertiport JSON.']);
        error(['Invalid asStr ''', asStr, '''.']);
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