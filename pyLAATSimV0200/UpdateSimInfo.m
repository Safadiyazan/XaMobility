%{
    UpdateSimInfo - Updates the simulation information structure with data
    from the given aircraft object.

    Syntax:
        [SimInfo] = UpdateSimInfo(SimInfo, ObjAircraft)

    Inputs:
        SimInfo - A structure containing the current simulation information.
        ObjAircraft - An object representing the aircraft, containing
                      relevant data to update the simulation information.

    Outputs:
        SimInfo - The updated simulation information structure.

    Description:
        This function takes the current simulation information structure
        and updates it using the data provided in the aircraft object.
        The updated structure is then returned.

    Example:
        SimInfo = UpdateSimInfo(SimInfo, ObjAircraft);

    Note:
        Ensure that ObjAircraft contains all necessary fields required
        for updating SimInfo.
%}
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