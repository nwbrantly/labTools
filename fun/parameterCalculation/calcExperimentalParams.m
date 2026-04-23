function out = calcExperimentalParams( ...
    trialData, subData, eventClass, initEventSide)
% calcExperimentalParams  Compute experimental parameters per stride.
%
%   Syntax:
%     out = calcExperimentalParams(trialData, subData)
%     out = calcExperimentalParams(trialData, subData, eventClass)
%     out = calcExperimentalParams( ...
%         trialData, subData, eventClass, initEventSide)
%
%   Computes stride-by-stride experimental parameters from a processed
% trial. Currently returns a placeholder parameterSeries containing a
% single NaN parameter; intended to be extended with study-specific
% parameter calculations.
%
%   Inputs:
%     trialData     - processedLabData object containing gait events,
%                     parameters, and metadata for the trial
%     subData       - subjectData object containing subject information
%     eventClass    - (optional) String specifying the gait event
%                     detection method (e.g., 'kin' or 'force');
%                     defaults to ''
%     initEventSide - (optional) 'L' or 'R'; side for the initial
%                     gait event; defaults to
%                     trialData.metaData.refLeg if omitted or empty
%
%   Outputs:
%     out - parameterSeries object containing computed parameters
%
%   Toolbox Dependencies:
%     None
%
%   See also: calcParameters, parameterSeries, getStrideInfo

arguments
    trialData     (1,1)
    subData       (1,1)
    eventClass    (1,:) char = ''
    initEventSide (1,:) char = ''
end

%% Resolve Reference Leg
if isempty(initEventSide)
    refLeg = trialData.metaData.refLeg;
else
    refLeg = initEventSide;
end

if strcmp(refLeg, 'R')
    s = 'R';
    f = 'L';
elseif strcmp(refLeg, 'L')
    s = 'L';
    f = 'R';
else
    ME = MException('MakeParameters:refLegError', ...
        ['The refLeg property of metaData must be ' ...
        'either ''L'' or ''R''.']);
    throw(ME);
end

%% Find Number of Strides
% 'good' is already computed by calcParameters; use it to count strides
goodData   = trialData.adaptParams.getDataAsVector({'good'});
validMask  = ~isnan(goodData);
goodData   = goodData(validMask);
numStrides = length(goodData);

%% Configure Gait Event Types
eventTypes   = {[s, 'HS'], [f, 'TO'], [f, 'HS'], [s, 'TO']};
eventTypes   = strcat(eventClass, eventTypes);
eventLabels  = {'SHS', 'FTO', 'FHS', 'STO'};
triggerEvent = eventTypes{1};
[strideCount, initTime, endTime] = getStrideInfo(trialData, triggerEvent);

%% Compute Parameters
% TODO: add study-specific parameter calculations here
aux = {'fakeParam', 'fakeDescription'};
paramLabels = aux(:, 1);
description = aux(:, 2);
fakeParam   = nan(numStrides, 1);

%% Assign Parameters to Data Matrix
data = nan(numStrides, length(paramLabels));
for ii = 1:length(paramLabels)
    eval(['data(:, ii) = ' paramLabels{ii} ';']);
end

%% Output Computed Parameters
out = parameterSeries( ...
    data, paramLabels, trialData.adaptParams.hiddenTime, description);

end

