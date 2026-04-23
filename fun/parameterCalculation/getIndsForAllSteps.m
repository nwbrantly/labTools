function [indData] = getIndsForAllSteps(gaitEvents, s, f)
% getIndsForAllSteps  Return event indices and times for all strides.
%
%   Syntax:
%     indData = getIndsForAllSteps(gaitEvents, s, f)
%
%   Extracts the sample index and time of each gait event for every
% stride in a trial. A stride spans two consecutive slow heel strikes
% (SHS). For each stride, the function records indices and times for
% eight events in sequence: SHS, FTO, FHS, STO, SHS2, FTO2, FHS2,
% STO2. The output is a struct with a data matrix and column labels
% for use in downstream parameter computations.
%
%   Inputs:
%     gaitEvents - labTimeSeries containing binary gait event columns
%                  with labels [sHS, fTO, fHS, sTO] (where s and f
%                  are the slow and fast leg identifiers)
%     s          - Char ('L' or 'R') identifying the slow leg
%     f          - Char ('L' or 'R') identifying the fast leg
%
%   Outputs:
%     indData - Struct with fields:
%                 .Data   - numStrides-by-16 matrix; columns 1-8 are
%                           sample indices (SHS FTO FHS STO SHS2 FTO2
%                           FHS2 STO2) and columns 9-16 are the
%                           corresponding times
%                 .labels - 16-element cell array of column names
%                           (e.g., 'indsRHS', 'indsLTO2', 'timesRHS')
%
%   Toolbox Dependencies:
%     None
%
%   See also: getIndsForThisStep, calcParameters

eventList={[s 'HS'], [f 'TO'], [f 'HS'], [s 'TO']};
N=length(eventList);
events=gaitEvents.getDataAsVector(eventList);

for i=1:N
    eval([eventList{i} '=events(:, i);']);
end

eventsTime=gaitEvents.Time;
aux=find(SHS);
M=length(aux)-1;
inds=NaN(M, 2*N);
times=NaN(M, 2*N);

%Set ind and time for all SHS events
inds(:, 1)=aux(1:M);
times(:, 1)=eventsTime(aux(1:M));

%Set other events for all steps except last
for step=1:M-1;
    for i=2:N
        eval(['inds(step, i)=find((eventsTime>times(step, i-1))&' eventList{i} ', 1);']);
        times(step, i)=eventsTime(inds(step, i));
    end
    inds(step, N+1)=inds(step+1, 1);
    times(step, N+1)=eventsTime(inds(step, N+1));
    for i=N+2:2*N
        eval(['inds(step, i)=find((eventsTime>times(step, i-1))&' eventList{i} ', 1);']);
        times(step, i)=eventsTime(inds(step, i));
    end
end

%Set for last step:
step=M;
for i=2:N
    eval(['inds(step, i)=find((eventsTime>times(step, i-1))&' eventList{i} ', 1);']);
    times(step, i)=eventsTime(inds(step, i));
end
inds(step, N+1)=aux(M+1);
times(step, N+1)=eventsTime(inds(step, N+1));
for i=N+2:2*N
    eval(['aux=find((eventsTime>times(step, i-1))&' eventList{i} ', 1);']); %There is no assurance that these events exist, as we only now that there are M+1 SHS events, but not FTO, FHS, STO
    if ~isempty(aux) %In case an event was actually found, if not, leave NaN in place
        inds(step, i)=aux;
        times(step, i)=eventsTime(inds(step, i));
    end
end


%Set labels for events
labels=cell(4*N, 1);
labels(1:N)=eventList;
for i=1:N
    labels(i)=['inds' eventList{i}];
    labels(N+i)=['inds' eventList{i} '2'];
    labels(2*N+i)=['times' eventList{i}];
    labels(3*N+i)=['times' eventList{i} '2'];
end

indData.Data=[inds, times];
indData.labels=labels;

end

