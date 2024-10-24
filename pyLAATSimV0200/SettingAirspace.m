function [Airspace] = SettingAirspace(dx,dy,dz,asStr)
Airspace.asStr = asStr;
if ismember(asStr, {'Subset', 'VTOL'})
    Airspace.Vertiports = 0;
else
    Airspace.Vertiports = 1;
end

if Airspace.Vertiports
    [VertiportOD,MaxXY,minDz1] = LoadVertiports(asStr);
    Airspace.dx = MaxXY*2; % width [m]
    Airspace.dy = MaxXY*2; % length [m]
    Airspace.dz = dz;%Airspace.dz2-Airspace.dz1;  % height [m]
    Airspace.dz1 = minDz1;  % start at height [m]
else
    Airspace.dx = dx; % width [m]
    Airspace.dy = dy; % length [m]
    Airspace.dz = dz;%Airspace.dz2-Airspace.dz1;  % height [m]
    Airspace.dz1 = 30;  % start at height [m]
end
Airspace.dz2 = dz+Airspace.dz1; % end at height [m]
Airspace.xyz = [[-Airspace.dx;Airspace.dx]/2,[-Airspace.dy;Airspace.dy]/2,[[Airspace.dz1;Airspace.dz1]+[0;Airspace.dz]]];
Airspace.Space = Airspace.dx*Airspace.dy*Airspace.dz;
%% Pads heights
if ismember(asStr, {'Subset'})
    Airspace.VTOL = 0;
    Airspace.SubsetNetwork = 1;
else
    Airspace.VTOL = 1;
    Airspace.SubsetNetwork = 0;
end
if Airspace.VTOL
    Airspace.z01 = 0; % for takeoff and landing [m]
    Airspace.z02 = Airspace.dz1; % for takeoff and landing [m]
    Airspace.VTOLxyz = [[-Airspace.dx;Airspace.dx]/2,[-Airspace.dy;Airspace.dy]/2,[Airspace.z01;Airspace.z02]];
else
    Airspace.z01 = 0; % for takeoff and landing [m]
    Airspace.z02 = Airspace.dz1; % for takeoff and landing [m]
    Airspace.VTOLxyz = [[-Airspace.dx;Airspace.dx]/2,[-Airspace.dy;Airspace.dy]/2,[Airspace.z01;Airspace.z02]];
end
%% TODO: TLOF
%% function for regions boundaries
Airspace.RMode='2R';
if Airspace.VTOL
    if Airspace.RMode=='2R'
        [Airspace.Regions,Airspace.Layers] = SettingAirspaceRegionsVTOL2R(Airspace);
    else
        [Airspace.Regions,Airspace.Layers] = SettingAirspaceRegionsVTOL(Airspace);
    end
else
    if Airspace.RMode=='2R'
        [Airspace.Regions,Airspace.Layers] = SettingAirspaceRegions2R(Airspace);
    else
        [Airspace.Regions,Airspace.Layers] = SettingAirspaceRegions(Airspace);
    end
end
warning('TODO: add multi-layer 5L with emergcnacy layer!')
%% TODO: Wind settings
%% TODO: Obstacles settings
%% TODO: Highway settings

end

