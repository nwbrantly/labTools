function [h,pThreshold,i1,pAdjusted] = BenjaminiHochberg(p,fdr,twoStageFlag)
%Performs the Benjamini-Hochberg procedure to determine significance in
%multiple comparisons while controlling the False Discovery Rate (number of
%false positives as a % of the number of total comparisons). This is a
%less taxing alternative to performing a Bonferroni correction, for example.
%FDR control is done in expectation over many realizations.
%See also: mafdr

%INPUT:
%p: vector of p-values from the multiple comparisons, has to be 1-D
%fdr: value in [0,1] that determines the (expected) False Discovery Rate that is
%tolerated
%twoStageFlag: if true, it performs the two-stage procedure suggested in
%Benjamini, Krieger and Yekuteli 2006, which maintains fdr control
%guarantees (under independent tests) but has more power. Default = false.
%OUTPUT:
%h= binary vector that is 1 if the corresponding p-value was deemed
%significant, and 0 if not.
%pThreshold = value that ends up being the cut-off for p. Should satisfy:
%h = p<=pThreshold = pAdjusted<fdr
%i1 = no. of significant results, equals sum(h)
%pAdjusted = adjusted p-values

%Validated on Oct 19th 2017 against fdr_bh() function from Matlab Exchange,
%and on Nov 29th 2018 agains BioInformatic's Toolbox mafdr()
%References:
%Benjamini & Hochberg 1995
%Yekuteli & Benjamini 1999 (for definition of adjusted p-values)
%Benjamini, Krieger and Yekuteli 2006 (for two-stage procedure)

if nargin<3 || isempty(twoStageFlag)
    twoStageFlag=false;
end
if twoStageFlag
    fdr=fdr/(1+fdr); %BKY procedure requires using this value
    %in the first and second pass for FDR guarantee, although authors later use fdr
    %itself for the first pass and claim that it is ok in practice.
end

M=numel(p); %No. of total comparisons

[p1,idx]=sort(p(:),'ascend');
h1=zeros(size(p1));
ii=find(p1 < fdr*[1:M]'/M,1,'last');
if isempty(ii)
    i1=0;
else
    i1=ii;
end

h1(1:i1)=1; %Significant results
h=nan(size(p));
h(idx)=h1; %Re-sorting

pThreshold=p1(ii);

if nargout>3 %Computing adjusted p-values
    %Adjusted p-values are the thing that is compared to fdr
    pAdjusted=nan(size(p));
    newP=p1*M./[1:M]';
    for i=(length(newP)-1):-1:1
        if newP(i)>newP(i+1)
            newP(i)=newP(i+1);
        end
    end
    pAdjusted(idx)=newP;
end

if twoStageFlag
    [h,pThreshold,i1] = BenjaminiHochberg(p,fdr*M/(M-i1),false);
end

end
