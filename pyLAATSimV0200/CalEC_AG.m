function [EC,ObjAircraft] = CalEC_AG(EC,SimInfo,ObjAircraft)
%{
Input Values:
Trajectory (n,3) - First column - X axis [m]; Second column - y axis [m]; Third Column - z axis [m]
Speed Vector (n-1,1) - A vector defining the norm of a 3D speed between two points through the given trajectory [m/s] 
Output Values:
P_Total_Consumed (1,1) - A scalar defining the amount of energy consumed by the UAV during the entire trip [Wh]
Accumulated_Energy_Consumption (n,1) - A vector tracking the accumulation of the energy consumed during the trip [Wh]
Energy_Consumption (n,1) - A vector tracking the amount of energy consumed during each increment of the trip [Wh]
n - Number of time increments during the trip
%}
%%
t=SimInfo.t;
dtS=SimInfo.dtS;
dtM=SimInfo.dtM;
ActiveAircraft=SimInfo.Mact;
%%
for aai=1:size(ActiveAircraft,2)
    %Trajectory = SimInfo.pdt((t/dtS):1:(t/dtS)+1,[3*ActiveAircraft(aai)-2,3*ActiveAircraft(aai)-1,3*ActiveAircraft(aai)]);
    Speed_Vector = SimInfo.vdt((t/dtS),[3*ActiveAircraft(aai)-2,3*ActiveAircraft(aai)-1,3*ActiveAircraft(aai)]);
    %%
    Energy_Consumption = 0; %Total Energy Spend during the trip [Wh]
    Battery_Capacity = 0;
    [~, ~, Battery_Capacity(1), ~] = Cal_EC_Model_AG(1); %Battery capacity remained during the trip [Wh]
    E_limit_vector = 0;
    [~, ~, ~, E_limit_vector(1)] = Cal_EC_Model_AG(1); %Battery safety limit allowed - usually 20% [Wh]
    % Phases Consumption Calc.
    Takeoff_Landing_Cons = 0; Cruising_Cons = 0; Angular_3D_Cons = 0; Hovering_Cons = 0;
    Time_Traveled = dtS/3600; %[hr]
    Vertical_Speed = Speed_Vector(3);
    Vertical_Speed(isnan(Vertical_Speed)) = 0;
    Horizontal_Speed = norm([Speed_Vector(1),Speed_Vector(2)]);
    Horizontal_Speed(isnan(Horizontal_Speed)) = 0;
    Operational_Speed = min(20,max(1,Horizontal_Speed)); %Speed control boundaries, preventing small values
    %% Classify Movement
    if Horizontal_Speed == 0 && Vertical_Speed == 0 %Stop
        P_Horizontal = 0; P_Vertical = 0; [~, ~, E_max, ~] = Cal_EC_Model_AG(1);
    elseif Horizontal_Speed < 1 && not(Vertical_Speed < 1) %Takeoff & Landing
        [~, P_Vertical, E_max, ~] = Cal_EC_Model_AG(Operational_Speed);
        P_Horizontal = 0;
        Takeoff_Landing_Cons = Takeoff_Landing_Cons + (P_Vertical)*Time_Traveled;
    elseif Vertical_Speed < 1 && Horizontal_Speed > 1 %&& (abs(X2-mean(Trajectory(i-1:i,1)))>5 || abs(Y2-mean(Trajectory(i-1:i,2)))>5)  %Cruising
        [P_Horizontal, ~, E_max, ~] = Cal_EC_Model_AG(Operational_Speed);
        P_Vertical = 0;
        Cruising_Cons = Cruising_Cons + (P_Horizontal)*Time_Traveled;
    elseif Horizontal_Speed > 1 && Vertical_Speed > 1
        [P_Horizontal, P_Vertical, E_max, ~] = Cal_EC_Model_AG(Operational_Speed); % 3D Angular Movement
        Angular_3D_Cons = Angular_3D_Cons + (P_Vertical + P_Horizontal)*Time_Traveled;
    else
        P_Horizontal = 0; [~, P_Vertical, E_max, ~] = Cal_EC_Model_AG(1); %Hovering
        Hovering_Cons = Hovering_Cons + (P_Vertical)*Time_Traveled;
    end
    Energy_Consumption = (P_Vertical + P_Horizontal)*Time_Traveled; %Energy consumed for the specific given segment of trip [Wh]
    %%
    % Update ObjAircraft
    ObjAircraft(ActiveAircraft(aai)).ECtdt = Energy_Consumption;
    ObjAircraft(ActiveAircraft(aai)).csECtdt = ObjAircraft(ActiveAircraft(aai)).csECtdt + Energy_Consumption;
    ObjAircraft(ActiveAircraft(aai)).Batdt = ObjAircraft(ActiveAircraft(aai)).Batdt-Energy_Consumption;
    EC.ECdt(round(t/(dtS))+1,ActiveAircraft(aai)) = Energy_Consumption; % size M*tf
