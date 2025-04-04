function [WaypointPaths] = LoadWaypoints(asStr)
switch asStr
    case 'LI'
        jsonFilePath = '../public/Waypoints/FixedWaypointSettings_V3_LI.json';
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