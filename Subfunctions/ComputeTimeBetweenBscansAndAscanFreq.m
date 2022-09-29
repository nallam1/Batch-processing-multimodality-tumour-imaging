TimePerAscan=0.0496%ms
NumAscansPerBscan=400;
GalvoDutyCycle=0.80;%Percentage of period actively acquiring data
%%
TimePerBscan=[]%unknown
AscanFrequency=[]%unknown
%%
AscanFrequency=1/(TimePerAscan*10^-3)%convert to Hz
TimePerBscan=TimePerAscan*NumAscansPerBscan/GalvoDutyCycle