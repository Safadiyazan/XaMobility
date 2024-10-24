function [SimInfo,ObjAircraft] = InitPedObj(SimInfo,Settings)
Airspace = Settings.Airspace;
Aircraft = Settings.Ped;
Sim = Settings.Sim;
Mina = SimInfo.Mina;
%% Create Set Vector with Perc.
ModelsTypes = [1,0,0,0];%/4,1/4,1/4,1/4];%[1/4,1/4,1/4,1/4]; %EPAV-1 EUAV-2 PAV-3 UAV-4 [0.3,0.3,0.3]
ModelsVec = [1.*ones(ceil(Sim.M.*ModelsTypes(1)),1);2.*ones(ceil(Sim.M.*ModelsTypes(2)),1);3.*ones(ceil(Sim.M.*ModelsTypes(3)),1);4.*ones(ceil(Sim.M.*ModelsTypes(4)),1)]';
% Model = ModelsVec(randi(size(ModelsVec,2)))
%%
for aa = 1:Sim.M
    %% Aircraft Model UAV/PAV/EAV
    ObjAircraft(aa).AMI = ModelsVec(randi(size(ModelsVec,2)));
    %%
    ObjAircraft(aa).id = aa; % index
    ObjAircraft(aa).status = 0; % status % 0 - Want to depart % 1 - Flying % 2 - Landed % 100 - Priority want to depart % 101 - Priority % 102 - Priority landed % 12 - Obstacle % 10 - Queue
    %% Velocity and Speed
    StepVm = 0.1;
    ObjAircraft(aa).vm = Aircraft.vm_range(1)+StepVm*(randi(((Aircraft.vm_range(2)-Aircraft.vm_range(1))/StepVm)+1)-1); % maximum speed
    ObjAircraft(aa).vm_set = ObjAircraft(aa).vm;
    ObjAircraft(aa).vt = [0,0,0]; % current velocity
    ObjAircraft(aa).vct = [0,0,0]; % current  velocity command
    ObjAircraft(aa).vnt = norm(ObjAircraft(aa).vt); % speed
    %     warning('double check the control gain')
    gain = [5,5,0]; %AircraftS.gain_range(1,:)+rand*(AircraftS.gain_range(2,:)-AircraftS.gain_range(1,:)); % aircraft motion control gain (can be scalar as well)
    ObjAircraft(aa).gain = (eye(length((gain))).*(gain));
    llgain = [5,5,Inf];
    ObjAircraft(aa).lgain = (eye(length((llgain)))./(llgain));
    %% Radius
    % ObjAircraft(aa).rs = Aircraft.rs_range(1)+rand*(Aircraft.rs_range(2)-Aircraft.rs_range(1)); % safety radius
    ObjAircraft(aa).rs = funcRS(Aircraft.rs_range, ObjAircraft(aa).AMI); % safety radius function
    ObjAircraft(aa).ra = 1.5*ObjAircraft(aa).rs; % avoidance radius
    ObjAircraft(aa).rv = ObjAircraft(aa).vm*norm(ObjAircraft(aa).lgain); % rv
    ObjAircraft(aa).rd = ObjAircraft(aa).ra + ObjAircraft(aa).rs + 2*ObjAircraft(aa).rv; % detetion radius
    %% Origin, Destiation, Waypoints, positions
    if (Airspace.VTOL)&&(~Airspace.Vertiports)
        ObjAircraft(aa).VTOL = 1;
        %         [ObjAircraft(aa).o, ObjAircraft(aa).d] = AircraftODGround(Airspace,ObjAircraft(aa).rs,ObjAircraft(aa).rd); % origin and desitation from ground
        [ObjAircraft(aa).o, ObjAircraft(aa).d] = AircraftODGround2R(Airspace,ObjAircraft(aa).rs,ObjAircraft(aa).rd); % origin and desitation from ground Two Regions Uniformly
        ObjAircraft(aa).wp  = AircraftRouteTL(Airspace,ObjAircraft(aa).o, ObjAircraft(aa).d,ObjAircraft(aa).rs); % waypoints
        % ObjAircraft(aa).wp  = AircraftRouteTL_MultiLayer(Airspace,ObjAircraft(aa).o, ObjAircraft(aa).d,ObjAircraft(aa).rs,ObjAircraft(aa).AMI); % waypoints
    elseif (Airspace.VTOL)&&(Airspace.Vertiports)
        ObjAircraft(aa).VTOL = 1;
        [ObjAircraft(aa).o, ObjAircraft(aa).d] = AircraftODVertiports(Airspace,ObjAircraft(aa).rs,ObjAircraft(aa).rd); % origin and desitation from ground Two Regions Uniformly
        % ObjAircraft(aa).wp  = AircraftRouteTL(Airspace,ObjAircraft(aa).o, ObjAircraft(aa).d,ObjAircraft(aa).rs); % waypoints
        ObjAircraft(aa).wp  = AircraftRouteTL_MultiLayer(Airspace,ObjAircraft(aa).o, ObjAircraft(aa).d,ObjAircraft(aa).rs,ObjAircraft(aa).AMI); % waypoints

    elseif(Airspace.SubsetNetwork)
        ObjAircraft(aa).VTOL = 0;
        [ObjAircraft(aa).o, ObjAircraft(aa).d] = AircraftODBoundary(Airspace,ObjAircraft(aa).rd); % origin and desitation at the boundaries
        ObjAircraft(aa).wp  = AircraftRoute(Airspace,ObjAircraft(aa).o, ObjAircraft(aa).d); % waypoints
    else
        ObjAircraft(aa).VTOL = 0;
        [ObjAircraft(aa).o, ObjAircraft(aa).d] = AircraftOD(Airspace,ObjAircraft(aa).rd); % origin and desitation
        ObjAircraft(aa).wp  = AircraftRoute(Airspace,ObjAircraft(aa).o, ObjAircraft(aa).d); % waypoints
    end
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
    %     %%
    %     ObjAircraft(aa).ptdt = [ObjAircraft(aa).pt];
    %     ObjAircraft(aa).vtdt = [ObjAircraft(aa).vt];
    %     ObjAircraft(aa).statusdt = [ObjAircraft(aa).status];
    %     ObjAircraft(aa).ridt = [ObjAircraft(aa).rit];
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
%%
function [rs] = funcRS(range,AMI)
switch AMI
    case 1 % EPAV
        rs = range(1) + ((range(2)-range(1))/2) + randi((range(2)-range(1))/2);
    case 3 % PAV
        rs = range(1) + ((range(2)-range(1))/2) + randi((range(2)-range(1))/2);
    case 2 % EUAV
        rs = range(1) + randi((range(2)-range(1))/2);
    case 4 % EUAV
        rs = range(1) + randi((range(2)-range(1))/2);
    otherwise
        rs = range(1) + randi((range(2)-range(1)));
