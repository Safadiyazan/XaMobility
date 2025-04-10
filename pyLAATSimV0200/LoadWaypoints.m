% LoadWaypoints - Loads waypoint paths from a specified directory.
%
% Syntax:
%   [WaypointPaths] = LoadWaypoints(asStr, public_dir)
%
% Inputs:
%   asStr      - A string or parameter specifying the waypoint data to load.
%   public_dir - The directory path where waypoint files are stored.
%
% Outputs:
%   WaypointPaths - A structure or array containing the loaded waypoint paths.
%
% Description:
%   This function reads waypoint data from the specified directory and
%   returns the paths in a structured format. The input 'asStr' determines
%   the specific waypoints to load, and 'public_dir' specifies the base
%   directory containing the waypoint files.
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