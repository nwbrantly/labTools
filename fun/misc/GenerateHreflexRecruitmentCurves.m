%% Generate H-Reflex Calibration Recruitment Curves & Other Figures
% author: NWB
% date (started): 05 May 2024
% purpose: to extract the M-wave and H-wave amplitudes from the H-reflex
% calibration EMG data shortly after the creation of the calibration trial
% C3D file in a Vicon Nexus software processing pipeline during experiment.
% NOTE: this processing script uses 'SL_Realtime.m' as a template to use
% the Vicon Nexus sofware tools.

% TODO:
%   1. handle case of only stimulating one leg during a trial (i.e., only
%   want to compute parameters and plot one leg)
%   2. use the feature of the stimulator to set the current output
%   based on the voltage of the trigger pulse to eliminate the need for
%   asking the user to input the stimulation amplitudes
%   3. use the Vicon SDK to update the recruitment curve and ratio figures
%   in real time (if possible)
%   4. adaptively choose the next stimulation amplitude
%   5. consider making each data retrieval its own function for modularity
%   and easy access and use for future applications

%% 1. Load the C3D File Data
try     % if Vicon Nexus is running with a file open, use that
    % Vicon Nexus must be open, offline, and the desired trial loaded
    vicon = ViconNexus();
    [path,filenameWOExt] = vicon.GetTrialName;   % get trial open in Nexus
    filenameWExt = [filenameWOExt '.c3d'];
    guessID = vicon.GetSubjectNames;    % retrieve participant / session ID
catch   % use below two lines when processing c3d files not open in Nexus
    [filenameWExt,path] = uigetfile('*.c3d', ...
        'Please select the c3d file of interest:');
    compsPath = strsplit(path,filesep);
    compsPath = compsPath(~cellfun(@isempty,compsPath));
    guessID = compsPath(contains(compsPath,'SA'));
    if isempty(guessID)
        guessID = compsPath(end);
    end
end

% verify participant / session ID with experimenter first
id = inputdlg({'Enter the Participant / Session ID:'},'ID',[1 50],guessID);
if isempty(id)  % if no ID provided, ...
    error('Participant / Session ID input is required.');
end
id = id{1};

% process filename and paths
[~,filename] = fileparts(filenameWExt);
trialNum = filename(end-1:end); % last two characters of file name are #
pathFigs = fullfile(path,'HreflexCalFigs');
if ~isfolder(pathFigs)          % if figure folder doesn't exist, ...
    mkdir(pathFigs);            % make it
end

H = btkReadAcquisition(fullfile(path,filenameWExt));    % load C3D data
% using the same method as labtools, retrieve the analog data
[analogs,analogsInfo] = btkGetAnalogs(H);

%% 2. Retrieve Existing Configuration or User Input Data
prompt = { ...
    ['Enter the EMG sensor muscles in sensor number order for all 16 ' ...
    'sensors of Box 1 (use ''NA'' for unused sensors):'], ...
    ['Use stimulation trigger pulse data to identify artifact peak ' ...
    'times? (''1'' = true (TM calibration where all triggers in Vicon ' ...
    'are valid and have a stim current written down), ''0'' = false)'], ...
    'Enter the right leg stimulation amplitudes (numbers only):', ...
    'Enter the left leg stimulation amplitudes (numbers only):', ...
    ['Stimulation Artifact Threshold (V) (NOTE: only relevant if not ' ...
    'using stim trigger pulse):'], ...
    ['Minimum Time Between Stimulation Pulses (s) (NOTE: only relevant' ...
    ' if not using stim trigger pulse):']};
dlgtitle = 'H-Reflex Calibration Input';
fieldsize = [1 200; 1 200; 1 200; 1 200; 1 200; 1 200];

