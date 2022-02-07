function [TimeElapsed,MouseName,DateName,InitialTimepointFile]= CalcTimePostRTx(TumourMaskAndStepsDir, GenDirectory)%,ListofInitialTimepoints)
%% extracts days since irradiation or reference timepoint (timepoint 0-)
%% Folder organization:
% All individual mouse-tumour folders and folder containing extracted
% metrics for all considered mice.
    % All timepoints per mouse-tumour folder and the respective initial
    % timepoint folder on its own (with text file about the FOV size and
    % the raw OCTA file).
        %All acquired modalities per timepoint per mouse-tumour folder and
        %the segmentation (and intermediates) folder
            % In the OCT folder, there is the acquisition type (e.g., high
            % resolution_setting4_6x6mm) and within, the folders of raw data
            % in both real and imaginary domains, and the folders of OCTA
            % processing, structural OCT extraction and vascular segmentation.
% if ~(sum(contains(DirectoryInitialTimepoints,NameDayFormat),'all') && contains(NameDayFormat,DirectoriesBareSkinMiceKeyword)) && ~(contains(NameDayFormat,DirectoryInitialTimepoints) && contains(BatchOfFolders{countBatchFolder,1},'pre'))%those with tumours have pre and post timepoints 


timeFid=fopen(fullfile(TumourMaskAndStepsDir,'Timepoint.txt'),'r');
ImgTimepoint_temp=fscanf(timeFid,'%s', [1, inf]);
ImgTimepoint=datetime(sprintf('%s %s',ImgTimepoint_temp(1:11),ImgTimepoint_temp(12:end)))%extracting precise date information of DAQ for determination of relative time elapsed automatically  old way:[~,Timepoint,]=fileparts(fileparts(MouseFolders{ind}));
timeFid=fopen(fullfile(TumourMaskAndStepsDir,'Timepoint.txt'),'r');

ImgTimepoint_temp2=strsplit(sprintf('%s',ImgTimepoint_temp(1:11)),'-');
DateName=[ImgTimepoint_temp2{2},' ',ImgTimepoint_temp2{1},' ',ImgTimepoint_temp2{3}];%rearranged to be Apr 23 2021 for example

            
            

%% Finding the corresponding timepoint 0- raw file to be able to extract the relative time
    %% Finding mouse name
    MouseNameTemp=strsplit(TumourMaskAndStepsDir,'\');
    %if contains(TumourMaskAndStepsDir,'pre')||contains(TumourMaskAndStepsDir,'post')
    MouseName=MouseNameTemp{3};
    dirgivenMouseTimepoints=dir(fullfile(GenDirectory,MouseName));
    %% now determine specifically which mouse timepoint 0- should be loaded%for RefMiceCount=1:length(DirectoryInitialTimepoints) if contains(DirectoryInitialTimepoints{RefMiceCount},MouseName) 
    countMT=0;
    for iii=1:length(dirgivenMouseTimepoints) %if you kept format of multiple tumours in one mouse all stored in same directory
        if contains(dirgivenMouseTimepoints(iii).name,'Timepoint 0-')%.txt
            countMT=countMT+1;
        end
    end
    InitialTimepointFile=[];
    if countMT>1
        [filenameTP_Time0,pathTP_Time0]=uigetfile(fullfile(GenDirectory,MouseName),'Please select Timepoint 0- Info text file ');
        InitialTimepointFile=fullfile(pathTP_Time0,filenameTP_Time0);
    elseif countMT==1 %if there is only one
            if exist(fullfile(GenDirectory,MouseName,'Timepoint 0-','Timepoint0-.txt'))
                InitialTimepointFile=fullfile(GenDirectory,MouseName,'Timepoint 0-','Timepoint0-.txt');
            end
        if isempty(InitialTimepointFile)
            if exist(fullfile(GenDirectory,MouseName,'Timepoint 0-','Timepoint 0-Info_path.mat'))
                load(fullfile(GenDirectory,MouseName,'Timepoint 0-','Timepoint 0-Info_path.mat'))
            else
                [filenameTP_Time0,pathTP_Time0]=uigetfile(fullfile(GenDirectory,MouseName),'Please select Timepoint 0- Info file');
                InitialTimepointFile=fullfile(pathTP_Time0,filenameTP_Time0);
                save(fullfile(GenDirectory,MouseName,'Timepoint 0-','Timepoint 0-Info_path.mat'),'InitialTimepointFile','-v7.3')
            end
        end
    else
        error('No reference timepoint found')
    end
RefTimeFid=fopen(InitialTimepointFile,'r');
RefTimepoint_temp=fscanf(RefTimeFid,'%s', [1, inf]);
RefTimepoint=datetime(sprintf('%s %s',RefTimepoint_temp(1:11),RefTimepoint_temp(12:end)))    
    
%% calculate difference in days
TimeElapsed.RelImgTimepointDaysRounded=caldays(caldiff([RefTimepoint,ImgTimepoint],'days'));
TimeElapsed.RelImgTimepoint_hours_min_sec=diff([RefTimepoint,ImgTimepoint]);%caldiff([RefTimepoint,ImgTimepoint],'Time');
%TimeElapsed.RelImgTimepoint_DaysFraction=TimeElapsed.RelImgTimepoint_hours_min_sec
%RelImgTimepoint_Days_frac=datetime(RelImgTimepoint_hours_min_sec);
RelImgTimepointDaysPreciseTemp=strsplit(sprintf('%s',TimeElapsed.RelImgTimepoint_hours_min_sec),':');
TimeElapsed.RelImgTimepointDaysPrecise=(str2num(RelImgTimepointDaysPreciseTemp{1})+str2num(RelImgTimepointDaysPreciseTemp{2})/60)/24;
save(fullfile(TumourMaskAndStepsDir,'TimeElapsedSinceT0-.mat'),'TimeElapsed','-v7.3');
end