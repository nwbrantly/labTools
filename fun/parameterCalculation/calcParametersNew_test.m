function out = calcParametersNew_test(trialData,subData,eventClass,initEventSide)
in=trialData;
%in must be an object of the class processedlabData
%
%To add a new parameter, it must be added to the paramLabels cell and the
%label must be the same as the variable name the data is saved to within
%the code. (ex: in paramlabels: 'swingTimeSlow', in code: swingTimeSlow(t)=timeSHS2-timeSTO;)
%note: if adding a slow and fast version of one parameter, make sure 'Fast'
%and 'Slow' appear at the end of the respective parameter names. See
%existing parameter names as an example.

if nargin<3 || isempty(eventClass)
    eventClass='';
end
if nargin<4 || isempty(initEventSide)
    refLeg=in.metaData.refLeg;
else
    refLeg=initEventSide; 
end

%% Separate into strides & identify events on each
% one "stride" contains the events: SHS,FTO,FHS,STO,SHS2,FTO2
if refLeg == 'R'
    s = 'R';    f = 'L';
elseif refLeg == 'L'
    s = 'L';    f = 'R';
else
    ME=MException('MakeParameters:refLegError','the refLeg/initEventSide property of metaData must be either ''L'' or ''R''.');
    throw(ME);
end

%Define the events that will be used for all further computations
eventTypes={[s,'HS'],[f,'TO'],[f,'HS'],[s,'TO']};
eventTypes=strcat(eventClass,eventTypes);
eventTypes2={['SHS'],['FTO'],['FHS'],['STO']};
triggerEvent=eventTypes{1};

%Initialize:
[strideIdxs,initTime,endTime]=getStrideInfo(in,triggerEvent);
if isempty(strideIdxs)
    out=[];
    return
end
stridedProcEMG=cell(max(strideIdxs),1);
%stridedMarkerData=cell(max(strideIdxs),1);
stridedEventData=cell(max(strideIdxs),1);

%Stride:
%steppedDataArray=separateIntoStrides(in,triggerEvent); %This is 
%computationally expensive to do: it calls the split function for every 
%labTS in trialData. If we only care about some fields, we should try 
%calling split independently for those TSs.
eventTimes=nan(length(strideIdxs),length(eventTypes));
eventTimes2=nan(length(strideIdxs),length(eventTypes));
for i=strideIdxs
    stridedProcEMG{i}=in.('procEMGData').split(initTime(i),endTime(i));
    %stridedMarkerData{i}=in.('markerData').split(initTime(i),endTime(i));
    stridedEventData{i}=in.('gaitEvents').split(initTime(i),endTime(i));
    for j=1:length(eventTypes)
        aux=stridedEventData{i}.getDataAsVector([eventClass eventTypes{j}]);
        aux=find(aux,2,'first'); %Finding next two events of the type
        if ~isempty(aux)
            eventTimes(i,j)=stridedEventData{i}.Time(aux(1));
        end
    end
end
eventTimes2=[eventTimes(2:end,:);nan(1,size(eventTimes,2))]; %This could be improved by trying to find if there exist any other events after the end of the last stride.
for j=1:length(eventTypes)
    eval(['strideEvents.t' upper(eventTypes2{j}) '=eventTimes(:,j);']);
    eval(['strideEvents.t' upper(eventTypes2{j}) '2=eventTimes2(:,j);']);
end

%% Compute basic parameters to save & initialize parameterSeries
%initialize the bad/good flag
extendedEventTimes=[eventTimes, eventTimes2(:,1:2)]; %Aligns SHS, FTO, FHS, FTO, SHS2, FTO2
times=nanmean(extendedEventTimes,2); %This is an average of the times of SHS, FTO, FHS, FTO, SHS2, FTO2 (same as old code), IF available.
strideDuration=diff(extendedEventTimes(:,[1,5]),1,2);
bad=any(isnan(extendedEventTimes),2) | any(diff(extendedEventTimes,1,2)<0,2) | (strideDuration >1.5*nanmedian(strideDuration)) | (strideDuration<.4) | (strideDuration>2.5); %Checking for missing events, negative duration phases (wrong event order), too long or too short strides

%initialize trial number
try
    trial=str2double(in.metaData.rawDataFilename(end-1:end)); %Need to FIX, but this data is not currently available on labMetaData
catch
    warning('calcParametersNew:gettingTrialNumber','Could not determine trial number from metaData, setting to NaN.');
    trial=nan;
end
trial=repmat(trial,length(bad),1);

%Initialize initTime
initTime=extendedEventTimes(:,1); %SHS
finalTime=extendedEventTimes(:,6); %FTO2

%Initialize parameterSeries
data=[bad,~bad,trial,initTime,finalTime];
labels={'bad','good','trial','initTime','finalTime'};
description={'True if events are missing, disordered or if stride time is too long or too short.', 'Opposite of bad.','Original trial number for stride','Time of initial event (SHS), with respect to trial beginning.','Time of final event (FTO2), with respect to trial beginning.'};
out=parameterSeries(data,labels,times,description);  

%% Compute parameters
%Temporal:
[temp] = computeTemporalParameters(strideEvents);
out=cat(out,temp);

%Spatial:
[spat] = computeSpatialParameters(strideEvents,in.markerData,in.angleData,s);
out=cat(out,spat);

%EMG:
if ~isempty(in.procEMGData)
    [emg] = computeEMGParameters(strideEvents,stridedProcEMG);
    out=cat(out,emg);
end
%% Compute an updated bad/good flag based on computed parameters



%% Issue bad strides warning
if any(bad)
    [file]= getSimpleFileName(in.metaData.rawDataFilename);
    disp(['Warning: Non consistent event detection in ' num2str(sum(bad)) ' strides of ',file])    
end

%% Use 'bad' as mask (necessary?)
out.Data(bad==1,6:end)=NaN; %First 5 parameters are kept for ID purposes: bad, good, trial, initTime, finalTime