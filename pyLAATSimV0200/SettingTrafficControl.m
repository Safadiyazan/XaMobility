function [TFC] = SettingTrafficControl(Settings)
TFC.TCmode = 1;
TFC.dtC = 60;
if(TFC.TCmode)
    TFC.TCPolicy = 1;
    TFC.TCRi = 23;
    switch TFC.TCRi
        case 1
            [TFC] = Setting_1R(TFC,Settings);
        case 23  % 2 regions in the same level, 3 levels
            [TFC] = Setting_23R(TFC,Settings);
        case 93  % 9 regions in the same level, 3 levels
            [TFC] = Setting_93R(TFC);
        case 91  % 9 regions in the same level, 3 levels ROUTING SUBSET!
            [TFC] = Setting_91R(TFC);
    end
    TFC.TCP_DepartureController_GC = 0;
    TFC.TCP_BoundaryController_GC = 0;
    TFC.TCP_BoundaryController_GC_Policy = 'Up'; % 'Down' / 'Same'
    TFC.TCP_BoundaryUpPolicyStr = 'FirstDeparted'; % MaxTL | MinTLDone | MinTLLeft | MaxTLLeft | FirstDeparted
    TFC.TCP_CoupledController_GC = 0;
    TFC.TCP_CoupledController_MPC = 1;
    TFC.TCP_SpeedController_GC = 0;
    TFC.TCP_SpeedController_MPC = 0;
    TFC.TCP_GatingController_GC = 0;
    TFC.TCP_GatingController_MPC = 0;
    TFC.TCP_PreRouting = 0;
    TFC.TCP_RTRouting = 0;
    TFC.MPCSim = [];
end
end

function [TFC] = Setting_1R(TFC,Settings)
load('./DataMAT/LAATEnergy_Funcvm20.mat')
TFC.Gn = @(x)((Func.GnAlpha(5)./Func.GnAlpha(1)).*x.*(exp(-Func.GnAlpha(2)*((x./Func.GnAlpha(4)).^Func.GnAlpha(3)))));%Func.Gn;
TFC.ECv = @(x)((20./Func.ECvAlpha(1)).*(exp(-x./Func.ECvAlpha(3))+Func.ECvAlpha(2)));%Func.ECv;
TFC.Vn = @(x)((Func.VnAlpha(6)./Func.VnAlpha(1)).*(exp(-Func.VnAlpha(2).*((x./Func.VnAlpha(5)).^Func.VnAlpha(3)))+Func.VnAlpha(4)));%Func.Vn;
TFC.ncn = 0.9*Func.nG_star;
TFC.Gmn = TFC.Gn(TFC.ncn);
TFC.vECstar = round(1.2*Func.vEC_min,1);
TFC.vECmin = round(1.2*Func.vEC_star,1);
TFC.vECmax = mean(Settings.Aircraft.vm_range);
end

