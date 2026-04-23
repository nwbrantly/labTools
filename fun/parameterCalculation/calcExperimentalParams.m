function out = calcExperimentalParams(in, subData, eventClass, initEventSide)
if nargin<2 || isempty(eventClass)
    eventClass='';
end
if nargin<3 || isempty(initEventSide)
    refLeg=in.metaData.refLeg;
else
    refLeg=initEventSide;
end

if strcmp(refLeg, 'R')
    s = 'R';    f = 'L';
elseif strcmp(refLeg, 'L')
    s = 'L';    f = 'R';
else
    ME=MException('MakeParameters:refLegError','the refLeg property of metaData must be either ''L'' or ''R''.');
    throw(ME);
end



%% Find number of strides
good=in.adaptParams.getDataAsVector({'good'}); %Getting data from 'good' label
ts=~isnan(good);
good=good(ts);
Nstrides=length(good);%Using lenght of the 'good' parameter already calculated in calcParams

%% get events
eventTypes={[s, 'HS'], [f, 'TO'], [f, 'HS'], [s, 'TO']};
eventTypes=strcat(eventClass, eventTypes);
eventTypes2={['SHS'], ['FTO'], ['FHS'], ['STO']};
triggerEvent=eventTypes{1};
[strideIdxs, initTime, endTime]=getStrideInfo(in, triggerEvent);

%% Compute params
aux1={ 'fakeParam', 'fakeDescription'};
paramLabels=aux1(:, 1);
description=aux1(:, 2);
fakeParam=nan(Nstrides, 1);

%% Save all the params in the data matrix & generate labTimeSeries
for i=1:length(paramLabels)
    eval(['data(:, i)=', paramLabels{i}, ';'])
end

%%
out=parameterSeries(data, paramLabels, in.adaptParams.hiddenTime, description);

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

