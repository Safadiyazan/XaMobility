function [scenarioName] = ExportJSON(SceStr,SimInfo,ObjAircraft,TFC,Settings)
M = SimInfo.M(end); % number of aircraft
full_pdt = full(SimInfo.pdt)'; % tranform position matrix
full_stat = full(SimInfo.statusdt)'; % transform status matrix
ObjAircraftData = cell(1, M);
for i = 1:M
    x = double(full_pdt(3*i-2, :)); % x position [m]
    y = double(full_pdt(3*i-1, :)); % y position [m]
    z = double(full_pdt(3*i, :)); % z position [m]
    stat = double(full_stat(i, :));  % aircraft flight staus {0-inactive, 1-active, 2-arrived}
    ObjAircraftData{i} = struct(...
    'AMI', ObjAircraft(i).AMI,...
    'stat', stat,...
    'tda',max(ObjAircraft(i).tdp,0),... % aircraft departure time [s]
    'taa',min(ObjAircraft(i).taa,SimInfo.tf),... % aircraft arrival time [s]
    'rs',ObjAircraft(i).rs,... % aircraft safety radius [m]
    'rd',ObjAircraft(i).rd,... % aircraft detection radius [m]
    'x', x,...
    'y', y,...
    'z', z...
    );
end
Data.TFC = TFC;
Data.SimInfo.tf = SimInfo.tf; % simulation final time [s]
Data.SimInfo.dtS = SimInfo.dtS; % simulation time step [s]
Data.SimInfo.dtM = SimInfo.dtM;
Data.Settings.dx = Settings.Airspace.dx; % Airspace x-axis size [m]
Data.Settings.dy = Settings.Airspace.dy; % Airspace y-axis size [m]
Data.Settings.dz = Settings.Airspace.dz; % Airspace z-axis size [m]
Data.Settings.asStr = Settings.Airspace.asStr; % Airspace config
Data.Settings.Airspace = Settings.Airspace; % Airspace x-axis size [m]

Data.ObjAircraft = ObjAircraftData;


json_str = jsonencode(Data);
TimestampNow = now;
scenarioName = [SceStr ' '  datestr(TimestampNow,'yyyy-mm-dd HH:MM')];
file_name = [SceStr '_'  datestr(TimestampNow,'yyyymmdd_hhMM') '.json']; % datestr(now,'yyyymmdd_hhMMss')
fid = fopen(file_name, 'w');
if fid > 0
    fwrite(fid, json_str, 'char');
    fclose(fid);
    disp(['Data saved to ' file_name]);
else
    disp('Error opening the file for writing.');
end
end


