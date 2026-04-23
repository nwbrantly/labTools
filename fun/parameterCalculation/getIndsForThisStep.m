function [indSHS, indFTO, indFHS, indSTO, indSHS2, indFTO2, indFHS2, indSTO2, timeSHS, timeFTO, timeFHS, timeSTO, timeSHS2, timeFTO2, timeFHS2, timeSTO2] = getIndsForThisStep(events, eventsTime, step)
% getIndsForThisStep  Return event indices and times for one stride.
%
%   Syntax:
%     [indSHS, indFTO, ..., timeSTO2] = ...
%         getIndsForThisStep(events, eventsTime, step)
%
%   Returns the sample index and time of each of the eight gait events
% bracketing one stride, defined as two consecutive slow heel strikes
% (SHS). The event sequence within the stride is SHS → FTO → FHS →
% STO → SHS2 → FTO2 → FHS2 → STO2. Events after SHS2 that cannot be
% located are returned as empty arrays.
%
%   Inputs:
%     events     - M-by-4 binary matrix of gait events; columns are
%                  [SHS FHS STO FTO] (slow heel strike, fast heel
%                  strike, slow toe-off, fast toe-off)
%     eventsTime - M-by-1 vector of sample times corresponding to
%                  rows of events
%     step       - Scalar index into the SHS event array specifying
%                  which stride to extract
%
%   Outputs:
%     indSHS   - Sample index of the slow heel strike
%     indFTO   - Sample index of the fast toe-off after SHS
%     indFHS   - Sample index of the fast heel strike after FTO
%     indSTO   - Sample index of the slow toe-off after FHS
%     indSHS2  - Sample index of the next slow heel strike
%     indFTO2  - Sample index of fast toe-off after SHS2 ([] if absent)
%     indFHS2  - Sample index of fast heel strike after FTO2
%                ([] if absent)
%     indSTO2  - Sample index of slow toe-off after FHS2 ([] if absent)
%     timeSHS  - Time of indSHS
%     timeFTO  - Time of indFTO
%     timeFHS  - Time of indFHS
%     timeSTO  - Time of indSTO
%     timeSHS2 - Time of indSHS2
%     timeFTO2 - Time of indFTO2 ([] if absent)
%     timeFHS2 - Time of indFHS2 ([] if absent)
%     timeSTO2 - Time of indSTO2 ([] if absent)
%
%   Toolbox Dependencies:
%     None
%
%   See also: getIndsForAllSteps, calcParameters

SHS=events(:,1);
FHS=events(:,2);
STO=events(:,3);
FTO=events(:,4);
inds=find(SHS);

indSHS=inds(step);
timeSHS=eventsTime(indSHS);
indFTO=find((eventsTime>timeSHS)&FTO,1);
timeFTO=eventsTime(indFTO);
indFHS=find((eventsTime>timeFTO)&FHS,1);
timeFHS=eventsTime(indFHS);
indSTO=find((eventsTime>timeFHS)&STO,1);
timeSTO=eventsTime(indSTO);
indSHS2=inds(step+1);
timeSHS2=eventsTime(indSHS2);
if ~isempty(timeSHS2)
    indFTO2=find((eventsTime>timeSHS2)&FTO,1);
    timeFTO2=eventsTime(indFTO2);
    if ~isempty(timeFTO2)
        indFHS2=find((eventsTime>timeFTO2)&FHS,1);
        timeFHS2=eventsTime(indFHS2);
        if ~isempty(timeFHS2)
            indSTO2=find((eventsTime>timeFHS2)&STO,1);
            timeSTO2=eventsTime(indSTO2);
        else
            indSTO2=[];
            timeSTO2=[];
        end
    else
        indFHS2=[];
        timeFHS2=[];
        indSTO2=[];
        timeSTO2=[];
    end
else
    indFTO2=[];
    timeFTO2=[];
    indFHS2=[];
    timeFHS2=[];
    indSTO2=[];
    timeSTO2=[];
end

end

