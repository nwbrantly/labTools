% TODO: would it be best to simply leave the zeros since unclear?
% handle invalid direction values (where only one valid y-value exists)
indsDirZeros = find(direction == 0);
numZeros = length(indsDirZeros);
for inv = 1:numZeros                    % for each invalid measure, ...
    if indsDirZeros(inv) == 1           % if first stride is invalid, ...
        direction(1) = direction(2);    % set to be same as stride 2
    else                                % otherwise, ...
        % set invalid direction value to be previous stride direction value
        direction(indsDirZeros(inv)) = direction(indsDirZeros(inv)-1);
    end
end

%% Compute Ankle Positions Relative to Hip
hipPos3D = 0.5 * (sHip + fHip);
hipPosFwd = hipPos3D(:, :, 2);    % extract y-axis component
hipPos3DRel = 0.5 * (sHipRel + fHipRel);    % just for check, should be all zeros
% hipPos = mean([sHip(indSHS,2) fHip(indSHS,2)]);
hipPosSHS = hipPosFwd(:, 1);     % hip position at SHS
% compute average hip position over gait cycle
hipPosAvg_forFast = mean(mean(hipPosFwd(:, 1:6), 'omitnan')); % average hip position from SHS to STO2
hipPosAvg_forSlow = mean(mean(hipPosFwd(:, 3:8), 'omitnan')); % average hip position from SHS to STO2

%rotate coordinates to be aligned wiht walking dierection
%sRotation = calcangle(sAnk(indSHS2,1:2),sAnk(indSTO,1:2),[sAnk(indSTO,1)-100*direction sAnk(indSTO,2)])-90;
%fRotation = calcangle(fAnk(indFHS,1:2),fAnk(indFTO,1:2),[fAnk(indFTO,1)-100*direction fAnk(indFTO,2)])-90;

%avgRotation = (sRotation+fRotation)./2;

