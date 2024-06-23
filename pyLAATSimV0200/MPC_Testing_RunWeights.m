%% Testing MPC
clc; close all force; close all hidden; clear all;
load('MPC_Testing.mat')
% [ud_opt,ub_opt,MPCSim] = MPC_CoupledModel_3L2R_V1('','',Settings,TFC,t);
% J = MPCSim.Jk0;
%%
Sai=1;
for a1 = [0:0.1:1]
    for a2 = [0:0.1:1]
        for a3 = [0:0.1:1]
            for a4 = [0:0.1:1]
                for a5 = [0:0.1:1]
                    Sa(Sai).a = [a1,a2,a3,a4,a5];
                    Sai = Sai +1;
                end
            end
        end
    end
end
Sample = 1:1:Sai-1;
for s=Sample
    a = Sa(s).a;
    nc1 = 35.6900;%TFC.nci(3);
    nc2 = 253.3300;%TFC.nci(4);
    nc = nc1 + nc2;
    WnijT = a(1).*[1/nc,1/nc,1/nc,1/nc] ; % 4 values
    Wni = a(2).*[1/nc1,1/nc2]; % 2 values
    Wndqi = [0,0]; % 2 values
    Wnbqih = [0,0]; % 2 values
    Wud = a(3).*[nc,nc]; % 2 values
    WubIN = a(4).*[nc,nc]; % 2 values
    WubOUT = a(5).*[nc,nc]; % 2 values
    Omega(s).Omega = [WnijT, Wni, Wndqi, Wnbqih, Wud, WubIN, WubOUT];
end
clear s;
% ================================
% Run
for s=Sample
    disp(['Sample' num2str(s)])
    disp(Omega(s).Omega)
    Settings.TFC.Omega = Omega(s).Omega;
    [ud_opt,ub_opt,MPCSim] = MPC_CoupledModel_3L2R_V1('','',Settings,TFC,t);
    J(s) = MPCSim.Jk0;
    Jun(s) = MPCSim.Jk0uw;
end
[a,b] = min(Jun)
disp(Omega(b).Omega)
