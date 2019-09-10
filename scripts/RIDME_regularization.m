%======================================================================
% DeerAnalyis2
% Example: Processing RIDME with strong background
% Comparison of processing RIDME's background by correction or by kernel
% definition.
%=======================================================================

clear,clc,clf

%Preparation
%----------------------------------------------
N = 200;
t = linspace(-0.2,8,N);
r = time2dist(t);
P = rd_onegaussian(r,[4,0.3]);
B = td_strexp(t,[0.2,5]);

%Generate RIDME signal
%----------------------------------------------
Tmix = 50; %Mixing time [us]
T1 = 88;   %Relaxation time [us]
OverCoeff = overtones(2,Tmix,T1);
V = dipolarsignal(t,r,P,'ModDepth',0.4,'Overtones',OverCoeff,...
                        'Background',B,'NoiseLevel',0.02);      
%Fit the background
[Bfit,lambdafit,Bparam] = fitbackground(V,t,@td_strexp);

%Fitting (background-correction)
%----------------------------------------------
%Correct by division
Vcorr = V./Bfit;
%Regularize background-corrected data
K = dipolarkernel(t,r,lambdafit,'OvertoneCoeffs',OverCoeff);
alpha = selregparam(Vcorr,K,'tikh','aic');
Pfit = fitregmodel(Vcorr,K,r,'tikh',alpha);

%Fitting (Kernel-based)
%----------------------------------------------
K2 = dipolarkernel(t,r,lambdafit,Bfit,'OvertoneCoeffs',OverCoeff);
alpha = selregparam(V,K2,'tikh','aic');
Pfit2 = fitregmodel(V,K2,r,'tikh',alpha);

%Plotting
%----------------------------------------------
subplot(141)
plot(t,V,'k',t,Bfit*(1-lambdafit),'b','LineWidth',1)
legend('Exp.','B_{fit}')
axis tight, box on, grid on
xlabel('Time [\mus]')
ylabel('V(t)')
title('Original Data')

subplot(142)
plot(t,Vcorr,'k',t,K*Pfit,'r','LineWidth',1)
legend('Exp.','Fit')
axis tight, box on, grid on
xlabel('Time [\mus]')
ylabel('V(t)')
title('Background correction')

subplot(143)
plot(t,V,'k',t,K2*Pfit2,'b','LineWidth',1)
legend('Exp.','Fit')
axis tight, box on, grid on
xlabel('Time [\mus]')
ylabel('V(t)')
title('No background correction')

subplot(144)
plot(r,P,'k',r,Pfit,'r',r,Pfit2,'b','LineWidth',1)
legend('Truth','B divided','B not divided')
axis tight, box on, grid on
xlabel('Distance [nm]')
ylabel('P(r)')
title('Distance Distributions')
