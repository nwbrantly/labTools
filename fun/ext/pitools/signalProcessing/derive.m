function [y] = derive(x,fsample)
derivativeFilter=fsample * 1/8 * [1,2,0,-2,-1]; %Order 5
derivativeFilter=fsample * 1/32 * [1,4,5,0,-5,-4,-1]; %Order 7
derivativeFilter=fsample * 1/128 * [1,6,14,14,0,-14,-14,-6,-1]; %Order 9
order=9;
%derivativeFilter=fsample * 1/512 * [1,8,.,.,.,0,-14,-14,-6,-1]; %Order 9
%Get vels:
y2=conv([x(end:-1:1);x;x(end:-1:1)],derivativeFilter,'same');
y=y2(length(x)+1:2*length(x));

end

