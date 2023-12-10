function [SimInfo,ObjAircraft] = InitAircraftObj(SimInfo,Settings)
Airspace = Settings.Airspace;
Aircraft = Settings.Aircraft;
Sim = Settings.Sim;
Mina = SimInfo.Mina;
for aa = 1:Sim.M
    ObjAircraft(aa).id = aa; % index
    ObjAircraft(aa).status = 0; % status % 0 - Want to depart % 1 - Flying % 2 - Landed % 100 - Priority want to depart % 101 - Priority % 102 - Priority landed % 12 - Obstacle % 10 - Queue
    %% Velocity and Speed
    ObjAircraft(aa).vm = Aircraft.vm_range(1)+rand*(Aircraft.vm_range(2)-Aircraft.vm_range(1)); % maximum speed
    ObjAircraft(aa).vm_set = ObjAircraft(aa).vm;
    ObjAircraft(aa).vt = [0,0,0]; % current velocity
    ObjAircraft(aa).vct = [0,0,0]; % current  velocity command
    ObjAircraft(aa).vnt = norm(ObjAircraft(aa).vt); % speed
    gain = [5,5,5]; %AircraftS.gain_range(1,:)+rand*(AircraftS.gain_range(2,:)-AircraftS.gain_range(1,:)); % aircraft motion control gain (can be scalar as well)
    ObjAircraft(aa).gain = (eye(length((gain))).*(gain));
    ObjAircraft(aa).lgain = (eye(length((gain)))./(gain));
    %% Radius
    ObjAircraft(aa).rs = Aircraft.rs_range(1)+rand*(Aircraft.rs_range(2)-Aircraft.rs_range(1)); % safety radius
    ObjAircraft(aa).ra = 1.5*ObjAircraft(aa).rs; % avoidance radius
    ObjAircraft(aa).rv = ObjAircraft(aa).vm*norm(ObjAircraft(aa).lgain); % rv
    ObjAircraft(aa).rd = ObjAircraft(aa).ra + ObjAircraft(aa).rs + 2*ObjAircraft(aa).rv; % detetion radius
    %% Origin, Destiation, Waypoints, positions
    ObjAircraft(aa).VTOL = 0;
    [ObjAircraft(aa).o, ObjAircraft(aa).d] = AircraftODBoundary(Airspace,ObjAircraft(aa).rd); % origin and desitation at the boundaries
    ObjAircraft(aa).wp  = AircraftRoute(Airspace,ObjAircraft(aa).o, ObjAircraft(aa).d); % waypoints
    ObjAircraft(aa).wpSet = ObjAircraft(aa).wp;
    ObjAircraft(aa).wpChange = 0;
    ObjAircraft(aa).wpRouting = 0;
    ObjAircraft(aa).wpta  = [0;];
    ObjAircraft(aa).wpCR  = 1;
    ObjAircraft(aa).wpTR  = size(ObjAircraft(aa).wp,1);
    ObjAircraft(aa).pt = ObjAircraft(aa).o; % current position
    ObjAircraft(aa).fpt = (ObjAircraft(aa).pt) + (ObjAircraft(aa).vt)*(ObjAircraft(aa).lgain); % ObjAircraft(aa).o; % current filterd position
    %% Regions
    ObjAircraft(aa).rio = RegionIndexXYZ(Airspace,ObjAircraft(aa).o); % origin region
    ObjAircraft(aa).rid = RegionIndexXYZ(Airspace,ObjAircraft(aa).d); % des. region
    ObjAircraft(aa).rit = RegionIndexXYZ(Airspace,ObjAircraft(aa).pt); % current region
    %% Times and Distances
    ObjAircraft(aa).tt = [inf]; % travel time
    ObjAircraft(aa).tte = [inf];%ObjAircraft(aa).tle/ObjAircraft(aa).vm; % expected travel time
    ObjAircraft(aa).tdp = AircraftDepartTime(aa,Sim); % planned departure time
    ObjAircraft(aa).tda = ObjAircraft(aa).tdp; % actual departure time
    ObjAircraft(aa).tap = [inf];%ObjAircraft(aa).tdp  + ObjAircraft(aa).tle/ObjAircraft(aa).vm; % planned arrival time
    ObjAircraft(aa).taa = [inf]; % actual arrival time
    ObjAircraft(aa).ctd = 1; % clear to depart
    ObjAircraft(aa).dd = [];
    ObjAircraft(aa).Curdd = [];
    ObjAircraft(aa).Safdd = 0;%[];
    ObjAircraft(aa).tle = norm(ObjAircraft(aa).o-ObjAircraft(aa).d); % expected trip length;
    ObjAircraft(aa).tla = [inf]; % actual trip length;
    ObjAircraft(aa).td = [inf]; % travel distance
    ObjAircraft(aa).tte = ObjAircraft(aa).tle/ObjAircraft(aa).vm; % expected travel time
    ObjAircraft(aa).tap = ObjAircraft(aa).tdp  + ObjAircraft(aa).tle/ObjAircraft(aa).vm; % planned arrival time
    %% Boundary Control
    ObjAircraft(aa).fptrd = [];
    ObjAircraft(aa).nextrit = [];
    ObjAircraft(aa).BQ = 0;
    ObjAircraft(aa).LastStopBoundary = [];
    ObjAircraft(aa).StopBoundary = [];
    ObjAircraft(aa).StopTime = [];
    ObjAircraft(aa).ResumeTime = [];
    ObjAircraft(aa).HoveringTime = [];
    ObjAircraft(aa).CurHoveringTime = [];
    %% Energy and Battery
    ObjAircraft(aa).ECtdt = 0;
    ObjAircraft(aa).ECqdt = 0;
    ObjAircraft(aa).csECtdt = 0;
    ObjAircraft(aa).csECqdt = 0;
    ObjAircraft(aa).DOD = [];
    ObjAircraft(aa).Bat_limit = Aircraft.Bat_limit;
    ObjAircraft(aa).Bat_max = Aircraft.Bat_max;
    ObjAircraft(aa).Batdt = ObjAircraft(aa).Bat_max;
    %% Index set
    Mina = [Mina, ObjAircraft(aa).id]; % inactive aircraft index set
