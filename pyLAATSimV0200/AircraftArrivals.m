%AircraftArrivals Handles aircraft arrival logic and state transitions.
%   This function checks the status of active aircraft to determine if they
%   have reached their destination, a waypoint, or are ready to exit a
%   boundary queue. It updates the aircraft's status, waypoints, and
%   simulation state accordingly.
%
%   The function iterates through all active aircraft and performs checks for:
%   1. Waypoint Arrival: If an aircraft reaches its next waypoint, its
%      current waypoint index is incremented.
%   2. Final Destination Arrival: If an aircraft is within the landing
%      epsilon of its final destination, its status is changed to 'arrived',
%      and it is moved from the active list to the arrived list.
%   3. Boundary Queue Resumption: If an aircraft was held in a boundary
%      queue and its resume time has been reached, its status is changed
%      back to 'active'.
%
% Inputs:
%   SimInfo     - (struct) Simulation information, including active/arrived aircraft lists and current time.
%   ObjAircraft - (struct) Array of aircraft objects.
%
% Outputs:
%   SimInfo     - (struct) Updated simulation information with modified aircraft lists.
%   ObjAircraft - (struct) Updated aircraft objects with new statuses or waypoint info.
%
% Author: Yazan Safadi
% Date Created: 2023-02-08
function [SimInfo,ObjAircraft] = AircraftArrivals(SimInfo,ObjAircraft)
Mact = SimInfo.Mact;
Marr = SimInfo.Marr;
t = SimInfo.t;
%%
aa = 1; % Loop counter
LMact = length(Mact);
LMarr = length(Marr);
while aa<=LMact
    % Define proximity thresholds for different events
    epsilon_landing = ObjAircraft(Mact(aa)).rd;
    epsilon_SwitchWaypoint = ObjAircraft(Mact(aa)).rd;
    epsilon_BoundaryControl = ObjAircraft(Mact(aa)).rd;
    epsilon_PreRouting = 2*ObjAircraft(Mact(aa)).rd;
    if(ObjAircraft(Mact(aa)).status==1)  % Active aircraft
        % Check if the aircraft has reached its next intermediate waypoint
        if (ObjAircraft(Mact(aa)).wpCR<ObjAircraft(Mact(aa)).wpTR-1)&&(norm(ObjAircraft(Mact(aa)).pt-ObjAircraft(Mact(aa)).wp(ObjAircraft(Mact(aa)).wpCR+1,:)) <= epsilon_SwitchWaypoint)
            ObjAircraft(Mact(aa)).wpCR = ObjAircraft(Mact(aa)).wpCR + 1;
            ObjAircraft(Mact(aa)).wpta  = [ObjAircraft(Mact(aa)).wpta;t];
        end
        % Check for pre-routing waypoint switch (larger radius)
        if (ObjAircraft(Mact(aa)).wpRouting)&&(ObjAircraft(Mact(aa)).wpCR<ObjAircraft(Mact(aa)).wpTR-1)&&(norm(ObjAircraft(Mact(aa)).pt-ObjAircraft(Mact(aa)).wp(ObjAircraft(Mact(aa)).wpCR+1,:)) <= epsilon_PreRouting)
            ObjAircraft(Mact(aa)).wpCR = ObjAircraft(Mact(aa)).wpCR + 1;
            ObjAircraft(Mact(aa)).wpta  = [ObjAircraft(Mact(aa)).wpta;t];
        end
        % Check if the aircraft has reached its final destination
        if (norm(ObjAircraft(Mact(aa)).pt-ObjAircraft(Mact(aa)).d) <= epsilon_landing)
            ObjAircraft(Mact(aa)).status = 2;
            ObjAircraft(Mact(aa)).vct   =  [0,0,0];
            ObjAircraft(Mact(aa)).vt   =  [0,0,0];
            ObjAircraft(Mact(aa)).taa = t;
            ObjAircraft(Mact(aa)).tt = ObjAircraft(Mact(aa)).taa - ObjAircraft(Mact(aa)).tda;
            Marr = [Marr, ObjAircraft(Mact(aa)).id];
            LMarr = LMarr + 1;
            Mact(ObjAircraft(Mact(aa)).id==Mact) = [];
            LMact = LMact - 1;
        else
            aa = aa + 1;
        end
    elseif(ObjAircraft(Mact(aa)).status==11) % Boundary queue aircraft
        if (norm(ObjAircraft(Mact(aa)).pt-ObjAircraft(Mact(aa)).wp(ObjAircraft(Mact(aa)).wpCR+1,:))<= epsilon_BoundaryControl)
            % If resume time is reached, change status back to active
            if((ObjAircraft(Mact(aa)).ResumeTime(end))<=t)
                ObjAircraft(Mact(aa)).status = 1;
                ObjAircraft(Mact(aa)).ResumeTime(end) = t;
                ObjAircraft(Mact(aa)).HoveringTime = ObjAircraft(Mact(aa)).ResumeTime - ObjAircraft(Mact(aa)).StopTime;
                ObjAircraft(Mact(aa)).CurHoveringTime = ObjAircraft(Mact(aa)).ResumeTime(end) - ObjAircraft(Mact(aa)).StopTime(end);
                SimInfo.MactBQ(ObjAircraft(Mact(aa)).id==SimInfo.MactBQ) = [];
            else
                aa = aa + 1;
            end
        else
            aa = aa + 1;
        end
    else
        error('AircraftArrivals: Aircraft in Mact list has unexpected status: %d', ObjAircraft(Mact(aa)).status);
    end
end
%%
% Update the simulation info structure with the modified lists
SimInfo.Mact = Mact;
SimInfo.Marr = Marr;
end