%rotationMatrix = [cosd(avgRotation) -sind(avgRotation) 0; sind(avgRotation) cosd(avgRotation) 0; 0 0 1];
%sAnk(indSHS:indFTO2,:) = (rotationMatrix*sAnk(indSHS:indFTO2,:)')';
%fAnk(indSHS:indFTO2,:) = (rotationMatrix*fAnk(indSHS:indFTO2,:)')';
%sHip(indSHS:indFTO2,:) = (rotationMatrix*sHip(indSHS:indFTO2,:)')';
%fHip(indSHS:indFTO2,:) = (rotationMatrix*fHip(indSHS:indFTO2,:)')';

% NEED TO ROTATE
hipPos2D = hipPos3D(:, :, 1:2);
% compute ankle positions
sAnkFwd = sAnk(:, :, 2);
fAnkFwd = fAnk(:, :, 2);
sAnk2D = sAnk(:, :, 1:2);
fAnk2D = fAnk(:, :, 1:2);
sAnk_fromAvgHip = sAnk(:, :, 2) - hipPosAvg_forSlow; % y positon of slow ankle corrected by average hip postion
fAnk_fromAvgHip = fAnk(:, :, 2) - hipPosAvg_forFast; % y positon of fast ankle corrected by average hip postion

% set all steps to have the same slope (a negative slope during stance phase is assumed)
%WHAT IS THIS FOR? WHAT PROBLEMS DOES IT SOLVE THAT THE PREVIOUS ROTATION
%DOESN'T?

% adjust stride data to ensure consistent slope during stance phase
aux = sign(diff(sAnk(:, [4 5], 2), 1, 2));  % checks for: sAnk(indSHS2,2) < sAnk(indSTO,2) (doesn't use HIP to avoid HIP fluctuation issues)
sAnkFwd = bsxfun(@times, sAnkFwd, aux);
fAnkFwd = bsxfun(@times, fAnkFwd, aux);
sAnk2D = bsxfun(@times, sAnk2D, aux);
fAnk2D = bsxfun(@times, fAnk2D, aux);

%Alternative definition: should be equivalent, since we reference to midHip
%when doing the rotation. Only difference may be in sign of walking, since
%its computed slighltly different. Should not cause issues as differences
%may only ocurr when subject is turning around, which is a bad stride
%anyway
%WARNING: THIS WAS DISABLED BECAUSE IT LEADS TO CRAPPY RESULTS WHEN HIP
%MARKERS ARE NOT RELIABLE (NOISY). NEED TO FIX. THE PROBLEM IS
%sAnkFwd-fAnkFwd DEPENDS ON HIP POSITION WHEN IT SHOULDNT (COMPUTING
%DIFFERENCE OF TWO MARKER POSITIONS USING SAME REFERENCE). NOT SURE WHY.
%sAnkFwd=sAnkRel(:,:,2);
%fAnkFwd=fAnkRel(:,:,2);
%sAnk2D=sAnkRel(:,:,1:2);
%fAnk2D=fAnkRel(:,:,1:2);

aux = sign(sAngle(:, 1));            % checks for sAngle(indSHS) < 0
sAngle = bsxfun(@times, sAngle, aux);
fAngle = bsxfun(@times, fAngle, aux);

end

function [rotatedMarkerData, sAnkFwd, fAnkFwd, sAnk2D, fAnk2D, ...
    sAngle, fAngle, direction, hipPosSHS, ...
    sAnk_fromAvgHip, fAnk_fromAvgHip] = ...
    getKinematicDataAbs(eventTimes, markerData, angleData, s)
%GETKINEMATICDATAABS Extract marker data in absolute lab-frame coordinates.
%
% Syntax
%   [rotatedMarkerData, sAnkFwd, fAnkFwd, sAnk2D, fAnk2D, sAngle, ...
%    fAngle, direction, hipPosSHS, sAnk_fromAvgHip, ...
%    fAnk_fromAvgHip] = ...
%       getKinematicDataAbs(eventTimes, markerData, angleData, s)
%
% Description
%   Like getKinematicData but uses an absolute lab-frame reference
%   (origin) rather than a hip-centered coordinate frame. Ankle
%   positions in sAnkFwd and sAnk2D are therefore absolute rather than
%   relative to the hip. The reference axis for rotation is derived
%   from the ankle markers instead of the hip markers.
%
% Inputs
%   eventTimes  - (numStrides x numEvents) array of gait event times
%   markerData  - orientedLabTimeSeries of 3D marker trajectories
%   angleData   - labTimeSeries of limb angles (or empty)
%   s           - (char) slow-leg identifier: 'L' or 'R'
%
% Outputs
%   rotatedMarkerData - markerData rotated to lab-frame orientation
%   sAnkFwd           - (numStrides x numEvents) slow ankle fore-aft
%                       position in absolute lab frame
%   fAnkFwd           - (numStrides x numEvents) fast ankle fore-aft
%                       position in absolute lab frame
%   sAnk2D            - (numStrides x numEvents x 2) slow ankle 2D
%                       position in absolute lab frame
%   fAnk2D            - (numStrides x numEvents x 2) fast ankle 2D
%                       position in absolute lab frame
%   sAngle            - (numStrides x numEvents) slow leg limb angles
%   fAngle            - (numStrides x numEvents) fast leg limb angles
%   direction         - (numStrides x 1) walking direction (+1 or -1)
%   hipPosSHS         - (numStrides x 1) hip position at slow heel
%                       strike
%   sAnk_fromAvgHip   - slow ankle fore-aft position relative to mean
%                       hip
%   fAnk_fromAvgHip   - fast ankle fore-aft position relative to mean
%                       hip
%
% Toolbox Dependencies
%   None
%
% See Also
%   getKinematicData, computeSpatialParameters

arguments
    eventTimes  (:,:) double
    markerData
    angleData
    s           (1,:) char
end

%% Rotate Marker Data to Absolute Lab Frame
refMarker3D = [0 0 0];  % absolute lab reference

% define reference axis:
% option 1 (ideal): body reference (vector from left to right hip)
% compute difference between LHIP and RHIP (i.e., RHIP - LHIP) for x, y, z
refAxis = squeeze( ...
    diff(markerData.getOrientedData({'LANK', 'RANK'}), 1, 2)); % L to R

% Ref axis option 2 (assuming the subject walks only along the y axis):
% option 2: assuming the subject walks primarily along the y-axis,
% project onto the x-direction to determine forward/backward motion
% merely makes the y and z columns zeros and leaves the x column as is
% projecting along x direction — equivalent to determining the
% forward/backward sign
refAxis = refAxis * [1 0 0]' * [1 0 0];

% align marker data by translating to the reference marker (origin)
% and rotating so that the reference axis aligns with the vertical axis
% call to 'alignRotate' appears equivalent to swapping the signs of the x
% and y columns (but not z) of the output from 'translate'
rotatedMarkerData = markerData.translate(-squeeze(refMarker3D)) ...
    .alignRotate(refAxis, [0 0 1]);

%% Get Relevant Sample of Data (Using Interpolation)
% 's' represents the slow limb, 'f' represents the fast limb
if strcmp(s, 'L')
    f = 'R';
elseif strcmp(s, 'R')
    f = 'L';
else
    error('Invalid limb specification. Must be ''L'' or ''R''.');
end

% extract marker orientation and axis information
orientation = markerData.orientation;
directions  = {orientation.sideAxis, orientation.foreaftAxis, ...
    orientation.updownAxis};
signs = [orientation.sideSign orientation.foreaftSign ...
    orientation.updownSign];

% define markers of interest
markers = {'HIP', 'ANK', 'TOE'};
labels  = {};
legs    = {s, f};
legs2   = {'s', 'f'};

% construct labels for markers (e.g., 'sHIP', 'fANK', etc.)
for iMarker = 1:length(markers)
    for leg = 1:2
        % odd indices: slow leg, even indices: fast leg
        labels{end+1} = [legs{leg} markers{iMarker}];
    end
end

% check for missing markers
[bool, idx] = isaLabelPrefix(markerData, labels);
if ~all(bool)
    warning(['Markers are missing: ' ...
        cell2mat(strcat(labels(~bool), ','))]);
end

% extract marker data at gait event times
for iLabel = 1:length(labels) % assign each marker data to a x3 str
    aux = markerData.getDataAsTS( ...
        markerData.addLabelSuffix(labels{iLabel}));
    if ~isempty(aux.Data)
        % extract data by finding the closest available sample at each
        % event time
        newMarkerData = aux.getSample(eventTimes, 'closest');
        relMarkerData = rotatedMarkerData.getDataAsTS( ...
            rotatedMarkerData.addLabelSuffix(labels{iLabel}));
        relMarkerData = relMarkerData.getSample(eventTimes, 'closest');
    else    % otherwise, a marker is missing
        warning(['Marker ' labels{iLabel} ...
            ' is missing. All references to it will return NaN.']);
        newMarkerData = nan([size(eventTimes), 3]);
        relMarkerData = nan([size(eventTimes), 3]);
    end

    % assign extracted marker data to corresponding variables
    if strcmp(labels{iLabel}(1), s)       % if slow leg markers, ...
        eval(['s' upper(labels{iLabel}(2)) ...
            lower(labels{iLabel}(3:4)) ' = newMarkerData;']);
        eval(['s' upper(labels{iLabel}(2)) ...
            lower(labels{iLabel}(3:4)) 'Rel = relMarkerData;']);
    elseif strcmp(labels{iLabel}(1), f)   % if fast leg markers, ...
        eval(['f' upper(labels{iLabel}(2)) ...
            lower(labels{iLabel}(3:4)) ' = newMarkerData;']);
        eval(['f' upper(labels{iLabel}(2)) ...
            lower(labels{iLabel}(3:4)) 'Rel = relMarkerData;']);
    else                            % otherwise, ...
        error('Marker labels must begin with ''R'' or ''L''.');
    end
end

%% Extract Angle Data at Gait Event Times
if ~isempty(angleData)
    newAngleData = angleData.getDataAsTS({[s 'Limb'], [f 'Limb']});
    newAngleData = newAngleData.getSample(eventTimes, 'closest');
    sAngle = newAngleData(:, :, 1);
    fAngle = newAngleData(:, :, 2);
else
    sAngle = nan(size(eventTimes, 1), size(eventTimes, 2), 1);
    fAngle = nan(size(eventTimes, 1), size(eventTimes, 2), 1);
end

%% Compute Walking Direction
% direction is determined from y-axis difference of slow ankle marker
% during swing phase (STO to SHS2)
% TODO: would using SHS and STO work just as well?
direction = sign(diff(sAnk(:, 4:5, 2), 1, 2));

% handle missing values in direction vector
indsDirNans = find(isnan(direction));   % identify any NaN values
numNans     = length(indsDirNans);      % number of NaN values
for miss = 1:numNans                    % for each missing value, ...
    % check only y-axis values for current stride (i.e., none of gait
    % events with '2' in the name since could be at or approaching a turn)
    hasVal = ~isnan(sAnk(indsDirNans(miss), 1:4, 2));
    % use two most disparate gait events in time to try to account for
    % noise in the ankle marker y-axis position during stance phase
    direction(indsDirNans(miss)) = sign(diff(sAnk(indsDirNans(miss), ...
        [find(hasVal, 1) find(hasVal, 1, 'last')], 2), 1, 2));
end

