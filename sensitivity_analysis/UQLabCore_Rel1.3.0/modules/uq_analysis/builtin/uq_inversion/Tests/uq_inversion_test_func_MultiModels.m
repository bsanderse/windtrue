function [success] = uq_inversion_test_func_MultiModels(level)
% UQ_INVERSION_TEST_FUNC_MULTIMODELS tests the functionality of 
%   Bayesian inversion module for multiple forward models.
%
%   See also: UQ_SELFTEST_UQ_INVERSION

%% START UQLAB
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| uq_inversion_test_func_MultiModels...\n']);

%% PROBLEM SETUP
load('uq_Example_BayesianLinearRegression');

%% PRIOR DISTRIBUTION
Prior.Name = 'Prior distribution';
for i = 1:Model.M*2
  Prior.Marginals(i).Name = sprintf('X%i',i);
  Prior.Marginals(i).Type = 'Gaussian';
  Prior.Marginals(i).Parameters = [0,1];
end
PriorDist = uq_createInput(Prior);

%% FORWARD MODEL
ModelOpt.Name = 'Forward model';
ModelOpt.mHandle = @(x) x * Model.A;
ModelOpt.isVectorized = true;
myModel = uq_createModel(ModelOpt);

% model structure
ForwardModel(1).Model = myModel;
ForwardModel(1).PMap = 1:8;
ForwardModel(2).Model = myModel;
ForwardModel(2).PMap = 9:16;

%% DATA
myData(1).y = [Data,Data(1:12);Data,Data(1:12)];
myData(1).MOMap = [ones(1,24),2*ones(1,12);...
                (1:24),(1:12)];
            
myData(2).y = [Data(13:24);Data(13:24)];
myData(2).MOMap = [2*ones(1,12);...
                (13:24)];

%% DISCREPANCY MODEL
DiscrepancyOpt(1).Type = 'Gaussian';
DiscrepancyOpt(1).Parameters = 1;

SigmaOpt.Name = 'Prior of sigma';
SigmaOpt.Marginals(1).Name = 'Sigma';
SigmaOpt.Marginals(1).Type = 'Uniform';
SigmaOpt.Marginals(1).Parameters = [0,20];
SigmaDist = uq_createInput(SigmaOpt);
DiscrepancyOpt(2).Type = 'Gaussian';
DiscrepancyOpt(2).Prior = SigmaDist;

%% SOLVER SETTINGS
% use MCMC with very few steps
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AM';
Solver.MCMC.Steps = 100;
Solver.MCMC.NChains = 2;
Solver.MCMC.Proposal.PriorScale = 1; 
Solver.MCMC.T0 = 1e3;

%% BAYESIAN MODEL
BayesOpt.Type = 'Inversion';
BayesOpt.Name = 'Bayesian model';
BayesOpt.Prior = PriorDist;
BayesOpt.ForwardModel = ForwardModel;
BayesOpt.Data = myData;
BayesOpt.Discrepancy = DiscrepancyOpt;
BayesOpt.Solver = Solver;
BayesianAnalysis = uq_createAnalysis(BayesOpt);

%% SOME TESTING
try
  uq_inversion_test_InversionObject(BayesianAnalysis);
  success = 1;
catch
  success = 0;
end