% determine default input
filesConf = dir(fullfile(pathFigs,[id 'Config*.mat']));
fnamesConf = {filesConf.name};
fnameConf = [id 'Config' trialNum '.mat'];
if isempty(fnamesConf)              % if no configuration file exists, ...
    definput = { ...                % use the default values for the input
        ['RTAP RTAD NA RPER RMG RLG RSOL LTAP LTAD LPER LMG LLG LSOL ' ...
        'NA NA sync1'], ...                     muscle list
        '1', ...                                should use stim trig pulse?
        ['5 5 5 5 5 5 7 7 7 7 7 7 9 9 9 9 9 9 11 11 11 11 11 11 13 13 ' ...
        '13 13 13 13 15 15 15 15 15 15 17 17 17 17 17 17 20 20 20 20 ' ...
        '20 20 23 23 23 23 23 23 26 26 26 26 26 26'], ...   right leg amps
        ['5 5 5 5 5 5 7 7 7 7 7 7 9 9 9 9 9 9 11 11 11 11 11 11 13 13 ' ...
        '13 13 13 13 15 15 15 15 15 15 17 17 17 17 17 17 20 20 20 20 ' ...
        '20 20 23 23 23 23 23 23 26 26 26 26 26 26'], ...   left leg amps
        '0.0003', ...                           stim artifact threshold (V)
        '5'};                                 % min. time between stim. (s)
elseif any(strcmpi(fnamesConf,fnameConf))   % if current trial file, ...
    load(fullfile(pathFigs,fnameConf),'answer');
    definput = answer;                      % set default input to config
else                                        % otherwise, ...
    load(fullfile(pathFigs,fnamesConf{end}),'answer');
    definput = answer;                      % use most recent trial config
end

% retrieve input from experimenter
answer = inputdlg(prompt,dlgtitle,fieldsize,definput);
if isempty(answer)                          % if no input provided, ...
    error('User input is required for calibration.');
end

% if config file does not exist (save new file) or if it does exist but ...
% has changed (overwrite previous file), ...
if ~isfile(fullfile(pathFigs,fnameConf)) || ...
        (isfile(fullfile(pathFigs,fnameConf)) && ~isequal(definput,answer))
    save(fullfile(pathFigs,fnameConf),'answer','analogs','analogsInfo', ...
        'H','id','path','pathFigs','trialNum','filenameWExt','fnameConf');
end

%% 3. Extract User Input Parameters
EMGList1 = strsplit(answer{1},' '); % list of EMG muscle labels
if isempty(EMGList1)                % if no EMG labels input, ...
    error(['No EMG labels have been provided. It is not possible to ' ...
        'generate H-reflex recruitment curves without EMG data.']);
end
% currently using below as a proxy for standing vs. walking trials
shouldUseStimTrig = logical(str2double(answer{2}));
ampsStimR = str2num(answer{3}); %#ok<ST2NM>
ampsStimL = str2num(answer{4}); %#ok<ST2NM>
threshStimArtifact = str2double(answer{5});% stimulation artifact threshold
threshStimTimeSep = str2double(answer{6}); % time between stim

numStimR = numel(ampsStimR);   % number of times stimulated right leg
numStimL = numel(ampsStimL);   % number of times stimulated left leg

%% Provide Summary of Extracted Data
fprintf('Participant/Session ID: %s\n',id);
fprintf('Trial Number: %s\n',trialNum);
fprintf('Number of Right Leg Stimulations: %d\n',numStimR);
fprintf('Number of Left Leg Stimulations: %d\n',numStimL);
fprintf('Artifact Threshold (V): %.4f\n',threshStimArtifact);
fprintf('Minimum Time Between Stimuli (s): %.2f\n',threshStimTimeSep);
disp('Data extraction completed successfully.');

%% 4. Retrieve EMG Data
% NOTE: below is copied directly from 'loadTrials.m'
% below are the muscle names (abbrev.) in the desired order
% NOTE: thigh and hip muscles have been removed since not currently
% relevant for the Spinal Adaptation project
orderedMuscleList = {'PER','TA','TAP','TAD','SOL','MG','LG'};
orderedEMGList={};
for j = 1:length(orderedMuscleList)
    orderedEMGList{end+1}=['R' orderedMuscleList{j}];
    orderedEMGList{end+1}=['L' orderedMuscleList{j}];
