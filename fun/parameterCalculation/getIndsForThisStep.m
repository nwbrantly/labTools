function [indSHS, indFTO, indFHS, indSTO, indSHS2, indFTO2, indFHS2, ...
    indSTO2, timeSHS, timeFTO, timeFHS, timeSTO, timeSHS2, timeFTO2, ...
    timeFHS2, timeSTO2] = getIndsForThisStep(events, eventsTime, step)
%GETINDSFORTHISSTEP Return event indices and times for one stride.
%
%   Returns the sample index and time of each of the eight gait events
% bracketing one stride, defined as two consecutive slow heel strikes
% (SHS). The event sequence within the stride is SHS → FTO → FHS →
% STO → SHS2 → FTO2 → FHS2 → STO2. Events after SHS2 that cannot be
% located are returned as empty arrays.
%
% Inputs:
%   events     - M-by-4 binary matrix of gait events; columns are
%                [SHS FHS STO FTO] (slow heel strike, fast heel
%                strike, slow toe-off, fast toe-off)
%   eventsTime - M-by-1 vector of sample times corresponding to
%                rows of events
%   step       - scalar index into the SHS event array specifying
%                which stride to extract
%
% Outputs:
%   indSHS   - sample index of the slow heel strike
%   indFTO   - sample index of the fast toe-off after SHS
%   indFHS   - sample index of the fast heel strike after FTO
%   indSTO   - sample index of the slow toe-off after FHS
%   indSHS2  - sample index of the next slow heel strike
%   indFTO2  - sample index of fast toe-off after SHS2 ([] if absent)
%   indFHS2  - sample index of fast heel strike after FTO2
%              ([] if absent)
%   indSTO2  - sample index of slow toe-off after FHS2 ([] if absent)
%   timeSHS  - time of indSHS
%   timeFTO  - time of indFTO
%   timeFHS  - time of indFHS
%   timeSTO  - time of indSTO
%   timeSHS2 - time of indSHS2
%   timeFTO2 - time of indFTO2 ([] if absent)
%   timeFHS2 - time of indFHS2 ([] if absent)
%   timeSTO2 - time of indSTO2 ([] if absent)
%
% Toolbox Dependencies:
%   None
%
% See also GETINDSFORALLSTEPS, CALCPARAMETERS.

arguments
    events     (:,:) double
    eventsTime (:,1) double
    step       (1,1) double
end

%% Extract Event Columns
slowHS  = events(:, 1);
fastHS  = events(:, 2);
slowTO  = events(:, 3);
fastTO  = events(:, 4);
shsInds = find(slowHS);

%% Current Stride Events
indSHS   = shsInds(step);
timeSHS  = eventsTime(indSHS);
indFTO   = find((eventsTime > timeSHS) & fastTO, 1);
timeFTO  = eventsTime(indFTO);
indFHS   = find((eventsTime > timeFTO) & fastHS, 1);
timeFHS  = eventsTime(indFHS);
indSTO   = find((eventsTime > timeFHS) & slowTO, 1);
timeSTO  = eventsTime(indSTO);
indSHS2  = shsInds(step + 1);
timeSHS2 = eventsTime(indSHS2);

%% Next Stride Events
if ~isempty(timeSHS2)
    indFTO2  = find((eventsTime > timeSHS2) & fastTO, 1);
    timeFTO2 = eventsTime(indFTO2);
    if ~isempty(timeFTO2)
        indFHS2  = find((eventsTime > timeFTO2) & fastHS, 1);
        timeFHS2 = eventsTime(indFHS2);
        if ~isempty(timeFHS2)
            indSTO2  = find((eventsTime > timeFHS2) & slowTO, 1);
            timeSTO2 = eventsTime(indSTO2);
        else
            indSTO2  = [];
            timeSTO2 = [];
        end
    else
        indFHS2  = [];
        timeFHS2 = [];
        indSTO2  = [];
        timeSTO2 = [];
    end
else
    indFTO2  = [];
    timeFTO2 = [];
    indFHS2  = [];
    timeFHS2 = [];
    indSTO2  = [];
    timeSTO2 = [];
end

end

