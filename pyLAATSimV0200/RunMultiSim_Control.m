%% RunMutliControl
% MaxTL | MinTLDone | MinTLLeft | MaxTLLeft | FirstDeparted
dbstop if error; clear all; clc;close all force; close all hidden;
[TTS_Final(1)] = RunLAATSimReplicate(['Settings_Qin25_NC_30min.mat'],['_DBC_MaxTL'],1,[],[],[],'MaxTL');
dbstop if error; clear all; clc;close all force; close all hidden;
[TTS_Final(2)] = RunLAATSimReplicate(['Settings_Qin25_NC_30min.mat'],['_DBC_MinTLDone'],1,[],[],[],'MinTLDone');
dbstop if error; clear all; clc;close all force; close all hidden;
[TTS_Final(3)] = RunLAATSimReplicate(['Settings_Qin25_NC_30min.mat'],['_DBC_MinTLLeft'],1,[],[],[],'MinTLLeft');
dbstop if error; clear all; clc;close all force; close all hidden;
[TTS_Final(4)] = RunLAATSimReplicate(['Settings_Qin25_NC_30min.mat'],['_DBC_MaxTLLeft'],1,[],[],[],'MaxTLLeft');
dbstop if error; clear all; clc;close all force; close all hidden;
[TTS_Final(5)] = RunLAATSimReplicate(['Settings_Qin25_NC_30min.mat'],['_DBC_FirstDeparted'],1,[],[],[],'FirstDeparted');