function [Ri,Li] = SettingAirspaceRegions(Airspace)
Ri.xn = 3;
Ri.yn = 3;
Ri.zn = 2;
Ri.Dx = Airspace.dx/Ri.xn;
Ri.Dy = Airspace.dy/Ri.yn;
Ri.Dz = (Airspace.dz)/Ri.zn;
Ri.n = Ri.xn*Ri.yn*Ri.zn;
Ri.nxy = Ri.xn*Ri.yn;
Ri.dzri = 10; while (Ri.dzri<=Ri.xn*Ri.yn);  Ri.dzri=Ri.dzri*10; end
% Ri.dzri = 0; while (Ri.dzri<=Ri.xn*Ri.yn);  Ri.dzri=Ri.dzri*10; end
ri = 0;
xyz = [];
for zi=1:Ri.zn
    Layer = zi;
    for yi=1:Ri.yn
        for xi=1:Ri.xn
            ri = ri + 1;
            xyz = [-Airspace.dx/2 + Ri.Dx*(xi-1); -Airspace.dx/2 + Ri.Dx*xi];
            xyz = [xyz,[-Airspace.dy/2 + Ri.Dy*(yi-1); -Airspace.dy/2 + Ri.Dy*yi]];
            %             xyz = [xyz,2.*[AirspaceS.dz1;AirspaceS.dz1]+[-AirspaceS.dz/2 + Ri.Dz*(zi-1);-AirspaceS.dz/2 + Ri.Dz*zi]];
            xyz = [xyz,[Airspace.dz1;Airspace.dz1]+[(Ri.Dz)*(zi-1);(Ri.Dz)*zi]];
            %             Ri.B(ri).ri = ri;
            if (ri==1); Ri.B(ri).ri = ri + zi*Ri.dzri; else; Ri.B(ri).ri =  mod(mod(Ri.B(ri-1).ri,Ri.dzri),Ri.xn*Ri.yn) + zi*Ri.dzri + 1; end
            Ri.B(ri).xyz = xyz;
            Ri.B(ri).center = (xyz(1,:) + xyz(2,:)) / 2;
            Ri.B(ri).dx = Ri.Dx; Ri.B(ri).dy = Ri.Dy; Ri.B(ri).dz = Ri.Dz;
            Ri.B(ri).ssize = abs(xyz(1,:) - xyz(2,:));
            Ri.B(ri).space = Ri.B(ri).ssize(1)*Ri.B(ri).ssize(2)*Ri.B(ri).ssize(3);
            Ri.B(ri).layer = Layer;
            if (mod(zi,2)==0)
                Ri.B(ri).Buffer = 1;
            else
                Ri.B(ri).Buffer = 0;
            end
            xyz = [];
        end
    end
    Li(zi).center = [0,0,(Airspace.dz1+(Ri.Dz)*(zi-1)+Airspace.dz1+(Ri.Dz)*zi)/2]; % DOUBLE - CHECK
    Li(zi).dx = Airspace.dx; Li(zi).dy = Airspace.dy; Li(zi).dz = Ri.Dz;
    if (mod(zi,2)==0)
        Ri.Buffer((zi/2)+1).layer = Layer;
        Ri.Buffer((zi/2)+1).xyz = [[-Airspace.dx;Airspace.dx]/2,[-Airspace.dy;Airspace.dy]/2,[Airspace.dz1;Airspace.dz1]+[(Ri.Dz)*(zi-1);(Ri.Dz)*zi]];
    end
end
end

function [Ri,Li] = SettingAirspaceRegions2R(Airspace)
Ri.xn = 3;
Ri.yn = 3;
Ri.zn = 2;
Ri.Dx = Airspace.dx/Ri.xn;
Ri.Dy = Airspace.dy/Ri.yn;
Ri.Dz = (Airspace.dz)/(Ri.zn);
Ri.n = Ri.xn*Ri.yn*Ri.zn;
Ri.nxy = 2;%Ri.xn*Ri.yn;
Ri.dzri = 10; while (Ri.dzri<=Ri.xn*Ri.yn);  Ri.dzri=Ri.dzri*10; end
ri = 0;
Ri.Buffer = [];
xyz = [];
% Airspace Regions
for zi=1:Ri.zn
    Layer = zi;
    for yi=1:Ri.yn
        for xi=1:Ri.xn
            ri = ri + 1;
            xyz = [-Airspace.dx/2 + Ri.Dx*(xi-1); -Airspace.dx/2 + Ri.Dx*xi];
            xyz = [xyz,[-Airspace.dy/2 + Ri.Dy*(yi-1); -Airspace.dy/2 + Ri.Dy*yi]];
            %             xyz = [xyz,2.*[AirspaceS.dz1;AirspaceS.dz1]+[-AirspaceS.dz/2 + Ri.Dz*(zi-1);-AirspaceS.dz/2 + Ri.Dz*zi]];
            xyz = [xyz,[Airspace.dz1;Airspace.dz1]+[(Ri.Dz)*(zi-1);(Ri.Dz)*zi]];
            if (ri==1); Ri.B(ri).ri = ri + zi*Ri.dzri; else; Ri.B(ri).ri =  mod(mod(Ri.B(ri-1).ri,Ri.dzri),Ri.xn*Ri.yn) + zi*Ri.dzri + 1; end
            Ri.B(ri).xyz = xyz;
            Ri.B(ri).center = (xyz(1,:) + xyz(2,:)) / 2;
            Ri.B(ri).dx = Ri.Dx; Ri.B(ri).dy = Ri.Dy; Ri.B(ri).dz = Ri.Dz;
            Ri.B(ri).ssize = abs(xyz(1,:) - xyz(2,:));
            Ri.B(ri).space = Ri.B(ri).ssize(1)*Ri.B(ri).ssize(2)*Ri.B(ri).ssize(3);
            Ri.B(ri).layer = Layer;
            if (mod(zi,2)==0)
                Ri.B(ri).Buffer = 1;
            else
                Ri.B(ri).Buffer = 0;
            end
            xyz = [];
            if abs(Ri.B(ri).center(1:2) - [0,0]) < [10^-4,10^-4]
                Ri.B(ri).ri = Ri.B(ri).ri - mod(Ri.B(ri).ri,Ri.dzri) + 1;% mod(Ri.B(ri).ri,Ri.dzri)
            else
                Ri.B(ri).ri = Ri.B(ri).ri - mod(Ri.B(ri).ri,Ri.dzri) + 2;
            end
        end
    end
    Li(zi).center = [0,0,(Airspace.dz1+(Ri.Dz)*(zi-1)+Airspace.dz1+(Ri.Dz)*zi)/2]; % DOUBLE - CHECK
    Li(zi).dx = Airspace.dx; Li(zi).dy = Airspace.dy; Li(zi).dz = Ri.Dz;
    if (mod(zi,2)==0)
        Ri.Buffer((zi/2)+1).layer = Layer;
        Ri.Buffer((zi/2)+1).xyz = [[-Airspace.dx;Airspace.dx]/2,[-Airspace.dy;Airspace.dy]/2,[Airspace.dz1;Airspace.dz1]+[(Ri.Dz)*(zi-1);(Ri.Dz)*zi]];
    end
