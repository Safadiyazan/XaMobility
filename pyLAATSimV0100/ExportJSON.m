function [scenarioName] = ExportJSON(SceStr,SimInfo,ObjAircraft,TFC,EC,Settings)
M = SimInfo.M(end);
full_pdt = full(SimInfo.pdt)';
full_stat = full(SimInfo.statusdt)';
ObjAircraftData = cell(1, M);
for i = 1:M
    x = double(full_pdt(3*i-2, :));
    y = double(full_pdt(3*i-1, :));
    z = double(full_pdt(3*i, :));
    stat = double(full_stat(i, :));
    ObjAircraftData{i} = struct(...
    'stat', stat,...
    'tda',max(ObjAircraft(i).tdp,0),...
    'taa',min(ObjAircraft(i).taa,SimInfo.tf),...
    'rs',ObjAircraft(i).rs,...
    'rd',ObjAircraft(i).rd,...
    'x', x,...
    'y', y,...
    'z', z...
    );
end
Data.TFC = TFC;
Data.SimInfo.tf = SimInfo.tf;
Data.SimInfo.dtS = SimInfo.dtS;
Data.SimInfo.dtM = SimInfo.dtM;
Data.Settings.dx = Settings.Airspace.dx;
Data.Settings.dy = Settings.Airspace.dy;
Data.Settings.dz = Settings.Airspace.dz;
Data.Settings.as = Settings.Airspace.as;

Data.ObjAircraft = ObjAircraftData;


json_str = jsonencode(Data);
TimestampNow = now;
scenarioName = [SceStr ' '  datestr(TimestampNow,'yyyy-mm-dd HH:MM')];
file_name = ['./public/Outputs/' 'SimOutput_' SceStr '_'  datestr(TimestampNow,'yyyymmdd_hhMM') '.json']; % datestr(now,'yyyymmdd_hhMMss')
fid = fopen(file_name, 'w');
if fid > 0
    fwrite(fid, json_str, 'char');
    fclose(fid);
    disp(['Data saved to ' file_name]);
else
    disp('Error opening the file for writing.');
end
end


