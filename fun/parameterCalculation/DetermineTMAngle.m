if ~isempty(findstr(trial, 'deg'))%( ~iscell(cell2mat(regexp(trial, 'deg'))))|| ~iscell(cell2mat(regexp(trial, '8.5'))) %~isempty(cell2mat(regexp(trial, 'deg'))) || ~isempty(cell2mat(regexp(trial, '8.5')))
    if ~isempty(findstr(trial,'decline')) || ~isempty(findstr(trial,'downhill'))
        sign=-1;
    else %Assuming incline by default
        sign=1;
    end
    i=regexp(trial,'deg');
    if iscell(i)
        i=i{1};
    end
    string=trial(max([i,7])-6:i);
    digits=regexp(string,'\d'); %Assuming the number of degrees does not precede the string 'deg' by more than 5 chars
    if ~isempty(digits)
        number=str2double(string(digits)); %This discards any decimal points that may appear
        firstDigit=digits(1);
        lastDigit=digits(end);
        if firstDigit~=lastDigit
            dots=regexp(string,'\.');

            %Should check that digits are consecutive indexes, except for a single
            %dot in the middle:
            aux=sort([digits dots], 'ascend');
            if any((aux-firstDigit-[0:length(aux)-1])~=0)
                failRead=true;
            end

            if ~isempty(dots)
                dots=dots(1);
                decimalPosition=lastDigit-dots(1);
                number=number/10^decimalPosition;
            end
        end

        if firstDigit>1 && string(firstDigit-1)=='-' %Using a minus sign to flip value
            sign=-1;
        end
        ang=number*sign;
    else %Didn't find digits
        failRead=true;
    end
    if failRead
        ang=input(['What angle (in degrees) was the study run at (' , trial, '): ',trialData.type ,'?   ']);
    end

else
    ang=0;
end

end

function ang = DetermineTMAngle(trialData)
% DetermineTMAngle  Extract treadmill incline angle from trial description.
%
%   Syntax:
%     ang = DetermineTMAngle(trialData)
%
%   Parses the trial description string to extract a numeric treadmill
% incline angle in degrees. If the description contains 'deg', the
% function locates the numeric value immediately preceding it and
% determines the sign from keywords ('decline'/'downhill' = negative,
% all others = positive incline). If no valid angle is parsed, prompts
% the user to enter the value manually. Returns 0 if the description
% contains no 'deg' substring.
%
%   Inputs:
%     trialData - Object with fields .description (string or cell array
%                 containing the trial name/condition) and .type
%                 (string used in the manual input prompt on failure)
%
%   Outputs:
%     ang - Treadmill incline angle in degrees; positive = uphill,
%           negative = downhill, 0 = level
%
%   Toolbox Dependencies:
%     None
%
%   See also: computeForceParameters, calcParameters
%
%   Author: CJS, 08/2016

arguments
    trialData (1,1)
end

%% Parse Trial Description
% NOTE: assuredly a more robust approach exists using regexp pattern
% matching, but this is functional for current naming conventions
trial = trialData.description;
if iscell(trial)
    trial = trial{1};
end
if iscell(trial)
    trial = char(trial);
end

%% Determine Treadmill Angle
% (old condition):
% (~iscell(regexp(trial, 'deg')) && ~iscell(cell2mat(regexp(trial, 'deg'))))|| ~iscell(regexp(trial, '8.5')) %~isempty(cell2mat(regexp(trial, 'deg'))) || ~isempty(cell2mat(regexp(trial, '8.5')))
failRead = false;
    %     if ~isempty(strfind(trial, '8.5 deg incline')) || ~isempty(strfind(trial, '8.5 deg uphill'))
    %         ang=8.5;
    %     elseif ~isempty(strfind(trial, '8.5 deg decline')) || ~isempty(strfind(trial, '8.5 decline')) || ~isempty(strfind(trial, '8.5 deg downhill'))
    %         ang=-8.5;
    %     elseif ~isempty(cell2mat(regexp(trial, '5 deg incline')))|| ~isempty(cell2mat(regexp(trial, '5 deg uphill'))) || ~isempty(cell2mat(regexp(trial, '5 deg')))
    %         ang=5;
    %     elseif ~isempty(cell2mat(regexp(trial, '5 deg decline')))|| ~isempty(cell2mat(regexp(trial, '5 deg downhill')))
    %         ang=-5;
    %     else
    %         ang=input(['What angle (in degrees) was the study run at ', trial, ': ',trialData.type ,'?   ']);
    %     end
