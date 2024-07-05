function [] = PlotMotionPicture(SES,SimInfo,ObjAircraft,TFC,Settings)
close all;
AirspaceS = Settings.Airspace;
SimS = Settings.Sim;
%% Video Setting
SnapshotsEverySecond = SES;
dstt = SnapshotsEverySecond/SimS.dtsim;
AddLegendforMap = 0;
PlotPath = 1;
SaveSnapshots = 'N'; % SaveSnapshots = input('Export Snapshots? [Y/N]','s');
if SaveSnapshots=='Y'
    if ~exist([SimInfo.SimOutputDirStr '\Snapshots'], 'dir')
        mkdir([SimInfo.SimOutputDirStr '\Snapshots'])
    end
else
    if ~exist([SimInfo.SimOutputDirStr], 'dir')
        mkdir([SimInfo.SimOutputDirStr])
    end
end
%% Figure Setup Parameters
plotsize = 600;
numofsubplotV = 1;
numofsubplotH = 1;
FigureSize = [10 50 numofsubplotV*plotsize+10 numofsubplotH*plotsize+50];
hFigure = figure(1);
set(hFigure,'PaperUnits','normalized','PaperPosition',FigureSize,'PaperType','A4','PaperOrientation','landscape');
set(gcf, 'outerposition',FigureSize);
set(gcf,'Color','White'); %set(gca,'Color','White');
set(hFigure, 'MenuBar', 'none'); set(hFigure, 'ToolBar', 'none');
FigFontSize = 10;
%% Show video
for dt=1:dstt:(1+SimS.tf/SimS.dtsim)
    %% Title
    tt = ((dt-1)*SimS.dtsim);
    titleTxt = {['$t=',sprintf('%d',tt),'~[\mathrm{s}]$']};
    % Title for TTS
    if(tt~=0)&&(mod(tt,SimS.dtMFD)==0)
        titleTTS = TFC.N.cumTTS(tt/SimS.dtMFD)/3600;
    elseif tt==0
        titleTTS = 0;
    end
    titleTTSTxt = ['$\mathrm{TTS}=' sprintf('%0.4f',titleTTS) '~[\mathrm{aircraft} \cdot \mathrm{hr}]$'];
    titleEle = sgtitle([titleTxt;titleTTSTxt],'interpreter','latex','FontUnits','points','FontSize',0.9*FigFontSize,'FontName','Times');
    %% Micro - Top View
    subplot(numofsubplotH,numofsubplotV,1)
%     hold off
%     PlotAirspaceDesign(AirspaceS,FigFontSize);
%     PlotTrajectories(tt,dt,SimInfo,ObjAircraft,FigFontSize);
%     view(2)
%     subplot(numofsubplotH,numofsubplotV,2)
%     hold off
%     PlotAirspaceDesign(AirspaceS,FigFontSize);
%     PlotTrajectories(tt,dt,SimInfo,ObjAircraft,FigFontSize);
%     view([90,0])
%     subplot(numofsubplotH,numofsubplotV,3)
%     hold off
%     PlotAirspaceDesign(AirspaceS,FigFontSize);
%     PlotTrajectories(tt,dt,SimInfo,ObjAircraft,FigFontSize);
%     view([0,0])
%     subplot(numofsubplotH,numofsubplotV,4)
%     hold off
    PlotAirspaceDesign(AirspaceS,FigFontSize);
    PlotTrajectories(tt,dt,SimInfo,ObjAircraft,FigFontSize);
    view([45,45])
    % view(2);
    %% Save frame
    %     pause(0.1);
    FRAMEI = max(1,((dt-1)/dstt)+1);
    F(FRAMEI) = getframe(gcf) ;
    drawnow
    hold off
    if(SaveSnapshots=='Y')
        print('-vector',[SimInfo.SimOutputDirStr '\Snapshots\tk' num2str(tt)],'-dpdf','-bestfit')
    end
    clf;
end
%% Save Video
DIRstrAVI = [SimInfo.SimOutputDirStr '\MotionPicture' '_' datestr(now,'yyyymmdd_hhMMss') '.avi'];
writerObj = VideoWriter(DIRstrAVI);%,'Uncompressed AVI');
writerObj.FrameRate = 60*((1+(SimS.tf/SimS.dtsim)/dstt))/(SimS.tf);
if (SimS.tf<1200)
    writerObj.FrameRate = ((1+(SimS.tf/SimS.dtsim)/dstt))/20;
end
open(writerObj);
for i=1:size(F,2)
    frame = F(i) ;
    writeVideo(writerObj, frame);
