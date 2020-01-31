function [err,data,maxerr] = test(opt,olddata)

rng(2)
t = linspace(0,4,200);
r = time2dist(t);

Parameters.regparam = linspace(0.1,1,3);
Parameters.type = {'tikh','tv'};

if opt.Display
    f = figure(1); clf;AxisHandle = axes(f);
else
    AxisHandle = [];
end

stats = sensitivan(@myfitting,Parameters,'AxisHandle',AxisHandle);
Median = stats.med;
Upper = stats.p75;
Lower = stats.p25;

err = false;
data = [];
maxerr = NaN;

if opt.Display
        cla
        hold on
        plot(r,Median,'b','LineWidth',1)
        f = fill([r fliplr(r)] ,[Upper.' fliplr(Lower.')],...
            'b','LineStyle','none');
        f.FaceAlpha = 0.5;
        hold('off')
        axis('tight')
        grid('on')
        box('on')
end

end


function Pfit = myfitting(param)
M = 200;
t = linspace(0,4,M);
r = time2dist(t);

P = rd_onegaussian(r,[4,0.3]);
K = dipolarkernel(t,r);
S = K*P;
S = dipolarsignal(t,r,P,'noiselevel',0.05);


regparam = param.regparam;
Pfit = fitregmodel(S,K,r,param.type,regparam);

end