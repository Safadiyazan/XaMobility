%AircraftDepartures Manages the departure of aircraft into the simulation.
%   This function checks both queued and inactive aircraft to determine if
%   they are scheduled to depart at the current simulation time.
%
%   The logic is as follows:
%   1. Process Queued Aircraft: Iterates through aircraft in the departure
%      queue (`Mque`). If an aircraft's departure time is now, it checks for
%      conflicts (i.e., other active aircraft too close to its origin).
%      - If clear, the aircraft becomes 'active' and is moved from the queue
%        to the active list.
%      - If not clear, its departure is delayed by a set headway, and it
%        remains in the queue.
%   2. Process Inactive Aircraft: Iterates through inactive aircraft (`Mina`)
%      scheduled to depart soon. The logic is similar to queued aircraft.
%      If an aircraft is ready to depart but faces a conflict, it is moved
%      to the departure queue (`Mque`).
%
% Inputs:
%   SimInfo     - (struct) Simulation information, including aircraft lists and time.
%   ObjAircraft - (struct) Array of aircraft objects.
%
% Outputs:
%   SimInfo     - (struct) Updated simulation information with modified aircraft lists.
%   ObjAircraft - (struct) Updated aircraft objects with new statuses and departure times.
%
% Author: Yazan Safadi
% Date Created: 2023-02-08
function [SimInfo,ObjAircraft] = AircraftDepartures(SimInfo,ObjAircraft)
Mina = SimInfo.Mina;
Mque = SimInfo.Mque;
Mact = SimInfo.Mact;
dtS = SimInfo.dtS;
dtM = SimInfo.dtM;
t = SimInfo.t;
%%
epsilon = 1.0000e-03;
aa = 1; % Loop counter
LMque = length(Mque);
% Process aircraft currently in the departure queue
while aa<=LMque
    if (ObjAircraft(Mque(aa)).tda - t) < epsilon
        ObjAircraft(Mque(aa)).ctd = 1;
        % Check for conflicts with any active aircraft near the departure point
        if (~isempty(Mact))
            Diffaaxyz = (ObjAircraft(Mque(aa)).pt.*ones(length(Mact),1) - cat(1,ObjAircraft(Mact).fpt));
            Distanceaa =  vecnorm(Diffaaxyz')';
            Vectorrd = cat(1,(ObjAircraft(Mact).rd)) + (ObjAircraft(Mque(aa)).rd).*ones(length(Mact),1);
            BolInrd = all([(0<Distanceaa),(Distanceaa<=Vectorrd)],2)';
            MactDetaa = cat(1,ObjAircraft(Mact(BolInrd)).id);
            LMact = length(MactDetaa);
            for aaj=1:LMact
                if norm(ObjAircraft(Mque(aa)).o-ObjAircraft(MactDetaa(aaj)).pt) < (ObjAircraft(Mque(aa)).ra+ObjAircraft(MactDetaa(aaj)).ra)
                    ObjAircraft(Mque(aa)).status = 10;
                    DesiredHeadway = dtS; % Delay departure by one simulation step
                    ObjAircraft(Mque(aa)).tda = t + DesiredHeadway - mod(t + DesiredHeadway,dtS);
                    ObjAircraft(Mque(aa)).Safdd = ObjAircraft(Mque(aa)).Safdd + DesiredHeadway;
                    ObjAircraft(Mque(aa)).dd = ObjAircraft(Mque(aa)).tda - ObjAircraft(Mque(aa)).tdp;
                    ObjAircraft(Mque(aa)).ctd = 0;
                    break;
                end
            end
        else
            LMact = 0;
        end
        clear aaj
        % If clear to depart, move from queue to active list
        if (ObjAircraft(Mque(aa)).ctd)
            ObjAircraft(Mque(aa)).status = 1;
            Mact = [Mact, ObjAircraft(Mque(aa)).id];
            LMact = LMact + 1;
            Mque(ObjAircraft(Mque(aa)).id==Mque) = [];
            LMque = LMque - 1;
        else
            aa = aa + 1;
        end
    elseif (ObjAircraft(Mque(aa)).tdp - t) < epsilon
        ObjAircraft(Mque(aa)).status = 10;
        aa = aa + 1;
    else
        aa = aa + 1;
    end
end
clear aa
% Process inactive aircraft scheduled for departure in the near future
aa = 1;
InActiveAircraftID = Mina(all([( (t) < (cat(1,ObjAircraft(Mina).tda)) ) , ( (cat(1,ObjAircraft(Mina).tda)) < (t+dtM+dtS) )],2));
LMina = size(InActiveAircraftID,2);
while aa<=LMina
    if (ObjAircraft(Mina(aa)).tda - t) < epsilon
        % Check for conflicts with any active aircraft near the departure point
        ObjAircraft(Mina(aa)).ctd = 1;
        if (~isempty(Mact))
            Diffaaxyz = (ObjAircraft(Mina(aa)).pt.*ones(length(Mact),1) - cat(1,ObjAircraft(Mact).fpt));
            Distanceaa =  vecnorm(Diffaaxyz')';
            Vectorrd = cat(1,(ObjAircraft(Mact).rd)) + (ObjAircraft(Mina(aa)).rd).*ones(length(Mact),1);
            BolInrd = all([(0<Distanceaa),(Distanceaa<=Vectorrd)],2)';
            MactDetaa = cat(1,ObjAircraft(Mact(BolInrd)).id);
            LMact = length(MactDetaa);
            for aaj=1:LMact
                if norm(ObjAircraft(Mina(aa)).o-ObjAircraft(MactDetaa(aaj)).pt) < (ObjAircraft(Mina(aa)).rs+ObjAircraft(MactDetaa(aaj)).rs)
                    ObjAircraft(Mina(aa)).status = 10;
                    DesiredHeadway = dtS; % Delay departure
                    ObjAircraft(Mina(aa)).tda = t + DesiredHeadway - mod(t + DesiredHeadway,dtS);
                    ObjAircraft(Mina(aa)).Safdd = ObjAircraft(Mina(aa)).Safdd + DesiredHeadway;
                    ObjAircraft(Mina(aa)).dd = ObjAircraft(Mina(aa)).tda - ObjAircraft(Mina(aa)).tdp;
                    ObjAircraft(Mina(aa)).ctd = 0;
                    break;
                end
            end
        else
            LMact = 0;
        end
        clear aaj
        % If clear to depart, move from inactive to active list
        if (~isempty(Mina))&&(ObjAircraft(Mina(aa)).ctd)
            ObjAircraft(Mina(aa)).tda = t;
            ObjAircraft(Mina(aa)).status = 1;
            Mact = [Mact, ObjAircraft(Mina(aa)).id];
            LMact = LMact + 1;
            Mina(ObjAircraft(Mina(aa)).id==Mina) = [];
            LMina = LMina - 1;
            % If not clear, move from inactive to departure queue
        elseif(~ObjAircraft(Mina(aa)).ctd)
            Mque = [Mque, ObjAircraft(Mina(aa)).id];
            Mina(ObjAircraft(Mina(aa)).id==Mina) = [];
            LMina = LMina - 1;
        end
    elseif (ObjAircraft(Mina(aa)).tdp - t) < epsilon
        ObjAircraft(Mina(aa)).status = 10;
        aa = aa + 1;
    else
        aa = aa + 1;
    end
end
%% Update SimInfo
SimInfo.Mina = Mina;
SimInfo.Mque = Mque;
SimInfo.Mact = Mact;
end
