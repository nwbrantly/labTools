function [expData] = populateNewParamBackToExpData(expData, adaptData)
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

trials = find(~cellfun(@isempty, expData.data));
arguments
    expData   (1,1)
    adaptData (1,1)
end

trialCol = ismember(adaptData.data.labels, 'trial');
for t = trials
    %find columes containing new data (do not touch data that's already
    %there + do not populate a fakeparam which is always in
    %experimentalParams, otherwise the fakeparam will be repeated and cause parameter
    % collision downstream when trying to create adaptData using adaptData = expData.makeDataObj([]);
    newDataCol = ~ismember(adaptData.data.labels, [expData.data{t}.adaptParams.labels; expData.data{t}.experimentalParams.labels]);
    newData = adaptData.data.Data(adaptData.data.Data(:, trialCol) == t, newDataCol);
    newLabels = adaptData.data.labels(newDataCol);
    newDescp = adaptData.data.description(newDataCol);
    expData.data{t}.adaptParams = expData.data{t}.adaptParams.appendData(newData, newLabels, newDescp);
    %repopulate the information as well.
    if isempty(expData.data{t}.adaptParams.DataInfo.UserData)
        %if used to be empty, just replace with what's in adaptData
        expData.data{t}.adaptParams.DataInfo.UserData = adaptData.data.DataInfo.UserData;
    else%if used have info, try to preserve or replace it.
        newUserData = adaptData.data.DataInfo.UserData;
        if isstruct(expData.data{t}.adaptParams.DataInfo.UserData)
            %used to have info and is already a struct, existing fields
            %use the new info from the adaptData, additional fields,
            %try to keep it.
            %look for additional fields that used to be in expData but
            %not in new adaptData. Note here repeated fields will honor the adaptData and
            %ignore the expData's userinfo
            uniqueToOld = setdiff(fieldnames(expData.data{t}.adaptParams.DataInfo.UserData),...
                fieldnames(newUserData));
            for fd = uniqueToOld %add in the additional info
                newUserData.(fd{1}) = expData.data{t}.adaptParams.DataInfo.UserData.(fd{1});
            end
        else %not a struct just save all old info into one field.
            newUserData.prevUserData = expData.data{t}.adaptParams.DataInfo.UserData;
        end
        expData.data{t}.adaptParams.DataInfo.UserData = newUserData;
    end
end
end