end
close(writerObj);
close all;
% if(input('Open Folder [Y/N]?','s')=='Y')
%     winopen(SimInfo.SimOutputDirStr)
% end
end
%% ========== Functions ==========
%
function [] = PlotAirspaceDesign(AirspaceS,FigFontSize)
if (AirspaceS.VTOL) % Vertical Takeoff and Landing
    PlotCube(AirspaceS.xyz,'none',0.01,'black',1,1,'-','none',1,'flat')
    PlotCube(AirspaceS.VTOLxyz,'none',0.01,'black',1,1,'--','none',1,'flat')
    AxisSize = 1.3*max(2*AirspaceS.dz2,max([AirspaceS.dx,AirspaceS.dy,AirspaceS.dz]));
    axis([-AxisSize/2 AxisSize/2 -AxisSize/2 AxisSize/2 -AxisSize/2 AxisSize/2])
    xticks([-AirspaceS.dx/2,0,AirspaceS.dx/2])
    yticks([-AirspaceS.dx/2,0,AirspaceS.dx/2])
    zticks(([0 AirspaceS.dz1 AirspaceS.dz2]))
else % Subset of airspace
    PlotCube(AirspaceS.xyz,'none',0.01,'black',1,1,'-','none',1,'flat')
    %     PlotCube(AirspaceS.VTOLxyz,'none',0.01,'black',1,1,'--','none',1,'flat')
    AxisSize = 1.3*max(2*AirspaceS.dz2,max([AirspaceS.dx,AirspaceS.dy,AirspaceS.dz]));
    axis([-AxisSize/2 AxisSize/2 -AxisSize/2 AxisSize/2 -AxisSize/2 AxisSize/2])
    xticks([-AirspaceS.dx/2,0,AirspaceS.dx/2])
    yticks([-AirspaceS.dx/2,0,AirspaceS.dx/2])
    zticks((2*[0 AirspaceS.dz1 AirspaceS.dz1]+[0 -AirspaceS.dz/2,AirspaceS.dz/2]))
end
% Set up figure
xlabel('$x~[\mathrm{m}]$','interpreter','latex','FontUnits','points','FontSize',FigFontSize,'FontName','Times');
ylabel('$y~[\mathrm{m}]$','interpreter','latex','FontUnits','points','FontSize',FigFontSize,'FontName','Times');
zlabel('$z~[\mathrm{m}]$','interpreter','latex','FontUnits','points','FontSize',FigFontSize,'FontName','Times');
set(findall(gca,'type','axes'),'FontUnits','points','FontSize',FigFontSize,'FontName','Times')
axis square
grid on
grid minor
PlotAirspaceRegionsDesign(AirspaceS,FigFontSize)
PlotAirspaceLayersDesign(AirspaceS,FigFontSize)
if AirspaceS.Regions.zn>2
    PlotAirspaceBuffersDesign(AirspaceS,FigFontSize)
end
end
%
function [] = PlotAirspaceRegionsDesign(AirspaceS,FigFontSize)
if AirspaceS.RMode=='2R'
    for ri=1:AirspaceS.Regions.n
        if mod(AirspaceS.Regions.B(ri).ri,AirspaceS.Regions.dzri)==1
            PlotCube(AirspaceS.Regions.B(ri).xyz,'none',0.01,'black',0.2,1,':','none',1,'flat');
        end
    end
else
    for ri=1:AirspaceS.Regions.n
        if AirspaceS.Regions.B(ri).Buffer == 0
            PlotCube(AirspaceS.Regions.B(ri).xyz,'none',0.01,'black',0.2,1,':','none',1,'flat');
        end
    end
end
end


function [] = PlotAirspaceLayersDesign(AirspaceS,FigFontSize)
zz = cat(1,AirspaceS.Regions.B(:).xyz);
unizz = unique(zz(:,3));
for li=1:size(unizz,1)
        PlotCube([AirspaceS.xyz(:,1:2), [unizz(li);unizz(li)]],'black',0.01,'black',0.1,1,'--','none',1,'flat');
end
end

function [] = PlotAirspaceBuffersDesign(AirspaceS,FigFontSize)
bb = cat(1,AirspaceS.Regions.Buffer(:).xyz);
for li=1:size(bb,1)/2
        PlotCube(bb(2*li-1:2*li,:),'cyan',0.05,'cyan',0.05,1,'--','none',1,'flat');
