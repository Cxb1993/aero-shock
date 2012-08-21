clear all
close all

tic
GHNC        = 0;
%CFL         = 0.9;
OUTTIME     = 0.1;
TAU			= 0.01;% !RELAXATION TIME

nx = 16; % number of elements
p  = 5;			%polinomial degree
pp =p+1;
rk =pp;			%RK order
BC_type = 0; % 0 No-flux; -1: reflecting
CFL=1/(2*p+1);
bb=1;

% filter_order=4;
% CutOff=0.75;
% 
% filter_sigma=filter_profile(p,filter_order, CutOff)

IT       = 0;
NV = 20;
NVh=20/2;
GH =[-5.38748089001,-4.60368244955,-3.94476404012,-3.34785456738, ...
    -2.78880605843,-2.25497400209,-1.73853771212,-1.2340762154,...
    -0.737473728545,-0.245340708301,0.245340708301,0.737473728545,...
    1.2340762154,1.73853771212,2.25497400209,2.78880605843,3.34785456738,...
    3.94476404012,4.60368244955,5.38748089001];
wp  =[0.898591961453,0.704332961176,0.62227869619,0.575262442852,...
    0.544851742366,0.524080350949,0.509679027117,0.499920871336,...
    0.493843385272,0.490921500667,0.490921500667,0.493843385272,...
    0.499920871336,0.509679027117,0.524080350949,0.544851742366,...
    0.575262442852,0.62227869619,0.704332961176,0.898591961453];

V=-GH;
dx=1/nx;		%Stepwidth in space
amax=abs(V(1))

% Initial State
% RL=1.0;
% UL=0.75;
% PL=1.0;
% 
% ET=PL+0.5*RL*UL^2;
% TL=4*ET/RL-2*UL^2;
% ZL=RL/sqrt(pi*TL);
% %                         T(i,m)    = 4*ET(i,m)/R(i,m) - 2*U(i,m)^2;
% %                         Z(i,m)    = R(i,m) / sqrt(pi* T(i,m));
% %                         P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
% RR=0.125;
% UR=0;
% PR=0.1;
% 
% ET=PR+0.5*RR*UR^2;
% TR=4*ET/RR-2*UR^2;
% ZR=RR/sqrt(pi*TR);
% 
UL  = 0.;
TL  = 4.38385;
ZL  = 0.2253353;
UR  = 0.;
TR  = 8.972544;
ZR  = 0.1204582;

% UR  = UL;
% TR  = TL;
% ZR  = ZL;


%nt=round(OUTTIME/dt);
[xl,w]=gauleg(pp);
[Pleg]=legtable(xl,p);
MF=zeros(NV,NV);
F=zeros(NV,nx,pp);
FEQ=zeros(NV,nx,pp);
%Fd=zeros(NV,nx,pp);
F_tmp=zeros(NV,nx,pp);
F_new=zeros(NV,nx,pp);
FS=zeros(NV,nx,pp);
% Floc=zeros(NV,nx,pp);
F_loc=zeros(NV,pp);
SR=zeros(nx,pp);
SU=zeros(nx,pp);
SE=zeros(nx,pp);
SAV=zeros(nx,pp);
R=zeros(nx,pp);
P=zeros(nx,pp);
U=zeros(nx,pp);
T=zeros(nx,pp);
Z=zeros(nx,pp);
ET=zeros(nx,pp);
AV=zeros(nx,pp);
x=zeros(1,nx*pp);
ffunc=zeros(1,pp);
alpha=zeros(1,rk);

FR=zeros(pp,1);
FU=zeros(pp,1);
FC=zeros(pp,1);
FN=zeros(pp,1);

%%%%%%%%%%%%%%  Transforming the initial condition to coefficients of Legendre Polinomials  %%%%%%%%%%%%%%%%%%%%
for i=1:nx
    xi=(2*i-1)*dx/2;      %evaluating the function `func' at the quadrature points
    x((i-1)*pp+1:i*pp)=xi+xl*dx/2;
        if(xi+xl(2)*dx/2 <= 0.5)
            U(i,:) = UL;
            T(i,:) = TL;
            Z(i,:) = ZL;
        else
            U(i,:) = UR;
            T(i,:) = TR;
            Z(i,:) = ZR;
        end
    
    for K = 1: NV
        for m=1:pp  %evaluating the function `func' at the quadrature points
            ffunc(m)  = 1/((exp((V(K)-U(i,m))^2/T(i,m))/Z(i,m)) + IT);
        end
        for j=0:p
            F(K,i,j+1)= sum (ffunc.*Pleg(j+1,:).*w)*(2*j+1)/2;
        end
    end
