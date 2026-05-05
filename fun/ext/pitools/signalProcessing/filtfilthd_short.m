function [filteredData] = filtfilthd_short(filterObj,data,method,M1)
%This is a copy of filtfilthd, but limiting the extent of the 'reflect'
%method for efficiency
%Filters data along dim=1 with filterObj first forwards, and then
%backwards.
%It is an implementation of filtfilt that works with filter objects from
%the DSP toolbox.
%By default uses 'reflect' method for dealing with borders.

if size(data,1)==1 
    warning('filtfiltHD expects input data to be entered as columns, transposing')
    data=data';
end
if size(data,1)<size(data,2)
    warning('Input data seems to be organized as rows, and filtfilthd filters along columns.')
end

M=size(data,1);

if nargin<3 || isempty(method)
    method='reflect'; %Default
end
if nargin<4 || isempty(M1)
    M1=min(1000,size(data,1));
    warning(['Unspecified size for reflective boundaries, setting to ' num2str(M1) ' samples'])
else
    M1=min(round(M1),size(data,1));
end
    switch method
        case 'reflect'
            post=[data([end:-1:end-M1+1],:)];
            pre=[data(M1:-1:1,:)];
        otherwise         
            pre=[];
            post=[];
    end
filteredData=filter(filterObj,[pre;data;post]);
filteredData=filter(filterObj,filteredData(end:-1:1,:));
filteredData=filteredData(end:-1:1,:);
%filteredData=filtfilt(filterObj,[pre;data;post]); %This should work, and
%is possibly more efficient, but doesn't.
filteredData=filteredData([M1+1:M1+M],:);


end

