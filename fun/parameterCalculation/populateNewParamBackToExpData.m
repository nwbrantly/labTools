function expData = populateNewParamBackToExpData(expData, adaptData)
% populateNewParamBackToExpData  Back-populate new parameters into expData.
%
%   Syntax:
%     expData = populateNewParamBackToExpData(expData, adaptData)
%
%   Copies parameters that exist in adaptData but not yet in expData back
% into each trial's adaptParams field. The primary use case is
% synchronizing EMG normalization parameters that were appended to
% adaptData after the initial processing run. Also propagates DataInfo
% UserData from adaptData, merging any additional fields unique to the
% existing trial. Parameters already present in adaptParams or
% experimentalParams for a given trial are skipped to avoid downstream
% collisions when makeDataObj later rebuilds adaptData from expData
% (e.g., fakeParam is always in experimentalParams and must not be
% duplicated).
%
%   Inputs:
%     expData   - experimentData object; each trial's adaptParams will
%                 be updated with new parameters from adaptData
%     adaptData - adaptationData object containing the new parameters
%                 to back-populate (e.g., after EMG normalization)
%
%   Outputs:
%     expData - Updated experimentData object with new parameters
%               appended to each trial's adaptParams
%
%   Toolbox Dependencies:
%     None
%
%   See also: appendEMGNormParameters, loadSubject,
%     experimentData.recomputeParameters,
%     experimentData.flushAndRecomputeParameters
%
%   Author: Shuqi Liu, 2026-04-02

arguments
    expData   (1,1)
    adaptData (1,1)
end

%% Identify Trials and Trial Column Index
trials   = find(~cellfun(@isempty, expData.data));
trialCol = ismember(adaptData.data.labels, 'trial');

%% Populate New Parameters Per Trial
for iTrial = trials
    trialAdapt     = expData.data{iTrial}.adaptParams;
    trialExpParams = expData.data{iTrial}.experimentalParams;

    % Identify parameters in adaptData not already in this trial
    newDataCol = ~ismember(adaptData.data.labels, ...
        [trialAdapt.labels; trialExpParams.labels]);
    newData         = adaptData.data.Data( ...
        adaptData.data.Data(:, trialCol) == iTrial, newDataCol);
    newLabels       = adaptData.data.labels(newDataCol);
    newDescriptions = adaptData.data.description(newDataCol);
    trialAdapt = trialAdapt.appendData( ...
        newData, newLabels, newDescriptions);

    % Propagate DataInfo UserData from adaptData
    if isempty(trialAdapt.DataInfo.UserData)
        % Previously empty: replace entirely with adaptData's UserData
        trialAdapt.DataInfo.UserData = adaptData.data.DataInfo.UserData;
    else
        % Merge: adaptData fields take precedence; preserve fields
        % unique to the old expData trial
        newUserData = adaptData.data.DataInfo.UserData;
        if isstruct(trialAdapt.DataInfo.UserData)
            uniqueFields = setdiff( ...
                fieldnames(trialAdapt.DataInfo.UserData), ...
                fieldnames(newUserData));
            for iField = uniqueFields'
                newUserData.(iField{1}) = ...
                    trialAdapt.DataInfo.UserData.(iField{1});
            end
        else
            % Not a struct: preserve old info in a single field
            newUserData.prevUserData = trialAdapt.DataInfo.UserData;
        end
        trialAdapt.DataInfo.UserData = newUserData;
    end

    expData.data{iTrial}.adaptParams = trialAdapt;
end

end

