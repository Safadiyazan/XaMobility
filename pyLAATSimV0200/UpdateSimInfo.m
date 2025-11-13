%UpdateSimInfo Logs the state of all aircraft at the current time step.
%   This function is a utility for recording the history of the simulation.
%   At each microscopic time step (`dtS`), it takes a snapshot of the key
%   state variables for every aircraft and stores them in large matrices
%   within the `SimInfo` structure.
%
%   The logged variables include:
%   - `pdt`: Position (x, y, z) of all aircraft.
%   - `vdt`: Velocity (vx, vy, vz) of all aircraft.
%   - `statusdt`: Flight status (inactive, active, queued, etc.) of all aircraft.
%   - `ridt`: Region index of all aircraft.
%   - `vmdt`: Current maximum speed of all aircraft.
%
%   This historical data is essential for post-processing, including the
%   calculation of macroscopic variables (TFC) and the generation of plots
%   and videos.
%
% Inputs:
%   SimInfo     - (struct) The main simulation information structure.
%   ObjAircraft - (struct) The array of all aircraft objects.
%
% Outputs:
%   SimInfo - (struct) The updated SimInfo structure with new data logged for the current time step.
% Author: Yazan Safadi
% Date Created: 2023-02-08
function [SimInfo] = UpdateSimInfo(SimInfo,ObjAircraft)
t = SimInfo.t;
dtS = SimInfo.dtS;
%%
SimInfo.pdt(round(t/(dtS))+1,:) = cat(1,[ObjAircraft.pt]);
SimInfo.vdt(round(t/(dtS))+1,:) = cat(1,[ObjAircraft.vt]);
SimInfo.statusdt(round(t/(dtS))+1,:) = cat(1,[ObjAircraft.status]);
%% Regions index
SimInfo.ridt(round(t/(dtS))+1,:) = cat(1,[ObjAircraft.rit]);
%% Max Speed Change
SimInfo.vmdt(round(t/(dtS))+1,:) = cat(1,[ObjAircraft.vm]);
end