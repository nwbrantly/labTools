function flag = isempty(this)
% isempty  Checks if the date equals the default value.
%
%   Determines whether the date equals the default sentinel
% date (Jan 1, 1900), which is used to represent an
% uninitialized labDate.
%
%   Inputs:
%     this - labDate object
%
%   Outputs:
%     flag - true if date equals default value, else false
%
%   See also: default, timeSince

flag = timeSince(this, labDate.default()) == 0;
end

