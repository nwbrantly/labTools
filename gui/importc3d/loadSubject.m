function [expData, rawExpData, adaptData] = loadSubject(info, eventClass)
% loadSubject  Load, organize, process, and save experimental session
%   data from C3D files into labTools data objects.
%
%   Reads raw trial data from the .c3d files specified by info, constructs
% labTools data objects (experimentData, subjectData), detects gait events,
% computes adaptation parameters, and saves the results to disk. If datlog
% files are present for all trials, data logs are synchronized prior to
% processing.
%
%   Inputs:
%     info       - Struct of session information returned by GetInfoGUI,
%                  containing participant demographics, file paths, trial
%                  and condition assignments, and EMG channel labels
%     eventClass - (optional) String specifying the gait event detection
%                  method. Defaults to '' if omitted or empty:
%                    ''      - default (forces for TM, kinematics for OG)
%                    'kin'   - strictly from kinematics (OG trials)
%                    'force' - strictly from forces (TM trials)
%
%   Outputs:
%     expData    - Processed experimentData object
%     rawExpData - Unprocessed experimentData object
%     adaptData  - adaptationData object with computed adaptation params
%
%   Toolbox Dependencies:
%     None
%
%   See also: GetInfoGUI, c3d2mat, getTrialMetaData, loadTrials,
%     experimentData, experimentData.process, SyncDatalog

arguments
    info       (1,1) struct
    eventClass (1,:) char   = ''
end

%% Initialize Diary to Save All Information Displayed during Loading
% onCleanup guarantees diary is closed even if an error is thrown
diaryFileName = fullfile(info.save_folder, [info.ID 'loading.log']);
diary(diaryFileName);
cleanupDiary  = onCleanup(@() diary('off'));

%% Determine Experiment Date
% 'labDate' is a 'labTools' repository class
expDate = labDate(info.day, info.month, info.year);

%% Experiment Information
% Creates 'experimentMetaData' object, which houses information about
% the number of trials, their descriptions, notes, and trial numbers.
% expMD = experimentMetaData(info.ExpDescription, expDate, ...
%     info.experimenter, info.exp_obs, strtrim(info.conditionNames), ...
%     info.conditionDescriptions, info.trialnums, info.numoftrials, ...
%     info.schenleyLab, info.perceptualTasks);
% Constructor(ID, date, experimenter, obs, conds, desc, trialLst, Ntrials);

