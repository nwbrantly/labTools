function [SB, SBsum, SP, SPsum, SBmax, SBmaxAbs, SBmaxQS, SPmax, ...
    SPmaxQS, ImpactMagS] = ComputeLegForceParameters( ...
    apForceTrace, forceBaseline, brakingSign, titleText)
%COMPUTELEGFORCEPARAMETERS Compute AP force parameters for one leg stride.
%
%   Computes mean and peak anterior-posterior (AP) ground reaction force
% parameters for one leg over a single stride. Parameters include mean
% and summed braking and propulsion forces, absolute and quasi-static
% peak braking and propulsion forces, and the AP impact peak magnitude.
%
% Inputs:
%   apForceTrace  - N-by-1 vector of normalized AP force data for
%                   the stance phase of the stride
%   forceBaseline - scalar baseline offset to subtract before
%                   classifying braking and propulsion phases
%   brakingSign   - sign multiplier (1 or -1) that makes the braking
%                   force positive for the leg of interest
%   titleText     - (optional) string used as a figure title in
%                   debugging; defaults to ''
%
% Outputs:
%   SB         - mean braking force over the stride
%   SBsum      - total braking impulse (sum) over the stride
%   SP         - mean propulsion force over the stride
%   SPsum      - total propulsion impulse (sum) over the stride
%   SBmax      - peak braking force (sign-flipped minimum)
%   SBmaxAbs   - absolute peak braking force relative to baseline
%   SBmaxQS    - quasi-static peak braking force
%   SPmax      - peak propulsion force (maximum)
%   SPmaxQS    - quasi-static peak propulsion force
%   ImpactMagS - peak AP force in the first 15% of the stride
%
% Toolbox Dependencies:
%   None
%
% See also COMPUTEFORCEPARAMETERS, PARAMETERSERIES.

arguments
    apForceTrace  (:,1) double
    forceBaseline (1,1) double
    brakingSign   (1,1) double
    titleText     (1,:) char = ''
end

%% Identify Braking and Propulsion Indices
% Braking: samples below baseline; propulsion: samples above baseline
brakingIdx = find((apForceTrace - forceBaseline) < 0);
propIdx    = find((apForceTrace - forceBaseline) > 0);

% Identify the AP impact peak in the first 15% of the stride
[ImpactMagS, impactIdx] = nanmax( ...
    apForceTrace(1:round(0.15*length(apForceTrace))));

% Exclude pre-impact samples from braking and propulsion classification
% (new method 2/25/2020)
if ~isempty(impactIdx)
    propIdx(find(propIdx < impactIdx))       = [];
    brakingIdx(find(brakingIdx < impactIdx)) = [];
end

%% Mean Braking and Propulsion Forces
if isempty(brakingIdx)  % no braking data
    SB    = NaN;
    SBsum = NaN;
else
    SB = brakingSign .* ...
        nanmean(apForceTrace(brakingIdx) - forceBaseline);
    SBsum = brakingSign .* ...
        nansum(apForceTrace(brakingIdx) - forceBaseline);
end

if isempty(propIdx)  % no propulsion data
    SP    = NaN;
    SPsum = NaN;
else
    SP    = nanmean(apForceTrace(propIdx) - forceBaseline);
    SPsum = nansum(apForceTrace(propIdx) - forceBaseline);
end

%% Peak Braking and Propulsion Forces
% Save pre-trim index copies; then remove the trailing 10% (end-of-stance
% decay) and leading 10% (impact transient) so neither is misidentified
% as the true braking or propulsion peak; 2/14/2018 (4/11/2017 CJS)
brakingIdxAll = brakingIdx;
propIdxAll    = propIdx;
brakingIdx(find(brakingIdx >= 0.9*length(apForceTrace))) = [];
propIdx(find(propIdx <= 0.1*length(apForceTrace)))       = [];

if isempty(brakingIdx)
    SBmax    = NaN;
    SBmaxAbs = NaN;
    SBmaxQS  = NaN;
else
    SBmax    = nanmin(apForceTrace(brakingIdx));  %-forceBaseline
    SBmax    = brakingSign .* SBmax;
    SBmaxQS  = SBmax - 2 .* brakingSign .* forceBaseline;
    SBmaxAbs = brakingSign .* nanmin(apForceTrace - forceBaseline);
end

if isempty(propIdx)
    SPmax   = NaN;
    SPmaxQS = NaN;
else
    SPmax   = nanmax(apForceTrace(propIdx));  %-forceBaseline
    SPmaxQS = SPmax - 2 .* forceBaseline;
end

% if propIdx(MaxWhereS) <= 0.1*length(apForceTrace)
%     figure
%     plot(apForceTrace, 'k'); hold on
%     line([0.1*length(apForceTrace) 0.1*length(apForceTrace)], [-0.2 0.2])
%     line([0.9*length(apForceTrace) 0.9*length(apForceTrace)], [-0.2 0.2])
%     plot(propIdx(MaxWhereS), apForceTrace(propIdx(MaxWhereS)), 'r*')
%     plot(brakingIdx(MinWhereS), apForceTrace(brakingIdx(MinWhereS)), 'b*')
%     title(titleText)
% end

end