end

EMG = [];
relData = [];
relDataTemp = [];
fieldList = fields(analogs);
idxList = [];
for j=1:length(fieldList)
    if  ~isempty(strfind(fieldList{j},'EMG'))  %Getting fields that start with 'EMG' only
        relDataTemp=[relDataTemp,analogs.(fieldList{j})];
        idxList(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'EMG')+3:end));
        analogs=rmfield(analogs,fieldList{j}); %Just to save memory space
    end
end
emptyChannels1=cellfun(@(x) contains(x,'NA') || contains(x,'sync'),EMGList1);
EMGList1 = EMGList1(~emptyChannels1);
relData(:,idxList)=relDataTemp; %Re-sorting to fix the 1,10,11,...,2,3 count that Matlab does
relData=relData(:,~emptyChannels1);
EMGList=EMGList1;

%Check if names match with expectation, otherwise query user
for k=1:length(EMGList)
    while sum(strcmpi(orderedEMGList,EMGList{k}))==0 && ~strcmpi(EMGList{k}(1:4),'sync')
        aux= inputdlg(['Did not recognize muscle name, please re-enter name for channel ' num2str(k) ' (was ' EMGList{k} '). Acceptable values are ' cell2mat(strcat(orderedEMGList,', ')) ' or ''sync''.'],'s');
        if k<=length(EMGList1)
            EMGList1{idxList(k)}=aux{1}; %This is to keep the same message from being prompeted for each trial processed.
        end
        EMGList{k}=aux{1};
    end
end

%For some reasing the naming convention for analog pins is not kept
%across Nexus versions:
fieldNames=fields(analogs);

refSync=analogs.(fieldNames{cellfun(@(x) ~isempty(strfind(x,'Pin3')) | ~isempty(strfind(x,'Pin_3')) | ~isempty(strfind(x,'Raw_3')),fieldNames)});

EMGfrequency=analogsInfo.frequency;
allData=relData;

%Pre-process:
[refSync] = clipSignals(refSync(:),.1); %Clipping top & bottom samples (1 out of 1e3!)
refAux=medfilt1(refSync,20);
%refAux(refAux<(median(refAux)-5*iqr(refAux)) | refAux>(median(refAux)+5*iqr(refAux)))=median(refAux);
refAux=medfilt1(diff(refAux),10);
clear auxData*

%Sorting muscles (orderedEMGList was created previously) so that they are always stored in the same order
orderedIndexes=zeros(length(orderedEMGList),1);
for j=1:length(orderedEMGList)
    for k=1:length(EMGList)
        if strcmpi(orderedEMGList{j},EMGList{k})
            orderedIndexes(j)=k;
            break;
        end
    end
end
orderedIndexes=orderedIndexes(orderedIndexes~=0); %Avoiding missing muscles
aux=zeros(length(EMGList),1);
aux(orderedIndexes)=1;
if any(aux==0) && ~all(strcmpi(EMGList(aux==0),'sync'))
    warning(['loadTrials: Not all of the provided muscles are in the ordered list, ignoring ' EMGList{aux==0}])
end
allData(allData==0)=NaN; %Eliminating samples that are exactly 0: these are unavailable samples
EMG=labTimeSeries(allData(:,orderedIndexes),0,1/EMGfrequency,EMGList(orderedIndexes)); %Throw away the synch signal
clear allData* relData* auxData*

