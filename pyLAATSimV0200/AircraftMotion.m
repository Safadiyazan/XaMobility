%AircraftMotion Updates the kinematic state of a single aircraft for one time step.
%   This function applies the aircraft's dynamics to update its position and
%   velocity based on the velocity command computed by the controller. It
%   also updates several other state variables for the aircraft.
%
%   The updates include:
%   - Position (`pt`): Updated using the current velocity.
%   - Velocity (`vt`): Updated using the velocity command (`vct`) and control gain.
%   - Speed (`vnt`): The norm of the new velocity vector.
%   - Filtered Position (`fpt`): A projected position used by the collision avoidance controller.
%   - Region Index (`rit`, `nextrit`): The current and predicted next airspace region.
%   - Distance and Trip Length Metrics: Updates distances from origin/destination
%     and calculates total, remaining, and completed trip lengths.
%
% Inputs:
%   aa          - (integer) The index of the current aircraft within the `Mact` list.
%   SimInfo     - (struct) Simulation information, including the active aircraft list `Mact`.
%   ObjAircraft - (struct) Array of aircraft objects.
%   Settings    - (struct) Simulation settings, including airspace and simulation parameters.
%
% Outputs:
%   SimInfo     - (struct) Unchanged in this function.
%   ObjAircraft - (struct) The updated aircraft object for the specified aircraft.
%
% Author: Yazan Safadi
% Date Created: 2023-02-08
function [SimInfo,ObjAircraft] = AircraftMotion(aa,SimInfo,ObjAircraft,Settings)
Ri = Settings.Airspace.Regions;
%%
dt = Settings.Sim.dtsim;
% Update aircraft state based on kinematic equations
ObjAircraft(SimInfo.Mact(aa)).pt = ObjAircraft(SimInfo.Mact(aa)).pt + dt.*ObjAircraft(SimInfo.Mact(aa)).vt; % Aircraft position update
ObjAircraft(SimInfo.Mact(aa)).vt = ObjAircraft(SimInfo.Mact(aa)).vt - dt.*ObjAircraft(SimInfo.Mact(aa)).vt*ObjAircraft(SimInfo.Mact(aa)).lgain + dt.*ObjAircraft(SimInfo.Mact(aa)).vct'*ObjAircraft(SimInfo.Mact(aa)).lgain; % Aircraft velocity update
ObjAircraft(SimInfo.Mact(aa)).vnt = norm(ObjAircraft(SimInfo.Mact(aa)).vt); % Aircraft velocity norm - speed
ObjAircraft(SimInfo.Mact(aa)).fpt = (ObjAircraft(SimInfo.Mact(aa)).pt) + (ObjAircraft(SimInfo.Mact(aa)).vt)*ObjAircraft(SimInfo.Mact(aa)).gain; % Aircraft filtered position
% Update region information
ObjAircraft(SimInfo.Mact(aa)).rit = max(0,Ri.B(all((abs(repmat(ObjAircraft(SimInfo.Mact(aa)).pt,Ri.n,1) - cat(1,Ri.B.center))) <= cat(1,Ri.B.ssize)./2,2)).ri); % Aircraft current region index
ObjAircraft(SimInfo.Mact(aa)).fptrd = (ObjAircraft(SimInfo.Mact(aa)).pt) + ObjAircraft(SimInfo.Mact(aa)).rd.*((ObjAircraft(SimInfo.Mact(aa)).vt)/norm(ObjAircraft(SimInfo.Mact(aa)).vt)); % Aircraft filtered position with detection radius distance
ObjAircraft(SimInfo.Mact(aa)).nextrit = max(0,Ri.B(all((abs(repmat(ObjAircraft(SimInfo.Mact(aa)).fptrd,Ri.n,1) - cat(1,Ri.B.center))) < cat(1,Ri.B.ssize)./2,2)).ri); % Aircraft expected next region index in the path
% Handle cases where the projected position is outside any defined region
if (~any(ObjAircraft(SimInfo.Mact(aa)).nextrit==cat(1,Settings.Airspace.Regions.B(:).ri)))
    ObjAircraft(SimInfo.Mact(aa)).fptrd = ObjAircraft(SimInfo.Mact(aa)).fpt;
    [~,indexFit] = max(all((abs(repmat(ObjAircraft(SimInfo.Mact(aa)).fptrd,Ri.n,1) - cat(1,Ri.B.center))) <= cat(1,Ri.B.ssize)./2,2));
    ObjAircraft(SimInfo.Mact(aa)).nextrit = max(0,Ri.B(indexFit).ri);
    if (~any(ObjAircraft(SimInfo.Mact(aa)).nextrit==cat(1,Settings.Airspace.Regions.B(:).ri)))
        ObjAircraft(SimInfo.Mact(aa)).nextrit = ObjAircraft(SimInfo.Mact(aa)).rit;
    end
end
% Update distance and trip length metrics
ObjAircraft(SimInfo.Mact(aa)).DfO = norm(ObjAircraft(SimInfo.Mact(aa)).o-ObjAircraft(SimInfo.Mact(aa)).pt); % Aircraft distance from origin point - direct line
ObjAircraft(SimInfo.Mact(aa)).DfD = norm(ObjAircraft(SimInfo.Mact(aa)).d-ObjAircraft(SimInfo.Mact(aa)).pt); % Aircraft distance from destination point - direct line
ObjAircraft(SimInfo.Mact(aa)).tl_total = sum(vecnorm(diff(ObjAircraft(SimInfo.Mact(aa)).wp(1:end,:))')); % Aircraft total trip length
ObjAircraft(SimInfo.Mact(aa)).tl_left = norm(ObjAircraft(SimInfo.Mact(aa)).wp(ObjAircraft(SimInfo.Mact(aa)).wpCR+1,:)-ObjAircraft(SimInfo.Mact(aa)).pt) + ((ObjAircraft(SimInfo.Mact(aa)).wpCR+1)~=ObjAircraft(SimInfo.Mact(aa)).wpTR)*sum(vecnorm(diff([ObjAircraft(SimInfo.Mact(aa)).wp(ObjAircraft(SimInfo.Mact(aa)).wpCR+1:end,:)])')); % Aircraft remaining trip length
ObjAircraft(SimInfo.Mact(aa)).tl_done = norm(ObjAircraft(SimInfo.Mact(aa)).wp(ObjAircraft(SimInfo.Mact(aa)).wpCR,:)-ObjAircraft(SimInfo.Mact(aa)).pt) + sum(vecnorm(diff([ObjAircraft(SimInfo.Mact(aa)).wp(1,:);ObjAircraft(SimInfo.Mact(aa)).wp(1:ObjAircraft(SimInfo.Mact(aa)).wpCR,:)])')); % Aircraft completed trip length
end