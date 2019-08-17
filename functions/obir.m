%
% OBIR Osher's Bregman-iterated regularization method
%
%   P = OBIR(S,K,r,'type',L,alpha)
%   OBIR of the N-point signal (S) to a M-point distance
%   distribution (P) given a M-point distance axis (r) and NxM point kernel
%   (K). The (M-2)xM point regularization matrix (L) and regularization
%   parameter (alpha) control the regularization properties.
%
%   The type of regularization employed in OBIR is set by the 'type'
%   input argument. The regularization models implemented in OBIR are:
%          'tikhonov' -   Tikhonov regularization
%          'tv'       -   Total variation regularization
%          'huber'    -   pseudo-Huber regularization
%
%   P = OBIR(...,'Property',Value)
%   Additional (optional) arguments can be passed as property-value pairs.
% 
%  The property-value pairs to be passed as options can be set in any order.
%       'NoiseLevelAim' - Level (standard deviation) of noise at which 
%                         Bregman iterations are to stop.
%
%       'DivergenceStop'- True/false forces Bregman iterations to stop if
%                         the evolution of the fit's standard deviation 
%                         starts to diverge. 
%
%       'MaxOuterIter' - Maximal number of Bregman iterations.
%
%       'Solver' - Minimization solver (default = 'fnnls')
%                      'fmincon' - Non linear constrained minimization
%                      'fnnls' - Fast non-negative least-squares
%
%       'TolFun' - Optimizer function tolerance
%
%       'MaxIter' - Maximum number of optimizer iterations
%
%       'MaxFunEvals' - Maximum number of optimizer function evaluations   
%
%       'AxisHandle' - Function handle to plot the state of the distance
%                      distribution at each iteration     
%
% Copyright(C) 2019  Luis Fabregas, DeerAnalysis2
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.


function [Distribution,ConvergenceCurve] = obir(Signal,Kernel,DistanceAxis,RegType,RegMatrix,RegParam,varargin)

if ~iscolumn(Signal)
    Signal = Signal';
end

%Get optional parameters
[NoiseLevelAim,Solver,MaxIter,TolFun,MaxFunEvals,DivergenceStop,MaxOuterIter,HuberParam,AxisHandle] = parseoptional({'NoiseLevelAim','Solver','MaxIter','TolFun','MaxFunEvals','DivergenceStop','MaxOuterIter','HuberParam','AxisHandle'},varargin);


if isempty(TolFun)
    TolFun = 1e-10;
else
    validateattributes(TolFun,{'numeric'},{'scalar','nonnegative'},mfilename,'TolFun')
end

if isempty(MaxOuterIter)
    MaxOuterIter = 5000;
else
    validateattributes(MaxOuterIter,{'numeric'},{'scalar','nonnegative'},mfilename,'MaxOuterIter')
end

if isempty(HuberParam)
    HuberParam = 1.35;
else
    validateattributes(HuberParam,{'numeric'},{'scalar','nonnegative'},mfilename,'HuberParam')
end

if isempty(MaxFunEvals)
    MaxFunEvals = 500000;
else
    validateattributes(MaxFunEvals,{'numeric'},{'scalar','nonnegative'},mfilename,'MaxFunEvals')
end

if isempty(MaxIter)
    MaxIter = 500000;
else
    validateattributes(MaxIter,{'numeric'},{'scalar','nonnegative'},mfilename,'MaxIter')
end

if isempty(Solver)
    Solver = 'fnnls';
else
    validateattributes(Solver,{'char'},{'nonempty'},mfilename,'Solver')
    validInputs = {'fnnls','fmincon'};
    validatestring(Solver,validInputs);
end

if isempty(NoiseLevelAim)
    NoiseLevelAim = noiselevel(Signal);
else
    validateattributes(NoiseLevelAim,{'numeric'},{'scalar','nonempty','nonnegative'},mfilename,'NoiseLevelAim')
end
validateattributes(RegParam,{'numeric'},{'scalar','nonempty','nonnegative'},mfilename,'RegParam')
validateattributes(Signal,{'numeric'},{'nonempty'},mfilename,'Signal')
validateattributes(Kernel,{'numeric'},{'nonempty'},mfilename,'Kernel')
validateattributes(RegMatrix,{'numeric'},{'nonempty'},mfilename,'RegMatrix')
checklengths(Signal,Kernel);

if nargin<3 || isempty(RegType)
    RegType = 'tikhonov';
elseif isa(RegType,'function_handle')
    RegFunctional = RegType;
    RegType = 'custom';