%% 5. Retrieve Ground Reaction Force (GRF) Data If It Exists
relData=[];
forceLabels ={};
units={};
fieldList=fields(analogs);
forceLabelIdx = contains(fieldList,'Force_Fz'); % only care about Fz
forceLabelIdx = find(forceLabelIdx,2,'first');  % FP 1 (Left) & 2 (Right)
hasForces = ~isempty(forceLabelIdx);
if hasForces     % if force data found, ...
    for j=1:length(forceLabelIdx)   % for each relevant force label, ...
        forceLabels{end+1} = fieldList{forceLabelIdx(j)};    % add label
        units{end+1} = eval(['analogsInfo.units.', ...
            fieldList{forceLabelIdx(j)}]);
        relData = [relData analogs.(fieldList{forceLabelIdx(j)})];
    end
    GRF = labTimeSeries(relData,0, ...
        1/analogsInfo.frequency,forceLabels);
    GRF.DataInfo.Units = units;
else    % otherwise, set force data to be empty, ...
    GRF = [];
end

clear relData

%% 6. Retrieve H-Reflex Stimulator Pin Data If It Exists
if shouldUseStimTrig    % if stimulation trigger data should be used, ...
    % NOTE: the below code block is copied from loadTrials (implemented by SL)
    relData = [];
    stimLabels = {};
    units = {};
    fieldList = fields(analogs);
    stimLabelIdx = cellfun(@(x) ~isempty(x), ...
        regexp(fieldList,'^Stimulator_Trigger_Sync_'));
    stimLabelIdx = find(stimLabelIdx);
    hasStimTrig = ~isempty(stimLabelIdx);
    if hasStimTrig	% if stimulator trigger sync data found, ...
        for st = 1:length(stimLabelIdx) % for each stim trigger pin, ...
            stimLabels{end+1} = fieldList{stimLabelIdx(st)};	% add the label
            units{end+1} = eval(['analogsInfo.units.', ...
                fieldList{stimLabelIdx(st)}]);
            relData = [relData analogs.(fieldList{stimLabelIdx(st)})];
        end
        HreflexStimPin = labTimeSeries(relData,0, ...
            1/analogsInfo.frequency,stimLabels);

        % verify that the # of frames matches that of the GRF data
        if ~isempty(GRF)    % if there is GRF data present, ...
            if (GRF.Length ~= HreflexStimPin.Length)
                error(['Hreflex stimulator pins have different length than' ...
                    'GRF data. This should never happen. Data is compromised.']);
            end
        end
    else
        warning(['User indicated stimulation trigger data should be ' ...
            'used to identify the artifact peak times, but no trigger ' ...
            'pulse data is present.']);
        HreflexStimPin = [];
    end
end

% clear analogs* %Save memory space, no longer need analog data, it was already loaded

%% Save the Data
% TODO: implement data saving if valuable for this script
% try
%     RTdata = struct();%initialize save structure
%     RTdata.trialname = filename;
%     RTdata.path = path;
%     RTdata.creationdate = clock;
%     RTdata.forcedata = forces;
%     RTdata.forcelabels = forceLabels;
%     RTdata.markerdata = markers;
%     RTdata.markerlabels = markerList;
%     RTdata.Rsteplengths = Rgamma;
%     RTdata.Lsteplengths = Lgamma;
%     RTdata.Rcadence = Rcadence;
%     RTdata.Lcadence = Lcadence;
%     RTdata.Rsteptime = Rsteptime;
%     RTdata.Lsteptime = Lsteptime;
%     RTdata.time = time;
%
%     fn = strrep(datestr(clock),'-','');
%
%     filesave = [path fn(1:9) '_' filename(1:end-4) '_SL_Realtime'];
%
%     save(filesave,'RTdata');
% catch ME
%     throw(ME)
% end

%% 7. Define H-Reflex Calibration Trial Parameters
% NOTE: should always be same across trials and should be same for forces
period = EMG.sampPeriod;                    % sampling period
threshSamps = threshStimTimeSep / period;   % convert to samples

%% 8. Identify Locations of the Stimulation Artifacts
% TODO: update to work in case of only one leg
% extract relevant EMG data
[EMG_RTAP,times] = EMG.getDataAsVector('RTAP'); % time array for plotting
EMG_LTAP = EMG.getDataAsVector('LTAP'); % TA proximal is for stim artifact
EMG_RH = EMG.getDataAsVector('RSOL');
EMG_LH = EMG.getDataAsVector('LSOL');   % H-reflex muscle (usually Soleus)

