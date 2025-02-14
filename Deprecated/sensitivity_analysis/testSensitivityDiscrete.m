%% Sobol indices computed with Monte Carlo and PCE-type methods
clc
close all
clearvars

caseName = 'aero_module'; % 'airfoil_lift','aero_module', etc;
input_file = caseName; % specify directory which contains test case settings and model

%% Sobol options
SobolOpts.Type        = 'Sensitivity';
SobolOpts.Method      = 'Sobol';
SobolOpts.Sobol.Order = 1;

%% Add paths for dependent routines located in the directories 'NURBS','AEROmoduleWrapper' and 'Geometry'
addpath([pwd,'/AEROmoduleWrapper/']);
addpath([pwd,'/NURBS/']);
addpath([pwd,'/Geometry/']);

%% initialize UQlab

% add path
run('config.m');
addpath(genpath(UQLab_path));

% start uqlab
uqlab

%% process input files
run(['cases/' input_file '/initialize.m']);

if (exist('mean_exact','var'))
    compare_mean = 1;
else
    compare_mean = 0;
end
if (exist('std_exact','var'))
    compare_std = 1;
else
    compare_std = 0;
end

% create and add the model to UQLab
myModel = uq_createModel(Model);
% create input object with UQLab
myInput = uq_createInput(Input) ;

% display input properties
uq_print(myInput);
uq_display(myInput);

%% Monte-Carlo
if(find(strcmp(methods,'MC')))
    
    disp('=========MC==========');
    N_MC     = length(NsamplesMC);
    mean_MC  = zeros(MC_repeat,N_MC);
    std_MC   = zeros(MC_repeat,N_MC);
    Sobol_MC_FirstOrder = zeros(MC_repeat,N_MC,ndim);
    Sobol_MC_Total      = zeros(MC_repeat,N_MC,ndim);
    
    % perform multiple runs to decrease effect of random sampling
    for k = 1:MC_repeat
        for i=1:N_MC
            
            %disp(NsamplesMC(i));
            % get random samples ('experimental design')
            X_ED = uq_getSample(NsamplesMC(i), 'MC');
 
            if(size(discrete_index,1)>=1)
                X_ED(:,discrete_index) = []; % get rid of the constant columns
                X_temp  = allcomb(discrete_param_vals); % Use ndgrids to make a grid of discrete variables
                X_discrete = []; % contains repeated discrete grid
                for di = 1:size(X_temp,1)
                    X_discrete = [X_discrete;repmat(X_temp(di,:),NsamplesMC(i),1)]; 
                end
                X_ED = repmat(X_ED,size(X_temp,1),1); % contains repeated LHS grid 
            
                Xnew = zeros(size(X_discrete,1),ndim);
                Xnew(:,discrete_index) = X_discrete;
                Xnew(:,cont_index) = X_ED;
            else
                Xnew = X_ED;
            end

            % evaluate model at sample
            Y_ED = uq_evalModel(myModel,Xnew);
                             
            % moments of solution
            mean_MC(k,i) = mean(Y_ED);
            std_MC(k,i)  = std(Y_ED);
            
            new_SampleSize = size(Y_ED,1);
            
            % Sobol analysis; 
            SobolOpts.Sobol.SampleSize = new_SampleSize;% NsamplesMC(i);            
            SobolAnalysis_MC           = uq_createAnalysis(SobolOpts);                      
            SobolResults_MC            = SobolAnalysis_MC.Results;
            
            Sobol_MC_FirstOrder(k,i,1:ndim) = SobolResults_MC.FirstOrder;
            Sobol_MC_Total(k,i,1:ndim)      = SobolResults_MC.Total;     
        end
    end
    
    % take average over first dimension (multiple MC runs)
    AVG_Sobol_MC_FirstOrder = squeeze(mean(Sobol_MC_FirstOrder,1));
    AVG_Sobol_MC_Total      = squeeze(mean(Sobol_MC_Total,1));
    
    if (compare_mean == 1)
        err_mean_MC = abs((mean(mean_MC,1)-mean_exact)/mean_ref);
    end
    if (compare_std == 1)
        err_std_MC = abs((mean(std_MC,1)-std_exact)/std_ref);
    end
 
end
%% Polynomial Chaos with quadrature 

