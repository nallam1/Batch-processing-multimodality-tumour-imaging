function [CoarseROI_Question,fineContouring_Question,ImageX,binaryImageDrawn,answer3]=ChooseImageStyleOptFluStyleSegmentv2(CurrentTimepoint,Timepoint0Analyzed,SegmentingFile,PrefixFLU_BRI,image1Segmentation,image2Segmentation,image3Segmentation,image4Segmentation,filenameT,OptFluSegmentationFolder,SegmentationFolderTimepoint0NotEmpty,MouseNameTimepoint0)
%% Lateral tumour mask creation options
ImageX=[];%image to be contoured contouring
binaryImageDrawn=[];

figure('Units','characters','Position',[300 30 60 25]);
imshow(image1Segmentation);
title(filenameT)
%% 1) Assessing options available for lateral tumour mask creation
%% Option 1
    Question1='1)Draw manually.';
%% Option 2
    if contains(SegmentingFile,'flu') && ~contains(SegmentingFile,'flu_0') %isequal(PrefixFLU_BRI,'FLU_')
        Question2='2)No thanks (directly automatic).';
    else
        Question2='N/A';
    end
%% Option 3
if Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed
    %
    Opt3= exist(fullfile(fileparts(SegmentationFolderTimepoint0NotEmpty),'2D OCT-bri','flu Co-registration + Tumour Mask',[MouseNameTimepoint0, ' ROI mask.mat']));
else
    Opt3=0;
end
    if Opt3
        Question3='3)Load Timepoint0- previously drawn.';
    else
        Question3='N/A';
    end
%% Option 4
    Opt4= exist(fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI, char(filenameT),' ROI mask.mat']));%last attempt of same timepoint
    if Opt4
        Question4='4)Load Last attempt drawn for this timepoint.';
    else
        Question4='N/A';
    end
%% Option 5
    % Preparing closest timepoint search relevant to option 5
        TempFileparts=strsplit(OptFluSegmentationFolder,'\')
            TimeDiff=[];
            Repository2DMasksForGivenMouse=dir(fullfile(TempFileparts{1:3},'2DMasksRepository','**'))
            Filecount=0;
                for ind=1:length(Repository2DMasksForGivenMouse)
                    ConsideredFile=Repository2DMasksForGivenMouse(ind).name;
                    if contains(ConsideredFile,PrefixFLU_BRI) && contains(ConsideredFile,' ROI mask.mat')
                        Filecount=Filecount+1;
                        ConsideredFileTimepointTemp1=strsplit(ConsideredFile,'_');
                        ConsideredFileTimepointTemp2=strsplit(ConsideredFileTimepointTemp1{2},' ');
                        ConsideredFileTimepoint=datetime([ConsideredFileTimepointTemp2{2},' ',strrep(ConsideredFileTimepointTemp2{3},'-',':')]);
                        TimeDiffTemp=diff([CurrentTimepoint,ConsideredFileTimepoint]);
                        TimeDiffTemp2=strsplit(sprintf('%s',TimeDiffTemp),':');
                        TimeDiff(Filecount)=(str2num(TimeDiffTemp2{1})+str2num(TimeDiffTemp2{2})/60)/24;
                        Mask2DName{Filecount}=ConsideredFile;
                    end
                end
                if isempty(TimeDiff)
                    ClosestTimepointROIDrawn=[]
                    Opt5=0;
                else
                    ClosestTimepointROIDrawn=Mask2DName{find(TimeDiff==min(TimeDiff))}
                    Opt5=1;
                end
    
    if Opt5
        Question5='5)Load closest timepoint drawn.'
    else
        Question5='N/A';
    end
%% 2) Presenting of options    
    CoarseROI_Questionprompt = sprintf('How to proceed with 2D contouring transversely? \n %s \n %s\n %s\n %s\n %s',Question1,Question2,Question3,Question4,Question5);
%% 3) Preparing answer acquisition    
if Timepoint0Analyzed==1 || (Timepoint0Analyzed==0 && ~(isequal(PrefixFLU_BRI,'BRI_') && ~Opt4))
    fineContouring_Questionprompt=['Perform automatic fine thresholding (Otsu method) 1/0'];
    prompt={CoarseROI_Questionprompt;fineContouring_Questionprompt};
    answer = inputdlg(prompt,'Tumour Segmentation options');%[1 2; 1 2]
