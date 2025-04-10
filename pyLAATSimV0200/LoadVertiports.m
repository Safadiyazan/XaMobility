function [VertiportOD,MaxXY,minDz1] = LoadVertiports(asStr, public_dir)

switch asStr
    case 'NYC'
        jsonFilePath = [public_dir '/Vertiports/FixedVertiportsSettings_V2_NYC.json'];
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