% if missing any of the EMG signals used below, ...
if any(cellfun(@isempty,{EMG_RTAP,EMG_LTAP,EMG_RH,EMG_LH}))
    error('Missing one or more EMG signals.');
end

% extract all stimulation trigger data for each leg
stimTrigR = HreflexStimPin.getDataAsVector( ...
    'Stimulator_Trigger_Sync_Right_Stimulator');
stimTrigL = HreflexStimPin.getDataAsVector( ...
    'Stimulator_Trigger_Sync_Left__Stimulator');

% TODO: implement check for if forces should be used in case of standing on
% the treadmill but not walking during calibration
% NOTE: using 'shouldUseStimTrig' as a proxy for walking trials where
% useful forces are present
% if forces are present and useful to examine (i.e., walking trial), ...
if hasForces && shouldUseStimTrig
    % extract Fz data from TM force plates 1 & 2
    GRFRFz = GRF.getDataAsVector('Force_Fz2');
    GRFLFz = GRF.getDataAsVector('Force_Fz1');
else                % otherwise, ...
    GRFRFz = [];    % create empty arrays
    GRFLFz = [];
end

% NOTE: it does not work to use stim trigger pulse to retrieve peak times
% if stimulator is disabled during trial (because there will be trigger
% pulse but participant will not have been stimulated)
% if there is stimulation trigger pulse data and it should be used to
% identify the locations of the artifact peaks, ...
if shouldUseStimTrig && hasStimTrig
    indsStimArtifact = Hreflex.extractStimArtifactIndsFromTrigger( ...
        times,{EMG_RTAP,EMG_LTAP},{stimTrigR,stimTrigL});
    locsR = indsStimArtifact{1};
    locsL = indsStimArtifact{2};

    % validate the number of detected stimulation triggers
    if (numStimR ~= numel(locsR)) || (numStimL ~= numel(locsL))
        error(['The number of stimulation trigger pulses does not ' ...
            'match the number of input stimulation amplitudes.']);
    end

    Hreflex.plotStimArtifactPeaks(times,{EMG_RTAP,EMG_LTAP}, ...
        {locsR,locsL},id,trialNum,pathFigs);
else
    warning(['No stimulation trigger signal being used. Artifact ' ...
        'identification may not be as accurate.']);

    % detect stimulation artifact locations without using stim triggers
    [~,locsR] = findpeaks(EMG_RTAP,'NPeaks',numStimR, ...
        'MinPeakHeight',threshStimArtifact,'MinPeakDistance',threshSamps);
    [~,locsL] = findpeaks(EMG_LTAP,'NPeaks',numStimL, ...
        'MinPeakHeight',threshStimArtifact,'MinPeakDistance',threshSamps);

    Hreflex.plotStimArtifactPeaks(times,{EMG_RTAP,EMG_LTAP}, ...
        {locsR,locsL},id,trialNum,threshStimArtifact,pathFigs);
end

% ask user if would like to continue after verifying artifact detection
shouldCont = questdlg('Was stimulation artifact detection accurate?', ...
    'Continue Script','Yes','No','Yes');
if strcmp(shouldCont,'No')      % if should not continue script, ...
    return;                     % stop script execution for adjustments
end

%% 9. Plot All Stimuli to Verify the Waveforms & Timing (Via GRFs)
[snippets,timesSnippet] = Hreflex.extractSnippets( ...
    {locsR;locsL},{EMG_RH;EMG_LH},{GRFRFz;GRFLFz});

%% 10.1 Plot All Snippets for Each Leg Together in One Figure
% TODO: add stim intensity array input to color snippets by amplitude
Hreflex.plotSnippets(timesSnippet,snippets,{'Force (N)','Force (N)', ...
    'Raw EMG (V)','Raw EMG (V)'}, ...
    {'Right & Left Fz - Right Stim','Left & Right Fz - Left Stim', ...
    'Right Sol','Left Sol'},id,trialNum,pathFigs);

