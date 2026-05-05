function [newP] = effconvn(pValues1,pValues2,shape)
%effconvn Implements the convn function by means of ffts, to -supposedly- be more efficient. It is certainly not the case for small arrays. 

[newP] = effconvnfull(pValues1,pValues2);

if nargin>2
    warning('Shape argument still not implemented.')
    if strcmp(shape,'valid')
        newP=[];
    elseif strcmp(shape,'same')
        newP=[];
    end %Assumes method='full'
end


end

