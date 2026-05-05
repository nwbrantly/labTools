function [flag] = checkBelongings(idx1,idx2)
%checkBelongings Gets two vectors of equal size and checks that no pair of
%indexes are repeated, i.e. that there is no i and j such that
%idx1(i)==idx1(j) && idx2(i)==idx2(j)
%The idea is that the idx vectors represents belongings to groups/clusters
%of a list of elements, and we want to make sure that no two elements have equal
%belongings in the two groups (Pauli's exclusion principle)
%Returns true if the exclusion criteria is fulfilled, false otherwise

%Check inputs are vectors are of same size
if length(idx1)~=numel(idx1) || length(idx2)~=numel(idx2)
    disp('Error in checkBelongings: inputs are not vectors')
    flag=[];
    return
end
if length(idx1)~=length(idx2)
    disp('Error in checkBelongings: vectors are not of the same size')
    flag=[];
    return
end



%Check belongings:
Nelem=length(idx1);
%M=sparse([],[],[],max(idx1),max(idx2),Nelem^2); %Create belonging matrix (sparse to avoid memory problems)
%for i=1:length(idx1)
%   M(idx1(i),idx2(i)) = M(idx1(i),idx2(i))+1;
%end
M=crosstab(idx1,idx2);

if any(M(:)>1)
    flag=false;
else
    flag=true;
end
end

