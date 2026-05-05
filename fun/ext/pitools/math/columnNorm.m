function [w] = columnNorm(X,p,dim)
%Calculates the p-norm of element in a matrix (along dimension dim)
%and returns it as a row vector.

if nargin<3
    dim=1;
end
if nargin<2
    p=2;
end
w = sum(abs(X).^p,dim).^(1/p);

end

