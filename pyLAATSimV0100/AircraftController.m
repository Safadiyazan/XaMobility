function [SimInfo,ObjAircraft] = AircraftController(SimInfo,ObjAircraft,Settings)
Sim = Settings.Sim;
Aircraft = Settings.Aircraft;
Airspace = Settings.Airspace;
Mact = SimInfo.Mact;
t = SimInfo.t;
%%
vm_matrix=zeros(3*length(SimInfo.Mact),length(SimInfo.Mact));
for aa=1:length(SimInfo.Mact)
    % TODO: Only aircraft in detection radius
    Diffaaxyz = (ObjAircraft(SimInfo.Mact(aa)).fpt.*ones(length(SimInfo.Mact),1) - cat(1,ObjAircraft(SimInfo.Mact).fpt));
    Distanceaa =  vecnorm(Diffaaxyz')';
    Vectorrd = cat(1,(ObjAircraft(SimInfo.Mact).rd)) + (ObjAircraft(SimInfo.Mact(aa)).rd).*ones(length(SimInfo.Mact),1);
    BolInrd = all([(0<Distanceaa),(Distanceaa<=Vectorrd)],2)';
    MactDetaa = cat(1,ObjAircraft(SimInfo.Mact(BolInrd)).id);
%     MactDetaa = SimInfo.Mact;
    for aaj=1:length(MactDetaa)
        if SimInfo.Mact(aa)~=MactDetaa(aaj)
            %Verification
            % Q- What is the problem?
            if norm((ObjAircraft(SimInfo.Mact(aa)).pt) - (ObjAircraft(MactDetaa(aaj)).pt)) - (ObjAircraft(SimInfo.Mact(aa)).rs + ObjAircraft(MactDetaa(aaj)).rs) < 0
                SimInfo.cc = SimInfo.cc + 1;
                SimInfo.Objcc(SimInfo.cc).t = t;
                SimInfo.Objcc(SimInfo.cc).ids = [SimInfo.Mact(aa),MactDetaa(aaj)];
                SimInfo.Objcc(SimInfo.cc).dis = norm((ObjAircraft(SimInfo.Mact(aa)).pt) - (ObjAircraft(MactDetaa(aaj)).pt));
                SimInfo.Objcc(SimInfo.cc).desireddis = (ObjAircraft(SimInfo.Mact(aa)).rs + ObjAircraft(MactDetaa(aaj)).rs);
            end
            %             %-------V3----------
            ksiaa = ObjAircraft(SimInfo.Mact(aa)).fpt;
            ksiaaj = ObjAircraft(MactDetaa(aaj)).fpt;
            ksimil = ksiaa-ksiaaj;
            rai = (ObjAircraft(SimInfo.Mact(aa)).ra*Aircraft.Gainfactor_ra);
            raj = (ObjAircraft(MactDetaa(aaj)).ra*Aircraft.Gainfactor_ra);
            rsi = (ObjAircraft(SimInfo.Mact(aa)).rs*Aircraft.Gainfactor_rs);
            rsj = (ObjAircraft(MactDetaa(aaj)).rs*Aircraft.Gainfactor_rs);
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
                dVmijDown = (1+e) - ds_ij;%(1+e) - (rsi+rsj)*ds_ij;
                b_ij = ( (dVmijUp/VmijDown) + VmijUp*(-dVmijDown)/(VmijDown^2) )*(1/norm(ksimil));
                vm_matrix(3*aa-2:3*aa,MactDetaa(aaj)==SimInfo.Mact) = - b_ij*ksimil;
            end
        end
    end
end

for aa=1:length(SimInfo.Mact)
    ObjAircraft(SimInfo.Mact(aa)).vct = mycontrol(aa,vm_matrix,SimInfo.Mact,ObjAircraft);
    [SimInfo,ObjAircraft] = AircraftMotion(aa,SimInfo,ObjAircraft,Settings);
end
end
%% Additional Function for the control.
%%
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
function u = mycontrol(aa,matrix,Mact,ObjAircraft)
fpt  =  ObjAircraft(Mact(aa)).fpt;
wpt  =  ObjAircraft(Mact(aa)).wp(ObjAircraft(Mact(aa)).wpCR+1,:);
vm = ObjAircraft(Mact(aa)).vm;
k1 = 1;
ksi_w  = fpt  - wpt;
Vw = - mysat(k1*ksi_w',vm);
Vmx=sum(matrix(3*aa-2,:));
Vmy=sum(matrix(3*aa-1,:));
Vmz=sum(matrix(3*aa,:));
Vm=[Vmx;Vmy;Vmz];
u = mysat(Vw+Vm,vm);
end
%%
function [u] = mysat(x,a)
if norm(x)>a
    u =a*x/norm(x);
else
    u =x ;
end
end