%% 10.2 Plot Snippets for a Given Amplitude for Each Leg Together
% TODO: move the finding of unique amplitudes and indices up here

%% 11. Compute M-wave & H-wave Amplitude (assuming waveforms are correct)
% TODO: reject measurements if GRF reveals not in single stance
[amps,durs] = Hreflex.computeAmplitudes({EMG_RH;EMG_LH},{locsR;locsL});
% convert wave amplitudes from Volts to Millivolts
amps = cellfun(@(x) 1000.*x,amps,'UniformOutput',false);

ampsMwaveR = amps{1,1};
ampsHwaveR = amps{1,2};
ampsNoiseR = amps{1,3};
ampsMwaveL = amps{2,1};
ampsHwaveL = amps{2,2};
ampsNoiseL = amps{2,3};

% plot the H-wave / M-wave duration (i.e., time difference between minimum
% and maximum) to determine whether valid waveform or not
% figure;
% hold on;
% histogram(durs{1,1},0.000:period:0.020,'EdgeColor','none');
% xline(0.008,'r-','LineWidth',3);
% hold off;
% xlim([0.000 0.020]);
% xlabel('M-Wave Width (s)');
% ylabel('Frequency');
% title([id ' - Right Leg']);
% saveas(gcf,[pathFigs id '_MwaveDurDistribution_Trial' trialNum '_RightLeg.png']);
% saveas(gcf,[pathFigs id '_MwaveDurDistribution_Trial' trialNum '_RightLeg.fig']);

%% 12. Compute Means and H/M Ratios for Unique Stimulation Amplitudes
ampsStimRU = unique(ampsStimR);
ampsStimLU = unique(ampsStimL);
% Gaussian fit function for fitting average H-wave amplitude data
% based on equation 2 (section 2.4. Curve fitting from Brinkworth et al.,
% Journal of Neuroscience Methods, 2007)
% fun = @(x,xdata)x(1).*exp(-((((((xdata).^(x(3)))-x(4))./(x(2))).^2)./2));
avgsHwaveR = arrayfun(@(x) mean(ampsHwaveR(ampsStimR == x),'omitnan'),ampsStimRU);
% TODO: alternate approach would be to convert the mean H-wave amplitudes
% to integer "frequencies" for each stim amplitude and fit a normal dist.
% pdR = fitdist(ampsStimRU','Normal', ...
%     'Frequency',round((avgsHwaveR / max(avgsHwaveR)) * 10000));
% initialize coefficients
% coefsR0 = [max(avgsHwaveR) std(ampsStimRU) 1 mean(ampsStimRU)];
% coefsR = lsqcurvefit(fun,coefsR0,ampsStimRU,avgsHwaveR);
avgsMwaveR = arrayfun(@(x) mean(ampsMwaveR(ampsStimR == x),'omitnan'),ampsStimRU);
avgsHwaveL = arrayfun(@(x) mean(ampsHwaveL(ampsStimL == x),'omitnan'),ampsStimLU);
% pdL = fitdist(ampsStimLU','Normal', ...
%     'Frequency',round((avgsHwaveL / max(avgsHwaveL)) * 10000));
% coefsL0 = [max(avgsHwaveL) std(ampsStimLU) 1 mean(ampsStimLU)];
% coefsL = lsqcurvefit(fun,coefsL0,ampsStimLU,avgsHwaveL);
avgsMwaveL = arrayfun(@(x) mean(ampsMwaveL(ampsStimL == x),'omitnan'),ampsStimLU);
% TODO: verify that these values will always be sorted in ascending order
% and, if not, sort them

ratioR = ampsHwaveR ./ ampsMwaveR;
ratioL = ampsHwaveL ./ ampsMwaveL;
avgsRatioR = arrayfun(@(x) mean(ratioR(ampsStimR == x)),ampsStimRU);
avgsRatioL = arrayfun(@(x) mean(ratioL(ampsStimL == x)),ampsStimLU);

