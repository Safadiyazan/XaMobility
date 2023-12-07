function [file_name] = ExportJSON(SimInfo,ObjAircraft,TFC,EC,Settings)
M = SimInfo.M(end);
full_pdt = full(SimInfo.pdt)';
ObjAircraftData = cell(1, M);
for i = 1:M
    x = double(full_pdt(3*i-2, :));
    y = double(full_pdt(3*i-1, :));
    z = double(full_pdt(3*i, :));
    ObjAircraftData{i} = struct('tda',max(ObjAircraft(i).tdp,0),'taa',min(ObjAircraft(i).taa,SimInfo.tf),'x', x, 'y', y, 'z', z);
end
json_data = struct('ObjAircraft', ObjAircraftData);
json_str = jsonencode(json_data);
file_name = ['./public/Outputs/' 'SimOutput_ObjAircraft_' datestr(now,'yyyymmdd_hhMMss')  '.json']; % datestr(now,'yyyymmdd_hhMMss')
fid = fopen(file_name, 'w');
if fid > 0
    fwrite(fid, json_str, 'char');
    fclose(fid);
    disp(['Data saved to ' file_name]);
else
    disp('Error opening the file for writing.');
end
end