else
    validateattributes(RegType,{'char'},{'nonempty'},mfilename,'RegType')
    allowedInput = {'tikhonov','tv','huber'};
    validatestring(RegType,allowedInput);
end


%--------------------------------------------------------------------------
% Parse & Validate Optional Input
%--------------------------------------------------------------------------

if isempty(MaxOuterIter)
    MaxOuterIter = 200;
else
    validateattributes(MaxOuterIter,{'numeric'},{'scalar','nonempty'},mfilename,'MaxOuterIter')
end

if isempty(MaxIter)
    MaxIter = 200000;
else
    validateattributes(MaxIter,{'numeric'},{'scalar','nonempty'},mfilename,'MaxIter')
end


if isempty(MaxFunEvals)
    MaxFunEvals = 200000;
else
    validateattributes(MaxFunEvals,{'numeric'},{'scalar','nonempty'},mfilename,'MaxFunEvals')
end

if isempty(DivergenceStop)
    DivergenceStop = false;
else
    validateattributes(DivergenceStop,{'logical'},{'nonempty'},mfilename,'DivergenceStop')
end

%--------------------------------------------------------------------------
% Preparation
%--------------------------------------------------------------------------

%Initialize
SizeDistribution = length(Signal);
Subgradient = zeros(SizeDistribution,1);
Counter = 1;
Iteration = 1;
Distribution = zeros(SizeDistribution,1);

%--------------------------------------------------------------------------
% Osher's Bregman Iterations Algorithm
%--------------------------------------------------------------------------

Dimension = length(Signal);
InitialGuess = zeros(Dimension,1);
NonNegConst = zeros(Dimension,1);

while Iteration <= MaxOuterIter
    
    %Store privous iteration distribution
    CheckDistribution = Distribution;
    
    switch Solver
        case 'fmincon'
            %Define current minimization problem
            RegFunctional = regfunctional(RegType,Signal,RegMatrix,Kernel,RegParam,HuberParam);
            fminconFunctional = @(Distribution)OBIRFunctional(Distribution,RegFunctional,Subgradient);
            fminconOptions = optimset('GradObj','on','MaxFunEvals',MaxFunEvals,'Display','off','MaxIter',MaxIter);
            %Run minimzation
            Distribution =  fmincon(fminconFunctional,InitialGuess,[],[],[],[],NonNegConst,[],[],fminconOptions);
        case 'fnnls'
            
            [Q,KtS] = lsqcomponents(Signal,Kernel,RegMatrix,RegParam,RegType,HuberParam);
            KtS = KtS - Subgradient;
            Distribution = fnnls(Q,KtS,InitialGuess,TolFun);
            %In some cases, fnnls may return negatives if tolerance is to high
            if any(Distribution < 0)
                %... in those cases continue from current solution
                Distribution = fnnls(Q,KtS,Distribution,1e-20);
            end
    end
    %Store current convergence curve point
    ConvergenceCurve(Iteration) = std(Kernel*Distribution - Signal);
    
    %If hook to axes is given, then plot the current Distribution
    if ~isempty(AxisHandle)
        set(AxisHandle,'YData',Distribution)
        drawnow
    end
    %Update subgradient at current solution
    Subgradient = Subgradient + Kernel'*(Kernel*Distribution - Signal);
    
    
    
    %--------------------------------------------------------------------------
    %Iteration Control
    %--------------------------------------------------------------------------
    if Iteration == 1
        %If at first iteration, thae residual deviation is already below the noise deviation then impose oversmoothing and remain at first iteration
        if NoiseLevelAim  > std(Kernel*Distribution - Signal)
            RegParam = RegParam*2^Counter;
            Counter = Counter + 1;
        else
            %Once the residual deviation is above the treshold, then proceed further with the Bregman iterations
            Iteration  = Iteration +1;
        end
    else
        %For the rest of the Bregman iterations control the condition and stop when fulfilled
        if NoiseLevelAim  > std(Kernel*Distribution - Signal)
            break;
        else
            Iteration  = Iteration +1;
        end
        %If residual deviation starts to diverge, stop
        if DivergenceStop && std(Kernel*CheckDistribution - Signal) < std(Kernel*Distribution - Signal)
            Distribution = CheckDistribution;
            break;
        end
    end
    
end

%Normalize distribution integral
Distribution = Distribution/sum(Distribution)/mean(diff(DistanceAxis));

end

function [Functional,Gradient] = OBIRFunctional(Distribution,RegFunctional,Subgradient)
[FunctionalPart,GradientPart] =  RegFunctional(Distribution);
Functional = FunctionalPart + dot(Distribution,Subgradient);
Gradient = GradientPart + Subgradient;
end