end
end
%
function [] = PlotCube(Bxyz,FC,FA,EC,EA,LW,LS,M,MS,MFC)
point1 = Bxyz(1,:);
point2 = Bxyz(2,:);
center = (point1 + point2) / 2;
dxyz = abs(point2 - point1);
B = zeros(8,3);
B(1,:) = center + [ dxyz(1)/2,  dxyz(2)/2,  dxyz(3)/2];
B(2,:) = center + [-dxyz(1)/2,  dxyz(2)/2,  dxyz(3)/2];
B(3,:) = center + [-dxyz(1)/2, -dxyz(2)/2,  dxyz(3)/2];
B(4,:) = center + [ dxyz(1)/2, -dxyz(2)/2,  dxyz(3)/2];
B(5,:) = center + [ dxyz(1)/2,  dxyz(2)/2, -dxyz(3)/2];
B(6,:) = center + [-dxyz(1)/2,  dxyz(2)/2, -dxyz(3)/2];
B(7,:) = center + [-dxyz(1)/2, -dxyz(2)/2, -dxyz(3)/2];
B(8,:) = center + [ dxyz(1)/2, -dxyz(2)/2, -dxyz(3)/2];
% plot patches
faces = [1 2 3 4; 2 6 7 3; 4 3 7 8; 1 5 8 4; 1 2 6 5; 5 6 7 8];
% FC='none'; FA=0.01; EC='black'; EA=0.01; LW=2; LS = ':'; M='none'; MS=1; MFC = 'flat';
% patch('Vertices',B,'Faces',faces,'FaceColor',FC,'FaceAlpha',FA,'EdgeColor',EC,'EdgeAlpha',EA,'LineWidth',LW,'LineStyle',LS,'Marker',M,'MarkerSize',MS,'MarkerFaceColor',MFC);
patch('Vertices',B,'Faces',faces,'FaceColor',FC,'FaceAlpha',FA,'EdgeColor',EC,'EdgeAlpha',EA,'LineWidth',LW,'LineStyle',LS); hold on
end
%
function [] = PlotTrajectories(tt,dt,SimInfo,ObjAircraft,FigFontSize)
pt = SimInfo.pdt;
ID = SimInfo.M;
for aa = 1:length(ID)
    if SimInfo.statusdt(dt,ID(aa)) == 1
        hold on;
        if ObjAircraft(aa).wpChange
            plot3(pt(1:dt,3*aa-2),pt(1:dt,3*aa-1),pt(1:dt,3*aa),'-','color',[1, 0, 0, 0.25],'LineWidth',1.1)
        else
            plot3(pt(1:dt,3*aa-2),pt(1:dt,3*aa-1),pt(1:dt,3*aa),'-','color',[0, 0, 0, 0.25],'LineWidth',1.1)
        end
        plot3([pt(dt,3*aa-2) ObjAircraft(ID(aa)).d(1)],[pt(dt,3*aa-1) ObjAircraft(ID(aa)).d(2)],[pt(dt,3*aa) ObjAircraft(ID(aa)).d(3)],'--','color',[0.3010, 0.7450, 0.9330, 0.25],'LineWidth',1.1)
%         plotSphere(pt(dt,3*aa-2),pt(dt,3*aa-1),pt(dt,3*aa),ObjAircraft(ID(aa)).rd,0.1,'k') % detection
%         plotSphere(pt(dt,3*aa-2),pt(dt,3*aa-1),pt(dt,3*aa),ObjAircraft(ID(aa)).ra,0.5,'y') % avoidance
%         plotSphere(pt(dt,3*aa-2),pt(dt,3*aa-1),pt(dt,3*aa),ObjAircraft(ID(aa)).rs,1,[0.4660, 0.6740, 0.1880]) % safety
%         plotCircle(pt(dt,3*aa-2),pt(dt,3*aa-1),pt(dt,3*aa),ObjAircraft(ID(aa)).rs,1,[0.4660, 0.6740, 0.1880]) % safety
        plot3(pt(dt,3*aa-2),pt(dt,3*aa-1),pt(dt,3*aa),'d','color',[0.4660, 0.6740, 0.1880],'LineWidth',1,'MarkerSize',2) % safety
        %         %         plotCircle(ObjAircraft(ID(aa)).o(1),ObjAircraft(ID(aa)).o(2),ObjAircraft(ID(aa)).o(3),ObjAircraft(ID(aa)).rs,0.1,'k') % origin
        %         %         plotCircle(ObjAircraft(ID(aa)).d(1),ObjAircraft(ID(aa)).d(2),ObjAircraft(ID(aa)).d(3),ObjAircraft(ID(aa)).rs,0.1,'k') % origin
        plot3(ObjAircraft(ID(aa)).o(1),ObjAircraft(ID(aa)).o(2),ObjAircraft(ID(aa)).o(3),'o','color',[0, 0, 0, 0.2],'LineWidth',1,'MarkerSize',2.5)
        plot3(ObjAircraft(ID(aa)).d(1),ObjAircraft(ID(aa)).d(2),ObjAircraft(ID(aa)).d(3),'x','color',[0, 0, 0, 0.2],'LineWidth',1,'MarkerSize',2.5)
