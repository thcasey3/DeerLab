function validationfunction_test()

clc,clf

%My script
M = 200;
t = linspace(0,4,M);
r = time2dist(t);

P = rd_onegaussian(r,[4,0.3]);
K = dipolarkernel(t,r);
S = K*P;
validationnoise = 0;
S = dipolarsignal(t,r,P,'noiselevel',0.05);

S = S + whitenoise(M,validationnoise);


regparam = 5;
Pfit = fitregmodel(S,K,r,'tikh',regparam);


end

