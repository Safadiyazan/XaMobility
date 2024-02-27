function [scenarioName] = ExportJSONPed()%SceStr,SimInfo,ObjAircraft,TFC,EC,Settings)
M = 100; % Pedestrain %SimInfo.M(end);
% full_pdt = full(SimInfo.pdt)';
% full_stat = full(SimInfo.statusdt)';
% ObjAircraftData = cell(1, M);
dtS = 0.5; % seconds
tf = 600; % seconds
hd = 4; % meters
ht = 2; % seconds
vped = 1.5; % m/s
xf = 100;
for i = 1:M
    clear stat x y z tda taa vt
    stat = 0;
    x = 0;
    y = 0;
    z = 0;
    vt = 0;
    for dt=2:1:tf/dtS
        x(dt) =  x(dt-1) + (dt/dtS)*vt(dt-1); % (i-1)*hd + headway + x0 + dt*V % double(full_pdt(3*i-2, :));
        y(dt) = 0; % double(full_pdt(3*i-1, :));
        z(dt) = 0; % double(full_pdt(3*i, :));
        tda = (i-1)*ht;
        if (dt/dtS)>tda
            vt(dt) = vped;
            stat(dt) = 1; %(i-1)*ht; % double(full_stat(i, :));
        else
            stat(dt) = 0;
        end
        if x(dt)>=xf
            if taa ==0
            taa = dt;
            end
            vt(dt) = 0;
        else 
            taa = 0;
        end
        if taa>0
            stat(dt) = 2;
        end
    end
    ObjAircraftData{i} = struct(...
        'stat', stat,...
        'tda', tda,...%max(ObjAircraft(i).tdp,0),...
        'taa', taa,...%min(ObjAircraft(i).taa,SimInfo.tf),...
        'rs', 2,... %ObjAircraft(i).rs,...
        'rd', 5,... %ObjAircraft(i).rd,...
        'x', x,...
        'y', y,...
        'z', z...
        );
end

Data.TFC = [];%TFC;
Data.SimInfo.tf = tf;%SimInfo.tf;
Data.SimInfo.dtS = dtS;%SimInfo.dtS;
Data.SimInfo.dtM = 60;%SimInfo.dtM;
Data.Settings.dx = 100;%Settings.Airspace.dx;
Data.Settings.dy = 20;%Settings.Airspace.dy;
Data.Settings.dz = 0;%Settings.Airspace.dz;
Data.Settings.as = Settings.Airspace.as;

Data.ObjAircraft = ObjAircraftData;

json_str = jsonencode(Data);
% TimestampNow = now;
% scenarioName = [SceStr ' '  datestr(TimestampNow,'yyyy-mm-dd HH:MM')];
% file_name = ['./public/Outputs/' 'SimOutput_' SceStr '_'  datestr(TimestampNow,'yyyymmdd_hhMM') '.json']; % datestr(now,'yyyymmdd_hhMMss')
file_name = ['PedTesting.json'];
fid = fopen(file_name, 'w');
if fid > 0
    fwrite(fid, json_str, 'char');
    fclose(fid);
    disp(['Data saved to ' file_name]);
else
    disp('Error opening the file for writing.');
end
end


