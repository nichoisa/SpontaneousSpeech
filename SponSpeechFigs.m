% script for getting data out of Spontaneous Speech .txt files

SponSpPath="/home/Aine/Documents/homeTasks/sponspeech/"; % change this to your usual directory
fileName=input(['please enter the name of the file you want to process'...
                ' (including .txt extension): '],'s');

sponSpFile=fopen(strcat(SponSpPath,fileName));
sponSpStore=textscan(sponSpFile,'%f %s %s %f','Delimiter', '\t','headerlines',1);
%%
outcomes=spontSpeech(sponSpStore);