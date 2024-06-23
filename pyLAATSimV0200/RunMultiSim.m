%% Run Different weights
dbstop if error; clear all; clc;close all force; close all hidden;
% Callculate weights
Sa(1).a = [1,0,0]; % POE
Sa(2).a = [0,1,0]; % POE
Sa(3).a = [0,0,1]; % POE
Sa(4).a = [1/3,1/3,1/3]; % POE
Sa(5).a = [1,0,0]; % PO
Sa(6).a = [0,1,0]; % PO
Sa(7).a = [0,0,1]; % PO
Sa(8).a = [0,1/2,1/2]; % PO
Sa(9).a = [1,0,0]; % PE
Sa(10).a = [0,1,0]; % PE
Sa(11).a = [0,0,1]; % PE
Sa(12).a = [1/2,0,1/2]; % PE
% Sa(1).a = [0.3508,0.3204,0.3288]; % POE Optimal
% Sa(2).a = [0,0.4524,0.5476]; % PO Optimal
% Sa(3).a = [0.5162,0,0.4838]; % PE Optimal
Sai = size(Sa,2);
Sample = 1:1:Sai;
for s=Sample
    a = Sa(s).a;
    ssECv11 = 24.3095;
    ssECv12 = 82.6916;
    nc1 = 40.5189;%TFC.nci(3);
    nc2 = 173.1593;%TFC.nci(4);
    nc = nc1 + nc2;
    % a = [1,1,1];
    % === POE ===
    if (s<=4)&&(s>=1)%s==1%
        % --- Energy Weights
        wEi = a(1).*[1, 1]; % POE
        % --- TTS Weights
        Wni = a(2).*[ssECv11/((nc1)^2),ssECv12/((nc2)^2)]; % POE
        % --- Speed Weights
        WuV = a(3).*[ssECv11,ssECv11,ssECv12,ssECv12]; % POE
    end
    % === PO
    if (s<=8)&&(s>=5)%s==2%
        % --- Energy Weights
        wEi = a(1).*[0, 0]; % PO
        % --- TTS Weights
        Wni = a(2).*[1/nc1,1/nc2]; % PO
        % --- Speed Weights
        WuV = a(3).*[nc1,nc1,nc2,nc2]; % PO
    end
    % === PE ===
    if (s<=12)&&(s>=9)%s==3%
        % --- Energy Weights
        wEi = a(1).*[1, 1]; % PE
        % --- TTS Weights
        Wni = a(2).*[0,0]; % PE
        % --- Speed Weights
        WuV = a(3).*[ssECv11,ssECv11,ssECv12,ssECv12]; % PE
    end
    % --- Merge
    Omega(s).Omega = [wEi, Wni, WuV];
end
clear s;
% ================================
% Run
TTS = zeros(1,Sai);
TTS_NC = 349.5815;
for s=Sample
    close all force; close all hidden; clearvars -except s Omega Sa TTS TTS_NC;
    if (s<=4)&&(s>=1)%s==1%
        Pstr = 'POE';    % === POE ===
    end
    if (s<=8)&&(s>=5)%s==2%
        Pstr = 'PO';    % === PO ===
    end
    if (s<=12)&&(s>=9)%s==3%
        Pstr = 'PE';    % === PE ===
    end
    disp(['_DC_' Pstr '_W' num2str(s)])
    disp(Omega(s).Omega)
    % [TTS_Final] = RunLAATSimReplicate(['Settings_Qin25_NC_30min.mat'],['_DC_' Pstr '_W' num2str(s)],1,Omega(s).Omega,[],1,[]);
    % [TTS_Final] = RunLAATSimReplicate(['Settings_Qin25_NC_30min.mat'],['_DC_' Pstr '_WS'],1,Omega(s).Omega,[],1,[]);
    TTS_Final = TTS_NC*rand;
    TTS(s) = TTS_Final;
    dTTS = TTS./(TTS_NC);
    if(any(dTTS<1))
        warning('success.')
    end
end
save(['Runs_TTS_' datestr(now,'yyyymmdd_hhMMss')]);
[a,b] = min(TTS)
figure;bar(TTS)
dTTS = TTS./(TTS_NC);
figure;bar(dTTS)
save(['Runs_weight_TTS_' datestr(now,'yyyymmdd_hhMMss')]);
TTS_V2 = reshape(TTS,4,[])
wi_V2 = (TTS_V2(4,1:3)./TTS_V2(:,1:3))
wi_V2(3,1) = 0;
wi_V2(2,2) = 0;
ai = wi_V2(1:3,1:3);
ai_f = ai./sum(ai);
wi_V2 = (TTS(:,4)./TTS(:,1:4));
ai = wi_V2(1:3);
ai_f = ai./sum(ai);
disp(ai_f')
save(['Runs_weight_TTS_' datestr(now,'yyyymmdd_hhMMss')]);
wi_V2 = (TTS(:,4)./TTS(:,1:4)); ai = wi_V2(1:3); ai_f = ai./sum(ai); disp(ai_f')