if (find(strcmp(methods,'PCE_Quad')))
    
    disp('=========PCE==========');
    
    N_Quad      = length(DegreesQuad);
    NsamplesQuad = zeros(N_Quad,1);
    mean_Quad    = zeros(N_Quad,1);
    std_Quad     = zeros(N_Quad,1);
    Sobol_Quad_FirstOrder = zeros(N_Quad,ndim);
    Sobol_Quad_Total = zeros(N_Quad,ndim);
    
    % set up PCE metamodel
    metamodelQuad.FullModel = myModel;
    metamodelQuad.Input     = myInput;
    metamodelQuad.Type      = 'Metamodel';
    metamodelQuad.MetaType  = 'PCE';
    metamodelQuad.Method          = 'Quadrature' ;
    metamodelQuad.Quadrature.Type = 'Full';
       
    for i = 1:N_Quad
        
        metamodelQuad.Degree = DegreesQuad(i);
        myPCE_Quad           = uq_createModel(metamodelQuad);
        
        % moments of solution
        NsamplesQuad(i) = myPCE_Quad.ExpDesign.NSamples;
        mean_Quad(i)    = myPCE_Quad.PCE.Moments.Mean;
        std_Quad(i)     = sqrt(myPCE_Quad.PCE.Moments.Var);
        
        % Sobol analysis
        % note the same options structure SobolOpts can be re-used to create a new analysis on the PCE model        
        SobolAnalysis_Quad    = uq_createAnalysis(SobolOpts);
        SobolResults_Quad     = SobolAnalysis_Quad.Results;
        Sobol_Quad_FirstOrder(i,1:ndim) = SobolResults_Quad.FirstOrder;
        Sobol_Quad_Total(i,1:ndim)      = SobolResults_Quad.Total;
    end
    
    if (compare_mean == 1)
        err_mean_Quad =  abs((mean_Quad - mean_exact)/mean_ref);
    end
    if (compare_std == 1)
        err_std_Quad  =  abs((std_Quad - std_exact)/std_ref);
    end
    
end
%% Polynomial Chaos with ordinary least squares (OLS)

if (find(strcmp(methods,'PCE_OLS')))
    
    disp('=========OLS==========');
    
    if (~exist('NsamplesOLS','var'))
        if (find(strcmp(methods,'PCE_Quad')))
            % we specify number of OLS samples based on samples used with
            % quadrature
            NsamplesOLS = NsamplesQuad;
            warning('number of OLS samples taken based on number of Quadrature samples');
        else
            error('please specify NsamplesOLS');
        end
    end
    
    N_OLS       = length(NsamplesOLS);
    mean_OLS    = zeros(OLS_repeat, N_OLS);
    std_OLS     = zeros(OLS_repeat, N_OLS);
    Sobol_OLS_FirstOrder = zeros(OLS_repeat, N_OLS, ndim);
    Sobol_OLS_Total      = zeros(OLS_repeat, N_OLS, ndim);
    
    metamodelOLS.FullModel = myModel;
    metamodelOLS.Input     = myInput;
    metamodelOLS.Type      = 'Metamodel';
    metamodelOLS.MetaType  = 'PCE';
    metamodelOLS.Method    = 'OLS';
    % specify array of possible degrees;
    % the degree with the lowest Leave-One-Out cross-validation error (LOO error)
    % is automatically selected:
    metamodelOLS.Degree    = 1:4;
    
    % if there are issues with LOO, try the following: metamodelOLS.OLS.ModifiedLOO = 0;
    % note that default sampling is LHS, this can be changed (see below)
    
    % as there is randomness in the experimental design, we can 
    % average over several runs
    for k = 1:OLS_repeat
        for i = 1:N_OLS
            
            metamodelOLS.ExpDesign.NSamples = NsamplesOLS(i);
            metamodelOLS.ExpDesign.Sampling = 'LHS'; % LHS is default
            
           % use manual experimental design:
            X_ED = uq_getSample(myInput,NsamplesOLS(i),'LHS');
            discrete_index
            if(size(discrete_index,1)>=1)
                X_ED(:,discrete_index) = []; % get rid of the constant columns
                X_temp  = allcomb(discrete_param_vals);
                X_discrete = []; % contains repeated discrete grid
                for di = 1:size(X_temp,1)
                    X_discrete = [X_discrete;repmat(X_temp(di,:),NsamplesOLS(i),1)]; 
                end
                X_ED = repmat(X_ED,size(X_temp,1),1); % contains repeated LHS grid
            
                Xnew = zeros(size(X_discrete,1),ndim);
                Xnew(:,discrete_index) = X_discrete;
                Xnew(:,cont_index) = X_ED;
            else
                Xnew = X_ED;
            end
            
            Ynew = uq_evalModel(myModel,Xnew);
            
            metamodelOLS.ExpDesign.X = Xnew;
            metamodelOLS.ExpDesign.Y = Ynew;

            metamodelOLS.ExpDesign.Sampling = 'user'; % or 'LHS' or 'Sobol' or 'Halton'
            metamodelOLS.ExpDesign.NSamples = size(Xnew,1);
            myPCE_OLS = uq_createModel(metamodelOLS);
            
            % moments of solution            
            mean_OLS(k,i) = myPCE_OLS.PCE.Moments.Mean;
            std_OLS(k,i)  = sqrt(myPCE_OLS.PCE.Moments.Var);          
            
            % Sobol analysis
            % note the same options structure SobolOpts can be re-used to create a new analysis on the PCE model
            SobolAnalysis_OLS    = uq_createAnalysis(SobolOpts);
            SobolResults_OLS     = SobolAnalysis_OLS.Results;
            Sobol_OLS_FirstOrder(k,i,1:ndim) = SobolResults_OLS.FirstOrder;
            Sobol_OLS_Total(k,i,1:ndim)      = SobolResults_OLS.Total;             
        end
        
    end
    
    %Take average over first dimension (multiple OLS runs)
    AVG_Sobol_OLS_FirstOrder = squeeze(mean(Sobol_OLS_FirstOrder,1));
    AVG_Sobol_OLS_Total      = squeeze(mean(Sobol_OLS_Total,1));
    
    % take mean over first dimension (k)
    if (compare_mean == 1)
        err_mean_OLS =  abs((mean(mean_OLS,1)-mean_exact)/mean_ref);
    end
    if (compare_std == 1)
        err_std_OLS =  abs((mean(std_OLS,1)-std_exact)/std_ref);
    end
    