%         plot3([ObjAircraft(ID(aa)).o(1) ObjAircraft(ID(aa)).d(1)],[ObjAircraft(ID(aa)).o(2) ObjAircraft(ID(aa)).d(2)],[ObjAircraft(ID(aa)).o(3) ObjAircraft(ID(aa)).d(3)],'--','color',[0, 0, 0, 0.2],'LineWidth',1.2,'MarkerSize',2.5)
%         if (ObjAircraft(ID(aa)).VTOL)
%             for wpi=size(ObjAircraft(ID(aa)).wpta,1):-1:1
%                 if ObjAircraft(ID(aa)).wpta(wpi)<=tt
%                     %                 % arrived already.
%                 elseif (tt<ObjAircraft(ID(aa)).wpta(wpi-1))&&(tt<ObjAircraft(ID(aa)).wpta(wpi))
%                     plot3([ObjAircraft(ID(aa)).wp(wpi,1) ObjAircraft(ID(aa)).wp(wpi-1,1)],[ObjAircraft(ID(aa)).wp(wpi,2) ObjAircraft(ID(aa)).wp(wpi-1,2)],[ObjAircraft(ID(aa)).wp(wpi,3) ObjAircraft(ID(aa)).wp(wpi-1,3)],':','color',[0, 0, 0, 0.5],'LineWidth',1.1)
%                 elseif (ObjAircraft(ID(aa)).wpta(wpi-1)<=tt)&&(tt<ObjAircraft(ID(aa)).wpta(wpi))
%                     plot3([pt(dt,3*aa-2) ObjAircraft(ID(aa)).wp(wpi,1)],[pt(dt,3*aa-1) ObjAircraft(ID(aa)).wp(wpi,2)],[pt(dt,3*aa) ObjAircraft(ID(aa)).wp(wpi,3)],':','color',[0, 0.4470, 0.7410, 0.5],'LineWidth',1.1)
%                     break;
%                 end
%             end
%         end
    end
    if SimInfo.statusdt(dt,ID(aa)) == 11
        hold on;
        plot3(pt(1:dt,3*aa-2),pt(1:dt,3*aa-1),pt(1:dt,3*aa),'-','color',[0, 0, 0, 0.5],'LineWidth',1.1)
        plot3([pt(dt,3*aa-2) ObjAircraft(ID(aa)).d(1)],[pt(dt,3*aa-1) ObjAircraft(ID(aa)).d(2)],[pt(dt,3*aa) ObjAircraft(ID(aa)).d(3)],'--','color',[0.3010, 0.7450, 0.9330, 0.5],'LineWidth',1.1)