%% 13. Plot the Noise Distributions for Both Legs
% compute four times noise floor (mean) to determine whether
% to send participant home or not (at least one leg must exceed threshold)
threshNoiseR = 4 * mean(ampsNoiseR);
threshNoiseL = 4 * mean(ampsNoiseL);

figure; hold on;
histogram(ampsNoiseR,0.00:0.05:0.30,'Normalization','probability');
xline(mean(ampsNoiseR),'r',sprintf('Mean = %.2f mV', ...
    mean(ampsNoiseR)),'LineWidth',2);
xline(median(ampsNoiseR),'g',sprintf('Median = %.2f mV', ...
    median(ampsNoiseR)),'LineWidth',2);
xline(prctile(ampsNoiseR,75),'k',sprintf( ...
    '75^{th} Percentile = %.2f mV',prctile(ampsNoiseR,75)),'LineWidth',2);
hold off;
axis([0 0.3 0 0.8]);
xlabel('Noise Amplitude Peak-to-Peak (mV)');
ylabel('Proportion of Stimuli');
title([id ' - Trial' trialNum ' - Right Leg - Noise Distribution']);
saveas(gcf,[pathFigs id '_NoiseDistribution_Trial' trialNum ...
    '_RightLeg.png']);
saveas(gcf,[pathFigs id '_NoiseDistribution_Trial' trialNum ...
    '_RightLeg.fig']);

figure; hold on;
histogram(ampsNoiseL,0.00:0.05:0.30,'Normalization','probability');
xline(mean(ampsNoiseL),'r',sprintf('Mean = %.2f mV', ...
    mean(ampsNoiseL)),'LineWidth',2);
xline(median(ampsNoiseL),'g',sprintf('Median = %.2f mV', ...
    median(ampsNoiseL)),'LineWidth',2);
xline(prctile(ampsNoiseL,75),'k',sprintf( ...
    '75^{th} Percentile = %.2f mV',prctile(ampsNoiseL,75)),'LineWidth',2);
hold off;
axis([0 0.3 0 0.8]);
xlabel('Noise Amplitude Peak-to-Peak (mV)');
ylabel('Proportion of Stimuli');
title([id ' - Trial' trialNum ' - Left Leg - Noise Distribution']);
saveas(gcf,[pathFigs id '_NoiseDistribution_Trial' trialNum ...
    '_LeftLeg.png']);
saveas(gcf,[pathFigs id '_NoiseDistribution_Trial' trialNum ...
    '_LeftLeg.fig']);

%% 14. Plot Recruitment Curve for Both Legs
% TODO: add normal distribution fit to H-wave recruitment curve to pick out
% peak amplitude and current at which peak occurs
% incX = 0.1; % increment for curve fit (in mA)
% xR = min(ampsStimRU):incX:max(ampsStimRU);
% yR = fun(coefsR,xR);
% xL = min(ampsStimLU):incX:max(ampsStimLU);
% yL = fun(coefsL,xL);
Hreflex.plotCal(ampsStimR,{ampsMwaveR; ampsHwaveR}, ...
    'MG EMG Amplitude (mV)','Right Leg',id,trialNum,mean(ampsNoiseR), ...
    pathFigs);
Hreflex.plotCal(ampsStimL,{ampsMwaveL; ampsHwaveL}, ...
    'MG EMG Amplitude (mV)','Left Leg',id,trialNum,mean(ampsNoiseL), ...
    pathFigs);

%% 15. Plot Ratio of H-wave to M-wave amplitude
Hreflex.plotCal(ampsStimR,{ratioR},'H:M Ratio','Right Leg',id,trialNum, ...
    pathFigs);
Hreflex.plotCal(ampsStimL,{ratioL},'H:M Ratio','Left Leg',id,trialNum, ...
    pathFigs);
