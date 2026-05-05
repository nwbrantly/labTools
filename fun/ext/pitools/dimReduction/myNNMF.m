function [W,C,d] = myNNMF(data,rank,reps,useParallel)
%myNNMF Customized call to NNMF to get more consistent results
%This function calls nnmf with custom params:
%INPUTS:
%data is the matrix to be factorized
%rank is the desired rank of the factorization (dimensionality)
%useParallel defines whether to use parallel computation
%------------------------------------------------------------------------
%CUSTOM PARAMS:
%tolF is a % error that will be accepted as the min increment to say that
%convergence has been achieved
%tolX is 

if nargin<4
    useParallel='always';
end
if nargin<3
    reps=8;
end

if size(data,1)<size(data,2)
    data=data';
end

if rank==0
    disp('There are no possible factorizations of rank 0, returning')
    return
elseif rank==size(data,2)
    %disp('Full rank factorization: returning original matrix.')
    C=eye(size(data,2));
    W=data;
    d=0;
    return
end

nm=numel(data);
alg='als'; %Should verify this is the best choice
tolF=sqrt(.0001*norm(data,'fro')^2/(nm*(rank^2))) + eps; % 0.1% tolerance in objective function (note that this is 1/1000th of the max value for the tolerance function F)divided by desired rank squared.
tolX=0.0001; %This is as a percentage (0.01%). It will determine convergence if the element that changes the most in W or H changes less than 0.01% of the highest element in those matrices.

opts=statset('TolFun',tolF,'TolX',tolX,'UseParallel',useParallel,'Display','off');

[W,C,d]=nnmf(data,rank,'replicates',reps,'algorithm',alg,'options',opts);


end

