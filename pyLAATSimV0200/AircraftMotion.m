% AircraftMotion - Simulates the motion of an aircraft based on input parameters.
%
% Syntax:
%   [SimInfo, ObjAircraft] = AircraftMotion(aa, SimInfo, ObjAircraft, Settings)
%
% Inputs:
%   aa          - Input parameter(s) related to aircraft motion (specific details needed).
%   SimInfo     - Structure containing simulation information and state.
%   ObjAircraft - Object representing the aircraft, including its properties and state.
%   Settings    - Structure containing configuration settings for the simulation.
%
% Outputs:
%   SimInfo     - Updated simulation information after processing the aircraft motion.
%   ObjAircraft - Updated aircraft object with new state information.
%
% Description:
%   This function calculates the motion of an aircraft based on the provided
%   input parameters, simulation information, aircraft object, and settings.
%   It updates the simulation state and the aircraft's state accordingly.
%
% Author: Yazan Safadi
% Date Created: 2023-02-08
function [SimInfo,ObjAircraft] = AircraftMotion(aa,SimInfo,ObjAircraft,Settings)
Ri = Settings.Airspace.Regions;
%%
dt = Settings.Sim.dtsim;
ObjAircraft(SimInfo.Mact(aa)).pt = ObjAircraft(SimInfo.Mact(aa)).pt + dt.*ObjAircraft(SimInfo.Mact(aa)).vt; % Aircraft position update
ObjAircraft(SimInfo.Mact(aa)).vt = ObjAircraft(SimInfo.Mact(aa)).vt - dt.*ObjAircraft(SimInfo.Mact(aa)).vt*ObjAircraft(SimInfo.Mact(aa)).lgain + dt.*ObjAircraft(SimInfo.Mact(aa)).vct'*ObjAircraft(SimInfo.Mact(aa)).lgain; % Aircraft velocity update
ObjAircraft(SimInfo.Mact(aa)).vnt = norm(ObjAircraft(SimInfo.Mact(aa)).vt); % Aircraft velocity norm - speed
ObjAircraft(SimInfo.Mact(aa)).fpt = (ObjAircraft(SimInfo.Mact(aa)).pt) + (ObjAircraft(SimInfo.Mact(aa)).vt)*ObjAircraft(SimInfo.Mact(aa)).gain; % Aircraft filtered position
ObjAircraft(SimInfo.Mact(aa)).rit = max(0,Ri.B(all((abs(repmat(ObjAircraft(SimInfo.Mact(aa)).pt,Ri.n,1) - cat(1,Ri.B.center))) <= cat(1,Ri.B.ssize)./2,2)).ri); % Aircraft current region index
ObjAircraft(SimInfo.Mact(aa)).fptrd = (ObjAircraft(SimInfo.Mact(aa)).pt) + ObjAircraft(SimInfo.Mact(aa)).rd.*((ObjAircraft(SimInfo.Mact(aa)).vt)/norm(ObjAircraft(SimInfo.Mact(aa)).vt)); % Aircraft filtered position with detection radius distance
ObjAircraft(SimInfo.Mact(aa)).nextrit = max(0,Ri.B(all((abs(repmat(ObjAircraft(SimInfo.Mact(aa)).fptrd,Ri.n,1) - cat(1,Ri.B.center))) < cat(1,Ri.B.ssize)./2,2)).ri); % Aircraft expected next region index in the path
if (~any(ObjAircraft(SimInfo.Mact(aa)).nextrit==cat(1,Settings.Airspace.Regions.B(:).ri)))
    ObjAircraft(SimInfo.Mact(aa)).fptrd = ObjAircraft(SimInfo.Mact(aa)).fpt;
    [~,indexFit] = max(all((abs(repmat(ObjAircraft(SimInfo.Mact(aa)).fptrd,Ri.n,1) - cat(1,Ri.B.center))) <= cat(1,Ri.B.ssize)./2,2));
    ObjAircraft(SimInfo.Mact(aa)).nextrit = max(0,Ri.B(indexFit).ri);
    if (~any(ObjAircraft(SimInfo.Mact(aa)).nextrit==cat(1,Settings.Airspace.Regions.B(:).ri)))
        ObjAircraft(SimInfo.Mact(aa)).nextrit = ObjAircraft(SimInfo.Mact(aa)).rit;
    end
end
ObjAircraft(SimInfo.Mact(aa)).DfO = norm(ObjAircraft(SimInfo.Mact(aa)).o-ObjAircraft(SimInfo.Mact(aa)).pt); % Aircraft distance from origin point - direct line
ObjAircraft(SimInfo.Mact(aa)).DfD = norm(ObjAircraft(SimInfo.Mact(aa)).d-ObjAircraft(SimInfo.Mact(aa)).pt); % Aircraft distance from destination point - direct line
ObjAircraft(SimInfo.Mact(aa)).tl_total = sum(vecnorm(diff(ObjAircraft(SimInfo.Mact(aa)).wp(1:end,:))')); % Aircraft total trip length
ObjAircraft(SimInfo.Mact(aa)).tl_left = norm(ObjAircraft(SimInfo.Mact(aa)).wp(ObjAircraft(SimInfo.Mact(aa)).wpCR+1,:)-ObjAircraft(SimInfo.Mact(aa)).pt) + ((ObjAircraft(SimInfo.Mact(aa)).wpCR+1)~=ObjAircraft(SimInfo.Mact(aa)).wpTR)*sum(vecnorm(diff([ObjAircraft(SimInfo.Mact(aa)).wp(ObjAircraft(SimInfo.Mact(aa)).wpCR+1:end,:)])')); % Aircraft remaining trip length
ObjAircraft(SimInfo.Mact(aa)).tl_done = norm(ObjAircraft(SimInfo.Mact(aa)).wp(ObjAircraft(SimInfo.Mact(aa)).wpCR,:)-ObjAircraft(SimInfo.Mact(aa)).pt) + sum(vecnorm(diff([ObjAircraft(SimInfo.Mact(aa)).wp(1,:);ObjAircraft(SimInfo.Mact(aa)).wp(1:ObjAircraft(SimInfo.Mact(aa)).wpCR,:)])')); % Aircraft completed trip length
end