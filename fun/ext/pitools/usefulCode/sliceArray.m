function [slices] = sliceArray(data,inds,dim)
%sliceArray returns a subset of 'slices' of an array (indexed by inds)
%along dimension dim. %Preferable to solutions using permute() which create copies of the array,
%which is not desirable for large arrays.
%It is equivalent to slices=data(:,:,..,:,inds,:,...,:), where 'inds' is
%located at the 'dim' dimension of the array.

nd=ndims(data);
if dim>nd
    error('')
end
N=size(data,dim);
if any(inds>N | inds<1)
    error()
end
prefix=repmat(':,',1,dim-1);
suffix=repmat(',:',1,nd-dim);
eval(['slices=data(' prefix 'inds' suffix ');'])
end