end
%%
QueuedAircraft=SimInfo.Mque;
%% Queued Aircraft Energy Consuption.
for aai=1:size(QueuedAircraft,2)
    %%
    Energy_Consumption=0;
    Time_Traveled = dtS/3600; %[hr]
    Hovering_Cons = 0;
    %% Classify Movement
    P_Horizontal = 0; [~, P_Vertical, E_max, ~] = Cal_EC_Model_AG(1); %Hovering
    Hovering_Cons = Hovering_Cons + (P_Vertical)*Time_Traveled;
    Energy_Consumption = (P_Vertical + P_Horizontal)*Time_Traveled; %Energy consumed for the specific given segment of trip [Wh]
    %%
    % Update ObjAircraft
    ObjAircraft(QueuedAircraft(aai)).ECqdt = Energy_Consumption;
    ObjAircraft(QueuedAircraft(aai)).csECqdt = ObjAircraft(QueuedAircraft(aai)).csECqdt + Energy_Consumption;
    ObjAircraft(QueuedAircraft(aai)).Batdt = ObjAircraft(QueuedAircraft(aai)).Batdt-Energy_Consumption;
    EC.ECdt(round(t/(dtS))+1,QueuedAircraft(aai)) = Energy_Consumption; % size M*tf
end
%% Total Value
EC.sumECtdt(round(t/(dtS))+1,1) = sum(cat(1,ObjAircraft(ActiveAircraft).ECtdt));
EC.sumECqdt(round(t/(dtS))+1,1) = sum(cat(1,ObjAircraft(QueuedAircraft).ECqdt));
EC.avgECtdt(round(t/(dtS))+1,1) = sum(cat(1,ObjAircraft(ActiveAircraft).ECtdt))/(size(ActiveAircraft,2));
EC.avgECqdt(round(t/(dtS))+1,1) = sum(cat(1,ObjAircraft(QueuedAircraft).ECqdt))/(size(QueuedAircraft,2));
EC.sumECdt(round(t/(dtS))+1,1) = EC.sumECtdt(round(t/(dtS))+1,1)+EC.sumECqdt(round(t/(dtS))+1,1);
end

function [P_Horizontal, P_Vertical, E_max, E_limit] = Cal_EC_Model_AG(v)
%Model Coefficients
C_D = 0.025 ; C_L = 0.45; %Drag and Lift coefficients
A = 0.2;                  %Front facing area pi*b^2 [m^2]
D = 1.2;                  %Air Density at average altitude of flight 40-120 m [kg/m^3]
%v = 5;                    %velocity [m/s]
W = 3.5;                  %Total weight of UAV = Battry + Payload + Frame [kg]
g = 9.8;                  %Gravity [N]
b = 0.25;                 %Width of UAV body - Rotor radius [m]
E_max = 69.5;             %Battery capacity 250 [kJ] = 69.5 [Watt per hour]
E_limit = E_max*0.2;      %Safety factor for battery
%% Model Power Consumption Equations
%Horizontal Moving
P_Horizontal = 0.5*(C_D*A*D*v^3)+(W^2)/(D*v*b^2); %[Watts]
%Hovering, Vertical Takeoff and Landing
P_Vertical = ((W*g)^(3/2))/sqrt(2*D*A); %[Watts]
end