%% Participant Information
% Determine the reference leg, which assumes that:
%   1) the leg on the fast belt is the dominant leg
%   2) info.domleg is either 'left' or 'right'
%   3) the reference leg is the leg on the slow belt
if isfield(info, 'fastLeg')                 % if fast leg specified, ...
    if strcmpi(info.fastLeg, 'right')
        info.refLeg = 'L';
    elseif strcmpi(info.fastLeg, 'left')
        info.refLeg = 'R';
    else
        warning(['Reference leg could not be determined from ' ...
            'information given. Make sure info.fastLeg is either ' ...
            '''Left'' or ''Right''.']);
    end
elseif isfield(info, 'isStroke') && info.isStroke == 1  % if stroke, ...
    % Reference leg is the affected side when belt speed is not given.
    % TODO: add condition in case fast leg field does not exist
    if strcmpi(info.affectedSide, 'right')
        info.refLeg  = 'R';
        info.fastLeg = 'Left';
    elseif strcmpi(info.affectedSide, 'left')
        info.refLeg  = 'L';
        info.fastLeg = 'Right';
    else
        warning(['Reference leg could not be determined from ' ...
            'information given. Make sure info.affectedSide is ' ...
            'either ''Left'' or ''Right''.']);
    end
else                                                    % otherwise, ...
    % Assume reference leg is non-dominant when information not given
    if strcmpi(info.domleg, 'right')
        info.refLeg  = 'L';
        info.fastLeg = 'Right';
    elseif strcmpi(info.domleg, 'left')
        info.refLeg  = 'R';
        info.fastLeg = 'Left';
    else
        warning(['Reference leg could not be determined from ' ...
            'information given. Make sure info.domleg is either ' ...
            '''Left'' or ''Right''.']);
    end
end

DOB         = labDate(info.DOBday, info.DOBmonth, info.DOByear);
% Compute age at time of experimental session to nearest month
% TODO: why not compute age to the nearest day? Privacy concern?
ageInMonths = round(expDate.timeSince(DOB));
age         = ageInMonths / 12;

if ~isfield(info, 'isStroke') || info.isStroke == 0    % if no stroke, ...
    subData = subjectData(DOB, info.gender, info.domleg, info.domhand, ...
        info.height, info.weight, age, info.ID, info.fastLeg);
else                                                    % otherwise, ...
    % TODO: add date of stroke to participant data object
    subData = strokeSubjectData(DOB, info.gender, info.domleg, ...
        info.domhand, info.height, info.weight, age, info.ID, ...
        info.fastLeg, info.affectedSide);
end

%% Process Trial Data
% Generate meta data for each trial in the experimental session
[trialMD, fileList, secFileList, datlogExist] = getTrialMetaData(info);
rawTrialData = loadTrials(trialMD, fileList, secFileList, info);

% The below code block is most likely redundant, but keep for now;
% the code will always have datlog = true when perceptual task = 1.
if datlogExist || info.perceptualTasks == 1
    datlog = {{}};
    for trial = 1:length(rawTrialData)      % for each trial, ...
        if ~isempty(rawTrialData{trial})    % if trial data available, ...
            % Extract trial data logs from trial meta data
            datlog{trial} = rawTrialData{trial}.metaData.datlog;
        else                                % otherwise, ...
            datlog{trial} = {};             % set as empty cell
        end
    end
    % Creates 'experimentMetaData' object, which contains information about
    % the number of trials, their descriptions, notes, and trial numbers.
    expMD = experimentMetaData(info.ExpDescription, expDate, ...
        info.experimenter, info.exp_obs, strtrim(info.conditionNames), ...
        info.conditionDescriptions, info.trialnums, info.numoftrials, ...
        info.schenleyLab, info.perceptualTasks, datlog);
else
    expMD = experimentMetaData(info.ExpDescription, expDate, ...
        info.experimenter, info.exp_obs, strtrim(info.conditionNames), ...
        info.conditionDescriptions, info.trialnums, info.numoftrials, ...
        info.schenleyLab, info.perceptualTasks);
    % Constructor(ID,date,experimenter,obs,conds,desc,trialLst,Ntrials);
end
rawExpData = experimentData(expMD, subData, rawTrialData);

% FIXME: close all figures and remove intermediate variables to free
% up some memory in MATLAB.
% There seems to be a memory issue since summer 2025. During c3d2mat,
% the PC will run out of memory, shown as OutOfMemory, OutOfHeapSpace,
% or png file failed to write errors. A better solution is needed to
% identify why we are running out of memory or if there is a memory
% leak. Since the cause is not yet known, closing figures and removing
% variables is a temporary workaround to allow the code to run.
close('all');
clc();
clearvars -except info eventClass rawExpData datlogExist;

% Synchronize data logs if datlog files exist for all trials and the
% forces exist within those files.
if datlogExist                          % if there are data log files, ...
    rawExpData = SyncDatalog(rawExpData, ...
        [fullfile(info.save_folder, 'DatlogSyncRes') filesep]);
end
save(fullfile(info.save_folder, [info.ID 'RAW.mat']), ...
    'rawExpData', '-v7.3');

%% Process Data
expData   = rawExpData.process(eventClass);
% Save processed data object
save(fullfile(info.save_folder, [info.ID '.mat']), 'expData', '-v7.3');
% Create 'adaptationData' object, and save 'params' file
adaptData = expData.makeDataObj(fullfile(info.save_folder, info.ID));

%% Handle Experiments Requiring Special Trial Splitting from Data Logs
if contains(erase(info.ExpDescription, ' '), 'SpinalAdaptation')
    [expData, adaptData] = SepCondsInExpByAudioCue(expData, ...
        info.save_folder, info.ID, eventClass, info.ExpDescription);
end

end