%         plotSphere(pt(dt,3*aa-2),pt(dt,3*aa-1),pt(dt,3*aa),ObjAircraft(ID(aa)).rd,0.1,'k') % detection
%         plotSphere(pt(dt,3*aa-2),pt(dt,3*aa-1),pt(dt,3*aa),ObjAircraft(ID(aa)).ra,0.5,'y') % avoidance
%         plotSphere(pt(dt,3*aa-2),pt(dt,3*aa-1),pt(dt,3*aa),ObjAircraft(ID(aa)).rs,1,[0.9290, 0.6940, 0.1250]) % safety
%         plotCircle(pt(dt,3*aa-2),pt(dt,3*aa-1),pt(dt,3*aa),ObjAircraft(ID(aa)).rs,1,[0.9290, 0.6940, 0.1250]) % safety
        plot3(pt(dt,3*aa-2),pt(dt,3*aa-1),pt(dt,3*aa),'d','color',[0.9290, 0.6940, 0.1250],'LineWidth',1,'MarkerSize',2) % safety
        %         %         plotCircle(ObjAircraft(ID(aa)).o(1),ObjAircraft(ID(aa)).o(2),ObjAircraft(ID(aa)).o(3),ObjAircraft(ID(aa)).rs,0.1,'k') % origin
        %         %         plotCircle(ObjAircraft(ID(aa)).d(1),ObjAircraft(ID(aa)).d(2),ObjAircraft(ID(aa)).d(3),ObjAircraft(ID(aa)).rs,0.1,'k') % origin
        plot3(ObjAircraft(ID(aa)).o(1),ObjAircraft(ID(aa)).o(2),ObjAircraft(ID(aa)).o(3),'o','color',[0, 0, 0, 0.2],'LineWidth',1,'MarkerSize',2.5)
        plot3(ObjAircraft(ID(aa)).d(1),ObjAircraft(ID(aa)).d(2),ObjAircraft(ID(aa)).d(3),'x','color',[0.9290, 0.6940, 0.1250, 0.2],'LineWidth',1,'MarkerSize',2.5)
        if (ObjAircraft(ID(aa)).VTOL)
            for wpi=size(ObjAircraft(ID(aa)).wpta,1):-1:1
                if ObjAircraft(ID(aa)).wpta(wpi)<=tt
                    %                 % arrived already.
                elseif (tt<ObjAircraft(ID(aa)).wpta(wpi-1))&&(tt<ObjAircraft(ID(aa)).wpta(wpi))
                    plot3([ObjAircraft(ID(aa)).wp(wpi,1) ObjAircraft(ID(aa)).wp(wpi-1,1)],[ObjAircraft(ID(aa)).wp(wpi,2) ObjAircraft(ID(aa)).wp(wpi-1,2)],[ObjAircraft(ID(aa)).wp(wpi,3) ObjAircraft(ID(aa)).wp(wpi-1,3)],':','color',[0, 0, 0, 0.5],'LineWidth',1.1)
                elseif (ObjAircraft(ID(aa)).wpta(wpi-1)<=tt)&&(tt<ObjAircraft(ID(aa)).wpta(wpi))
                    plot3([pt(dt,3*aa-2) ObjAircraft(ID(aa)).wp(wpi,1)],[pt(dt,3*aa-1) ObjAircraft(ID(aa)).wp(wpi,2)],[pt(dt,3*aa) ObjAircraft(ID(aa)).wp(wpi,3)],':','color',[0, 0.4470, 0.7410, 0.5],'LineWidth',1.1)
                    break;
                end
            end
        end
    end
    if SimInfo.statusdt(dt,ID(aa)) == 10
        hold on;
        plot3(ObjAircraft(ID(aa)).o(1),ObjAircraft(ID(aa)).o(2),ObjAircraft(ID(aa)).o(3),'o','color',[0.6350, 0.0780, 0.1840, 0.2],'LineWidth',1,'MarkerSize',2.5)
        plot3(ObjAircraft(ID(aa)).d(1),ObjAircraft(ID(aa)).d(2),ObjAircraft(ID(aa)).d(3),'x','color',[0.827, 0.827, 0.827, 0.2],'LineWidth',1,'MarkerSize',2.5)
        plot3([ObjAircraft(ID(aa)).o(1) ObjAircraft(ID(aa)).d(1)],[ObjAircraft(ID(aa)).o(2) ObjAircraft(ID(aa)).d(2)],[ObjAircraft(ID(aa)).o(3) ObjAircraft(ID(aa)).d(3)],'--','color',[0.827, 0.827, 0.827, 0.2],'LineWidth',1)
%         plotSphere(pt(dt,3*aa-2),pt(dt,3*aa-1),pt(dt,3*aa),ObjAircraft(ID(aa)).rs,1,[0.6350, 0.0780, 0.1840]) % safety
        plot3(pt(dt,3*aa-2),pt(dt,3*aa-1),pt(dt,3*aa),'d','color',[0.6350, 0.0780, 0.1840],'LineWidth',1,'MarkerSize',2) % safety
    end
end
end
%plot sphere
function [] = plotSphere(x,y,z,r,FaceAlpha,FaceColor)
[u,v,w]=sphere(3);
u=r*u+x;
v=r*v+y;
w=r*w+z;
fs=surf(u,v,w);
fs.EdgeAlpha = 0;
fs.FaceAlpha = FaceAlpha;
fs.FaceColor = FaceColor;
end

function [] = plotCircle(x,y,z,r,FaceAlpha,FaceColor)
alpha = 0:pi/20:2*pi;
xd = x + r*cos(alpha);
yd = y + r*sin(alpha);
hd=fill(xd,yd,FaceColor);hold on
set(hd,'edgealpha',1,'facealpha',FaceAlpha)
end