end
end

function [Ri,Li] = SettingAirspaceRegionsVTOL(Airspace)
Ri.xn = 3;
Ri.yn = 3;
Ri.zn = 2;
Ri.Dx = Airspace.dx/Ri.xn;
Ri.Dy = Airspace.dy/Ri.yn;
Ri.Dz = (Airspace.dz)/(Ri.zn-1);
Ri.n = Ri.xn*Ri.yn*Ri.zn;
Ri.nxy = Ri.xn*Ri.yn;
Ri.dzri = 10; while (Ri.dzri<=Ri.xn*Ri.yn);  Ri.dzri=Ri.dzri*10; end
ri = 0;
xyz = [];
Ri.Buffer = [];
% Airspace Regions
for zi=1:Ri.zn-1
    Layer = zi;
    for yi=1:Ri.yn
        for xi=1:Ri.xn
            ri = ri + 1;
            xyz = [-Airspace.dx/2 + Ri.Dx*(xi-1); -Airspace.dx/2 + Ri.Dx*xi];
            xyz = [xyz,[-Airspace.dy/2 + Ri.Dy*(yi-1); -Airspace.dy/2 + Ri.Dy*yi]];
            %             xyz = [xyz,2.*[AirspaceS.dz1;AirspaceS.dz1]+[-AirspaceS.dz/2 + Ri.Dz*(zi-1);-AirspaceS.dz/2 + Ri.Dz*zi]];
            xyz = [xyz,[Airspace.dz1;Airspace.dz1]+[(Ri.Dz)*(zi-1);(Ri.Dz)*zi]];
            if (ri==1); Ri.B(ri).ri = ri + zi*Ri.dzri; else; Ri.B(ri).ri =  mod(mod(Ri.B(ri-1).ri,Ri.dzri),Ri.xn*Ri.yn) + zi*Ri.dzri + 1; end
            Ri.B(ri).xyz = xyz;
            Ri.B(ri).center = (xyz(1,:) + xyz(2,:)) / 2;
            Ri.B(ri).dx = Ri.Dx; Ri.B(ri).dy = Ri.Dy; Ri.B(ri).dz = Ri.Dz;
            Ri.B(ri).ssize = abs(xyz(1,:) - xyz(2,:));
            Ri.B(ri).space = Ri.B(ri).ssize(1)*Ri.B(ri).ssize(2)*Ri.B(ri).ssize(3);
            Ri.B(ri).layer = Layer;
            if (mod(zi,2)==0)
                Ri.B(ri).Buffer = 1;
            else
                Ri.B(ri).Buffer = 0;
            end
            xyz = [];
        end
    end
    Li(zi+1).center = [0,0,(Airspace.dz1+(Ri.Dz)*(zi-1)+Airspace.dz1+(Ri.Dz)*zi)/2]; % DOUBLE - CHECK
    Li(zi+1).dx = Airspace.dx; Li(zi+1).dy = Airspace.dy; Li(zi+1).dz = Ri.Dz;
    if (mod(zi,2)==0)
        Ri.Buffer((zi/2)+1).layer = Layer;
        Ri.Buffer((zi/2)+1).xyz = [[-Airspace.dx;Airspace.dx]/2,[-Airspace.dy;Airspace.dy]/2,[Airspace.dz1;Airspace.dz1]+[(Ri.Dz)*(zi-1);(Ri.Dz)*zi]];
    end
