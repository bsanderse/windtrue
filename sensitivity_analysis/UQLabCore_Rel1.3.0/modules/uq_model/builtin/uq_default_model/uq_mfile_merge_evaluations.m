function merged_results = uq_mfile_merge_evaluations(resultfiles)
% UQ_MFILE_MERGE_EVALUATIONS is a simple merging routine for outputs 
% produced by uq_evalModel


uq_retrieveSession

% the current analysis name

%%%UQHPCSTART%%%

merged_results{1} = [];

for i = 1:length(resultfiles)
    % load the output files and only retrieve the important information
    imported = load(resultfiles{i}, 'UQ');
    model_name = imported.UQ.dispatcher.current_module.Internal.current_model.Name;
    results{i} = imported.UQ.model.get_module(model_name).Internal.HPC.Eval.Y.';
end

merged_results = [results{:}].';

uq_saveSession([resultfiles{1}(1:end-8) 'merged.mat']);

%%%UQHPCEND%%%
