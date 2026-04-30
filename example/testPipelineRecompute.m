%TESTPIPELINERECOMPUTE Template script for regression-testing recompute pipelines.
%
%   Loads a reference experimentData object, runs three recompute
% pipeline variants, and compares each result against the reference
% params.mat. Fill in the two file paths in the Configuration section
% before running.
%
%   Requires compareAdaptationData (fun/misc/) and the labTools
% directory on the MATLAB path.
%
% See also COMPAREADAPTATIONDATA, TESTING.md.

%% Configuration — fill in before running
% Path to the reference *params.mat saved from known-good code
refParamsFile = '';

% Path to the *expData.mat for the same session
expDataFile = '';

if isempty(refParamsFile) || isempty(expDataFile)
    error('testPipelineRecompute:missingConfig', ...
        'Set refParamsFile and expDataFile before running.');
end

%% Variant A: recomputeParameters
% Use after changes to fun/parameterCalculation/ or fun/eventExtraction/.
% Recalculates stride-by-stride parameters from existing processed data.
load(expDataFile, 'expData');
expData.recomputeParameters();
expData.makeDataObj();

% makeDataObj saves the file to the session folder; adjust the path
% below to match the actual output location.
newParamsA = strrep(expDataFile, 'expData.mat', 'params.mat');

compareAdaptationData(refParamsFile, newParamsA, ...
    RefName='reference', NewName='recomputeParameters');

%% Variant B: flushAndRecomputeParameters
% Use after changes to raw-processing code (filters, torques, EMG) or
% any step in labData.process. Fully reprocesses from the loaded data.
load(expDataFile, 'expData');
expData.flushAndRecomputeParameters();
expData.makeDataObj();

newParamsB = strrep(expDataFile, 'expData.mat', 'params.mat');

compareAdaptationData(refParamsFile, newParamsB, ...
    RefName='reference', NewName='flushAndRecomputeParameters');

%% Variant C: recomputeParameters with a single parameter class
% Use to scope a test to one parameter class (e.g., 'force', 'temporal',
% 'spatial', 'EMG'). Faster than a full recompute.
load(expDataFile, 'expData');
expData.recomputeParameters('force');
expData.makeDataObj();

newParamsC = strrep(expDataFile, 'expData.mat', 'params.mat');

compareAdaptationData(refParamsFile, newParamsC, ...
    RefName='reference', NewName='recomputeParameters(force)');