end
% Take off and Landing Regions
Layer = 0;
for yi=1:Ri.yn
    for xi=1:Ri.xn
        ri = ri + 1;
        xyz = [-Airspace.dx/2 + Ri.Dx*(xi-1); -Airspace.dx/2 + Ri.Dx*xi];
        xyz = [xyz,[-Airspace.dy/2 + Ri.Dy*(yi-1); -Airspace.dy/2 + Ri.Dy*yi]];
        xyz = [xyz,[Airspace.z01;Airspace.z02]];
        Ri.B(ri).ri = mod(mod(Ri.B(ri-1).ri,Ri.dzri),Ri.xn*Ri.yn) + 1;
        Ri.B(ri).xyz = xyz;
        Ri.B(ri).center = (xyz(1,:) + xyz(2,:)) / 2;
        Ri.B(ri).dx = Ri.Dx; Ri.B(ri).dy = Ri.Dy; Ri.B(ri).dz = (Airspace.z02-Airspace.z01);
        Ri.B(ri).ssize = abs(xyz(1,:) - xyz(2,:));
        Ri.B(ri).space = Ri.B(ri).ssize(1)*Ri.B(ri).ssize(2)*Ri.B(ri).ssize(3);
        Ri.B(ri).layer = Layer;
        xyz = [];
    end
    Li(1).center = [0,0,(Airspace.z01+Airspace.z02)/2];
    Li(1).dx = Airspace.dx; Li(1).dy = Airspace.dy; Li(1).dz = Airspace.z02-Airspace.z01;
end
end