function [TFC] = Setting_23R(TFC,Settings)
% G(n) Gi(ni) Functions settings
TFC.nci = [];
TFC.nijam = [];
TFC.Gmi = [];
load('./DataMAT/MFD_VTOL_Func_N_Ide6_1Hr.mat')
TFC.funGN = Func.Gn;
TFC.nc = Func.nG_star;
TFC.njam = Func.nG_min;
TFC.Gm = TFC.funGN(Func.nG_star);
TFC.ECv = @(x)((20./Func.ECvAlpha(1)).*(exp(-x./Func.ECvAlpha(3))+Func.ECvAlpha(2)));%Func.ECv;
TFC.Vn = @(x)((Func.VnAlpha(6)./Func.VnAlpha(1)).*(exp(-Func.VnAlpha(2).*((x./Func.VnAlpha(5)).^Func.VnAlpha(3)))+Func.VnAlpha(4)));%Func.Vn;
TFC.vECstar = round(1.2*Func.vEC_min,1);
TFC.vECmin = round(1.2*Func.vEC_star,1);
TFC.vECmax = mean(Settings.Aircraft.vm_range);
TFC.ssECv = TFC.ECv(TFC.vECstar);
clearvars -except TFC;
load('./DataMAT/MFD_VTOL_Func_Ri1_Ide6_1Hr.mat')
TFC.funGNRi1 = Func.Gn;
TFC.nci = [TFC.nci,Func.nG_star];
TFC.nijam = [TFC.nijam,Func.nG_min];
TFC.Gmi = [TFC.Gmi,TFC.funGN(Func.nG_star)];
TFC.ECv1 = @(x)((20./Func.ECvAlpha(1)).*(exp(-x./Func.ECvAlpha(3))+Func.ECvAlpha(2)));%Func.ECv;
TFC.Vn1 = @(x)((Func.VnAlpha(6)./Func.VnAlpha(1)).*(exp(-Func.VnAlpha(2).*((x./Func.VnAlpha(5)).^Func.VnAlpha(3)))+Func.VnAlpha(4)));%Func.Vn;
TFC.vECstar1 = round(1.2*Func.vEC_min,1);
TFC.vECmin1 = round(1.2*Func.vEC_star,1);
TFC.vECmax1 = TFC.vECmax; % mean(Settings.Aircraft.vm_range);
TFC.ssECv1 = TFC.ECv1(TFC.vECstar1);
clearvars -except TFC;
load('./DataMAT/MFD_VTOL_Func_Ri2_Ide6_1Hr.mat')
TFC.funGNRi2 = Func.Gn;
TFC.nci = [TFC.nci,Func.nG_star];
TFC.nijam = [TFC.nijam,Func.nG_min];
TFC.Gmi = [TFC.Gmi,TFC.funGN(Func.nG_star)];
TFC.ECv2 = @(x)((20./Func.ECvAlpha(1)).*(exp(-x./Func.ECvAlpha(3))+Func.ECvAlpha(2)));%Func.ECv;
TFC.Vn2 = @(x)((Func.VnAlpha(6)./Func.VnAlpha(1)).*(exp(-Func.VnAlpha(2).*((x./Func.VnAlpha(5)).^Func.VnAlpha(3)))+Func.VnAlpha(4)));%Func.Vn;
TFC.vECstar2 = 15.2;% round(1.2*Func.vEC_min,1);
TFC.vECmin2 = 10.5;% round(1.2*Func.vEC_star,1);
TFC.vECmax2 = TFC.vECmax; % mean(Settings.Aircraft.vm_range);
TFC.ssECv2 = TFC.ECv2(TFC.vECstar2);
clearvars -except TFC;
load('./DataMAT/MFD_VTOL_Func_Ri1_Ide6_1Hr.mat')
TFC.funGNRi11 = Func.Gn;
TFC.nci = [TFC.nci,Func.nG_star];
TFC.nijam = [TFC.nijam,Func.nG_min];
TFC.Gmi = [TFC.Gmi,TFC.funGN(Func.nG_star)];
TFC.ECv11 = @(x)((20./Func.ECvAlpha(1)).*(exp(-x./Func.ECvAlpha(3))+Func.ECvAlpha(2)));%Func.ECv;
TFC.Vn11 = @(x)((Func.VnAlpha(6)./Func.VnAlpha(1)).*(exp(-Func.VnAlpha(2).*((x./Func.VnAlpha(5)).^Func.VnAlpha(3)))+Func.VnAlpha(4)));%Func.Vn;
TFC.vECstar11 = round(1.2*Func.vEC_min,1);
TFC.vECmin11 = round(1.2*Func.vEC_star,1);
TFC.vECmax11 = TFC.vECmax; % mean(Settings.Aircraft.vm_range);
TFC.ssECv11 = TFC.ECv11(TFC.vECstar11);
clearvars -except TFC;
load('./DataMAT/MFD_VTOL_Func_Ri2_Ide6_1Hr.mat')
TFC.funGNRi12 = Func.Gn;
TFC.nci = [TFC.nci,Func.nG_star];
TFC.nijam = [TFC.nijam,Func.nG_min];
TFC.Gmi = [TFC.Gmi,TFC.funGN(Func.nG_star)];
TFC.ECv12 = @(x)((20./Func.ECvAlpha(1)).*(exp(-x./Func.ECvAlpha(3))+Func.ECvAlpha(2)));%Func.ECv;
TFC.Vn12 = @(x)((Func.VnAlpha(6)./Func.VnAlpha(1)).*(exp(-Func.VnAlpha(2).*((x./Func.VnAlpha(5)).^Func.VnAlpha(3)))+Func.VnAlpha(4)));%Func.Vn;
TFC.vECstar12 = 15.2;% round(1.2*Func.vEC_min,1);
TFC.vECmin12 = 10.5;% round(1.2*Func.vEC_star,1);
TFC.vECmax12 = TFC.vECmax; % mean(Settings.Aircraft.vm_range);
TFC.ssECv12 = TFC.ECv12(TFC.vECstar12);
clearvars -except TFC;
load('./DataMAT/MFD_VTOL_Func_Ri1_Ide6_1Hr.mat')
TFC.funGNRi21 = Func.Gn;
TFC.nci = [TFC.nci,Func.nG_star];
TFC.nijam = [TFC.nijam,Func.nG_min];
TFC.Gmi = [TFC.Gmi,TFC.funGN(Func.nG_star)];
TFC.ECv21 = @(x)((20./Func.ECvAlpha(1)).*(exp(-x./Func.ECvAlpha(3))+Func.ECvAlpha(2)));%Func.ECv;
TFC.Vn21 = @(x)((Func.VnAlpha(6)./Func.VnAlpha(1)).*(exp(-Func.VnAlpha(2).*((x./Func.VnAlpha(5)).^Func.VnAlpha(3)))+Func.VnAlpha(4)));%Func.Vn;
TFC.vECstar21 = round(1.2*Func.vEC_min,1);
TFC.vECmin21 = round(1.2*Func.vEC_star,1);
TFC.vECmax21 = TFC.vECmax; % mean(Settings.Aircraft.vm_range);
TFC.ssECv21 = TFC.ECv21(TFC.vECstar21);
clearvars -except TFC;
load('./DataMAT/MFD_VTOL_Func_Ri2_Ide6_1Hr.mat')
TFC.funGNRi22 = Func.Gn;
TFC.nci = [TFC.nci,Func.nG_star];
TFC.nijam = [TFC.nijam,Func.nG_min];
TFC.Gmi = [TFC.Gmi,TFC.funGN(Func.nG_star)];
TFC.ECv22 = @(x)((20./Func.ECvAlpha(1)).*(exp(-x./Func.ECvAlpha(3))+Func.ECvAlpha(2)));%Func.ECv;
TFC.Vn22 = @(x)((Func.VnAlpha(6)./Func.VnAlpha(1)).*(exp(-Func.VnAlpha(2).*((x./Func.VnAlpha(5)).^Func.VnAlpha(3)))+Func.VnAlpha(4)));%Func.Vn;
TFC.vECstar22 = 15.2;% round(1.2*Func.vEC_min,1);
TFC.vECmin22 = 10.5;% round(1.2*Func.vEC_star,1);
TFC.vECmax22 = TFC.vECmax; % mean(Settings.Aircraft.vm_range);
TFC.ssECv22 = TFC.ECv22(TFC.vECstar22);
clearvars -except TFC;
TFC.d_cr = 0.9;
TFC.ncr = TFC.d_cr*TFC.nc;
TFC.ncri = TFC.d_cr*TFC.nci;
TFC.nc = TFC.d_cr*TFC.nc;
TFC.nci = TFC.d_cr*TFC.nci;
% Control Settings
TFC.dtC = 60;
TFC.dtMPC = TFC.dtC;
TFC.Np = 5;
TFC.NMPC = TFC.dtMPC*TFC.Np;
%% Weights
nc1 = TFC.nci(3);
nc2 = TFC.nci(4);
nc = nc1 + nc2;
StrCase = 'DBC';
switch StrCase
    case 'DBC'
        % a = [0.6211    0.3789         0]; % V3 DC
        % a = [0.4539         0    0.5461]; % V3 BC
        % a = [0.4379    0.1374    0.4247]; % V3 DBC
        % a = [0.7406    0.2594         0]; % V4 DC
        % a = [0.5495         0    0.4505]; % V4 BC
        a = [0.2742    0.1631    0.5627]; % V4 DBC
        nc1 = 33.6753;%TFC.nci(3);
        nc2 = 135.9900;%TFC.nci(4);
        nc = nc1 + nc2;
        WnijT = a(1).*[1/nc,1/nc,1/nc,1/nc]./4 ; % 4 values
        Wni = [0,0]; % 2 values
        Wndqi = [0,0]; % 2 values
        Wnbqih = [0,0]; % 2 values
        Wud = a(2).*[nc1,nc2]; % 2 values
        WubIN = a(3).*[nc,nc]; % 2 values
        WubOUT = a(3).*[nc,nc]; % 2 values
        TFC.Omega = [WnijT, Wni, Wndqi, Wnbqih, Wud, WubIN, WubOUT];
    case 'DC'
        a = [0.7406    0.2594         0]; % V4 DC
        nc1 = 33.6753;%TFC.nci(3);
        nc2 = 135.9900;%TFC.nci(4);
        nc = nc1 + nc2;
        WnijT = a(1).*[1/nc,1/nc,1/nc,1/nc]./4 ; % 4 values
        Wni = [0,0]; % 2 values
        Wndqi = [0,0]; % 2 values
        Wnbqih = [0,0]; % 2 values
        Wud = a(2).*[nc1,nc2]; % 2 values
        WubIN = a(3).*[nc,nc]; % 2 values
        WubOUT = a(3).*[nc,nc]; % 2 values
        TFC.Omega = [WnijT, Wni, Wndqi, Wnbqih, Wud, WubIN, WubOUT];
    case 'BC'
        a = [0.5495         0    0.4505]; % V4 BC
        nc1 = 33.6753;%TFC.nci(3);
        nc2 = 135.9900;%TFC.nci(4);
        nc = nc1 + nc2;
        WnijT = a(1).*[1/nc,1/nc,1/nc,1/nc]./4 ; % 4 values
        Wni = [0,0]; % 2 values
        Wndqi = [0,0]; % 2 values
        Wnbqih = [0,0]; % 2 values
        Wud = a(2).*[nc1,nc2]; % 2 values
        WubIN = a(3).*[nc,nc]; % 2 values
        WubOUT = a(3).*[nc,nc]; % 2 values
        TFC.Omega = [WnijT, Wni, Wndqi, Wnbqih, Wud, WubIN, WubOUT];
    case 'POE'
        a = [0.3508,0.3204,0.3288,0]; % POE Optimal
        ssECv11 = 24.3095;
        ssECv12 = 82.6916;
        nc1 = 40.5189;%TFC.nci(3);
        nc2 = 173.1593;%TFC.nci(4);
        nc = nc1 + nc2;
        % --- Energy Weights
        wEi = a(1).*[1, 1]; % POE
        % --- TTS Weights
        Wni = a(2).*[ssECv11/((nc1)^2),ssECv12/((nc2)^2)]; % POE
        % --- Departure Weights
        Wud = a(3).*[ssECv11,ssECv12]; % POE
        % --- Boundary Weights
        Wub = a(4).*[ssECv11,ssECv12]; % POE
        % --- Merge
        TFC.Omega = [wEi, Wni, Wud, Wub];
    case 'PO'
        a = [0,0.4524,0.5476,0]; % PO Optimal
        ssECv11 = 24.3095;
        ssECv12 = 82.6916;
        nc1 = 40.5189;%TFC.nci(3);
        nc2 = 173.1593;%TFC.nci(4);
        nc = nc1 + nc2;
        % --- Energy Weights
        wEi = a(1).*[0, 0]; % PO
        % --- TTS Weights
        Wni = a(2).*[1/nc1,1/nc2]; % PO
        % --- Departure Weights
        Wud = a(3).*[nc1,nc2]; % PO
        % --- Boundary Weights
        Wub = a(4).*[nc,nc]; % PO
        % --- Merge
        TFC.Omega = [wEi, Wni, Wud, Wub];
    case 'PE'
        a = [0.5162,0,0.4838,0]; % PE Optimal
        ssECv11 = 24.3095;
        ssECv12 = 82.6916;
        nc1 = 40.5189;%TFC.nci(3);
        nc2 = 173.1593;%TFC.nci(4);
        nc = nc1 + nc2;
        % --- Energy Weights
        wEi = a(1).*[1, 1]; % PE
        % --- TTS Weights
        Wni = a(2).*[0,0]; % PE
        % --- Departure Weights
        Wud = a(3).*[ssECv11,ssECv12]; % PE
        % --- Boundary Weights
        Wub = a(4).*[ssECv11,ssECv12]; % PE
        % --- Merge
        TFC.Omega = [wEi, Wni, Wud, Wub];
    case 'POESpeed'
        warning('not calribated')
        a = [1/3,1/3,1/3];
        % === POE ===
        % --- Energy Weights
        wEi = a(1).*[1, 1]; % POE
        % --- TTS Weights
        Wni = a(2).*[TFC.ssECv11/((nc1)^2),TFC.ssECv12/((nc2)^2)]; % POE
        % --- Speed Weights
        WuV = a(3).*[TFC.ssECv11,TFC.ssECv11,TFC.ssECv12,TFC.ssECv12]; % POE
        % --- Merge
        TFC.Omega = [wEi, Wni, WuV];
    case 'POSpeed'
        warning('not calribated')
        a = [1/3,1/3,1/3];
        % === POE ===
        % --- Energy Weights
        wEi = a(1).*[1, 1]; % POE
        % --- TTS Weights
        Wni = a(2).*[TFC.ssECv11/((nc1)^2),TFC.ssECv12/((nc2)^2)]; % POE
        % --- Speed Weights
        WuV = a(3).*[TFC.ssECv11,TFC.ssECv11,TFC.ssECv12,TFC.ssECv12]; % POE
        % --- Merge
        TFC.Omega = [wEi, Wni, WuV];
    case 'PESpeed'
        warning('not calribated')
        a = [1/3,1/3,1/3];
        % === POE ===
        % --- Energy Weights
        wEi = a(1).*[1, 1]; % POE
        % --- TTS Weights
        Wni = a(2).*[TFC.ssECv11/((nc1)^2),TFC.ssECv12/((nc2)^2)]; % POE
        % --- Speed Weights
        WuV = a(3).*[TFC.ssECv11,TFC.ssECv11,TFC.ssECv12,TFC.ssECv12]; % POE
        % --- Merge
        TFC.Omega = [wEi, Wni, WuV];
    otherwise
        error('error omega case')
