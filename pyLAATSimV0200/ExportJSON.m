% ExportJSON - Exports simulation data to a JSON file.
%
% Syntax:
%   [scenarioName] = ExportJSON(SceStr, SimInfo, ObjAircraft, TFC, Settings)
%
% Inputs:
%   SceStr      - Structure containing scenario data.
%   SimInfo     - Structure containing simulation information.
%   ObjAircraft - Object or structure representing aircraft data.
%   TFC         - Traffic data or related structure.
%   Settings    - Structure containing export settings and configurations.
%
% Outputs:
%   scenarioName - Name of the exported scenario file.
%
% Description:
%   This function takes simulation data, including scenario details,
%   simulation information, aircraft objects, traffic data, and settings,
%   and exports it to a JSON file. The function returns the name of the
%   exported scenario file.
%
% Author: Yazan Safadi
% Date Created: 2023-02-08
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
scenarioName = [SceStr '_'  datestr(TimestampNow,'yyyy-mm-dd HH:MM')];
file_name = [SceStr '_'  datestr(TimestampNow,'yyyymmdd_hhMM') '.json'];
fid = fopen(file_name, 'w');
if fid > 0
    fwrite(fid, json_str, 'char');
    fclose(fid);
    disp(['[INFO] ExportJSON: Data saved to ', file_name]);
else
    disp('[ERROR] ExportJSON: Error opening file for writing.');
end
end