end
if isequal(PrefixFLU_BRI,'BRI_') && ~Opt3 && ~Opt4 && ~Opt5 %Timepoint0Analyzed==0 && isequal(PrefixFLU_BRI,'BRI_')%to save on time, reducing options (where there is no choice
    answer{1}='1';
    answer{2}='0';
end
% Find nearest timepoint as well?
%% Image used
CoarseROI_Question = str2double(answer{1});
fineContouring_Question = str2double(answer{2});

if CoarseROI_Question ==1 || CoarseROI_Question ==3 || CoarseROI_Question ==4 || CoarseROI_Question ==5 %"Manual"
    figure,
    t=tiledlayout(1,4)
    nexttile
    imshow(image1Segmentation)
        title('1')
    nexttile
    imshow(image2Segmentation)
        title('2')
    nexttile
    imshow(image3Segmentation)
        title('3')
    nexttile
    imshow(image4Segmentation)
        colormap(gca, 'jet'); 
            limits = [0,255];
            set(gca,'clim',limits([1,end]))    
    title('4')
    
    title(t,sprintf('Image options for %s',filenameT))
    
    answer3=[];
    while isempty(answer3) || (answer3~=1 && answer3~=2 && answer3~=3 && answer3~=4)
        prompt3={'What image should be used for manual segmentation? (1,2,3, or 4)'}
        answer3 = str2double(inputdlg(prompt3,'Tumour segmentation image format'));%,[1 2]);%assignin difficult to make work%f=Manual_Contouring_method_1v2(image1Segmentation,image2Segmentation,image3Segmentation,filenameT)
    end
    if answer3==1
        ImageX=image1Segmentation;
    elseif answer3==2
        ImageX=image2Segmentation;
    elseif answer3==3
        ImageX=image3Segmentation;
    elseif answer3==4
        ImageX=image4Segmentation;
        %ColMap=
    end
elseif CoarseROI_Question==2%"No, thanks"
    ImageX=image1Segmentation;
end
if CoarseROI_Question ==3 && Opt3%exist(fullfile(OptFluSegmentationFolder,[char(filenameT),' ROI mask.mat']))
        %             [name,path]=uigetfile('*.mat', 'Select the ROI mask previously created',OptFluSegmentationFolder)
        %             load(fullfile(path,name))%(OptFluSegmentationFolder,[char(filenameT),' ROI mask']));%loadROI;
    Temp=load(fullfile(fileparts(SegmentationFolderTimepoint0NotEmpty),'2D OCT-bri','flu Co-registration + Tumour Mask',[MouseNameTimepoint0,' ROI mask.mat']))
        TempInfo=whos('-file',fullfile(fileparts(SegmentationFolderTimepoint0NotEmpty),'2D OCT-bri','flu Co-registration + Tumour Mask',[MouseNameTimepoint0,' ROI mask.mat']));
        TempName=TempInfo.name;
    binaryImageDrawn=Temp.(TempName);
elseif CoarseROI_Question ==4 && Opt4%exist(fullfile(OptFluSegmentationFolder,[char(filenameT),' ROI mask.mat']))
    %             [name,path]=uigetfile('*.mat', 'Select the ROI mask previously created',OptFluSegmentationFolder)
    %             load(fullfile(path,name))%(OptFluSegmentationFolder,[char(filenameT),' ROI mask']));%loadROI;
    Temp=load(fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI, char(filenameT),' ROI mask.mat']))
        TempInfo=whos('-file',fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI, char(filenameT),' ROI mask.mat']));
        TempName=TempInfo.name;
    binaryImageDrawn=Temp.(TempName);
elseif CoarseROI_Question ==5 && Opt5%exist(fullfile(OptFluSegmentationFolder,[char(filenameT),' ROI mask.mat']))
    %             [name,path]=uigetfile('*.mat', 'Select the ROI mask previously created',OptFluSegmentationFolder)
    %             load(fullfile(path,name))%(OptFluSegmentationFolder,[char(filenameT),' ROI mask']));%loadROI;
    Temp=load(fullfile(TempFileparts{1:3},'2DMasksRepository',ClosestTimepointROIDrawn))
        TempInfo=whos('-file',fullfile(TempFileparts{1:3},'2DMasksRepository',ClosestTimepointROIDrawn));
        TempName=TempInfo.name;
    binaryImageDrawn=Temp.(TempName);
%if Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed
end
    
%end
%     assignin('caller','name',n);
%     assignin('caller','age2050',a);
close all
end