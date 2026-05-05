function data = lowpassfiltering(datafile, cutoff, complexity, samp);

%lowpassfilter function
%SMM 02/2004

%pass the 'lowpassfilter' function:  1) a data array for filtering,
                                    %2) the freqency you want removed, and
                                    %3) the sampling frequency
%'lowpassfilter' function returns the data array that has been filtered with a
%lowpass Butterworth filter, with the specified complexity and cutoff frequency



[b,a]=butter(complexity, (cutoff/(.5*samp)));   %get lowpass filter vectors
data = filtfilt(b,a,datafile);  %filter using filtfilt funtion to avoid phase shifts