function [Ri,Li] = SettingAirspaceRegionsVTOL2R(Airspace)
Ri.xn = 3;
Ri.yn = 3;
Ri.zn = 4;
Ri.Dx = Airspace.dx/Ri.xn;
Ri.Dy = Airspace.dy/Ri.yn;
Ri.Dz = (Airspace.dz)/(Ri.zn-1);
Ri.n = Ri.xn*Ri.yn*Ri.zn;
Ri.nxy = 2;%Ri.xn*Ri.yn;
Ri.dzri = 10; while (Ri.dzri<=Ri.xn*Ri.yn);  Ri.dzri=Ri.dzri*10; end
ri = 0;
Ri.Buffer = [];
xyz = [];
% Airspace Regions
for zi=1:Ri.zn-1
    Layer = zi;
    for yi=1:Ri.yn
        for xi=1:Ri.xn
            ri = ri + 1;
            xyz = [-Airspace.dx/2 + Ri.Dx*(xi-1); -Airspace.dx/2 + Ri.Dx*xi];
            xyz = [xyz,[-Airspace.dy/2 + Ri.Dy*(yi-1); -Airspace.dy/2 + Ri.Dy*yi]];
            %             xyz = [xyz,2.*[AirspaceS.dz1;AirspaceS.dz1]+[-AirspaceS.dz/2 + Ri.Dz*(zi-1);-AirspaceS.dz/2 + Ri.Dz*zi]];
            xyz = [xyz,[Airspace.dz1;Airspace.dz1]+[(Ri.Dz)*(zi-1);(Ri.Dz)*zi]];
            if (ri==1); Ri.B(ri).ri = ri + zi*Ri.dzri; else; Ri.B(ri).ri =  mod(mod(Ri.B(ri-1).ri,Ri.dzri),Ri.xn*Ri.yn) + zi*Ri.dzri + 1; end
            Ri.B(ri).xyz = xyz;
            Ri.B(ri).center = (xyz(1,:) + xyz(2,:)) / 2;
            Ri.B(ri).dx = Ri.Dx; Ri.B(ri).dy = Ri.Dy; Ri.B(ri).dz = Ri.Dz;
            % if (mod(zi,2)==0)
            %     Ri.B(ri).center = (xyz(1,:) + xyz(2,:)) / 2;
            % else
            %     Ri.B(ri).center = (xyz(1,:) + xyz(2,:)) / 2 + 1e-4;
            % end
            Ri.B(ri).ssize = abs(xyz(1,:) - xyz(2,:));
            Ri.B(ri).space = Ri.B(ri).ssize(1)*Ri.B(ri).ssize(2)*Ri.B(ri).ssize(3);
            Ri.B(ri).layer = Layer;
            if (mod(zi,2)==0)
                Ri.B(ri).buffer = 1;
            else
                Ri.B(ri).buffer = 0;
            end
            xyz = [];
            if abs(Ri.B(ri).center(1:2) - [0,0]) < [10^-4,10^-4]
                Ri.B(ri).ri = Ri.B(ri).ri - mod(Ri.B(ri).ri,Ri.dzri) + 1;% mod(Ri.B(ri).ri,Ri.dzri)
            else
                Ri.B(ri).ri = Ri.B(ri).ri - mod(Ri.B(ri).ri,Ri.dzri) + 2;
            end
        end
    end
    Li(zi+1).center = [0,0,(Airspace.dz1+(Ri.Dz)*(zi-1)+Airspace.dz1+(Ri.Dz)*zi)/2]; % DOUBLE - CHECK
    Li(zi+1).dx = Airspace.dx; Li(zi+1).dy = Airspace.dy; Li(zi+1).dz = Ri.Dz;
    if (mod(zi,2)==0)
        Ri.Buffer((zi/2)).layer = Layer;
        Ri.Buffer((zi/2)).xyz = [[-Airspace.dx;Airspace.dx]/2,[-Airspace.dy;Airspace.dy]/2,[Airspace.dz1;Airspace.dz1]+[(Ri.Dz)*(zi-1);(Ri.Dz)*zi]];
    end
end
% Take off and Landing Regions
for yi=1:Ri.yn
    for xi=1:Ri.xn
        ri = ri + 1;
        xyz = [-Airspace.dx/2 + Ri.Dx*(xi-1); -Airspace.dx/2 + Ri.Dx*xi];
        xyz = [xyz,[-Airspace.dy/2 + Ri.Dy*(yi-1); -Airspace.dy/2 + Ri.Dy*yi]];
        xyz = [xyz,[Airspace.z01;Airspace.z02]];
        Ri.B(ri).ri = mod(mod(Ri.B(ri-1).ri,Ri.dzri),Ri.xn*Ri.yn) + 1;
        Ri.B(ri).xyz = xyz;
        Ri.B(ri).center = (xyz(1,:) + xyz(2,:)) / 2;
        Ri.B(ri).dx = Ri.Dx; Ri.B(ri).dy = Ri.Dy; Ri.B(ri).dz = (Airspace.z02-Airspace.z01);
        Ri.B(ri).ssize = abs(xyz(1,:) - xyz(2,:));
        Ri.B(ri).space = Ri.B(ri).ssize(1)*Ri.B(ri).ssize(2)*Ri.B(ri).ssize(3);
        xyz = [];
        Ri.B(ri).layer = 0;
        if (mod(zi,2)==0)
            Ri.B(ri).buffer = 1;
        else
            Ri.B(ri).buffer = 0;
        end
        if abs(Ri.B(ri).center(1:2) - [0,0]) < [10^-4,10^-4]
            Ri.B(ri).ri = Ri.B(ri).ri - mod(Ri.B(ri).ri,Ri.dzri) + 1;% mod(Ri.B(ri).ri,Ri.dzri)
        else
            Ri.B(ri).ri = Ri.B(ri).ri - mod(Ri.B(ri).ri,Ri.dzri) + 2;
        end
    end
end
Li(1).center = [0,0,(Airspace.z01+Airspace.z02)/2];
Li(1).dx = Airspace.dx; Li(1).dy = Airspace.dy; Li(1).dz = Airspace.z02-Airspace.z01;
end
