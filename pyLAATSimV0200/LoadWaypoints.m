%LoadWaypoints Loads predefined waypoint paths from a JSON file.
%   This function reads a JSON file containing a set of fixed flight paths,
%   where each path is defined by a sequence of waypoints. This is used for
%   scenarios with structured routes, such as flights along predefined
%   air corridors.
%
%   The function performs the following steps:
%   1. Selects the appropriate JSON file based on the airspace string (`asStr`).
%   2. Reads and decodes the JSON file.
%   3. Iterates through each path in the JSON data and converts the sequence
%      of points into a matrix of waypoints.
%   4. Returns a cell array where each cell contains a matrix representing one flight path.
%
% Inputs:
%   asStr      - (string) A string identifier for the airspace (e.g., 'LI').
%   public_dir - (string) The path to the public data directory.
%
% Outputs:
%   WaypointPaths - (cell array) A cell array where each cell contains an M-by-3 matrix of waypoints for a specific path.
%
% Author: Yazan Safadi
% Date Created: 2025-03-27
function [WaypointPaths] = LoadWaypoints(asStr, public_dir)
switch asStr
    case 'LI'
        jsonFilePath = [public_dir '/Waypoints/FixedWaypointSettings_V3_LI.json'];
    otherwise
        error('error in loading waypoint json')
end
jsonText = fileread(jsonFilePath);
pathData = jsondecode(jsonText);
WaypointPaths = {};
for i = 1:length(pathData)
    pathStruct = pathData(i);
    points = pathStruct.path_points;
    numPoints = length(points);
    pathMatrix = zeros(numPoints, 3);
    for j = 1:numPoints
        point = points(j);
        pathMatrix(j, :) = [point.neuDistances.east, point.neuDistances.north, point.neuDistances.up];
    end
    pathMatrix = max(0,pathMatrix);
    WaypointPaths{i} = pathMatrix;
end
end