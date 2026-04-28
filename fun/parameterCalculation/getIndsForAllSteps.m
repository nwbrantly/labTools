function indData = getIndsForAllSteps(gaitEvents, s, f)
%GETINDSFORALLSTEPS Return event indices and times for all strides.
%
%   Extracts the sample index and time of each gait event for every
% stride in a trial. A stride spans two consecutive slow heel strikes
% (SHS). For each stride, the function records indices and times for
% eight events in sequence: SHS, FTO, FHS, STO, SHS2, FTO2, FHS2,
% STO2. The output is a struct with a data matrix and column labels
% for use in downstream parameter computations.
%
% Inputs:
%   gaitEvents - labTimeSeries containing binary gait event columns
%                with labels [sHS, fTO, fHS, sTO] (where s and f
%                are the slow and fast leg identifiers)
%   s          - char ('L' or 'R') identifying the slow leg
%   f          - char ('L' or 'R') identifying the fast leg
%
% Outputs:
%   indData - struct with fields:
%               .Data   - numStrides-by-16 matrix; columns 1-8 are
%                         sample indices (SHS FTO FHS STO SHS2 FTO2
%                         FHS2 STO2) and columns 9-16 are the
%                         corresponding times
%               .labels - 16-element cell array of column names
%                         (e.g., 'indsRHS', 'indsLTO2', 'timesRHS')
%
% Toolbox Dependencies:
%   None
%
% See also GETINDSFORTHISSTEP, CALCPARAMETERS.

arguments
    gaitEvents (1,1)
    s          (1,1) char
    f          (1,1) char
end

%% Configure Event Types
eventList  = {[s 'HS'], [f 'TO'], [f 'HS'], [s 'TO']};
numEvents  = length(eventList);
eventData  = gaitEvents.getDataAsVector(eventList);
eventsTime = gaitEvents.Time;

%% Initialize Index and Time Arrays
shsInds    = find(eventData(:, 1));
numStrides = length(shsInds) - 1;
eventInds  = NaN(numStrides, 2 * numEvents);
eventTimes = NaN(numStrides, 2 * numEvents);

% Set index and time for the SHS column (first event of each stride)
eventInds(:, 1)  = shsInds(1:numStrides);
eventTimes(:, 1) = eventsTime(shsInds(1:numStrides));

%% Fill Events for All Steps Except Last
for iStep = 1:numStrides - 1
    for ii = 2:numEvents
        eventInds(iStep, ii)  = find( ...
            (eventsTime > eventTimes(iStep, ii - 1)) & ...
            eventData(:, ii), 1);
        eventTimes(iStep, ii) = eventsTime(eventInds(iStep, ii));
    end
    eventInds(iStep, numEvents + 1)  = eventInds(iStep + 1, 1);
    eventTimes(iStep, numEvents + 1) = ...
        eventsTime(eventInds(iStep, numEvents + 1));
    for ii = numEvents + 2 : 2 * numEvents
        eventInds(iStep, ii)  = find( ...
            (eventsTime > eventTimes(iStep, ii - 1)) & ...
            eventData(:, ii - numEvents), 1);
        eventTimes(iStep, ii) = eventsTime(eventInds(iStep, ii));
    end
end

%% Fill Events for Last Step
iStep = numStrides;
for ii = 2:numEvents
    eventInds(iStep, ii)  = find( ...
        (eventsTime > eventTimes(iStep, ii - 1)) & ...
        eventData(:, ii), 1);
    eventTimes(iStep, ii) = eventsTime(eventInds(iStep, ii));
end
eventInds(iStep, numEvents + 1)  = shsInds(numStrides + 1);
eventTimes(iStep, numEvents + 1) = ...
    eventsTime(eventInds(iStep, numEvents + 1));
% NOTE: trailing second-stride events (FTO2, FHS2, STO2) may not
% exist for the last step — only M+1 SHS events are guaranteed
for ii = numEvents + 2 : 2 * numEvents
    foundIdx = find( ...
        (eventsTime > eventTimes(iStep, ii - 1)) & ...
        eventData(:, ii - numEvents), 1);
    if ~isempty(foundIdx)  % leave NaN in place if event not found
        eventInds(iStep, ii)  = foundIdx;
        eventTimes(iStep, ii) = eventsTime(eventInds(iStep, ii));
    end
end

%% Build Output Structure
colLabels = cell(4 * numEvents, 1);
for ii = 1:numEvents
    colLabels(ii)                = {['inds'  eventList{ii}]};
    colLabels(numEvents + ii)    = {['inds'  eventList{ii} '2']};
    colLabels(2 * numEvents + ii) = {['times' eventList{ii}]};
    colLabels(3 * numEvents + ii) = {['times' eventList{ii} '2']};
end

indData.Data   = [eventInds, eventTimes];
indData.labels = colLabels;

end

