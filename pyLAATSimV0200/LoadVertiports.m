function [VertiportOD,MaxXY] = LoadVertiports()
jsonFilePath = '../public/FixedVertiportsSettings.json';
jsonText = fileread(jsonFilePath);
vertiportData = jsondecode(jsonText);
for i=1:size(vertiportData)
    firstVertiport = vertiportData(i);
    VertiportOD(i,1:3) = [firstVertiport.neuDistances.east, firstVertiport.neuDistances.north, firstVertiport.height];
end
MaxXY = max(max(abs(VertiportOD(:,1))), max(abs(VertiportOD(:,2))));
MaxXY = 500*ceil(MaxXY/500);
end