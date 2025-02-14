function  pertThickness = computeThickness(samples, index, randVec, pc, plotSamples,bladeLength,...
                                      interpolationLocations,referenceThickness,...
                                      t0,n,sampledLocations,sampledValues)

 % This routine computes the random samples of airfoil Thickness using the purturbed
% control points of NURBS curve

% Input arguments
% 'samples' Number of samples of perturbed thickness
% 'randVec' a samples-by-numOfControlPoints matrix of random numbers
% 'pc' is vector with each element bw [0,1] representing fraction of perturbation for each control point from their baseline value.
% 'plotSamples' 0 for no plot, 1 (default) to plot the generated samples, the baseline curve and the control points
% 'interpolationLocations' Points along the blade length according to ECNAERO module input file 
% 'referenceThickness' Reference values of thickness*(t/c) obtained from ECNAERO module input file
% 't0' Knot vector b/w [0,1], the number of resulting basis function is numel(t0)+1
% 'n' NURBS order: 2 for linear B-splines, 3 for Quadratic, so on. The polynomial degree of B-spline is n-1.
% 'sampledLocations' Locations where the value of thickness is sample. NOTE: numel(sampleLocations) =  numel(t0) + 1
% 'sampledValues' Values of thickness at sampled location
% 'pc' is vector with each element bw [0,1] representing fraction of perturbation for control points from their baseline value. The numel(pc) = numel(sampledLocations)  

% Output argument
% 'samplesThickness' are samples of Thickness generated by perturbing the baseline control points. Each row corresponds to one sample.

if nargin < 6 % Default function argument values corresponding to NM80 turbine
    bladeLength = 38.8; % To normalize the blade length bw [0,1]   
    interpolationLocations = [0 2 4 6 8 10 12 14 16 18 20 22 ...
                          24 26 28 30 32 34 36 37 38 38.4 38.8]; 

    referenceChord = [2.42 2.48 2.65 2.81 2.98 3.14 3.17 2.99 2.79 2.58 2.38 ...
                  2.21 2.06 1.92 1.8 1.68 1.55 1.41 1.18 0.98 0.62 0.48 0.07];
    
    reference_t_by_c = [0.9999 0.9641 0.8053 0.6508 0.5167 0.403 0.3253 0.284 0.2562 0.2377 0.2225 ...
          0.2099 0.2003 0.194 0.1903 0.1879 0.186 0.1839 0.1795 0.1739 0.1633 0.157 0.1484];          
    
    referenceThickness = referenceChord.*reference_t_by_c; 
             
    t0 = [0 0.15 0.3 0.51 0.7 0.87 0.95 1]; 
    n = 3;
    sampledLocations = interpolationLocations([1 3 6 9 11 16 18 20 23]);
    sampledValues = referenceThickness([1 3 6 9 11 16 18 20 23]); 
        
end


%% set up NURBS

% normalize inputs
interpolationLocations = interpolationLocations/bladeLength; % Normalized between [0,1]
sampledLocations       = sampledLocations/bladeLength; % Normalized between [0,1]

% get NURBS basis function matrix
[Bref, t] = getNURBSBasisMatrix(sampledLocations,t0,n); % get basis matrix
% get control points by solving the NURBS equation system
c = getControlPoints(Bref,sampledValues); % control points for NURBS curve

% now the NURBS curve is fully defined and can be evaluated at different
% positions
% 'samplesCurve' is the function values of NURBS curve interpolated at interpolationLocations
Bu  = getNURBSBasisMatrix(interpolationLocations,t0,n);
samplesThickness = evalNURBS(Bu,c);

%% now create perturbations
% create vector for perturbations
pc_mod = zeros(numel(sampledLocations),1);
% magnitude of perturbation that is used to scale the random numbers
pc_mod(index(:)) = pc;

% value of random variable
randVec_mod = zeros(numel(sampledLocations),1);
randVec_mod(index(:)) = randVec;

% this is a key step, where the perturbation is added to the baseline
c_pert    = c.*(1+pc_mod.*randVec_mod);
pertThickness = evalNURBS(Bu,c_pert);



%% make plots
% plotSamples=1;
if plotSamples == 1
    % Plot to check the thickness variation along the blade span. This can be used to 
    % select the knot locations     
    figure
    plot(interpolationLocations,referenceThickness,'linewidth',2) 
    hold on
    plot(sampledLocations,c,'marker','o','linewidth',2) % plot control points
    plot(sampledLocations,sampledValues,'marker','x','markersize',8,'linestyle','none','linewidth',2) % plot sampled points
    plot(interpolationLocations,samplesThickness,'linewidth',2)
    plot(interpolationLocations,pertThickness,'linestyle','--')
    legend('reference thickness','control points','sampled data', 'NURBS approximation to reference','perturbed curve')
    hold off
end
return