end

%% Polynomial Chaos with LARS
if (find(strcmp(methods,'PCE_LARS')))
    
    disp('=========LARS==========');
    
    if (~exist('NsamplesLARS','var'))
        if (find(strcmp(methods,'PCE_Quad')))
            % we specify number of OLS samples based on samples used with
            % quadrature
            NsamplesLARS = NsamplesQuad;
            warning('number of LARS samples taken based on number of Quadrature samples');
        else
            error('please specify NsamplesLARS');
        end
    end
    
    N_LARS       = length(NsamplesLARS);
    mean_LARS    = zeros(LARS_repeat, N_LARS);
    std_LARS     = zeros(LARS_repeat, N_LARS);
    Sobol_LARS_FirstOrder = zeros(LARS_repeat, N_LARS, ndim);
    Sobol_LARS_Total      = zeros(LARS_repeat, N_LARS, ndim);
%     SobolOpts.Sobol.PCEBased = 0;

    
    metamodelLARS.FullModel = myModel;
    metamodelLARS.Input     = myInput;
    metamodelLARS.Type      = 'Metamodel';
    metamodelLARS.MetaType  = 'PCE';
    metamodelLARS.Method    = 'LARS';
    metamodelLARS.Degree    = 1:4; % this automatically switches on degree adaptive PCE
    metamodelLARS.TruncOptions.qNorm = 0.75;
    
    % as there is randomness in the experimental design, we can 
    % average over several runs    
    for k = 1:LARS_repeat
        for i = 1:N_LARS
         
           % use sampling strategy, note that default is MC!
            metamodelLARS.ExpDesign.Sampling = 'LHS'; % or 'LHS' or 'Sobol' or 'Halton'
            metamodelLARS.ExpDesign.NSamples = NsamplesLARS(i);            
            
           % use manual experimental design:
            X_ED = uq_getSample(myInput,NsamplesLARS(i),'LHS');
            discrete_index
            if(size(discrete_index,1)>=1)
                X_ED(:,discrete_index) = []; % get rid of the constant columns
                X_temp  = allcomb(discrete_param_vals);
                X_discrete = []; % contains repeated discrete grid
                for di = 1:size(X_temp,1)
                    X_discrete = [X_discrete;repmat(X_temp(di,:),NsamplesLARS(i),1)]; 
                end
                X_ED = repmat(X_ED,size(X_temp,1),1); % contains repeated LHS grid
            
                Xnew = zeros(size(X_discrete,1),ndim);
                Xnew(:,discrete_index) = X_discrete;
                Xnew(:,cont_index) = X_ED;
            else
                Xnew = X_ED;
            end
            
            Ynew = uq_evalModel(myModel,Xnew);

            metamodelLARS.ExpDesign.X = Xnew;
            metamodelLARS.ExpDesign.Y = Ynew;

            metamodelLARS.ExpDesign.Sampling = 'user'; % or 'LHS' or 'Sobol' or 'Halton'
            metamodelLARS.ExpDesign.NSamples = size(Xnew,1);
            myPCE_LARS     = uq_createModel(metamodelLARS);            
            
            % moments of solution            
            mean_LARS(k,i) = myPCE_LARS.PCE.Moments.Mean;
            std_LARS(k,i)  = sqrt(myPCE_LARS.PCE.Moments.Var);
 
            % Sobol analysis
            % note the same options structure SobolOpts can be re-used to create a new analysis on the PCE model
            SobolAnalysis_LARS    = uq_createAnalysis(SobolOpts);
            SobolResults_LARS     = SobolAnalysis_LARS.Results;
            Sobol_LARS_FirstOrder(k, i, 1:ndim) = SobolResults_LARS.FirstOrder;
            Sobol_LARS_Total(k, i, 1:ndim)      = SobolResults_LARS.Total;
        end 
    end
    
    % take average over first dimension (multiple LARS runs)
    AVG_Sobol_LARS_FirstOrder = squeeze(mean(Sobol_LARS_FirstOrder,1));
    AVG_Sobol_LARS_Total      = squeeze(mean(Sobol_LARS_Total,1));
    
    if (compare_mean == 1)
        err_mean_LARS =  abs((mean(mean_LARS,1)-mean_exact)/mean_ref);
    end
    if (compare_std == 1)
        err_std_LARS =  abs((mean(std_LARS,1)-std_exact)/std_ref);
    end
    
end

%% perform post processing
run(['cases/' input_file '/postProcessing.m']);
