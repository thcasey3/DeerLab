%
% SELECTMODEL Optimal parametric model selection
%
%   opt = SELECTMODEL({@model1,...,@modelN},S,r,K,{'aic',...})
%   Evaluates the fits of the parametric models (model1,...,modelN) to a
%   signal (S) according to the dipolar kernel (K) and distance axis (r).
%   The models must be passed as a cell array of function handles. Each fit
%   is then evaluated according to the model selection criterions 
%   ('aic','aicc','bic') specified in the last input argument M-point cell array. 
%   Function returns a M-point array containing the optimal models
%   according to each selection method.
%
%   [opt,f] = SELECTMODEL(...)
%   Returns the method selector functionals for the different methods.
%
%   opt = SELECTMODEL(...,'Property',Value)
%   Additional (optional) arguments can be passed as property-value pairs.
%
%   See "help fitparamodel" for a detailed list of the property-value pairs
%   accepted by the function.
%
%
% Copyright(C) 2019  Luis Fabregas, DeerAnalysis2
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.


function [optima,functionals] = selectmodel(Models,S,r,K,Methods,varargin)

%Input validation
if ~iscell(Methods)
   Methods = {Methods}; 
end
if ~iscolumn(r)
    r = r.';
end
if length(varargin)==1
   varargin = varargin{1}; 
end
allowedMethodInputs = {'aic','aicc','bic'};
if iscell(Methods)
    for i=1:length(Methods)
        if strcmp(Methods{i},'all')
            Methods = allowedMethodInputs;
            break;
        end
        validateattributes(Methods{i},{'char'},{'nonempty'})
        Methods{i} = validatestring(Methods{i},allowedMethodInputs);
    end
else
    validateattributes(Methods,{'char'},{'nonempty'})
    if strcmp(Methods,'all')
        Methods = allowedMethodInputs;
    else
        Methods = validatestring(Methods,allowedMethodInputs);
        Methods = {Methods};
    end
end

%Convert distance axis to nanoseconds if givne in Angstrom
if ~isnanometer(r)
   r = r/10; 
end


%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%Pre-allocate vectors
N = length(S);
aicc = zeros(length(Models),1);
bic = zeros(length(Models),1);
aic = zeros(length(Models),1);
%Run the different parametric model fits
for i=1:length(Models)
    currentModel = Models{i};
    Info = currentModel();
    [~,FitP] = fitparamodel(S,currentModel,r,K,varargin);
    Q = Info.nParam + 1;
    aicc(i) = N*log(sum(K*FitP - S).^2/N) + 2*Q + (2*Q*(Q+1))/(N - Q - 1);
    aic(i) = N*log(sum(K*FitP - S).^2/N) + 2*Q;
    bic(i) = N*log(sum(K*FitP - S).^2/N) + Q*log(N);
end

%Apply the requested selection methods
optima = zeros(length(Methods),1);
functionals = cell(length(Methods),1);
for i=1:length(Methods)
    currentMethod = Methods{i};
    switch currentMethod
        case 'aic'
            functional = aic;
            [~,optimum] = min(functional);
        case 'aicc'
            functional = aicc;
            [~,optimum] = min(functional);
        case 'bic'
            functional = bic;
            [~,optimum] = min(functional);
    end
    functionals{i} = functional;
    optima(i) = optimum;
end

if length(functionals)==1
   functionals = functionals{1}; 
end

