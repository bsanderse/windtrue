function [success] = uq_inversion_test_display(level)
% UQ_INVERSION_TEST_DISPLAY tests the UQ_DISPLAY_UQ_INVERSION function
%
%   See also: UQ_SELFTEST_UQ_INVERSION

%% START UQLAB
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| uq_inversion_test_func_AM...\n']);

%% PROBLEM SETUP
load('uq_Example_BayesianLinearRegression', 'Data', 'Model');

%% PRIOR DISTRIBUTION
Prior.Name = 'Prior distribution';
for i = 1:Model.M
  Prior.Marginals(i).Name = sprintf('X%i',i);
  Prior.Marginals(i).Type = 'Gaussian';
  Prior.Marginals(i).Parameters = [0,1];
end
PriorDist = uq_createInput(Prior);

%% FORWARD MODEL
ModelOpt.Name = 'Forward model';
ModelOpt.mHandle = @(x) x * Model.A;
ModelOpt.isVectorized = true;
ForwardModel.Model = uq_createModel(ModelOpt);

%% SOLVER
Solver.MCMC.Sampler = 'AIES';
Solver.MCMC.Steps = 2;
Solver.MCMC.nChains = 3;

%% BAYESIAN MODEL
BayesOpt.Type = 'Inversion';
BayesOpt.Name = 'Bayesian model';
BayesOpt.Prior = PriorDist;
BayesOpt.ForwardModel = ForwardModel;
BayesOpt.Solver = Solver;
BayesOpt.Data.y = Data;
BayesianAnalysis = uq_createAnalysis(BayesOpt);
%% TEST display
try
    uq_display(BayesianAnalysis,...
        'acceptance','true',...
        'scatterplot',1:4,...
        'meanConvergence',5:6,...
        'trace',7:8)
    close
    close
    close
    close
    close
    close
    close
    close
    success = 1;
catch
  success = 0;
end