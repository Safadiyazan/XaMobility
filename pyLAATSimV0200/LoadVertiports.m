function [VertiportOD,MaxXY,minDz1] = LoadVertiports(asStr)
switch asStr
    case 'NYC'
        jsonFilePath = '../public/FixedVertiportsSettings_V2_NYC.json';
        minDz1 = 400;
    case 'SF'
        jsonFilePath = '../public/FixedVertiportsSettings_V1_SF.json';
        minDz1 = 0;
    case 'PAR'
        jsonFilePath = '../public/FixedVertiportsSettings_V1_PAR.json';
        minDz1 = 0;
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