end
TFC.udi = [0,1];
TFC.ubij = [0,1];
end


% function [TFC] = Setting_23R_Testing(TFC)
% fitGNi = @(N) [(1/18.53)*N*e^((-1/1.38)*(N/42.00)^(1.38))];
% fitGN = @(N) [9*(1/18.53)*N*e^((-1/1.38)*(N/42.00)^(1.38))];
% nxyz = 6;
% Gm = 1.1.*ones(1,nxyz);
% %nc = 1.*ones(1,nxyz);
% ncmaxrange = 40;
% % nc = ceil((randperm(nxyz,nxyz)./nxyz)*ncmaxrange);
% nc(3) = 20*0.9;
% nc(4) = 20*8*0.9;
% nc(1) = 20*0.9;
% nc(2) = 20*8*0.9;
% nc(5) = 20*0.9;
% nc(6) = 20*8*0.9;
% nGm = 1.1*2;
% nnc = sum(nc);
% TFC.funGN = fitGN;
% TFC.funGNi = fitGNi;
% clear fitGN fitGNi
% degPcr = 1;
% TFC.Gmi = degPcr*Gm;
% TFC.nci = degPcr*nc;
% TFC.Gmn = degPcr*nGm;
% TFC.ncn = degPcr*nnc;
% clear degPcr Gm nc nGm nnc
% TFC.dtC = 60;
% TFC.dtMPC = TFC.dtC;
% TFC.Np = 5;
% TFC.NMPC = TFC.dtMPC*TFC.Np;
% TFC.Wni = (1./((TFC.ncn).*ones(size(TFC.nci))));
% TFC.Wnqi = (zeros(size(TFC.nci)));
% TFC.Wnqih = (zeros(size(TFC.nci)));
% TFC.Wud = ((TFC.nci));
% TFC.Wub = ((TFC.ncn).*ones(size(TFC.nci)));
% end