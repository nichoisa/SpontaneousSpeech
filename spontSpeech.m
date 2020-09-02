% spontaneous speech
% process data from Praat
% AC script  


%% required outcome measures
% 1. length of utterance in seconds
% 2. length of utterance in syllables
% function [outcomeStore]=spontSpeech(sponSpeech)
%%
    outcomeStore=cell(2,length(sponSpeech(:,1)));
    uttlength=[];
    syllength=[];
    for ppt=1
        for uttSec=1:length(sponSpeech{ppt,3})
            if ((strcmp(sponSpeech{ppt,2}(uttSec),'speaker ID'))||(strcmp(sponSpeech{ppt,2}(uttSec),'speaker ID '))||(strcmp(sponSpeech{ppt,2}(uttSec),'Speaker ID')))...
             &&((strcmp(sponSpeech{ppt,3}(uttSec),'infant'))||...
                    (strcmp(sponSpeech{ppt,3}(uttSec),'inf')))
                uttlength=[uttlength;(sponSpeech{ppt,4}(uttSec)-sponSpeech{1,1}(uttSec))];
            end
            if strcmp(sponSpeech{ppt,2}(uttSec),'NumSyll')
                syllength=[syllength;str2num(sponSpeech{ppt,3}{uttSec}),str2num(sponSpeech{ppt,3}{uttSec})/(sponSpeech{ppt,4}(uttSec)-sponSpeech{ppt,1}(uttSec))];
                %num syllables, syllables per second
            end
        end
        outcomeStore{1,ppt}=uttlength;
        outcomeStore{2,ppt}=syllength;

        %% timing measures- likely to be difficult
        % try to group?
        % first port of call - split out all the different tiers
        %3. length of pausing between adult and infant
        % Smith and Lambrecht Smith parameters: 0 to 2.5s
        %first - split out the speaker ID information
        speakerHolder=cell(1,4);
        speakerCHolder=cell(1,4);
        spkrs1=find(strcmp(sponSpeech{ppt,2},'speaker ID'));
        spkrs2=find(strcmp(sponSpeech{ppt,2},'speaker ID '));
        spkrs=[spkrs1;spkrs2];
        infs1=regexp(sponSpeech{ppt,3},regexptranslate('wildcard','inf*'));
        infs=[];
        expC1=find(strcmp(sponSpeech{ppt,2},'exp before inf'));
        for x=1:length(infs1)
            if infs1{x}==1
                infs=[infs;x];
            end
        end
        for spkH=1:length(speakerHolder)
            speakerHolder{ppt,spkH}=sponSpeech{ppt,spkH}(spkrs);
        end
        for spkC=1:length(speakerCHolder)
            speakerCHolder{ppt,spkC}=sponSpeech{ppt,spkC}(expC1);
        end
        %second, find instances where an infant follows an adult
        pauses=cell(1,4); %cell storing 1. location of adult to infant transition using spkrs and 2. whether exp or parent 
        pauses2=cell(1,3);
        spkrStore=[];
        for spkrRows = 1:(length(spkrs)-1)
           if ((strcmp(speakerHolder{ppt,3}(spkrRows),'inf')==0)&&(strcmp(speakerHolder{ppt,3}(spkrRows),'infant')==0))&&...
                   ((strcmp(speakerHolder{ppt,3}(spkrRows+1),'infant'))||(strcmp(speakerHolder{ppt,3}(spkrRows+1),'inf')))
               % if one line is not equal to infant or inf, and the following
               % line is...

               pauselength=speakerHolder{ppt,1}(spkrRows+1)-speakerHolder{ppt,4}(spkrRows);
               if (pauselength>0)&&(pauselength<2.5)
                   pauses{1,1}=[pauses{1,1};pauselength];
                   pauses{1,2}=[pauses{1,2};speakerHolder{ppt,3}(spkrRows)]; 
               %... pull out the length of the gap between non-infant and infant speaker
               % and the identity of the first speaker

                   adultuttStart=speakerHolder{ppt,1}(spkrRows);
                   adultuttEnd=speakerHolder{ppt,4}(spkrRows);
                   validity=find((speakerCHolder{ppt,1}>(adultuttStart-0.5))&(speakerCHolder{ppt,1}<(adultuttEnd)));
                   if length(validity)==1
                        pauses{1,3}=[pauses{1,3};speakerCHolder{ppt,3}(validity)];
                   else
                        pauses{1,3}=[pauses{1,3};'Missing'];             
                   end
                   pauses{1,4}=[pauses{1,4};speakerHolder{ppt,4}(spkrRows)];
                   % find the corresponding "exp before inf" value
               end
           end
        end
        for pcheck=1:length(pauses{1})
            if (pauses{1,3}{pcheck}(1)=='C')||(pauses{1,3}{pcheck}(1)=='c')
                pauses2{1,1}=[pauses2{1,1};pauses{1,1}(pcheck)];
                pauses2{1,2}=[pauses2{1,2};pauses{1,2}(pcheck)];
                pauses2{1,3}=[pauses2{1,3};pauses{1,4}(pcheck)];
            end
        end
        outcomeStore{3,ppt}=pauses2;
        outcomeStore{5,ppt}=pauses;



        % 4. time difference within a multi-word utterance (within speaker pausing)
        % Smith and Lambrecht Smith parameters: 0.25 to 2.5s
        withinpause=[];
        for wp=1:(length(infs)-1)
            uttEnd=sponSpeech{ppt,4}(infs(wp));
            evtcheck=sponSpeech{ppt,2}(infs(wp)+1:infs(wp+1)-1);
            % the above assumes that praat exports in order of onset of event
            % so searches from the event that follows the onset of the infant
            % speech to the event that precedes the onset of the next infant
            % speech
            evtCut=find(strcmp(evtcheck,'speaker ID')|strcmp(evtcheck,'speaker ID '));  
            if isempty(evtCut)
                evts=sponSpeech{ppt,3}(infs(wp)+1:infs(wp+1)-1);
                infgap=1;
            else
                evts=sponSpeech{ppt,3}(infs(wp)+1:(infs(wp)+evtCut(1)-1));
                infgap=0;
            end
            % find if another speaker pops up between the infant events, and if
            % so, limit the evts variable to up to they show up

            %2 kinds of within-speaker pauses
            % first: count the difference between infant utterances with less than 2.5 seconds
            % between them as a silence
            if infgap==1
                if (sponSpeech{ppt,1}(infs(wp+1))-sponSpeech{ppt,4}(infs(wp)))<=2.5
                    winpaus=(sponSpeech{ppt,1}(infs(wp+1))-sponSpeech{ppt,4}(infs(wp)));
                else
                    winpaus=999; %catch; definitely >2.5
                end

                if (winpaus<2.5)&&(winpaus>0.25)
                    withinpause=[withinpause;winpaus,infs(wp),1];
                end
            end
            % second: find silences within an utterance
            timewindow=[sponSpeech{ppt,1}(infs(wp));sponSpeech{ppt,4}(infs(wp))];
            silcounter=find(strcmp(evts,'silent'));
            for sc=1:length(silcounter)
                if (sponSpeech{ppt,1}(infs(wp)+silcounter(sc))>timewindow(1))&&...
                        (sponSpeech{ppt,4}(infs(wp)+silcounter(sc))<timewindow(2))
                    winpaus=sponSpeech{ppt,4}(infs(wp)+silcounter(sc))-sponSpeech{ppt,1}(infs(wp)+silcounter(sc));
                else
                    winpaus=999;
                end
                if (winpaus<2.5)&&(winpaus>0.25)
                    withinpause=[withinpause;winpaus,infs(wp)+silcounter(sc),2];
                end
            end   
        end
    end
    outcomeStore{4,ppt}=withinpause;
    %%


    %mlu
    disp(['Mean Length of Utterance: ', num2str(mean(outcomeStore{1,1}))])
    %msu
    disp(['Mean Syllables per Utterance: ', num2str(mean(outcomeStore{2,1}(:,1)))])
    %syll/s
    disp(['Mean Syllables per Second: ', num2str(mean(outcomeStore{2,1}(:,2)))])
    %total utts
    disp(['Total utterances by infant: ', num2str(length(outcomeStore{1,1}))])   
    %wsp
    disp(['Mean length of within-speaker pauses: ', num2str(mean(outcomeStore{4,1}(:,1)))])   
    %bsp
    disp(['Mean length of between-speaker pauses: ', num2str(mean(outcomeStore{3,1}{1}))])   
    %bs turns
    disp(['Number of adult to infant turns: ', num2str(length(outcomeStore{3,1}{1}))])   
% end
    