end
end
%%
function [o, d] = AircraftOD(AirspaceS,rd)
o = [2*(rand-0.5)*AirspaceS.dx/2, 2*(rand-0.5)*AirspaceS.dy/2, AirspaceS.dz1 + (rand)*AirspaceS.dz];
d = [2*(rand-0.5)*AirspaceS.dx/2, 2*(rand-0.5)*AirspaceS.dy/2, AirspaceS.dz1 + (rand)*AirspaceS.dz];
while norm(o-d)<rd % verify the o and d is not close enough
    d = [2*(rand-0.5)*AirspaceS.dx/2, 2*(rand-0.5)*AirspaceS.dy/2, AirspaceS.dz1 + (rand)*AirspaceS.dz];
end
end

function [o, d] = AircraftODBoundary(AirspaceS,rd)
ODFaces = randperm(18,2);
o = PointatFace(AirspaceS,ODFaces(1),rd);
d = PointatFace(AirspaceS,ODFaces(2),rd);
% o = [2*(rand-0.5)*AirspaceS.dx/2, 2*(rand-0.5)*AirspaceS.dy/2, AirspaceS.dz1 + (rand)*AirspaceS.dz];
% d = [2*(rand-0.5)*AirspaceS.dx/2, 2*(rand-0.5)*AirspaceS.dy/2, AirspaceS.dz1 + (rand)*AirspaceS.dz];
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

