function [timeDiff,corrCoef,lagInSamples] = findTimeLag(referenceSignal,secondarySignal)

%First: truncate:
M=max([length(referenceSignal) length(secondarySignal)]);
referenceSignal(end+1:M)=0;
secondarySignal(end+1:M)=0;

%Second: correlate
F1=fft(referenceSignal);
F2=fft(fftshift(secondarySignal));
F=F1.*conj(F2);
P=ifft(F);

%Third: sub-sample:
aux=0:.01:length(P)-1;
P2=interp1(0:length(P)-1,P,aux,'spline')/sqrt(sum(referenceSignal.^2)*sum(secondarySignal.^2)); %For sub-sample resolution

%Fourth: find max correlation
[~,t]=max(abs(P2));
lagInSamples=aux(t)-floor(M/2); %The -floor(M/2) term accounts for the fftshift
corrCoef=P2(t);

if abs(corrCoef)<.3
    warning(['Could not synch signals: r^2= ' num2str(abs(corrCoef))])
end
timeDiff = NaN;

end