end
SimInfo.Mina = Mina; % Update SimInfo Object
end

function [o, d] = AircraftODBoundary(AirspaceS,rd)
ODFaces = randperm(18,2);
o = PointatFace(AirspaceS,ODFaces(1),rd);
d = PointatFace(AirspaceS,ODFaces(2),rd);
while norm(o-d)<2*rd % verify the o and d is not close enough
    o = PointatFace(AirspaceS,ODFaces(1),rd);
    d = PointatFace(AirspaceS,ODFaces(2),rd);
end
end

function [p] = PointatFace(AirspaceS,Face,rd)
switch Face
    case 4
        p = [2*(rand-0.5)*AirspaceS.dx/2, 2*(-0.5)*AirspaceS.dy/2, AirspaceS.dz1 + (rand)*AirspaceS.dz];
    case 3
        p = [2*(rand-0.5)*AirspaceS.dx/2, 2*(0.5)*AirspaceS.dy/2, AirspaceS.dz1 + (rand)*AirspaceS.dz];
    case 2
        p = [2*(-0.5)*AirspaceS.dx/2, 2*(rand-0.5)*AirspaceS.dy/2, AirspaceS.dz1 + (rand)*AirspaceS.dz];
    case 1
        p = [2*(0.5)*AirspaceS.dx/2, 2*(rand-0.5)*AirspaceS.dy/2, AirspaceS.dz1 + (rand)*AirspaceS.dz];
    otherwise
        switch randperm(2,1)
            case 1
                p = [2*(rand-0.5)*AirspaceS.dx/2, 2*(rand-0.5)*AirspaceS.dy/2, AirspaceS.dz1 + (1)*AirspaceS.dz];
            case 2
                p = [2*(rand-0.5)*AirspaceS.dx/2, 2*(rand-0.5)*AirspaceS.dy/2, AirspaceS.dz1 + (0)*AirspaceS.dz];
        end
end
end
function wp  = AircraftRoute(AirspaceS,o,d)
wp = [o;d];
end
function ri = RegionIndexXYZ(AirspaceS,xyz)
ri =  max(0,AirspaceS.Regions.B(all((abs(repmat(xyz,AirspaceS.Regions.n,1) - cat(1,AirspaceS.Regions.B.center))) <= cat(1,AirspaceS.Regions.B.ssize)./2,2)).ri);
end
function tdp = AircraftDepartTime(aa,Sim)
if aa ~= Sim.M
    tt = Sim.dtsim:Sim.dtsim:Sim.tf;
    II = Sim.AircraftCumNumdtSim;
    IN = diff([1;(ones(size(II)).*aa >= II)]);
    tdp = tt(IN~=0)-Sim.dtsim;
else
    tt = Sim.dtsim:Sim.dtsim:Sim.tf;
    II = Sim.AircraftCumNumdtSim;
    IN = diff([1;(ones(size(II)).*(aa-1) >= II)]);
    tdp = tt(IN~=0)-Sim.dtsim+Sim.dtsim;
end
end