function [o, d] = AircraftODGround(AirspaceS,rs,rd)
% ('Optional Take off and landing from builiding on the ground.')
z0o = 0;%max(0,min(AirspaceS.z02,rs + rand*(AirspaceS.z02 - rs - AirspaceS.z01)));
z0d = 0;%max(0,min(AirspaceS.z02,rs + rand*(AirspaceS.z02 - rs - AirspaceS.z01)));
o = [2*(rand-0.5)*AirspaceS.dx/2, 2*(rand-0.5)*AirspaceS.dy/2, z0o];
d = [2*(rand-0.5)*AirspaceS.dx/2, 2*(rand-0.5)*AirspaceS.dy/2, z0d];
while norm(o-d)<rd % verify the o and d is not close enough
    d = [2*(rand-0.5)*AirspaceS.dx/2, 2*(rand-0.5)*AirspaceS.dy/2, 0];
end
% TODO: warning('Optional Fixed-OD - Similiar to TLOF,')
end
%%

function [o, d] = AircraftODGround2R(AirspaceS,rs,rd)
% ('Optional Take off and landing from builiding on the ground.')
z0o = 0;%max(0,min(AirspaceS.z02,rs + rand*(AirspaceS.z02 - rs - AirspaceS.z01)));
z0d = 0;%max(0,min(AirspaceS.z02,rs + rand*(AirspaceS.z02 - rs - AirspaceS.z01)));
ODRi = randperm(4,1); % 11, 12, 21, 22
R2_options = [-1, -1, 0; 0, -1, 0; 1, -1, 0; -1, 0, 0; 1, 0, 0; -1, 1, 0; 0, 1, 0; 1, 1, 0];
switch ODRi
    case 1 % R1->R1
        o = [2*(rand-0.5)*AirspaceS.dx/6, 2*(rand-0.5)*AirspaceS.dy/6, z0o];
        d = [2*(rand-0.5)*AirspaceS.dx/6, 2*(rand-0.5)*AirspaceS.dy/6, z0d];
    case 2 % R1->R2
        o = [2*(rand-0.5)*AirspaceS.dx/6, 2*(rand-0.5)*AirspaceS.dy/6, z0o];
        %         d = [(2*randi([0, 1])-1),(2*randi([0, 1])-1),0].*([AirspaceS.dx/6,AirspaceS.dx/6,0] + [(rand)*AirspaceS.dx/3, (rand)*AirspaceS.dy/3, z0d]);
        d = R2_options(randi(size(R2_options, 1)),:).*[AirspaceS.dx/3, AirspaceS.dy/3, z0o] + [2*(rand-0.5)*AirspaceS.dx/6, 2*(rand-0.5)*AirspaceS.dy/6, z0o];
    case 3 % R2->R1
        o = R2_options(randi(size(R2_options, 1)),:).*[AirspaceS.dx/3, AirspaceS.dy/3, z0o] + [2*(rand-0.5)*AirspaceS.dx/6, 2*(rand-0.5)*AirspaceS.dy/6, z0o];
        d = [2*(rand-0.5)*AirspaceS.dx/6, 2*(rand-0.5)*AirspaceS.dy/6, z0o];
    otherwise %case 4 % R2->R2
        o = R2_options(randi(size(R2_options, 1)),:).*[AirspaceS.dx/3, AirspaceS.dy/3, z0o] + [2*(rand-0.5)*AirspaceS.dx/6, 2*(rand-0.5)*AirspaceS.dy/6, z0o];
        d = R2_options(randi(size(R2_options, 1)),:).*[AirspaceS.dx/3, AirspaceS.dy/3, z0o] + [2*(rand-0.5)*AirspaceS.dx/6, 2*(rand-0.5)*AirspaceS.dy/6, z0o];
end
while norm(o-d)<rd % verify the o and d is not close enough
    d = [2*(rand-0.5)*AirspaceS.dx/2, 2*(rand-0.5)*AirspaceS.dy/2, 0];
end
% TODO: warning('Optional Fixed-OD - Similiar to TLOF,')
end

function [o, d] = AircraftODVertiports(AirspaceS,rs,rd)
% Vertiports = [
% -73.98440300426283 40.77275113399261 20.89627363010538;
% -73.96773955133848 40.75007173649506 4.318934694714676;
% -73.98427004394215 40.72990870353391 -15.521595383896994;
% -73.99687660760746 40.724604427122294 28.434851429241917;
% ];
if AirspaceS.Vertiports
    [VertiportOD,MaxXY] = LoadVertiports();
    ODMat = VertiportOD;
