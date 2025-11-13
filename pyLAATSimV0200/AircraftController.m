%AircraftController Calculates velocity commands for aircraft using an APF-based controller.
%   This function implements a decentralized collision avoidance and waypoint
%   following controller for all active aircraft. It uses an Artificial
%   Potential Field (APF) approach, where each aircraft is influenced by
%   repulsive forces from nearby aircraft and an attractive force towards its
%   next waypoint.
%
%   The process involves:
%   1. For each aircraft, detect neighboring aircraft within its detection radius.
%   2. If a neighbor is within the avoidance radius, calculate a repulsive
%      velocity component using a barrier function (Lyapunov-like).
%   3. Calculate an attractive velocity component towards the current waypoint.
%   4. Combine the repulsive and attractive components to get the final
%      velocity command, saturating it to the aircraft's maximum speed.
%   5. Call AircraftMotion to update the aircraft's state based on this command.
%
%   Helper functions (mys, dmys, mysigma, dmysigma, mycontrol, mysat) define
%   the specific shapes of the potential fields and saturation logic.
%
% Inputs:
%   SimInfo     - (struct) Simulation information, including the list of active aircraft.
%   ObjAircraft - (struct) Array of aircraft objects.
%   Settings    - (struct) Simulation settings, including aircraft and airspace parameters.
%
% Outputs:
%   SimInfo     - (struct) Updated simulation information.
%   ObjAircraft - (struct) Updated aircraft objects with new velocity commands and states.
%
% Author: Rao Fu
% Date Created: 2021-05-10
function [SimInfo,ObjAircraft] = AircraftController(SimInfo,ObjAircraft,Settings)
Sim = Settings.Sim;
Aircraft = Settings.Aircraft;
Airspace = Settings.Airspace;
Mact = SimInfo.Mact;
MactCA = SimInfo.Mact;
t = SimInfo.t;
%%
% Pre-calculate repulsive velocity components for all aircraft pairs
vm_matrix=zeros(3*length(MactCA),length(MactCA));
for aa=1:length(MactCA)
    if((ObjAircraft(MactCA(aa)).AMI == 3)||(ObjAircraft(MactCA(aa)).AMI == 4))
        Diffaaxyz = (ObjAircraft(MactCA(aa)).fpt.*ones(length(MactCA),1) - cat(1,ObjAircraft(MactCA).fpt));
        Distanceaa =  vecnorm(Diffaaxyz')'; % Distances to all other aircraft
        Vectorrd = cat(1,(ObjAircraft(MactCA).rd)) + (ObjAircraft(MactCA(aa)).rd).*ones(length(MactCA),1);
        BolInrd = all([(0<Distanceaa),(Distanceaa<=Vectorrd)],2)';
        MactDetaa = cat(1,ObjAircraft(MactCA(BolInrd)).id);
        for aaj=1:length(MactDetaa)
            if MactCA(aa)~=MactDetaa(aaj)
                ksiaa = ObjAircraft(MactCA(aa)).fpt;
                ksiaaj = ObjAircraft(MactDetaa(aaj)).fpt;
                ksimil = ksiaa-ksiaaj;
                rai = (ObjAircraft(MactCA(aa)).ra*Aircraft.Gainfactor_ra);
                raj = (ObjAircraft(MactDetaa(aaj)).ra*Aircraft.Gainfactor_ra);
                rsi = (ObjAircraft(MactCA(aa)).rs*Aircraft.Gainfactor_rs);
                rsj = (ObjAircraft(MactDetaa(aaj)).rs*Aircraft.Gainfactor_rs);
                % If neighbor is within avoidance radius, calculate repulsive force
                if norm(ksimil)<(rai+rsj)
                    gamma = 1; k2 = 1; e = 0.000001;
                    nksimil = norm(ksimil);
                    sigma_ij = mysigma(nksimil,(rsi+rsj),rai+rsj);
                    s_ij = mys((nksimil/(rsi+rsj)),e);
                    dsigma_ij = dmysigma(nksimil,(rsi+rsj),rai+rsj);
                    ds_ij = dmys((nksimil/(rsi+rsj)),e);
                    VmijUp = k2*sigma_ij;
                    VmijDown = (1+e)*nksimil - (rsi+rsj)*s_ij;
                    dVmijUp = k2*dsigma_ij;
                    dVmijDown = (1+e) - ds_ij;
                    b_ij = ( (dVmijUp/VmijDown) + VmijUp*(-dVmijDown)/(VmijDown^2) )*(1/norm(ksimil));
                    vm_matrix(3*aa-2:3*aa,MactDetaa(aaj)==MactCA) = - b_ij*ksimil;
                end
            end
        end
    end
end

% Calculate final velocity command and update motion for each aircraft
for aa=1:length(MactCA)
    ObjAircraft(MactCA(aa)).vct = mycontrol(aa,vm_matrix,MactCA,ObjAircraft); % Combine attractive and repulsive forces
    [SimInfo,ObjAircraft] = AircraftMotion(aa,SimInfo,ObjAircraft,Settings); % Update aircraft position and velocity
end
end
%% Additional Function for the control.
%%
% Derivative of the smooth step function 'mys'
function [u] = dmys(x,rs)
x2 =  1 + 1/tan(67.5/180*pi)*rs;
x1 = x2 - sin(45/180*pi)*rs;
if x<=x1
    u = 1;
elseif x1<=x  && x<=x2
    u = (x2-x)/sqrt(rs^2-(x-x2)^2);
else
    u = 0;
end
end
%%
% Smooth step function used in the barrier function
function [u] = mys(x,rs)
x2 =  1 + 1/tan(67.5/180*pi)*rs;
x1 = x2 - sin(45/180*pi)*rs;
if x<=x1
    u = x;
elseif x1<=x  && x<=x2
    u = (1-rs)+sqrt(rs^2-(x-x2)^2);
else
    u = 1;
end
end
%%
% Derivative of the smooth bump function 'mysigma'
function [u] = dmysigma(x,d1,d2)
if x<=d1
    u = 0;
elseif d1<=x  && x<=d2
    A = -2/((d1-d2)^3); B = 3*(d1+d2)/((d1-d2)^3); C = -6*d1*d2/((d1-d2)^3);
    u = 3*A*x^2 + 2*B*x + C;
else
    u = 0;
end
end
%%
% Smooth bump function to create the potential field
function [u] = mysigma(x,d1,d2)
if x<=d1
    u = 1;
elseif d1<=x  && x<=d2
    A = -2/((d1-d2)^3); B = 3*(d1+d2)/((d1-d2)^3); C = -6*d1*d2/((d1-d2)^3); D = d2^2*(3*d1-d2)/((d1-d2)^3);
    u = A*x^3 + B*x^2 + C*x + D;
else
    u = 0;
end
end
%%
% Combines attractive (waypoint) and repulsive (collision avoidance) velocity components
function u = mycontrol(aa,matrix,Mactcol,ObjAircraft)
fpt  =  ObjAircraft(Mactcol(aa)).fpt;
wpt  =  ObjAircraft(Mactcol(aa)).wp(ObjAircraft(Mactcol(aa)).wpCR+1,:);
vm = ObjAircraft(Mactcol(aa)).vm;
k1 = 1;
ksi_w  = fpt  - wpt;
Vw = - mysat(k1*ksi_w',vm);
Vmx=sum(matrix(3*aa-2,:)); % Sum of all x-components of repulsive velocities
Vmy=sum(matrix(3*aa-1,:)); % Sum of all y-components of repulsive velocities
Vmz=sum(matrix(3*aa,:)); % Sum of all z-components of repulsive velocities
Vm=[Vmx;Vmy;Vmz];
u = mysat(Vw+Vm,vm); % Combine and saturate the final velocity command
end
%%
% Saturates a vector 'x' to a maximum magnitude 'a'
function [u] = mysat(x,a)
if norm(x)>a
    u =a*x/norm(x);
else
    u =x ;
end
end
