function timeInMonths = timeSince(this, other)
% timeSince  Calculates elapsed time from another date.
%
%   Approximates fractional months by assuming 30 days per month.
%
%   Inputs:
%     this  - labDate object (later date)
%     other - labDate object (earlier date)
%
%   Outputs:
%     timeInMonths - Elapsed time in months (approximate;
%                    assumes 30 days per month)
%
%   Example:
%     d1     = labDate(1, 'jan', 2015);
%     d2     = labDate(1, 'jun', 2015);
%     months = d2.timeSince(d1);  % returns 5
%
%   See also: isempty

timeInMonths = 12 * (this.year  - other.year)  + ...
    (this.month - other.month) + ...
    (this.day   - other.day) / 30;
end

