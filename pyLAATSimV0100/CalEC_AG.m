function [EC,ObjAircraft] = CalEC_AG(EC,SimInfo,ObjAircraft)
t=SimInfo.t;
dtS=SimInfo.dtS;
dtM=SimInfo.dtM;
ActiveAircraft=SimInfo.Mact;
for aai=1:size(ActiveAircraft,2)
    Speed_Vector = SimInfo.vdt((t/dtS),[3*ActiveAircraft(aai)-2,3*ActiveAircraft(aai)-1,3*ActiveAircraft(aai)]);
    Energy_Consumption = 0;
    Battery_Capacity = 0;
    [~, ~, Battery_Capacity(1), ~] = Cal_EC_Model_AG(1);
    E_limit_vector = 0;
    [~, ~, ~, E_limit_vector(1)] = Cal_EC_Model_AG(1);
    Takeoff_Landing_Cons = 0; Cruising_Cons = 0; Angular_3D_Cons = 0; Hovering_Cons = 0;
    Time_Traveled = dtS/3600;
    Vertical_Speed = Speed_Vector(3);
    Vertical_Speed(isnan(Vertical_Speed)) = 0;
    Horizontal_Speed = norm([Speed_Vector(1),Speed_Vector(2)]);
    Horizontal_Speed(isnan(Horizontal_Speed)) = 0;
    Operational_Speed = min(20,max(1,Horizontal_Speed));
    if Horizontal_Speed == 0 && Vertical_Speed == 0
        P_Horizontal = 0; P_Vertical = 0; [~, ~, E_max, ~] = Cal_EC_Model_AG(1);
    elseif Horizontal_Speed < 1 && not(Vertical_Speed < 1)
        [~, P_Vertical, E_max, ~] = Cal_EC_Model_AG(Operational_Speed);
        P_Horizontal = 0;
        Takeoff_Landing_Cons = Takeoff_Landing_Cons + (P_Vertical)*Time_Traveled;
    elseif Vertical_Speed < 1 && Horizontal_Speed > 1
        [P_Horizontal, ~, E_max, ~] = Cal_EC_Model_AG(Operational_Speed);
        P_Vertical = 0;
        Cruising_Cons = Cruising_Cons + (P_Horizontal)*Time_Traveled;
    elseif Horizontal_Speed > 1 && Vertical_Speed > 1
        [P_Horizontal, P_Vertical, E_max, ~] = Cal_EC_Model_AG(Operational_Speed);
        Angular_3D_Cons = Angular_3D_Cons + (P_Vertical + P_Horizontal)*Time_Traveled;
    else
        P_Horizontal = 0; [~, P_Vertical, E_max, ~] = Cal_EC_Model_AG(1);
        Hovering_Cons = Hovering_Cons + (P_Vertical)*Time_Traveled;
    end
    Energy_Consumption = (P_Vertical + P_Horizontal)*Time_Traveled;
    ObjAircraft(ActiveAircraft(aai)).ECtdt = Energy_Consumption;
    ObjAircraft(ActiveAircraft(aai)).csECtdt = ObjAircraft(ActiveAircraft(aai)).csECtdt + Energy_Consumption;
    ObjAircraft(ActiveAircraft(aai)).Batdt = ObjAircraft(ActiveAircraft(aai)).Batdt-Energy_Consumption;
    EC.ECdt(round(t/(dtS))+1,ActiveAircraft(aai)) = Energy_Consumption;
end
QueuedAircraft=SimInfo.Mque;
for aai=1:size(QueuedAircraft,2)
    Energy_Consumption=0;
    Time_Traveled = dtS/3600;
    Hovering_Cons = 0;
    P_Horizontal = 0; [~, P_Vertical, E_max, ~] = Cal_EC_Model_AG(1);
    Hovering_Cons = Hovering_Cons + (P_Vertical)*Time_Traveled;
    Energy_Consumption = (P_Vertical + P_Horizontal)*Time_Traveled;
    ObjAircraft(QueuedAircraft(aai)).ECqdt = Energy_Consumption;
    ObjAircraft(QueuedAircraft(aai)).csECqdt = ObjAircraft(QueuedAircraft(aai)).csECqdt + Energy_Consumption;
    ObjAircraft(QueuedAircraft(aai)).Batdt = ObjAircraft(QueuedAircraft(aai)).Batdt-Energy_Consumption;
    EC.ECdt(round(t/(dtS))+1,QueuedAircraft(aai)) = Energy_Consumption;
end
EC.sumECtdt(round(t/(dtS))+1,1) = sum(cat(1,ObjAircraft(ActiveAircraft).ECtdt));
EC.sumECqdt(round(t/(dtS))+1,1) = sum(cat(1,ObjAircraft(QueuedAircraft).ECqdt));
EC.avgECtdt(round(t/(dtS))+1,1) = sum(cat(1,ObjAircraft(ActiveAircraft).ECtdt))/(size(ActiveAircraft,2));
EC.avgECqdt(round(t/(dtS))+1,1) = sum(cat(1,ObjAircraft(QueuedAircraft).ECqdt))/(size(QueuedAircraft,2));
EC.sumECdt(round(t/(dtS))+1,1) = EC.sumECtdt(round(t/(dtS))+1,1)+EC.sumECqdt(round(t/(dtS))+1,1);
end

function [P_Horizontal, P_Vertical, E_max, E_limit] = Cal_EC_Model_AG(v)
C_D = 0.025 ; C_L = 0.45;
A = 0.2;
D = 1.2;
W = 3.5;
g = 9.8;
b = 0.25;
E_max = 69.5;
E_limit = E_max*0.2;
P_Horizontal = 0.5*(C_D*A*D*v^3)+(W^2)/(D*v*b^2);
P_Vertical = ((W*g)^(3/2))/sqrt(2*D*A);
end