else
    ODMat = 0.99.*[
        AirspaceS.dx/2,AirspaceS.dy/2,0;
        -AirspaceS.dx/2,AirspaceS.dy/2,0;
        AirspaceS.dx/2,-AirspaceS.dy/2,0;
        -AirspaceS.dx/2,-AirspaceS.dy/2,0;
        ];
end
z0o = 0;
z0d = 0;
ODRi = randperm(size(ODMat,1),2); % 11, 12, 21, 22
o = ODMat(ODRi(1),:);
d = ODMat(ODRi(2),:);
end
%%
function wp  = AircraftRoute(AirspaceS,o,d)
wp = [o;d];
end
function wp  = AircraftRouteTL(AirspaceS,o,d,rs)
if(AirspaceS.Regions.zn<=2)
    TakeOff = [o(1:2),0] + [0,0,AirspaceS.z02+AirspaceS.dz/2];
    Landing = [d(1:2),0] + [0,0,AirspaceS.z02+AirspaceS.dz/2];
else
    TakeOff = [o(1:2),0] + [0,0,AirspaceS.Regions.B(1).center(3)];
    Landing = [d(1:2),0] + [0,0,AirspaceS.Regions.B(1).center(3)];
end
wp = [o;TakeOff;Landing;d];
end
function wp  = AircraftRouteTL_MultiLayer(AirspaceS,o,d,rs,AMI)
switch AMI
    case 1
        MatLayer = cat(1,AirspaceS.Regions.B(:).center);
        dzEm = max(MatLayer(:,3));
        TakeOff = [o(1:2),0] + [0,0,dzEm];
        Landing = [d(1:2),0] + [0,0,dzEm];
    case 2
        MatLayer = cat(1,AirspaceS.Regions.B(:).center);
        dzEm = max(MatLayer(:,3));
        TakeOff = [o(1:2),0] + [0,0,dzEm];
        Landing = [d(1:2),0] + [0,0,dzEm];
    case 3
        TakeOff = [o(1:2),0] + [0,0,AirspaceS.Regions.B(1).center(3)];
        Landing = [d(1:2),0] + [0,0,AirspaceS.Regions.B(1).center(3)];
    case 4
        TakeOff = [o(1:2),0] + [0,0,AirspaceS.Regions.B(1).center(3)];
        Landing = [d(1:2),0] + [0,0,AirspaceS.Regions.B(1).center(3)];
    otherwise
        TakeOff = [o(1:2),0] + [0,0,AirspaceS.Regions.B(1).center(3)];
        Landing = [d(1:2),0] + [0,0,AirspaceS.Regions.B(1).center(3)];
end
wp = [o;TakeOff;Landing;d];
end
%%
function ri = RegionIndexXYZ(AirspaceS,xyz)
% regions clasification
ri =  max(0,AirspaceS.Regions.B(all((abs(repmat(xyz,AirspaceS.Regions.n,1) - cat(1,AirspaceS.Regions.B.center))) <= cat(1,AirspaceS.Regions.B.ssize)./2,2)).ri);
% regions
% rn = AirspaceS.Regions.n;
% for ri=1:rn
%     p1 = AirspaceS.Regions.B(ri).xyz(1,:);
%     p2 = AirspaceS.Regions.B(ri).xyz(2,:);
%     center = (p1 + p2) / 2;
%     ssize = abs(p2 - p1);
%     if all(abs(xyz - center) <= ssize/2)
%         break;
%     end
% end
end
%%
function tdp = AircraftDepartTime(aa,Sim)
% TODO: warning('change to unirformly distrubtion.')
if aa ~= Sim.M
    tt = Sim.dtsim:Sim.dtsim:Sim.tf;
    II = Sim.AircraftCumNumdtSim; % Tables of indexes
    IN = diff([1;(ones(size(II)).*aa >= II)]); % Idetifny the right row
    tdp = tt(IN~=0)-Sim.dtsim;
else
    tt = Sim.dtsim:Sim.dtsim:Sim.tf;
    II = Sim.AircraftCumNumdtSim; % Tables of indexes
    IN = diff([1;(ones(size(II)).*(aa-1) >= II)]); % Idetifny the right row
    tdp = tt(IN~=0)-Sim.dtsim+Sim.dtsim;
end
end