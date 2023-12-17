function [Airspace] = SettingAirspace(dx,dy,dz)
Airspace.dx = dx;%1500; % width [m]
Airspace.dy = dy;%1500; % length [m]
Airspace.dz1 = 0;  % start at height [m]
Airspace.dz2 = dz+0;%120;  % end at height [m]
Airspace.dz = Airspace.dz2-Airspace.dz1;  % height [m]
Airspace.xyz = [[-Airspace.dx;Airspace.dx]/2,[-Airspace.dy;Airspace.dy]/2,[[Airspace.dz1;Airspace.dz1]+[0;Airspace.dz]]];
Airspace.Space = Airspace.dx*Airspace.dy*Airspace.dz;
%% Subset
Airspace.SubsetNetwork = 1;
%% function for regions boundaries
[Airspace.Regions] = SettingAirspaceRegions(Airspace);
end

function [Ri] = SettingAirspaceRegions(Airspace)
Ri.xn = 3;
Ri.yn = 3;
Ri.zn = 1;
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
    if (mod(zi,2)==0)
        Ri.Buffer((zi/2)+1).layer = Layer;
        Ri.Buffer((zi/2)+1).xyz = [[-Airspace.dx;Airspace.dx]/2,[-Airspace.dy;Airspace.dy]/2,[Airspace.dz1;Airspace.dz1]+[(Ri.Dz)*(zi-1);(Ri.Dz)*zi]];
    end
end
end