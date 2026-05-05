function [Y] = demean(X)
%Removes the mean of X, acting along columns

aux=mean(X,1);
Y=X(:,:)-repmat(aux(:,:),[size(X,1),1]);
Y=reshape(Y,size(X));

end