end

for i=1:nx
    Mtemp=zeros(NV,pp);
    for K=1:NV
        Mtemp(K,:)=F(K,i,:);
    end
    F_loc(:,:)=Mtemp*Pleg;    
    for m=1:pp
        SR(i,:) = wp * F_loc;
        SU(i,m) = sum(wp.*F_loc(:,m)'.* V);
        SE(i,m) = sum(wp.*F_loc(:,m)'.* V.^2)/2;
        SAV(i,m)= sum(wp.*F_loc(:,m)'.* abs(V));
 
        R(i,m)    = SR(i,m);
        U(i,m)    = SU(i,m)/SR(i,m);
        ET(i,m)   = SE(i,m);
        AV(i,m)   = SAV(i,m);
        T(i,m)    = 4*ET(i,m)/R(i,m) - 2*U(i,m)^2;
        Z(i,m)    = R(i,m) / sqrt(pi* T(i,m));
    end
end

    eigMF=0;    
        for i = 1:nx
            for m=1:pp
                for K = 1:NV  
                    Fd   = (exp( (V(K)-U(i,m))^2 /T(i,m) )/Z(i,m) ) + IT;
                    dFU=(2*exp( ((-U(i,m) + V(K))^2)/T(i,m)) *(-U(i,m) + V(K)))/(T(i,m)*Fd^2*Z(i,m));
                    dFT=(exp(((-U(i,m) + V(K))^2)/T(i,m))*(-U(i,m) + V(K))^2)/(T(i,m)^2*Fd^2*Z(i,m));
                    dFZ=(exp(((-U(i,m) + V(K))^2)/T(i,m)))/(Fd^2*Z(i,m)^2);
                    dRj=wp(K);
                    dUj=(wp(K)*V(K)-U(i,m)*wp(K))/R(i,m);
                    dETj=wp(K)*V(K)^2/2;
                    dTj=4*(dETj*R(i,m)-ET(i,m)*wp(K))/R(i,m)^2-4*U(i,m)*dUj;
                    dZj=(wp(K)*sqrt(T(i,m))-R(i,m)/sqrt(T(i,m))*dTj/2)/(sqrt(pi)*T(i,m));
                    dFj=dFU*dUj+dFT*dTj+dFZ*dZj;
                   % MF(K,1:NV)=dFj;
                    eigMF=max(abs(dFj),eigMF);                   
                end
            end
        end        
        eigF=NV*eigMF*pp;
        dx*CFL/6
        TAU/eigF
        dtmin=1/(eigF/TAU+1/TAU+6/(dx*CFL))
        dt=dtmin*0.5;

r_plot=reshape(R',nx*pp,1);
u_plot=reshape(U',nx*pp,1);
scrsz = get(0,'ScreenSize');
if bb==1
  
    figure('Position',[1 scrsz(4)/8 scrsz(3)/2 scrsz(4)*3/4])
    wave_handleu=plot(x,u_plot,'-');
    axis([-0.2, 1.2, -0.5, 1.5]);
   
figure('Position',[scrsz(3)/4 scrsz(4)/8 scrsz(3)/2 scrsz(4)*3/4])
    wave_handler=plot(x,r_plot,'-');

        axis([-0.2, 1.2, 0., 1.2]);
    xlabel('x'); ylabel('R(x,t)')

    drawnow
end

pause(0.2)

A=zeros(pp,pp);
b=zeros(1,pp);
c=zeros(1,pp);
for i=1:pp
    for j=1:pp
        if j>i && rem(j-i,2)==1
            A(i,j)=2;
        end
    end
    b(i)=(i-1/2)*2/dx;
    c(i)=(-1)^(i-1);
end
alpha(1)=1;
for m=1:rk
    for k=(m-1):(-1):1
        alpha(k+1)=1/k*alpha(k);
    end
    alpha(m)=1/factorial(m);
    alpha(1)=1-sum(alpha(2:m));
end

ITER  = 1;
TIME  = 0;
ISTOP = 0;
FC=zeros(pp,1);
FN=zeros(pp,1);
FB=zeros(pp,1);

while ISTOP ==0
    VIS(1:nx,1:pp) = TAU;
    
    %dt = dx * CFL/V(1);
    TIME = TIME + dt;
    dtdx = dt/dx;
    
    if (TIME > OUTTIME)
        DTCFL = OUTTIME - (TIME - dt) ;
        TIME = OUTTIME;
        dt = DTCFL;
        dtdx = dt /dx;
        ISTOP = 1;
    end
       
    %%%%%%%%%%%%  Calculating the d(eta)/d(t) for every timestep i  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    F_tmp=F;
    F_new=alpha(1)*F;
    
    for l=1:rk
        
        for i = 1:nx
            for K = 1:NV
                for m=1:pp
                    FEQ(K,i,m)   = 1/((exp( (V(K)-U(i,m))^2 /T(i,m))/Z(i,m)) + IT );
                end
            end
        end
        
        for i=1:nx
            for K = 1: NV
                FC(:)=F(K,i,:);
                FB(:)=FEQ(K,i,:);
                FC=(FC'*Pleg-FB')';
                
                for j=0:p
 %         FS(K,i,j+1)=sum (FC'.*Pleg(j+1,:).*w)*(2*j+1)/2/VIS(i,j+1);                    
                    FS(K,i,j+1)=sum (FC'.*Pleg(j+1,:).*w)*dx/2/VIS(i,j+1);
%                    FS(K,i,j+1)=0;
                end
            end
            
            
        end
        for K=1:NVh
            %phi_t(1,:)=( (A'*phi_alt(1,:)' - sum(phi_alt(1,1:pp))- sum(psi_alt(1,1:pp).* c) * c')' .* b); 
            if BC_type == 0
                %BC no-flux
            FC(:)=F(K,1,:);
            FU=FC;
            FR(:)=FS(K,1,:);
            F_tmp(K,1,:)=( (V(K)*A'*FC -V(K)* sum(FC)+ V(K)* sum(FU'.* c) * c'-FR)' .* b);
            elseif BC_type == -1            %BC reflecting
            FC(:)=F(K,1,:);
            FU(:)=F(NV-K+1,1,:);
            FR(:)=FS(K,1,:);
            F_tmp(K,1,:)=( (V(K)*A'*FC -V(K)* sum(FC)+ V(K)* sum(FU'.* c) * c'-FR)' .* b);
            else
            end
            for i=2:nx
                FU(:)=F(K,i-1,:);
                FC(:)=F(K,i,:);
                FR(:)=FS(K,i,:);
                F_tmp(K,i,:)=( (V(K)*A'*FC -V(K)* sum(FC) +V(K)* sum(FU) * c'-FR)' .* b);
                % phi_t(i,:)=( (A'*phi_alt(i,:)' - sum(phi_alt(i,1:pp)) + sum(phi_alt(i-1,1:pp)) * c')' .* b);
            end
            
            for i=1:nx-1
                FU(:)=F(NVh+K,i+1,:);
                FC(:)=F(NVh+K,i,:);
                FR(:)=FS(NVh+K,i,:);
                F_tmp(NVh+K,i,:)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU'.* c) + V(NVh+K)*sum(FC'.* c) * c'-FR)' .* b);
                %F_tmp(NVh+K,i,:)=( (A'*-psi_alt(i,:)' + sum(psi_alt(i+1,1:pp).* c) - sum(psi_alt(i,1:pp).* c) * c')' .* b);
            end
            %            psi_t(nx,:)=( (A'*-psi_alt(nx,:)' - sum(phi_alt(nx,1:pp)) - sum(psi_alt(nx,1:pp).*c) * c')' .* b);
            if BC_type == 0
                %BC no-flux
            FC(:)=F(NVh+K,nx,:);
            FU=FC;
            %FB(:)=F(NVh-K+1,nx,:);
            FR(:)=FS(NVh+K,nx,:);
            F_tmp(NVh+K,nx,:)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU) +V(NVh+K)* sum(FC'.*c) * c'-FR)' .* b);
            elseif BC_type == -1
                %BC reflexting
            FC(:)=F(NVh+K,nx,:);
            FU(:)=F(NVh-K+1,nx,:);
            FR(:)=FS(NVh+K,nx,:);
            F_tmp(NVh+K,nx,:)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU) +V(NVh+K)* sum(FC'.*c) * c'-FR)' .* b);           
            end
        end % loop for NV
        
        if l<rk
            %                 phi=phi+ alpha(l+1)*(phi_alt+dt*phi_t);
            %                 phi_alt=phi_alt+dt*phi_t;
            %                 psi=psi+ alpha(l+1)*(psi_alt+dt*psi_t);
            %                 psi_alt=psi_alt+dt*psi_t;
            F_new=F_new+ alpha(l+1)*(F+dt*F_tmp);
            F=F+dt*F_tmp;
            
            for i=1:nx
                Mtemp=zeros(NV,pp);
                for K=1:NV
                    Mtemp(K,:)=F(K,i,:);
                end
                F_loc(:,:)=Mtemp*Pleg;
                for m=1:pp
                    SR(i,:) = wp * F_loc;
                    SU(i,m) = sum(wp.*F_loc(:,m)'.* V);
                    SE(i,m) = sum(wp.*F_loc(:,m)'.* V.^2)/2;
                    SAV(i,m)= sum(wp.*F_loc(:,m)'.* abs(V));

                    R(i,m)    = SR(i,m);
                    U(i,m)    = SU(i,m)/SR(i,m);
                    ET(i,m)   = SE(i,m);
                    AV(i,m)   = SAV(i,m);
                end
            end
            
            if (IT == 0)
                for i=1:nx
                    for m=1:pp
                        T(i,m)    = 4*ET(i,m)/R(i,m) - 2*U(i,m)^2;
                        Z(i,m)    = R(i,m) / sqrt(pi* T(i,m));
                        P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
                    end
                end
            else
                for i=1:nx
                    for m=1:pp
                        
                        ZA = 0.0001;
                        ZB = 0.99;
                        while (abs(ZA-ZB) > 0.00001)
                            GA12 = 0;
                            GB12 = 0;
                            GA32 = 0;
                            GB32 = 0;
                            for L = 1:50
                                if (IT == 1)
                                    GA12 = GA12 + (ZA^L)*(-1)^(L-1)/(L^0.5);
                                    GB12 = GB12 + (ZB^L)*(-1)^(L-1)/(L^0.5);
                                    GA32 = GA32 + (ZA^L)*(-1)^(L-1)/(L^1.5);
                                    GB32 = GB32 + (ZB^L)*(-1)^(L-1)/(L^1.5);
                                else
                                    GA12 = GA12 + (ZA^L)/(L^0.5);
                                    GB12 = GB12 + (ZB^L)/(L^0.5);
                                    GA32 = GA32 + (ZA^L)/(L^1.5);
                                    GB32 = GB32 + (ZB^L)/(L^1.5);
                                end
                            end
                            PSIA = 2*ET(i,m) - GA32*(R(i,m)/GA12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                            PSIB = 2*ET(i,m) - GB32*(R(i,m)/GB12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                            ZC = (ZA + ZB)/2;
                            GC12 = 0;
                            GC32 = 0;
                            GC52 = 0;
                            for L = 1:50
                                if  (IT == 1)
                                    GC12 = GC12 + (ZC^L)*(-1)^(L-1)/(L^0.5);
                                    GC32 = GC32 + (ZC^L)*(-1)^(L-1)/(L^1.5);
                                    GC52 = GC52 + (ZC^L)*(-1)^(L-1)/(L^2.5);
                                else
                                    GC12 = GC12 + (ZC^L)/(L^0.5);
                                    GC32 = GC32 + (ZC^L)/(L^1.5);
                                    GC52 = GC52 + (ZC^L)/(L^2.5);
                                end
                            end
                            PSIC = 2*ET(i,m) - GC32*(R(i,m)/GC12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                            
                            if ((PSIA*PSIC) < 0)
                                ZB = ZC;
                            else
                                ZA = ZC;
                            end
                        end
                        Z(i,m) = ZC;
                        T(i,m) = R(i,m)^2 / (pi*GC12^2 );
                        P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
                        
                    end
                end
            end %if IT
            
        else
            F_new=F_new+ alpha(rk)*dt*F_tmp;
            %                 phi=phi+ alpha(rk)*dt*phi_t;
            %                 psi=psi+ alpha(rk)*dt*psi_t;
        end
    end % RK
    F=F_new;
    for i=1:nx
        Mtemp=zeros(NV,pp);
        for K=1:NV
            Mtemp(K,:)=F(K,i,:);
        end
        F_loc(:,:)=Mtemp*Pleg;
        for m=1:pp
            SR(i,:) = wp * F_loc;
            SU(i,m) = sum(wp.*F_loc(:,m)'.* V);
            SE(i,m) = sum(wp.*F_loc(:,m)'.* V.^2)/2;
            SAV(i,m)= sum(wp.*F_loc(:,m)'.* abs(V));

            R(i,m)    = SR(i,m);
            U(i,m)    = SU(i,m)/SR(i,m);
            ET(i,m)   = SE(i,m);
            AV(i,m)   = SAV(i,m);
        end
    end
    
    if (IT == 0)
        for i=1:nx
            for m=1:pp
                T(i,m)    = 4*ET(i,m)/R(i,m) - 2*U(i,m)^2;
                Z(i,m)    = R(i,m) / sqrt(pi* T(i,m));
                P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
            end
        end
    else
        for i=1:nx
            for m=1:pp
                ZA = 0.0001;
                ZB = 0.99;
                while (abs(ZA-ZB) > 0.00001)
                    GA12 = 0;
                    GB12 = 0;
                    GA32 = 0;
                    GB32 = 0;
                    for L = 1:50
                        if (IT == 1)
                            GA12 = GA12 + (ZA^L)*(-1)^(L-1)/(L^0.5);
                            GB12 = GB12 + (ZB^L)*(-1)^(L-1)/(L^0.5);
                            GA32 = GA32 + (ZA^L)*(-1)^(L-1)/(L^1.5);
                            GB32 = GB32 + (ZB^L)*(-1)^(L-1)/(L^1.5);
                        else
                            GA12 = GA12 + (ZA^L)/(L^0.5);
                            GB12 = GB12 + (ZB^L)/(L^0.5);
                            GA32 = GA32 + (ZA^L)/(L^1.5);
                            GB32 = GB32 + (ZB^L)/(L^1.5);
                        end
                    end
                    PSIA = 2*ET(i,m) - GA32*(R(i,m)/GA12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                    PSIB = 2*ET(i,m) - GB32*(R(i,m)/GB12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                    ZC = (ZA + ZB)/2;
                    GC12 = 0;
                    GC32 = 0;
                    GC52 = 0;
                    for L = 1:50
                        if  (IT == 1)
                            GC12 = GC12 + (ZC^L)*(-1)^(L-1)/(L^0.5);
                            GC32 = GC32 + (ZC^L)*(-1)^(L-1)/(L^1.5);
                            GC52 = GC52 + (ZC^L)*(-1)^(L-1)/(L^2.5);
                        else
                            GC12 = GC12 + (ZC^L)/(L^0.5);
                            GC32 = GC32 + (ZC^L)/(L^1.5);
                            GC52 = GC52 + (ZC^L)/(L^2.5);
                        end
                    end
                    PSIC = 2*ET(i,m) - GC32*(R(i,m)/GC12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                    
                    if ((PSIA*PSIC) < 0)
                        ZB = ZC;
                    else
                        ZA = ZC;
                    end
                end
                Z(i,m) = ZC;
                T(i,m) = R(i,m)^2 / (pi*GC12^2 );
                P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
            end
        end
    end %if IT
    
      eigMF=0;    
        for i = 1:nx
            for m=1:pp
                for K = 1:NV  
                    Fd   = (exp( (V(K)-U(i,m))^2 /T(i,m))/Z(i,m)) + IT;
                    FEQ(K,i,m)   = 1/((exp( (V(K)-U(i,m))^2 /T(i,m))/Z(i,m)) + IT );
                    dFU=(2*exp(((-U(i,m) + V(K))^2)/T(i,m))*(-U(i,m) + V(K)))/(T(i,m)*Fd^2*Z(i,m));
                    dFT=(exp(((-U(i,m) + V(K))^2)/T(i,m))*(-U(i,m) + V(K))^2)/(T(i,m)^2*Fd^2*Z(i,m));
                    dFZ=(exp(((-U(i,m) + V(K))^2)/T(i,m)))/(Fd^2*Z(i,m)^2);
                    dRj=wp(K);
                    dUj=(wp(K)*V(K)-U(i,m)*wp(K))/R(i,m);
                    dETj=wp(K)*V(K)^2/2;
                    dTj=4*(dETj*R(i,m)-ET(i,m)*wp(K))/R(i,m)^2-4*U(i,m)*dUj;
                    dZj=(wp(K)*sqrt(T(i,m))-R(i,m)/sqrt(T(i,m))*dTj/2)/(sqrt(pi)*T(i,m));
                    dFj=dFU*dUj+dFT*dTj+dFZ*dZj;
                    MF(K,1:NV)=dFj;
                    eigMF=max(abs(dFj),eigMF);                   
                end
                %eigMF=max(abs(eig(transpose(MF)*MF)));
                %eigF=max(eigF,sqrt(eigMF));
                eigF=NV*eigMF*pp;
            end
        end

        dt_tmp=1/(eigF/TAU+1/TAU+6/(dx*CFL));

    r_plot=reshape(R',nx*pp,1);
    u_plot=reshape(U',nx*pp,1);
    if bb==1
        set(wave_handleu,'YData',u_plot); 
        set(wave_handler,'YData',r_plot); 
        drawnow
        %         set(wave_handlev,'YData',u_plot); drawnow
    end
    if dt_tmp <dtmin
           ITER
           dtmin=dt_tmp%;
           dt=dtmin*0.5;
           pause(0.1)
       end
    
    %fprintf('1X ELAPSED TIME: %f7.4,4 DENSITY AT X=4.0,Y=5.: %f7.4\n', TIME, R(NXP1/2))
    
    ITER = ITER + 1;
    
end

toc


