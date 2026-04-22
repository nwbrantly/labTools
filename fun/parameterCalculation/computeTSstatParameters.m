function out = computeTSstatParameters(tsData, strideEvents)
% computeTSstatParameters  Compute summary statistics per stride.
%
%   Syntax:
%     out = computeTSstatParameters(tsData, strideEvents)
%
%   Computes stride-by-stride summary statistics for each channel of a
% labTimeSeries and returns a parameterSeries object that can be
% concatenated with other parameter series objects (e.g., from
% computeTemporalParameters).
%
%   Inputs:
%     tsData       - labTimeSeries object containing channel data
%     strideEvents - N-by-K matrix of stride event times (seconds),
%                    where N is the number of strides; the first
%                    column is used to slice tsData into strides
%
%   Outputs:
%     out - parameterSeries object containing, for each channel,
%           the following statistics per stride: max, min, avg
%           (mean), var (variance), med (median), snr
%           (signal-to-noise ratio in dB), and bad (data-quality
%           flag)
%
%   Toolbox Dependencies:
%     None
%
%   See also: computeSpatialParameters, computeTemporalParameters,
%     computeForceParameters, parameterSeries, calcParameters


%% Statistic Labels
% 'skw', 'kur', and 'iqr' are excluded -- never used and slow to compute
statSuffixes = {'max', 'min', 'avg', 'var', 'med', 'snr', 'bad'};

%% Slice Time Series and Allocate Arrays
slicedTS = tsData.sliceTS(strideEvents(:, 1), 0);  % first event only

numStrides    = length(slicedTS);
numStats      = length(statSuffixes);
channelLabels = tsData.labels;
numChannels   = length(channelLabels);
paramData     = nan(numStrides, numChannels, numStats);
paramLabels   = cell(numChannels, numStats);
description   = cell(numChannels, numStats);

%% Build Parameter Labels and Descriptions
for iChan = 1:numChannels
    for iStat = 1:numStats
        paramLabels{iChan, iStat} = ...
            [channelLabels{iChan} statSuffixes{iStat}];
        if strcmp(statSuffixes{iStat}, 'bad')
            description{iChan, iStat} = [ ...
                'Signals if quality was anything other than good ' ...
                '(no missing, no spikes, no out-of-range) for muscle ' ...
                channelLabels{iChan}];
        else
            description{iChan, iStat} = [ ...
                statSuffixes{iStat} ' in timeseries ' ...
                channelLabels{iChan}];
        end
    end
end

%% Compute Per-Stride Statistics
for iStride = 1:numStrides
    strideData = slicedTS{iStride}.Data;
    strideQual = slicedTS{iStride}.Quality;
    for iChan = 1:numChannels
        channelData = strideData(:, iChan);
        if ~isempty(strideQual)
            qualColumn = strideQual(:, iChan);
        else
            qualColumn = 0;
        end
        for iStat = 1:numStats
            switch statSuffixes{iStat}
                case 'max'
                    %description{iChan,iStat}=['Peak proc EMG in muscle ' channelLabels{iChan}];
                    paramData(iStride, iChan, iStat) = max(channelData);
                case 'min'
                    %description{iChan,iStat}=['Min proc EMG in muscle ' channelLabels{iChan}];
                    paramData(iStride, iChan, iStat) = min(channelData);
                case 'iqr'
                    %description{iChan,iStat}=['Inter-quartile range of proc EMG in muscle ' channelLabels{iChan}];
                    paramData(iStride, iChan, iStat) = iqr(channelData);
                case 'avg'
                    %description{iChan,iStat}=['Avg. (mean) of proc EMG in muscle ' channelLabels{iChan}];
                    paramData(iStride, iChan, iStat) = mean(channelData);
                case 'var'
                    %description{iChan,iStat}=['Variance of proc EMG in muscle ' channelLabels{iChan}];
                    paramData(iStride, iChan, iStat) = ...
                        var(channelData, 0);  % unbiased
                case 'skw'
                    %description{iChan,iStat}=['Skewness of proc EMG in muscle ' channelLabels{iChan}];
                    paramData(iStride, iChan, iStat) = ...
                        skewness(channelData, 0);  % unbiased
                case 'kur'
                    %description{iChan,iStat}=['Kurtosis of proc EMG in muscle ' channelLabels{iChan}];
                    paramData(iStride, iChan, iStat) = ...
                        kurtosis(channelData, 0);  % unbiased
                case 'med'
                    %description{iChan,iStat}=['Median of proc EMG in muscle ' channelLabels{iChan}];
                    paramData(iStride, iChan, iStat) = median(channelData);
                case 'snr'
                    %description{iChan,iStat}=['Energy of proc EMG divided by base noise energy (in dB) for muscle ' channelLabels{iChan}];
                    % TODO: min() may be near zero after low-pass
                    %   filtering; verify this is a valid SNR estimate
                    paramData(iStride, iChan, iStat) = 20 * log10( ...
                        mean(channelData.^2) / min(channelData)^2);
                case 'bad'
                    % quality codes are powers of 2 (up to 8 per int8);
                    % summing unique values tracks all issues at once
                    paramData(iStride, iChan, iStat) = ...
                        sum(unique(qualColumn));
            end
        end
    end
end

%% Output Computed Parameters
out = parameterSeries(paramData(:, :), paramLabels(:), [], description(:));

end

