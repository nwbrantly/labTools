function [newP] = effconvnfull(pValues1,pValues2)
%effconvn Implements the convn function by means of ffts, to -supposedly- be more efficient. It is certainly not the case for small arrays. 

newSize=size(pValues1)+size(pValues2)-1;
newP=ifftn(fftn(pValues1,newSize).*fftn(pValues2,newSize));


end

