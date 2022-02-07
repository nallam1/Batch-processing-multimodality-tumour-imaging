clear
DirectoryProcCodeLetter='C:\Users\admin\Desktop'; %'D:'
DirectoryDataLetter='F';%'I:'; %'H:'; %'J:'
DirectoryVesselsData ='F:\SBRT project March-June 2021'%'I:\Test orthotopic mice' %'F:\DLF data' %'H:\Processing DLF Nov 25 2021\Healthy (Bare Skin)'%%[DirectoryVesselLetter '\DLF data']%'G:\DLF data'%'C:\Users\nader\Desktop\DLF data';%'G:\SBRT project March-June 2021'%'G:\PDXovo';
cd(DirectoryVesselsData);
addpath(genpath(DirectoryVesselsData));
%addpath(genpath('Y:\'));
addpath(genpath([DirectoryProcCodeLetter '\All-in-1_Tissue and vessels segmentation, co-registration and quantification']))%'\Users\Luuk\Desktop\low memory mask creation, coregistration and metric extraction intermediates OCT 31 2021'])) %addpath(genpath([DirectoryProcCodeLetter '\Processing code']))%'C:\Users\Nader\Desktop\Processing code\OCT\Extract VOI'));%'C:\Users\nader\Desktop\'));% Important to save at the end:
addpath(genpath(fullfile(DirectoryProcCodeLetter ,'Processing code')))
%addpath(genpath([DirectoryStructLetter '\DLF data']));
tic
%% User initial input

%the idea is that at the start of every call of the script (Create3DTumourMaskOnly_BatchProcessing) 
%to load additional data then process it and then load more and so on
%(either loaded automatically (2) from all folders in directories of workspace, or semiAutomatically (1) all files from specified directories, or manually (3) all files individually selected. When you finish creating the mask (it checks), it proceeds to next file loading by calling this function again.

%% input variables
% If performing ManualSelFew_0_OR_SemiAutomatic_2_OR_FullAutomatic_3 == 1 or 2, must define all files that it should look for 
    % Contains vascular map
    %% *****************3D tumour mask creation or only metric extraction and 2D tumour mask creation*****************
    Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2=2;%For speed complete 0 on all files to be processed then once all complete, change to 1 and allow the program to select the files to be used to generate the full 3D masks and longitudinally coregistered data sets. Select 2 if you prefer to do it all at once, seeing the results as you go
    VisualizeResults=1;%whether to check created 3D mask before proceeding to next creation for approval
    %% *****************Tumour Mask creation settings*****************
        % General
            MatlabVer=2021;
            LateralorFullCoregPreTisContour=0;% Moves co-registration of volume step prior to tissue contour (but after glass contour)--only if have sufficient memory and helps mostly if OnlyTissueLabelTimepoint0==0 (manally drawn for each timepoint
            glass_1_Tissue_2_both_3_contour=1;%whether contouring of glass (broken or not) will be performed or the actual tissue surface to help in consistency and accuracy inter-timepoint of manually drawn contours if applying --> Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1 or 2 is possible on the computer
                    MaskCreationFolder={'Manual_With_WO_Glass2';'Manual_OnlyTissue'};
                    num_contoured_slices=[2,15];
            ActiveMemoryOffload=1;%If performing both contouring (glass_1_Tissue_2_both_3_contour==3), whether to clear intermediate loaded variables          
            BinVesselsAlreadyPrepared=0;% (1) The binarized vessels map is already prepared, (0) performing contouring prior to creation of binarized vasculature map (thus co-registration transforms cannot be applied during mask creation)
            
            OnlyTissueLabelTimepoint0=0;%Perform tissue contouring only for timepoint 0 (when there is no exudate) then later timepoints just rely on first timepoint tissue contour     
            PredrawnTumourMask=1;%use pre-drawn transverse mask if existsn
            
            PreviousDrawnFrameROIifPossible=1; % redoing drawing to keep drawing consistent and only slightly modifying
            TryAutomaticAllignment=0;%During transverse mask creation attempt automatic allignment to raw svOCT
            %alignedPredrawn=0;%already aligned brightfield fluorescence tumour mask with OCT 
        % Physical to pix conversions
            umPerPix_For200PixDepthInAir=10.8336;%empirically determined through measurements of borosillicate glass of known dimensions and refractive index at 1320nm, 1.503            
            umPerPix_For200PixDepthInTissue=7.738282833;
            GlassThickness_200PixDepth=18;%empirically determined average glass thickness is 18 when the volume on our nrcOCT is rescaled to 200pixels in depth
            ReferencePixDepth=200;%observation above based on 200 pix depth rescaling, do not change
            DataCroppedNotResizedInDepth=1;%%If not resized no difference in pixel scale from original at 500pixels
        %Struct image for reference change
            %ToRemoveOS=0;%make it optional during code run?
            OSremoval=0%0.003%0.003;%0.003
        % Saving info
%         if glass_1_Tissue_2_both_3_contour==1
%             SaveFilenameUnrestricted='Full 3D tumour mask_Manual_GlassUnlimited';
%         else
%             SaveFilenameUnrestricted='Full 3D tumour mask_Manual_TissueUnlimited';
%         end
            SaveFilenameUnrestricted={'Full 3D tumour mask_Manual_GlassUnlimited';'Full 3D tumour mask_Manual_TissueUnlimited'};
            SaveFilenameCylindricalProj='Full 3D tumour mask_Manual_CylindricalProj';
    %% Vessel segmentation settings
        % General
            BinarizeVesselsNOW_0_no_1_manual_2_automatic=1;%(0) Do not perform vessel segmentation now (1) Perform manual vessel segmentation after mask creation step, (2) Perform automatic vessel segmentation after mask creation step  
            if (BinarizeVesselsNOW_0_no_1_manual_2_automatic== 1 || BinarizeVesselsNOW_0_no_1_manual_2_automatic== 2) && BinVesselsAlreadyPrepared==1
                BinVesselsAlreadyPrepared=0; %If you are still going to be creating the binarized vessels, they would not yet be ready to be transformed during the mask creation steps
                error('Cannot have BinVesselsAlreadyPrepared==1 if you will be creating the binarized vessels now.')
            end
            ProcessFullFOV_0_no_1_yes=0;%whether to rely on (1) the full FOV of the raw acquisition or (0) just the defined 3D mask     
    CheckIntermediates=1;
    ColormapDirectory=fullfile(DirectoryProcCodeLetter,'All-in-1_Tissue and vessels segmentation, co-registration and quantification\subfunctions\Colour-depth encoding',"cmap2.mat")
        % More detailed settings for vessel segmentation are in the body of the script below
        
    %% *****************Files to be selected settings*****************
        % General
            ManualSelFew_0_OR_SemiAutomatic_2_OR_FullAutomatic_3=2;%0: when just for a select few, 2: for selective huge batch processing (not in a rush to get results for a select few), 3: For processing everything
            UnformatedDataSet=0;%If applying to isolated data not following current organization system (as in old data in the lab from Valentin for example) it will simply perform manual file selection (saving paths) and recording data as date of folder name
            if UnformatedDataSet==1 && ManualSelFew_0_OR_SemiAutomatic_2_OR_FullAutomatic_3~=0
                ManualSelFew_0_OR_SemiAutomatic_2_OR_FullAutomatic_3=0;
                error('Cannot have dataset of different organization processed semi/fully automatically if you will be creating the binarized vessels now.')
            end
            stOCTAvailability=1;%whether structural OCT data sets available or not
            if UnformatedDataSet==0 && stOCTAvailability==0
                stOCTAvailability=1;
                error('Careful if you are using the current dataset organization stOCT would be available')
            end
            if stOCTAvailability==0 && (glass_1_Tissue_2_both_3_contour==2||glass_1_Tissue_2_both_3_contour==3)
                glass_1_Tissue_2_both_3_contour=1;
                error('svOCT will be used to contour only glass (Tissue will not be easy nor consistent')
            end
            %allignedPredrawn=0;%already aligned brightfield fluorescence tumour mask with OCT 
            %ProcessingDate='Valentin_older_with_rotation' %whether it is Valentin's processing which he rotates
        % Automatic search terms to assist in speed of file selection    
            RawVasculatureFileKeywordRaw={'D3D_single.mat';'SV_volume.mat'}; 
            stOCTFileKeyword={'st3D_uint16.mat'}; 
            %Ke
                    predrawnTumourMaskFileKeyword={'TumourMask2D_aligned_coregTime0.mat';'TumourMask2D_aligned.mat';'TumourMask2D.mat';'tumor_mask.mat'};%.mat%'tumor_mask'%{}%Tumour_mask2D.mat
                if BinVesselsAlreadyPrepared==1
                    BinVasculatureFileKeyword={'vessels_processed_binary.mat';'VTD_Binarized.mat'};
                else
                    BinVasculatureFileKeyword={''};
                end
    %% *****************Info about data*********************************
%    DirectoryInitialTimepoints={'BSOrt1\Jan 7 2022'}; % Create a folder called Timepoint 0- with FOV and Timepoint
%    TotalDoses={'NoRTx BSOrt Pilot'}
DirectoryInitialTimepoints={'BS1\Apr 23 2021';... %must also contain pre if no 'BS'
                                'BS3\Apr 23 2021';... %will save the OCTA file directly outside the folder for ease in folder called Timepoint 0-
                                'L0R1\Apr 12 2021';...
                                'L0R2\Apr 7 2021';...
                                'L0R3\Apr 12 2021';...
                                'L0R4\Apr 12 2021';...
                                'L1R1\Apr 19 2021';...
                                'L1R2\Apr 19 2021';...
                                'L1R3\Apr 19 2021';...
                                'L2R2 Control small\Apr 21 2021';...
                                'L2R2 Control large\Apr 21 2021';...
                                'L2R4 Control small\Apr 26 2021';...
                                'L2R4 Control Centre large\Apr 26 2021';...
                                'L2R4 Treated\Apr 26 2021'};
TotalDoses={'noRTx BS';'noRTx BS';'noRTx Control';'noRTx Control';'3x12Gy MWF';'3x12Gy MWF';'noRTx Control';'3x12Gy MWF';'3x12Gy MWF''noRTx MultiChamber Control';'noRTx MultiChamberControl';'noRTx MultiChamber Control';'noRTx MultiChamberControl';'MultiChamber 3x12Gy MWF'};                           

    exposureTimes_BriFlu=[400,400,400,400,400,800,800,800,800,800,800];
    
    DirectoriesMice={'L1R2';'L1R3';};%{'BSOrt1'}{'BS1';'BS3'};%{'L0R1';'L0R2';'L0R3';'L0R4';'L1R1';'L1R2';'L1R3';'L2R2';'L2R4'};%'\DLF data\20 Gy\M26 - double tumor-(looking at BOTTOM one)';'\DLF data\10 Gy'};%'\DLF data\20 Gy\M44';'\DLF data\20 Gy\M45';'\DLF data\20 Gy\M58';'\DLF data\30 Gy'; '\DLF data\Control'};%
    DirectoriesBareSkinMiceKeyword={'BS'};
    DirectoriesStruct=DirectoriesMice;
    for indMice=1:length(DirectoriesMice)
        DirectoriesMice{indMice}=[fullfile(DirectoryVesselsData,DirectoriesMice{indMice})];
    end
    for indMice=1:length(DirectoryInitialTimepoints)
        DirectoryInitialTimepoints{indMice}=[fullfile(DirectoryVesselsData,DirectoryInitialTimepoints{indMice})];
    end
    for indMice=1:length(DirectoriesStruct)
        DirectoriesStruct{indMice}=[fullfile(DirectoryDataLetter,DirectoriesStruct{indMice})];
    end
%% Defining directories for automatic and semi-automatic file search
if ManualSelFew_0_OR_SemiAutomatic_2_OR_FullAutomatic_3==2

        allMice=[];
        for idx=1:length(DirectoriesMice)
            %fprintf('yo')
            allMice=[allMice ; dir(fullfile(DirectoriesMice{idx},'**'))]; %list all files in directory to do file search (since all sv files named differently, just have key words
            %all=[all;allTemp];
        end
        
%         allStruct=[];
elseif ManualSelFew_0_OR_SemiAutomatic_2_OR_FullAutomatic_3==3
    allMice=dir(fullfile(DirectoryVesselsData,'**')); %list all files in directory to do file search (since all sv files named differently, just have key words
end

%% Searching through folders manually
if ManualSelFew_0_OR_SemiAutomatic_2_OR_FullAutomatic_3==0
    countBatchFolder=1;
     BatchOfFolders=cell(1,5);%{[],[],[]};
     FileSelectDirectory=DirectoryVesselsData;
%     while ind<=NumFiles_max && BatchOfFolders{ind}~=0%MiceFolderInd=1:NumMice
    while isempty(BatchOfFolders{countBatchFolder,1})
       %PredrawnTumourMask=0; %resetting
        [filenameOCTVesRaw,pathOCTVesRaw]=uigetfile(FileSelectDirectory,'Please select RAW OCTA-processed data file');
                if filenameOCTVesRaw==0
                        fprintf('Skipping\n')
                   break;
                else
                    FolderStructAndRawOCTA=fileparts(pathOCTVesRaw);
                    NameTimepointComboTemp=strsplit(pathOCTVesRaw,'\')%fileparts(fileparts(fileparts(pathOCTVesRaw)));
                        if UnformatedDataSet==1%Just picking data from data set not following current organization
                            FolderConsidered=pathOCTVesRaw;
                        else
                            FolderConsidered=fullfile(NameTimepointComboTemp{1:4});
                        end
                        
                            if contains(FolderStructAndRawOCTA,'pre')
                                TumourMaskAndStepsDir=fullfile(FolderConsidered,'Segmentation_TumourMaskCreation2D-3D','pre',NameTimepointComboTemp{end-2});
                            elseif contains(FolderStructAndRawOCTA,'post')
                                TumourMaskAndStepsDir=fullfile(FolderConsidered,'Segmentation_TumourMaskCreation2D-3D','post',NameTimepointComboTemp{end-2});
                            else
                                TumourMaskAndStepsDir=fullfile(FolderConsidered,'Segmentation_TumourMaskCreation2D-3D',NameTimepointComboTemp{end-2});
                            end
                                if ~exist(TumourMaskAndStepsDir,'dir')
                                    mkdir(TumourMaskAndStepsDir);
                                end
                        saveFolder=fullfile(TumourMaskAndStepsDir,MaskCreationFolder);
                        %% Timepoint identification and time elapsed since T0-
                        if UnformatedDataSet==1
                                MouseName=NameTimepointComboTemp{end-2};
                                Timepoint=NameTimepointComboTemp{end-1};
                                    NameDayFormat=fullfile(MouseName,Timepoint)
                            MouseNameTimepoint=[MouseName,' ',Timepoint];
                            DaysPrecise=[];
                            TimepointTrueAndRel=Timepoint;
                        else
                            NameDayFormat=fullfile(NameTimepointComboTemp{3},NameTimepointComboTemp{4});%varies in depth if pre and post image%NameDayFormat=fullfile(NameTimepointComboTemp{end-4},NameTimepointComboTemp{end-3});
                            NameTimepointCombo=strsplit(NameTimepointComboTemp{end-1},'_');
                                MouseName=NameTimepointCombo{1};
                                Timepoint=NameTimepointCombo{2};
                                    TimepointVarNameDraft=strsplit(strrep(Timepoint,'-',''),' ');
                                    TimeDraft=strsplit(TimepointVarNameDraft{2},',');%,{'h';'m'})
                                    Time=[TimeDraft{1} 'h' TimeDraft{2} 'm' TimeDraft{3} 's'];%strrep(Timepoint,',',{'h';'m'})
                                    TimepointVarName{1}=['Day' TimepointVarNameDraft{1}]; 
                                    TimepointVarName{2}=['Time' Time];
                                    
                                     %% Timepoint calculation
                                        %TimepointDataFolder=fileparts(fileparts(fileparts(fileparts(fileparts(BatchOfFolders{countBatchFolder,2})))))

                                        [TimeElapsed, MouseName,Timepoint,InitialTimepointtxtFile]=CalcTimePostRTx(TumourMaskAndStepsDir, DirectoryVesselsData);
                                              for iii=1:length(DirectoryInitialTimepoints)
                                                    if contains(DirectoryInitialTimepoints{iii},MouseName)
                                                        IndexMouse=iii;
                                                    end
                                              end
                                          DaysRounded=TimeElapsed.RelImgTimepointDaysRounded;% IF IT is irradiated, Time 0 is not the 1hour pre irradiation OCT scan but the time of irradiation.
                                          DaysPrecise=TimeElapsed.RelImgTimepointDaysPrecise;%to convert into days with fraction
                                                if contains(FolderStructAndRawOCTA,'pre')
                                                   MouseNameTimepoint=[MouseName sprintf('_{%dd pre}',DaysRounded)];% 'd_pre'];
                                                elseif contains(FolderStructAndRawOCTA,'post') 
                                                   MouseNameTimepoint=[MouseName sprintf('_{%dd post}',DaysRounded)]; %'_{post}'];
                                                else
                                                   MouseNameTimepoint=[MouseName sprintf('_{%dd}',DaysRounded)]; 
                                                end                    
                        end
                                
        %% Files checked to see if already processed 
%         if glass_1_Tissue_2_both_3_contour==1
%             glass_1_Tissue_2_contour={1,0}
%         elseif glass_1_Tissue_2_both_3_contour==2
%             glass_1_Tissue_2_contour={0,2}
%         elseif glass_1_Tissue_2_both_3_contour==3
%             glass_1_Tissue_2_contour={1,2}
%         end
%Initialization otherwise gets stuck when notices no second column to cell
%variables!
MaskCreationDraft=cell(2,1);
saveContour=cell(2,1);
SaveFilenameRawMaskApplied=cell(2,1);
SaveFilenameDataUnlimited_UnCoregT0=cell(2,1);
SaveFilenameDataCylindricalProj_UnCoregT0=cell(2,1);
SaveFilenameDataUnlimited=cell(2,1);
SaveFilenameDataCylindricalProj=cell(2,1);

            if glass_1_Tissue_2_both_3_contour==1 || glass_1_Tissue_2_both_3_contour==3              
                    MaskCreationDraft{1}=fullfile(saveFolder{1},['Glass removal intermediate steps']);%, replace(char(datetime),':','_')]);%careful if there is space after filename--not allowed in directory immediately before backslash                
                    mkdir(MaskCreationDraft{1});
                    saveContour{1}=fullfile(MaskCreationDraft{1},'zline_GlassBot_uncoregTime0-.mat');
                           % not done anymore
                           SaveFilenameRawMaskApplied{1}=fullfile(saveFolder{1},'RawVess_UnCoregTime0-_RotShift.mat');
                           SaveFilenameDataUnlimited_UnCoregT0{1}=[fullfile(saveFolder{1},[SaveFilenameUnrestricted{1} '_UnCoregT0.mat'])];
                           SaveFilenameDataCylindricalProj_UnCoregT0{1}=[fullfile(saveFolder{1},[SaveFilenameCylindricalProj '_UnCoregT0.mat'])];
                        if glass_1_Tissue_2_both_3_contour==1
                           if UnformatedDataSet==1
                               SaveFilenameDataUnlimited{1}=SaveFilenameDataUnlimited_UnCoregT0{1};
                               SaveFilenameDataCylindricalProj{1}=SaveFilenameDataCylindricalProj_UnCoregT0{1};
                           else
                               SaveFilenameDataUnlimited{1}=SaveFilenameDataUnlimited_UnCoregT0{1};
                               SaveFilenameDataCylindricalProj{1}=SaveFilenameDataCylindricalProj_UnCoregT0{1};
                               BinVasculatureFileKeyword={fullfile(saveFolder{1},'Bin Manual','BinVess_UnCoregTime0-_RotShift.mat')};
%                                SaveFilenameDataUnlimited{1}=[fullfile(saveFolder{1},[SaveFilenameUnrestricted{1} '.mat'])];
%                                SaveFilenameDataCylindricalProj{1}=[fullfile(saveFolder{1},[SaveFilenameCylindricalProj '.mat'])];
                           end
                        end
            end
            if glass_1_Tissue_2_both_3_contour==2 || glass_1_Tissue_2_both_3_contour==3   
                    MaskCreationDraft{2}=fullfile(saveFolder{2},['Tissue masking intermediate steps']);%, replace(char(datetime),':','_')]);%careful if there is space after filename--not allowed in directory immediately before backslash                
                    mkdir(MaskCreationDraft{2});
                    saveContour{2}=fullfile(MaskCreationDraft{2},'zline_TissueTop_uncoregTime0-.mat');
                        if -1<DaysPrecise && DaysPrecise<=0 %initial timepoint
                            if OnlyTissueLabelTimepoint0==0 %labelling each timepoint tissue  
                               SaveFilenameRawMaskApplied{2}=fullfile(saveFolder{2},'RawVess_CoregTime0-_isT0_TissueMaskApp.mat');
                               if glass_1_Tissue_2_both_3_contour==2 
                                    BinVasculatureFileKeyword={fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_NotInZ_TissueMaskApp.mat')};%BinVasculatureFileKeyword=fullfile(saveFolder{2
                               elseif glass_1_Tissue_2_both_3_contour==3
                                    BinVasculatureFileKeyword={fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_isT0_TissueMaskApp.mat')};
                               end
                            elseif OnlyTissueLabelTimepoint0==1 
                                if glass_1_Tissue_2_both_3_contour==3    
                                    SaveFilenameRawMaskApplied{2}=fullfile(saveFolder{2},'RawVess_CoregTime0-_isT0_TissueMaskApp.mat');
                                    BinVasculatureFileKeyword={fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_isT0_TissueMaskApp.mat')};
                                elseif glass_1_Tissue_2_both_3_contour==2    
                                    SaveFilenameRawMaskApplied{2}='';
                                    BinVasculatureFileKeyword={};% not worth doing if no coregistration in depth using glass
                                end
                            end
                           SaveFilenameDataUnlimited_UnCoregT0{2}=[fullfile(saveFolder{2},[SaveFilenameUnrestricted{2} '_isT0_UnCoregT0.mat'])];
                           SaveFilenameDataCylindricalProj_UnCoregT0{2}=[fullfile(saveFolder{2},[SaveFilenameCylindricalProj '_isT0_UnCoregT0.mat'])];
                           SaveFilenameDataUnlimited{2}=[fullfile(saveFolder{2},[SaveFilenameUnrestricted{2} '_isT0.mat'])];
                           SaveFilenameDataCylindricalProj{2}=[fullfile(saveFolder{2},[SaveFilenameCylindricalProj '_isT0.mat'])];
                        else %other timepoints (TPx)
                            if OnlyTissueLabelTimepoint0==0 %labelling each timepoint tissue   
                               SaveFilenameRawMaskApplied{2}=fullfile(saveFolder{2},'RawVess_CoregTime0-_CurrentTP_TissueMaskApp.mat');
                               SaveFilenameDataUnlimited_UnCoregT0{2}=[fullfile(saveFolder{2},[SaveFilenameUnrestricted{2} '_CurrentTP_UnCoregT0.mat'])];
                               SaveFilenameDataCylindricalProj_UnCoregT0{2}=[fullfile(saveFolder{2},[SaveFilenameCylindricalProj '_CurrentTP_UnCoregT0.mat'])];
                               SaveFilenameDataUnlimited{2}=[fullfile(saveFolder{2},[SaveFilenameUnrestricted{2} '_CurrentTP.mat'])];
                               SaveFilenameDataCylindricalProj{2}=[fullfile(saveFolder{2},[SaveFilenameCylindricalProj '_CurrentTP.mat'])];
                               if glass_1_Tissue_2_both_3_contour==2 
                                    BinVasculatureFileKeyword={fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_NotInZ_TissueMaskApp.mat')};%BinVasculatureFileKeyword=fullfile(saveFolder{2
                               elseif glass_1_Tissue_2_both_3_contour==3
                                    BinVasculatureFileKeyword={fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_CurrentTP_TissueMaskApp.mat')};
                               end
                            elseif OnlyTissueLabelTimepoint0==1 
                                if glass_1_Tissue_2_both_3_contour==3    
                                    SaveFilenameRawMaskApplied{2}=fullfile(saveFolder{2},'RawVess_CoregTime0-_FromT0_TissueMaskApp.mat');
                                    BinVasculatureFileKeyword={fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_FromT0_TissueMaskApp.mat')};
                                elseif glass_1_Tissue_2_both_3_contour==2    
                                    SaveFilenameRawMaskApplied{2}='';
                                    BinVasculatureFileKeyword={};
                               end
                               SaveFilenameDataUnlimited_UnCoregT0{2}=[fullfile(saveFolder{2},[SaveFilenameUnrestricted{2} '_FromT0_UnCoregT0.mat'])];
                               SaveFilenameDataCylindricalProj_UnCoregT0{2}=[fullfile(saveFolder{2},[SaveFilenameCylindricalProj '_FromT0_UnCoregT0.mat'])];
                               SaveFilenameDataUnlimited{2}=[fullfile(saveFolder{2},[SaveFilenameUnrestricted{2} '_FromT0.mat'])];
                               SaveFilenameDataCylindricalProj{2}=[fullfile(saveFolder{2},[SaveFilenameCylindricalProj '_FromT0.mat'])];
                            end
                        end
            end
%% Now checking if files already exist (alternatively skips)                           
%if ~exist(savebotContour) && (Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1)% || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2)
MissingFilesForAutomation= (Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1) && ((glass_1_Tissue_2_both_3_contour==1 && ~exist(saveContour{1})) || (glass_1_Tissue_2_both_3_contour==2 && ~exist(saveContour{2})) || (glass_1_Tissue_2_both_3_contour==3 && ~exist(saveContour{1}) && ~exist(saveContour{2})))
if MissingFilesForAutomation==1
    fprintf('Missing 2D contours (tissue or glass mode according to setting), skipping\n')
    continue
else                           
                   AlreadyCompletedJustContouring= ((glass_1_Tissue_2_both_3_contour==1 && exist(saveContour{1})) || (glass_1_Tissue_2_both_3_contour==2 && exist(saveContour{2})) || (glass_1_Tissue_2_both_3_contour==3 && exist(saveContour{1}) && exist(saveContour{2}))) 
                   AlreadyCompletedMaskCreation=((glass_1_Tissue_2_both_3_contour==1 && exist(SaveFilenameDataUnlimited_UnCoregT0{1})) || (glass_1_Tissue_2_both_3_contour==2 && exist(SaveFilenameDataUnlimited{2})) || (glass_1_Tissue_2_both_3_contour==3 && exist(SaveFilenameDataUnlimited{1}) && exist(SaveFilenameDataUnlimited{2}))) 
%% Binarization already performed? (whether or not stated BinVesselsAlreadyPrepared==1)
                        AllInFolderRawOCTAConsidered=dir(fullfile(pathOCTVesRaw ,'**'));
                           FoundBinOCTA=0;
                                for cc=1:length(AllInFolderRawOCTAConsidered)%AllInFolderConsidered)
                                    for trialOCTBin=1:length(BinVasculatureFileKeyword)
                                        if (contains(AllInFolderRawOCTAConsidered(cc).name,BinVasculatureFileKeyword{trialOCTBin}) && ~isequal(AllInFolderRawOCTAConsidered(cc).name,'.'))
                                            pathOCTVesBin=AllInFolderRawOCTAConsidered(cc).folder;
                                            filenameOCTVesBin=AllInFolderRawOCTAConsidered(cc).name;    
                                            FoundBinOCTA=1;
                                        break;
                                        end
                                    end
                                    if FoundBinOCTA==1
                                            break
                                    end
                                end
                                        AlreadyCompletedBinarizationIfapplicable=BinarizeVesselsNOW_0_no_1_manual_2_automatic==0|| (FoundBinOCTA && (BinarizeVesselsNOW_0_no_1_manual_2_automatic==1 || BinarizeVesselsNOW_0_no_1_manual_2_automatic==2))
                                        %% Final check to determine whether should procede with processing
                        PotentiallyNotWorthProcessing=(AlreadyCompletedJustContouring && Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==0)|| (AlreadyCompletedMaskCreation && (Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2))&& AlreadyCompletedBinarizationIfapplicable;
                    StillPursue=[];
                        if PotentiallyNotWorthProcessing % && exist(fullfile(saveFolder,'CheckedOrientationsL12.txt'))%exist(fullfile(saveFolder,'CheckedOrientations.txt'))
                           fprintf('Already completed\n')
                                StillPursueQ=sprintf('Shall we still process? n otherwise type literally anything else or just press enter for yes\n');%,'s'];
                                    StillPursueA = inputdlg(StillPursueQ,'Reprocess?');%[1 2; 1 2]
                                        StillPursue=StillPursueA{1};%input('Right orientation? n otherwise type literally anything else or just press enter for yes\n','s');
                                    if isequal(StillPursue,'n')||isequal(StillPursue,'N')
                                        continue %skip this iteration of for loop and go to next iteration since already done previously                           
                                    elseif isempty(StillPursue)
                                        StillPursue='Y'
                                    end
                        end
                       if (PotentiallyNotWorthProcessing==0 && isempty(StillPursue))|| (PotentiallyNotWorthProcessing==1 && ~(isequal(StillPursue,'n')||isequal(StillPursue,'N')))%elseif~exist(fullfile(saveFolder,'CheckedOrientationsL11.txt'))%elseif ~exist(SaveFilenameDataUnlimited) && ~exist(fullfile(saveFolder,'CheckedOrientations.txt')) 
                           %% Analysis Folder creation
                                for i=1:length(saveFolder)
                                    if ~exist(saveFolder{i},'dir')
                                        mkdir(saveFolder{i});
                                    end
                                end
                    countBatchFolder=countBatchFolder+1;
                    AllInFolderConsidered=dir(fullfile(FolderStructAndRawOCTA ,'**'));
                    %Fileparts=strsplit(FolderConsidered,'\');
                    BatchOfFolders{countBatchFolder,1}=fullfile(pathOCTVesRaw,filenameOCTVesRaw); %OCT file found and recorded

                    FoundRawOCTA=1;
                    if UnformatedDataSet==0 
                    %% Which Mouse timepoint 0 file to refer to? and index
                                    TimepointTrueAndRel=sprintf('%s_%.1fd',Timepoint,DaysPrecise);
% GoodFile=inputgl('Shall we continue trying to process this file?');
                        if ~(-1<DaysPrecise && DaysPrecise<=0)           
% GoodFile=inputgl('Shall we continue trying to process this file?');
                    try
                        if glass_1_Tissue_2_both_3_contour==1 || glass_1_Tissue_2_both_3_contour==3
                                        [SegmentationFolderTimepoint0Temp{1},IndexMouse]=findSegmentationtimepoint0_Folderv2(MouseName,Timepoint,BatchOfFolders,countBatchFolder,DirectoryInitialTimepoints,InitialTimepointtxtFile,DirectoriesBareSkinMiceKeyword,saveContour{1},MaskCreationFolder{1});%SaveFilenameRawMaskApplied--not necessarily already done
                                if ~contains(SegmentationFolderTimepoint0Temp{1},'Manual_With_WO_Glass2')%the case when you are just starting timepoint 0- processing)
                                    SegmentationFolderTimepoint0{1}=fullfile(SegmentationFolderTimepoint0Temp{1},'Manual_With_WO_Glass2');
                                else
                                    SegmentationFolderTimepoint0{1}=SegmentationFolderTimepoint0Temp{1};
                                end
                        end
                        if glass_1_Tissue_2_both_3_contour==2 || glass_1_Tissue_2_both_3_contour==3
                                        [SegmentationFolderTimepoint0Temp{2},IndexMouse]=findSegmentationtimepoint0_Folderv2(MouseName,Timepoint,BatchOfFolders,countBatchFolder,DirectoryInitialTimepoints,InitialTimepointtxtFile,DirectoriesBareSkinMiceKeyword,saveContour{2},MaskCreationFolder{2});%SaveFilenameRawMaskApplied--not necessarily already done
                                if ~contains(SegmentationFolderTimepoint0Temp{2},'Manual_OnlyTissue')%the case when you are just starting timepoint 0- processing)
                                    SegmentationFolderTimepoint0{2}=fullfile(SegmentationFolderTimepoint0Temp{2},'Manual_OnlyTissue');
                                else
                                    SegmentationFolderTimepoint0{2}=SegmentationFolderTimepoint0Temp{2};
                                end
                        end
                    catch
                        fprintf('Timepoint0- file for requested segmentation style not yet performed.\n')
                    end
                        else%Day 0 pre
                           if glass_1_Tissue_2_both_3_contour==1 || glass_1_Tissue_2_both_3_contour==3
                                SegmentationFolderTimepoint0{1}=fullfile(fileparts(InitialTimepointtxtFile),'Manual_With_WO_Glass2');
                           end
                           if glass_1_Tissue_2_both_3_contour==2 || glass_1_Tissue_2_both_3_contour==3
                            SegmentationFolderTimepoint0{2}=fullfile(fileparts(InitialTimepointtxtFile),'Manual_OnlyTissue');
                           end
                           for ii=1:length(DirectoryInitialTimepoints)
                                if contains(DirectoryInitialTimepoints{ii},MouseName)
                                    IndexMouse=ii;
                                end
                            end
                       end
                                for ii=1:length(SegmentationFolderTimepoint0)
                                    if ~isempty(SegmentationFolderTimepoint0{ii})
                                        indxNotEmpty=ii
                                        break;
                                    end
                                end
                                            if (-1<DaysPrecise && DaysPrecise<=0)
                                                Timepoint0=[TimepointTrueAndRel '_RefT0'];
                                            else
                                                for ii=1:length(SegmentationFolderTimepoint0)
                                                    if ~isempty(SegmentationFolderTimepoint0{ii})
                                                        Timepoint0Temp=strsplit(SegmentationFolderTimepoint0{ii},'\');
                                                        Timepoint0=sprintf('%s_0.0d_RefT0',Timepoint0Temp{4},TimeElapsed.RelImgTimepointDaysPrecise);
                                                        indxNotEmpty=ii
                                                        break
                                                    end
                                                end
                                            end
                                            %Timepoint0Temp=strsplit(RawFolderTimepoint0,'\');
                                            %if contains(RawFolderTimepoint0,'pre')
                                            %Timepoint0=[TimepointTrueAndRel '_RefT0'];
                                        MouseNameTimepoint0=[MouseName ' ' Timepoint0];
                             timepoint0ProcDir=dir(fullfile(fileparts(SegmentationFolderTimepoint0{indxNotEmpty}),'**'));
                             timepoint0AlreadyProcQuestion= (sum(contains({timepoint0ProcDir(:).name},'zline_GlassBot_uncoregTime0-.mat'))+sum(contains({timepoint0ProcDir(:).name},'zline_TissueTop_uncoregTime0-.mat')))>1%>0;
                             if glass_1_Tissue_2_both_3_contour==2 || glass_1_Tissue_2_both_3_contour==3
                                timepoint0AlreadyProcQuestion= (sum(contains({timepoint0ProcDir(:).name},'zline_GlassBot_uncoregTime0-.mat'))+sum(contains({timepoint0ProcDir(:).name},'zline_TissueTop_uncoregTime0-.mat')))>1%>0;
                             elseif glass_1_Tissue_2_both_3_contour==1
                                timepoint0AlreadyProcQuestion= (sum(contains({timepoint0ProcDir(:).name},'zline_GlassBot_uncoregTime0-.mat'))+sum(contains({timepoint0ProcDir(:).name},'zline_TissueTop_uncoregTime0-.mat')))>0%>0;
                              end
                                    if ~(-1<DaysPrecise && DaysPrecise<=0) %If not considering processing timepoint 0-, asking whether timepoint 0- was previously processed or not yet
                                        if timepoint0AlreadyProcQuestion==1
                                            fprintf('Timepoint 0- already processed, good to go!\n')
                                        else
                                            fprintf('Timepoint 0- not already processed, skipping this timepoint for now...\n')
                                            continue
                                        end
                                    end
                    end
                    
%% Now to load structural file                           
        if UnformatedDataSet==1 && stOCTAvailability==0
                        filenameStOCT=filenameOCTVesRaw;
                        pathStOCT=pathOCTVesRaw;
        else
            if exist(fullfile(pathOCTVesRaw,'StOCTFileUsed.mat'),'file')
                load(fullfile(pathOCTVesRaw,'StOCTFileUsed.mat'))
                temp=strsplit(StOCTFileUsed,'\');
                pathStOCT=fileparts(StOCTFileUsed);
                filenameStOCT=temp{end};
            else
                FileSelectDirectory=fileparts(pathOCTVesRaw);
                [filenameStOCT,pathStOCT]=uigetfile(FileSelectDirectory,'Please select structural data file');
    %                 AllInFolderConsidered=dir(fullfile(pathOCT,'**'))
                    if filenameStOCT~=0
                        StOCTFileUsed=fullfile(pathStOCT,filenameStOCT);
                        save(fullfile(pathOCTVesRaw,'StOCTFileUsed.mat'),'StOCTFileUsed','-v7.3')
                    end
            end
        end
        
        
            if filenameStOCT==0
                %BatchOfFolders{ind}={'All loaded'}
                fprintf('Skipping\n')
               break;
            else
                
                %%
                FileSelectDirectory=fileparts(pathOCTVesRaw);%fileparts(BatchOfFolders{ind,1});
                     if BinVesselsAlreadyPrepared==1 % are there binarized vessels to act as reference 
                        if exist(fullfile(pathOCTVesRaw,'BinOCTAFileUsed.mat'),'file')
                            load(fullfile(pathOCTVesRaw,'BinOCTAFileUsed.mat'))
                            temp=strsplit(BinOCTAFileUsed,'\');
                            pathOCTVesBin=fileparts(BinOCTAFileUsed);
                            filenameOCTVesBin=temp{end};
                        else
                            FileSelectDirectory=pathOCTVesRaw;%fileparts(BatchOfFolders{ind,1});        
                            [filenameOCTVesBin,pathOCTVesBin]=uigetfile(FileSelectDirectory,'Please select BINARIZED OCTA data file');
                            if filenameOCTVesBin==0
                                %BatchOfFolders{ind}={'All loaded'}
                                    fprintf('Skipping\n')
                                    continue%break;
                            else
                                BinOCTAFileUsed=fullfile(pathOCTVesBin,filenameOCTVesBin);
                                save(fullfile(pathOCTVesRaw,'BinOCTAFileUsed.mat'),'BinOCTAFileUsed','-v7.3')
                            end
                        end
                     else
                            filenameOCTVesBin=[];
                            pathOCTVesBin=[];
                     end
                            
                            %% 2D Tumour mask selection/creation if applicable
                                OptFluSegmentationFolder=fullfile(TumourMaskAndStepsDir,'2D OCT-bri/flu Co-registration + Tumour Mask');
                                    if ~exist(OptFluSegmentationFolder,'dir')
                                            mkdir(OptFluSegmentationFolder);
                                    end
                                OCTLateralTimepointCoregistrationFolder=fullfile(TumourMaskAndStepsDir,'3D Time OCT Co-registration intermediate');
                                    if ~exist(OCTLateralTimepointCoregistrationFolder,'dir')
                                            mkdir(OCTLateralTimepointCoregistrationFolder);
                                    end    
                                FoundTumourMask2DButCorrectAlignment=0;%Initialized variable which determines whether coregistered drawn 2D tumour mask created or not    
                                fprintf('Folder is %s \n',fullfile(NameTimepointComboTemp{end-2:end}));
                                %if ~contains(MouseName,DirectoriesBareSkinMiceKeyword) && PredrawnTumourMask==1%if previously drawn can be loaded
                                if PredrawnTumourMask==1%if previously drawn can be loaded
                                    if exist(fullfile(pathOCTVesRaw,'TumourFileUsed.mat'),'file')
                                        load(fullfile(pathOCTVesRaw,'TumourFileUsed.mat'))
                                        temp=strsplit(TumourFileUsed,'\');
                                        path2DMask=fileparts(TumourFileUsed);
                                        filename2DMask=temp{end};
                                        createTumourMaskQuestion='n';%Variable not used (just for coder's reference)
                                        BatchOfFolders{countBatchFolder,4}=TumourFileUsed;
                                    else
                                    [filename2DMask,path2DMask]=uigetfile(OptFluSegmentationFolder,'Please select previously created tumour mask file (if none just cancel).');
                                        TumourFileUsed=fullfile(path2DMask,filename2DMask);
                                        if isequal(filename2DMask,0) || isequal(path2DMask,0)%not found this previously drawn mask
                                            createTumourMaskQuestion=input('Shall we create one and extract all the metrics (fast,<8min)? y/n \n','s');
                                                if ~isequal(createTumourMaskQuestion,'y')|| isempty(createTumourMaskQuestion)
                                                    fprintf('Skipping\n')
                                                    continue%error('Please select a pre-drawn 2D tumour mask for me... please!')
                                                end
                                        %else 
                                        else%found previously drawn mask
                                            createTumourMaskQuestion='n';
    %                                         BatchOfFolders{countBatchFolder,1}=fullfile(pathOCTVesRaw,filenameOCTVesRaw);%uigetdir(FileSelectDirectory,'Please select folders of datasets to be sv processed');
                                            save(fullfile(pathOCTVesRaw,'TumourFileUsed.mat'),'TumourFileUsed','-v7.3');
                                            BatchOfFolders{countBatchFolder,4}=TumourFileUsed;
                                        end
                                    end
                                else
                                    filename2DMask=0;
                                end
                                            if isequal(filename2DMask,'TumourMask2D_aligned_coregTime0.mat') %Selecting this only means it skips even checking for alignment step (between TPX OCT and TPX opt flu
                                                    FoundTumourMask2DButCorrectAlignment=1; %if it is named this way, it was created with the script for aligning
                                                    createTumourMaskQuestion='n';
                                            elseif isequal(filename2DMask,0) 
                                                createTumourMaskQuestion='y';
                                                    FoundTumourMask2DButCorrectAlignment=0;
                                            elseif isequal(filename2DMask,'TumourMask2D_aligned.mat')
                                                createTumourMaskQuestion='y';
                                                    FoundTumourMask2DButCorrectAlignment=2;%some other mask intermediate    
                                            end                                
                                
                                  %% Dose received up to considered timepoint  
                                if UnformatedDataSet==1
                                    if contains(pathOCTVesRaw,'Bare Skin')
                                       DoseReceivedUpToTP=0;
                                    elseif contains(pathOCTVesRaw,'10 Gy')%Not ready need to know dates...
                                    end   
                                else
                                DoseCohort=TotalDoses{IndexMouse};
                                    if contains(DoseCohort,'noRTx','IgnoreCase',true) 
                                        DoseReceivedUpToTP=0;
                                    elseif contains(DoseCohort,'3x12Gy MWF','IgnoreCase',true)        
                                        if DaysRounded<=0
                                            if contains(FolderStructAndRawOCTA,'pre')
                                                DoseReceivedUpToTP=0; 
                                            elseif contains(FolderStructAndRawOCTA,'post')
                                                DoseReceivedUpToTP=12;%Could also make it DoseReceivedUpToDayConsidered=DoseReceivedUpToDayConsidered+12;
                                            else
                                                DoseReceivedUpToTP=0;
                                            end
                                        elseif DaysRounded<=2%caldays(2)%2 %only looks for this condition if the first is not met according to the logic of if and elseif conditionals
                                            if contains(FolderStructAndRawOCTA,'pre')
                                                DoseReceivedUpToTP=12;
                                            elseif contains(FolderStructAndRawOCTA,'post')
                                                DoseReceivedUpToTP=24;
                                            else
                                                DoseReceivedUpToTP=12;
                                            end
                                        elseif DaysRounded<=4 %only looks for this condition if the first is not met according to the logic of if and elseif conditionals
                                            if contains(FolderStructAndRawOCTA,'pre')
                                                DoseReceivedUpToTP=24;
                                            elseif contains(FolderStructAndRawOCTA,'post')
                                                DoseReceivedUpToTP=36;
                                            else
                                                DoseReceivedUpToTP=24;
                                            end      
                                        end
                                    end
                                    
                                
                                    for iv=1:length(saveFolder)
%                                        if ~exist(fullfile(saveFolder{iv},'MouseTimepointInfo.txt'))
                                        fid = fopen(fullfile(saveFolder{iv},'MouseTimepointInfo.txt'), 'wt');
                                            fprintf(fid, 'Mouse: %s \nTimepoint: %s \nTimepointRel: %sday(s) \nDoseReceivedUpToTP: %.1f \nPlanned dose: %s',MouseName,Timepoint,TimeElapsed.RelImgTimepointDaysPrecise,DoseReceivedUpToTP,DoseCohort);%'Jake said: %f\n', sqrt(1:10));
                                            fclose(fid);
                                    end
                                end
                                %% 2D/3D coregistration, Gross tumour response metrics and longitudinal coregistration
                                    % If this step was already performed it
                                    % can be skipped
                                    if AlreadyCompletedJustContouring==0 || AlreadyCompletedMaskCreation==0
                                        toc
                                        if LateralorFullCoregPreTisContour==0
                                            if UnformatedDataSet==1
                                                BatchOfFolders = VOIorTumourMaskPrep_Metextraction_LongCoreg_fun17_NoStOCT(GlassThickness_200PixDepth,DataCroppedNotResizedInDepth,ReferencePixDepth,BatchOfFolders,countBatchFolder,MouseName,TimepointTrueAndRel,NameDayFormat,NameTimepointComboTemp,DirectoryInitialTimepoints,DirectoryVesselsData,DirectoryDataLetter,FolderConsidered,DirectoriesBareSkinMiceKeyword,OptFluSegmentationFolder,MaskCreationDraft,saveFolder,pathOCTVesRaw,filenameOCTVesRaw,pathOCTVesBin,filenameOCTVesBin,pathStOCT,filenameStOCT,RawVasculatureFileKeywordRaw,TryAutomaticAllignment,exposureTimes_BriFlu,num_contoured_slices,OSremoval,TumourMaskAndStepsDir,OCTLateralTimepointCoregistrationFolder,FoundTumourMask2DButCorrectAlignment,SaveFilenameDataUnlimited,SaveFilenameDataCylindricalProj,SaveFilenameDataUnlimited_UnCoregT0,SaveFilenameDataCylindricalProj_UnCoregT0,BinVesselsAlreadyPrepared,Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2,VisualizeResults,glass_1_Tissue_2_both_3_contour,DoseReceivedUpToTP,DaysPrecise,OnlyTissueLabelTimepoint0,ActiveMemoryOffload);                                    
                                            else
                                                BatchOfFolders = VOIorTumourMaskPrep_Metextraction_fun19_TP0Bef_CoregMaybeL8r(GlassThickness_200PixDepth,DataCroppedNotResizedInDepth,ReferencePixDepth,BatchOfFolders,countBatchFolder,MouseName,NameDayFormat,NameTimepointComboTemp,DirectoryInitialTimepoints,DirectoryVesselsData,DirectoryDataLetter,TimepointTrueAndRel,TimepointVarName,FolderConsidered,DirectoriesBareSkinMiceKeyword,OptFluSegmentationFolder,MaskCreationDraft,saveFolder,pathOCTVesRaw,filenameOCTVesRaw,pathOCTVesBin,filenameOCTVesBin,pathStOCT,filenameStOCT,RawVasculatureFileKeywordRaw,TryAutomaticAllignment,exposureTimes_BriFlu,IndexMouse,num_contoured_slices,OSremoval,TumourMaskAndStepsDir,OCTLateralTimepointCoregistrationFolder,FoundTumourMask2DButCorrectAlignment,SaveFilenameDataUnlimited,SaveFilenameDataCylindricalProj,SaveFilenameDataUnlimited_UnCoregT0,SaveFilenameDataCylindricalProj_UnCoregT0,BinVesselsAlreadyPrepared,Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2,VisualizeResults,glass_1_Tissue_2_both_3_contour,DoseReceivedUpToTP,DaysPrecise,SegmentationFolderTimepoint0,indxNotEmpty,MouseNameTimepoint0,OnlyTissueLabelTimepoint0,InitialTimepointtxtFile,ActiveMemoryOffload);                                    
                                            end
                                        else
                                            if UnformatedDataSet==1
                                            
                                            else
                                                BatchOfFolders = VOIorTumourMaskPrep_Metext_LongCoreg_fun16_CoregBefContTis(GlassThickness_200PixDepth,DataCroppedNotResizedInDepth,ReferencePixDepth,BatchOfFolders,countBatchFolder,MouseName,NameDayFormat,NameTimepointComboTemp,DirectoryInitialTimepoints,DirectoryVesselsData,DirectoryDataLetter,TimepointTrueAndRel,TimepointVarName,FolderConsidered,DirectoriesBareSkinMiceKeyword,OptFluSegmentationFolder,MaskCreationDraft,saveFolder,pathOCTVesRaw,filenameOCTVesRaw,pathOCTVesBin,filenameOCTVesBin,pathStOCT,filenameStOCT,RawVasculatureFileKeywordRaw,TryAutomaticAllignment,exposureTimes_BriFlu,IndexMouse,num_contoured_slices,OSremoval,TumourMaskAndStepsDir,OCTLateralTimepointCoregistrationFolder,FoundTumourMask2DButCorrectAlignment,SaveFilenameDataUnlimited,SaveFilenameDataCylindricalProj,SaveFilenameDataUnlimited_UnCoregT0,SaveFilenameDataCylindricalProj_UnCoregT0,BinVesselsAlreadyPrepared,Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2,VisualizeResults,glass_1_Tissue_2_both_3_contour,DoseReceivedUpToTP,DaysPrecise,SegmentationFolderTimepoint0,indxNotEmpty,MouseNameTimepoint0,OnlyTissueLabelTimepoint0,InitialTimepointtxtFile,ActiveMemoryOffload);                                    
                                            end
                                        end
                                        toc
                                    end   
%% Tissue or glass masks already produced, just loading them
                                        if BinarizeVesselsNOW_0_no_1_manual_2_automatic==1 || BinarizeVesselsNOW_0_no_1_manual_2_automatic==2 %manual vessel segmentation
                                            %Nevermind-->Using data
                                            %uncoregistered to Timepoint 0-
                                            %as the geometry of the volume
                                            %is simpler (not rotated)%extra
                                            %steps
                                            load(ColormapDirectory)
                                            if glass_1_Tissue_2_both_3_contour==1
                                                %Raw OCTA used
                                                    BatchOfFolders{countBatchFolder,6}=fullfile(saveFolder{1},'RawVess_UnCoregTime0-_RotShift.mat');
                                                %Toward 3D mask
                                                    BatchOfFolders{countBatchFolder,7}=SaveFilenameDataCylindricalProj_UnCoregT0{1};
                                                    %pathBinarization=fullfile(saveFolder{1},'Binarization Manual');
                                                    BatchOfFolders{countBatchFolder,8}=fullfile(saveFolder{1},'Bin Manual','BinVess_UnCoregTime0-_RotShift.mat');%BinOCTAOutPut
                                                    pathBinarization=fullfile(saveFolder{1},'Bin Manual');
                                            elseif glass_1_Tissue_2_both_3_contour==2
                                                if OnlyTissueLabelTimepoint0==0 %if drawing it manually for each timepoint--worth saving tissue mask                                         
                                                    %Raw OCTA used
                                                        BatchOfFolders{countBatchFolder,6}=fullfile(saveFolder{2},'RawVess_CoregTime0-_NotInZ_TissueMaskApp.mat');% since will be using coreg to T0 to draw tissue mask
                                                    %Toward 3D mask
                                                        BatchOfFolders{countBatchFolder,7}=SaveFilenameDataUnlimited{2};%SaveFilenameDataUnlimited{2}; We do want coreg T0 because coreg T0 will assist in drawing of tissue mask ignore previous--> %use uncoregistered version for in case current method of co-registration to be updated
                                                        %pathBinarization=fullfile(saveFolder{2},'Binarization');
                                                        BatchOfFolders{countBatchFolder,8}=fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_NotInZ_TissueMaskApp.mat');
                                                        pathBinarization=fullfile(saveFolder{2},'Bin Manual');
                                                end
                                            elseif glass_1_Tissue_2_both_3_contour==3
                                                if OnlyTissueLabelTimepoint0==0 %if drawing it manually for each timepoint--worth saving tissue mask                                         
                                                    if (-1<DaysPrecise && DaysPrecise<=0)
                                                        %Raw OCTA used
                                                            BatchOfFolders{countBatchFolder,6}=fullfile(saveFolder{2},'RawVess_CoregTime0-_isT0_TissueMaskApp.mat')  
                                                            BatchOfFolders{countBatchFolder,8}=fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_isT0_TissueMaskApp.mat');
                                                    else
                                                        %Raw OCTA used
                                                            BatchOfFolders{countBatchFolder,6}=fullfile(saveFolder{2},'RawVess_CoregTime0-_CurrentTP_TissueMaskApp.mat')
                                                            BatchOfFolders{countBatchFolder,8}=fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_CurrentTP_TissueMaskApp.mat')
                                                    end
                                                        %Toward 3D mask
                                                            BatchOfFolders{countBatchFolder,7}=SaveFilenameDataUnlimited_UnCoregT0{2}; 
                                                            pathBinarization=fullfile(saveFolder{2},'Bin Manual');
                                                elseif OnlyTissueLabelTimepoint0==1
                                                    if (-1<DaysPrecise && DaysPrecise<=0)
                                                        %Raw OCTA used
                                                            BatchOfFolders{countBatchFolder,6}=fullfile(saveFolder{2},'RawVess_CoregTime0-_isT0_TissueMaskApp.mat')
                                                            BatchOfFolders{countBatchFolder,8}=fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_isT0_TissueMaskApp.mat');
                                                    else
                                                        %Raw OCTA used
                                                            BatchOfFolders{countBatchFolder,6}=fullfile(saveFolder{2},'RawVess_CoregTime0-_FromT0_TissueMaskApp.mat')
                                                            BatchOfFolders{countBatchFolder,8}=fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_FromT0_TissueMaskApp.mat');
                                                    end
                                                    %Toward 3D mask
                                                        BatchOfFolders{countBatchFolder,7}=SaveFilenameDataUnlimited{2};% only case when cortegistration necessary (otherwise mask cannot be applied)
                                                end
                                                pathBinarization=fullfile(saveFolder{2},'Bin Manual');
                                            end
                                                if ~exist(pathBinarization,'dir')
                                                    mkdir(pathBinarization)
                                                end
                                            RawOCTATemp=matfile(BatchOfFolders{countBatchFolder,6});%svOCTBin=matfile(BatchOfFolders{countBatchFolder,1});
                                                RawOCTAVarname=whos('-file',BatchOfFolders{countBatchFolder,6});
                                            mask_3DTemp=matfile(BatchOfFolders{countBatchFolder,7});%svOCTBin=matfile(BatchOfFolders{countBatchFolder,1});
                                                mask_3DVarname=whos('-file',BatchOfFolders{countBatchFolder,7});
                                            
                                %% Obtaining dimensions of file for image preparation    
                                    DimsData=size(RawOCTATemp.(RawOCTAVarname.name));
                                    
                                    if ~isempty(strfind(BatchOfFolders{countBatchFolder,1},'3x3mm'))
                                        width_xProcRange=linspace(0,3,DimsData(2));%size(RawOCTATemp.(RawOCTAVarname.name),2));
                                        width_yProcRange=linspace(0,3,DimsData(3));%size(RawOCTATemp.(RawOCTAVarname.name),3));
                                    elseif ~isempty(strfind(BatchOfFolders{countBatchFolder,1},'3x6mm'))
                                        width_xProcRange=linspace(0,3,DimsData(2));
                                        width_yProcRange=linspace(0,6,DimsData(3));
                                    elseif ~isempty(strfind(BatchOfFolders{countBatchFolder,1},'4x4mm'))
                                        width_xProcRange=linspace(0,4,DimsData(2));
                                        width_yProcRange=linspace(0,4,DimsData(3));
                                    elseif ~isempty(strfind(BatchOfFolders{countBatchFolder,1},'6x6mm'))
                                        width_xProcRange=linspace(0,6,DimsData(2));
                                        width_yProcRange=linspace(0,6,DimsData(3));
                                    elseif ~isempty(strfind(BatchOfFolders{countBatchFolder,1},'9x9mm'))
                                        width_xProcRange=linspace(0,9,DimsData(2));
                                        width_yProcRange=linspace(0,9,DimsData(3));
                                    else
                                        width_xProcRange=linspace(0,6,DimsData(2));
                                        width_yProcRange=linspace(0,6,DimsData(3));
                                    end
                                toc
                                        end

                                %% Manual vessel segmentation now if not performed apriori (step to perform coregistration to timepoint 0- would have to still be applied afterwards in this case)
                                if BinarizeVesselsNOW_0_no_1_manual_2_automatic==1
                                    %% Run VTD Processing Code (Valentin code) + otsu thresholding in depth
                                        % Step 1: Morphological processing (open/close + median
                                        % filter)--Usually no need to change  --also implemented in Step 4
                                        % (2nd median filter)
                                            num_rounds = 1; %CHANGE THIS--Less common
                                            opening_closing_parameter = 15; %CHANGE THIS--Less common (15)
                                            median_filtering_parameter = 2; %CHANGE THIS--Less common (2)
                                        % Step 2: Hard thresholding --Not so sure about keeping this (can be
                                        % made linear as a function of depth)
                                            thresh_superficial = 2500; %CHANGE THIS
                                            thresh_deep = 2000; %Minimum threshold level %CHANGE THIS
                                        % Step 3: Deshadowing
                                            deshadowing_para = 15; % CHANGE THIS % Decrease this number to increase the strength of deshadowing (15-17)
                                        % Step 4: 2nd median filter
                                        % Step 5: Binarization as a function of depth via Otsu's method
                                        % Step 6: Removal of small artifacts
                                            volumeThreshold = 1000; % CHANGE THIS (or set to zero)
                                            
                                    %VTD_processed = VTD_ProcessingWithVisualization(svOCT.sv3D_uint16.*mask_3D_compressedTop,[0 0 0 0 0 0 0]);%VTD_Processing(raw_data);%does not use incorrect approximation of axial resolution except for VVD calculation
                                    %no change of dimensions since only temporary resizing just to help
                                    %with various post-processing without rounding errors
                                if ProcessFullFOV_0_no_1_yes==1 %|| ProcessFullFOV_0_no_1_yes==2 
                                    %% Segmentation functions on full vasculature data in entire FOV
%                                         vessels_processed_binaryWithoutTransverseLimits=ManualVesselBinarizer(RawOCTATemp.(RawOCTAVarname.name),num_rounds,...
%                                         opening_closing_parameter,median_filtering_parameter, thresh_superficial,...
%                                         thresh_deep,deshadowing_para,volumeThreshold);
                                            %% Denoising ----------------------------------------   
                                                % num_rounds = 1; %CHANGE THIS
                                                % opening_closing_parameter = 15; %CHANGE THIS
                                                % median_filtering_parameter = 2; %CHANGE THIS
                                                % % I found that the above numbers work well for almost all OCT volumes so
                                                % % try adjusting some of the other paremters first.
                                                VTD_1 = RawOCTATemp.(RawOCTAVarname.name);

                                                for roundOfFilter = 1:1:num_rounds

                                                    % Morphological Processing - Morphological Opening/Closing
                                                    VTD_top_hat=zeros(size(VTD_1,1),size(VTD_1,2),size(VTD_1,3));
                                                    for o=1:size(VTD_1,3)
                                                        s = imtophat(VTD_1(:,:,o),strel('disk',opening_closing_parameter));
                                                        k=imtophat(VTD_1(:,:,o),strel('disk',1));
                                                        B_scan_dn=s-k;
                                                        VTD_top_hat(:,:,o)=B_scan_dn(:,:);
                                                        clc; display(['Morphological opening/closing, frame  ' num2str(o)]);
                                                    end
                                                    %Noresizing from raw (z,x,y) 500,1152,1200 
                                                    % Morphological Processing - Median Filter
                                                    VTD_median=zeros(size(VTD_top_hat,1),size(VTD_top_hat,2),size(VTD_top_hat,3));
                                                    for w=1:size(VTD_top_hat,2)
                                                        ST=squeeze(VTD_top_hat(:,w,:));
                                                        STT_temp=medfilt2(ST,[median_filtering_parameter median_filtering_parameter]);
                                                        VTD_median(:,w,:)=STT_temp(:,:);
                                                        clc; display(['Median filtering, frame  ' num2str(w)]);
                                                    end
                                                    %No resizing from raw (z,x,y) 500,1152,1200 
                                                    VTD_1 = VTD_median;

                                                end

                                                VTD_median = VTD_1;

                                                figure, imshow3D(cat(2,RawOCTATemp.(RawOCTAVarname.name),VTD_median))
                                                figure, imshow3D(cat(2,shiftdim(RawOCTATemp.(RawOCTAVarname.name),1),shiftdim(VTD_median,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                fprintf('Step 1 complete\n')
                                                %% Hard Thresholding ----------------------------------------

                                                close all
%                                                 clearvars VTD_1

                                                % thresh_superficial = 1000; %CHANGE THIS
                                                % thresh_deep = 1000; %Minimum threshold level %CHANGE THIS

                                                VTD_thresh = zeros(size(VTD_median,1),size(VTD_median,2),size(VTD_median,3));

                                                r=flip(1*linspace(thresh_deep,thresh_superficial,size(VTD_median,1)));% Threshold as a function of depth

                                                for u=1:size(VTD_median,1)
                                                 ST=squeeze(VTD_median(u,:,:));
                                                 ST(ST<r(u))=0;
                                                 VTD_thresh(u,:,:)=ST(:,:);
                                                 clc; display(['Applying depth-decaying threshold, depth  ' num2str(u)]);
                                                end

                                                figure, imshow3D(cat(2,VTD_median,VTD_thresh))
                                                figure, imshow3D(cat(2,shiftdim(VTD_median,1),shiftdim(VTD_thresh,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                %No resizing from raw (z,x,y) 500,1152,1200 

%                                                 figure, plot(r)
%                                                 hold on
%                                                 xlabel('depth','fontsize',15)
%                                                 ylabel('threshold','fontsize',15)

                                                %% Step down exponential filter for deshadowing ------------------------

                                                % deshadowing_para = 17; % CHANGE THIS % Decrease this number to increase the strength of deshadowing 

                                                close all
%                                                 clearvars VTD_median

                                                Depth=size(VTD_thresh,1);
                                                VTD_deshadowed=zeros(size(VTD_thresh,1),size(VTD_thresh,2),size(VTD_thresh,3));
                                                parfor i=1:size(VTD_deshadowed,3)
                                                B=VTD_thresh(:,:,i); 
                                                [ D ] = deshadowing_functionv2( B, Depth , deshadowing_para);
                                                VTD_deshadowed(:,:,i)=D;
                                                display(['De-shadowing, frame  ' num2str(i)]);
                                                end

                                                figure, imshow3D(cat(2,VTD_thresh,VTD_deshadowed))
                                                figure, imshow3D(cat(2,shiftdim(VTD_thresh,1),shiftdim(VTD_deshadowed,1)))
                                                
                                                fprintf('Step 3 complete\n')
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                %% Second Morphological Processing --------------------------------------

%                                                 clearvars VTD_thresh
                                                VTD_1 = VTD_deshadowed;
                                                % Morfological Processing - Morphological Opening/Closing
                                                VTD_top_hat=zeros(size(VTD_1,1),size(VTD_1,2),size(VTD_1,3));
                                                for o=1:size(VTD_1,3)
                                                    s = imtophat(VTD_1(:,:,o),strel('disk',opening_closing_parameter));
                                                    k=imtophat(VTD_1(:,:,o),strel('disk',1));
                                                    B_scan_dn=s-k;
                                                    VTD_top_hat(:,:,o)=B_scan_dn(:,:);
                                                    clc; display(['Morphological opening/closing, frame  ' num2str(o)]);
                                                end

%                                                 clearvars VTD_1
                                                % Morfological Processing - Median Filter
                                                VTD_median_2=zeros(size(VTD_top_hat,1),size(VTD_top_hat,2),size(VTD_top_hat,3));
                                                for w=1:size(VTD_top_hat,2)
                                                    ST=squeeze(VTD_top_hat(:,w,:));
                                                    STT_temp=medfilt2(ST,[median_filtering_parameter median_filtering_parameter]);
                                                    VTD_median_2(:,w,:)=STT_temp(:,:);
                                                    clc; display(['Median filtering, frame  ' num2str(w)]);
                                                end
                                                figure, imshow3D(cat(2,VTD_deshadowed,VTD_median_2))
                                                figure, imshow3D(cat(2,shiftdim(VTD_deshadowed,1),shiftdim(VTD_median_2,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                % VTD_median_2 = VTD_deshadowed; % If this step is to be skipped
%                                                 clearvars VTD_top_hat
                                                %% Otsu's thresholding --------------------------------------------------

                                                close all

                                                vessels_processed_binaryWithoutTransverseLimits = zeros(size(VTD_median_2,1),size(VTD_median_2,2),size(VTD_median_2,3));
                                                for o=1:size(vessels_processed_binaryWithoutTransverseLimits,1)
                                                    temp_2D = squeeze(VTD_median_2(o,:,:));
                                                    temp_2D = temp_2D./max(temp_2D(:));
                                                    vessels_processed_binaryWithoutTransverseLimits(o,:,:)=imbinarize(temp_2D);
                                                %     VTD_binarized(o,:,:)= thresholdLocally(temp_2D);
                                                    clc; display(['Segmenting, depth  ' num2str(o)]);
                                                end
%                                                 clearvars VTD_median_2
                                                % Remove small connected components

                                                % volumeThreshold = 100; % CHANGE THIS (or set to zero)

                                                %Remove Components:

                                                vessels_processed_binaryWithoutTransverseLimits = RemoveComponents(vessels_processed_binaryWithoutTransverseLimits, volumeThreshold, false, false);

                                                vessels_processed_binaryWithoutTransverseLimits = imbinarize(vessels_processed_binaryWithoutTransverseLimits);

                                                figure, imshow3D(cat(2,VTD_deshadowed./max(VTD_deshadowed(:)),vessels_processed_binaryWithoutTransverseLimits))
                                                figure, imshow3D(cat(2,shiftdim(VTD_deshadowed./max(VTD_deshadowed(:)),1),shiftdim(vessels_processed_binaryWithoutTransverseLimits,1)))
                                                fprintf('Step 6 complete\n')
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                               % clearvars VTD_deshadowed
                                    %% Saving created vasculature maps 
                                        save([fullfile(pathBinarization,['vessels_processed_binaryWithoutTransverseLimits.mat'])],'vessels_processed_binaryWithoutTransverseLimits','-mat','-v7.3')
                                    %% Colour depth encoded processed and binarized volume
                                        %% Full transverse
                                            saveFolderAndNameWithoutTransverseLimits=fullfile(pathBinarization,'DepthEncoded Post-processedVasculature map_Full');
                                                colourDepthEncodev4(vessels_processed_binaryWithoutTransverseLimits(1:round(1000/(umPerPix_For200PixDepthInTissue*200/size(vessels_processed_binaryWithoutTransverseLimits,1))),:,:),width_xProcRange,width_yProcRange,saveFolderAndNameWithoutTransverseLimits,umPerPix_For200PixDepthInTissue*200/size(vessels_processed_binaryWithoutTransverseLimits,1),cmap2);
                                                toc
                                %% Applying lateral mask
%                                     vessels_processed_binary=vessels_processed_binaryWithoutTransverseLimits.*logical(mask_3DTemp.(mask_3DVarname.name));
%                                     save(BatchOfFolders{countBatchFolder,8},'vessels_processed_binary','-mat','-v7.3')
%                                         saveFolderAndNameWithTransverseLimits=fullfile(pathBinarization,'DepthEncoded Post-processedVasculature map_OnlyVOI.png');    
%                                         colourDepthEncodev3(vessels_processed_binary,width_xProcRange,width_yProcRange,saveFolderAndNameWithTransverseLimits,umPerPix_For200PixDepthInAir*200/size(vessels_processed_binary,1));
%                                 
                                        clearvars vessels_processed_binaryWithoutTransverseLimits
                                    toc
                                end
                                %%
                                if ProcessFullFOV_0_no_1_yes==0 || ProcessFullFOV_0_no_1_yes==1 %If doing both maybe can apply lateral mask separately? Or not because of median filters around edges
                                    %% Segmentation functions on full vasculature data in entire FOV
%                                         vessels_processed_binary=ManualVesselBinarizer(RawOCTATemp.(RawOCTAVarname.name).*logical(mask_3DTemp.(mask_3DVarname.name)),num_rounds,...
%                                         opening_closing_parameter,median_filtering_parameter, thresh_superficial,...
%                                         thresh_deep,deshadowing_para,volumeThreshold);
                                            %% Denoising ----------------------------------------   
                                                % num_rounds = 1; %CHANGE THIS
                                                % opening_closing_parameter = 15; %CHANGE THIS
                                                % median_filtering_parameter = 2; %CHANGE THIS
                                                % % I found that the above numbers work well for almost all OCT volumes so
                                                % % try adjusting some of the other paremters first.
                                                VTD_1 = RawOCTATemp.(RawOCTAVarname.name).*logical(mask_3DTemp.(mask_3DVarname.name));

                                                for roundOfFilter = 1:1:num_rounds

                                                    % Morphological Processing - Morphological Opening/Closing
                                                    VTD_top_hat=zeros(size(VTD_1,1),size(VTD_1,2),size(VTD_1,3));
                                                    for o=1:size(VTD_1,3)
                                                        s = imtophat(VTD_1(:,:,o),strel('disk',opening_closing_parameter));
                                                        k=imtophat(VTD_1(:,:,o),strel('disk',1));
                                                        B_scan_dn=s-k;
                                                        VTD_top_hat(:,:,o)=B_scan_dn(:,:);
                                                        clc; display(['Morphological opening/closing, frame  ' num2str(o)]);
                                                    end
                                                    %Noresizing from raw (z,x,y) 500,1152,1200 
                                                    % Morphological Processing - Median Filter
                                                    VTD_median=zeros(size(VTD_top_hat,1),size(VTD_top_hat,2),size(VTD_top_hat,3));
                                                    for w=1:size(VTD_top_hat,2)
                                                        ST=squeeze(VTD_top_hat(:,w,:));
                                                        STT_temp=medfilt2(ST,[median_filtering_parameter median_filtering_parameter]);
                                                        VTD_median(:,w,:)=STT_temp(:,:);
                                                        clc; display(['Median filtering, frame  ' num2str(w)]);
                                                    end
                                                    %No resizing from raw (z,x,y) 500,1152,1200 
                                                    VTD_1 = VTD_median;

                                                end

                                                VTD_median = VTD_1;

                                                figure, imshow3D(cat(2,RawOCTATemp.(RawOCTAVarname.name),VTD_median))
                                                figure, imshow3D(cat(2,shiftdim(RawOCTATemp.(RawOCTAVarname.name),1),shiftdim(VTD_median,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                fprintf('Step 1 complete\n')
                                                %% Hard Thresholding ----------------------------------------

                                                close all
%                                                 clearvars VTD_1

                                                % thresh_superficial = 1000; %CHANGE THIS
                                                % thresh_deep = 1000; %Minimum threshold level %CHANGE THIS

                                                VTD_thresh = zeros(size(VTD_median,1),size(VTD_median,2),size(VTD_median,3));

                                                r=flip(1*linspace(thresh_deep,thresh_superficial,size(VTD_median,1)));% Threshold as a function of depth

                                                for u=1:size(VTD_median,1)
                                                 ST=squeeze(VTD_median(u,:,:));
                                                 ST(ST<r(u))=0;
                                                 VTD_thresh(u,:,:)=ST(:,:);
                                                 clc; display(['Applying depth-decaying threshold, depth  ' num2str(u)]);
                                                end

                                                figure, imshow3D(cat(2,VTD_median,VTD_thresh))
                                                figure, imshow3D(cat(2,shiftdim(VTD_median,1),shiftdim(VTD_thresh,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                %No resizing from raw (z,x,y) 500,1152,1200 

                                                figure, plot(r)
                                                hold on
                                                xlabel('depth','fontsize',15)
                                                ylabel('threshold','fontsize',15)

                                                %% Step down exponential filter for deshadowing ------------------------

                                                % deshadowing_para = 17; % CHANGE THIS % Decrease this number to increase the strength of deshadowing 

                                                close all
%                                                 clearvars VTD_median

                                                Depth=size(VTD_thresh,1);
                                                VTD_deshadowed=zeros(size(VTD_thresh,1),size(VTD_thresh,2),size(VTD_thresh,3));
                                                parfor i=1:size(VTD_deshadowed,3)
                                                B=VTD_thresh(:,:,i); 
                                                [ D ] = deshadowing_functionv2( B, Depth , deshadowing_para);
                                                VTD_deshadowed(:,:,i)=D;
                                                display(['De-shadowing, frame  ' num2str(i)]);
                                                end

                                                figure, imshow3D(cat(2,VTD_thresh,VTD_deshadowed))
                                                figure, imshow3D(cat(2,shiftdim(VTD_thresh,1),shiftdim(VTD_deshadowed,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                fprintf('Step 3 complete\n')

                                                %% Second Morphological Processing --------------------------------------

%                                                 clearvars VTD_thresh
                                                VTD_1 = VTD_deshadowed;
                                                % Morfological Processing - Morphological Opening/Closing
                                                VTD_top_hat=zeros(size(VTD_1,1),size(VTD_1,2),size(VTD_1,3));
                                                for o=1:size(VTD_1,3)
                                                    s = imtophat(VTD_1(:,:,o),strel('disk',opening_closing_parameter));
                                                    k=imtophat(VTD_1(:,:,o),strel('disk',1));
                                                    B_scan_dn=s-k;
                                                    VTD_top_hat(:,:,o)=B_scan_dn(:,:);
                                                    clc; display(['Morphological opening/closing, frame  ' num2str(o)]);
                                                end

%                                                 clearvars VTD_1
                                                % Morfological Processing - Median Filter
                                                VTD_median_2=zeros(size(VTD_top_hat,1),size(VTD_top_hat,2),size(VTD_top_hat,3));
                                                for w=1:size(VTD_top_hat,2)
                                                    ST=squeeze(VTD_top_hat(:,w,:));
                                                    STT_temp=medfilt2(ST,[median_filtering_parameter median_filtering_parameter]);
                                                    VTD_median_2(:,w,:)=STT_temp(:,:);
                                                    clc; display(['Median filtering, frame  ' num2str(w)]);
                                                end
                                                figure, imshow3D(cat(2,VTD_deshadowed,VTD_median_2))
                                                figure, imshow3D(cat(2,shiftdim(VTD_deshadowed,1),shiftdim(VTD_median_2,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                % VTD_median_2 = VTD_deshadowed; % If this step is to be skipped
%                                                 clearvars VTD_top_hat
                                                %% Otsu's thresholding --------------------------------------------------

                                                close all

                                                vessels_processed_binaryWithinMask = zeros(size(VTD_median_2,1),size(VTD_median_2,2),size(VTD_median_2,3));
                                                for o=1:size(vessels_processed_binaryWithinMask,1)
                                                    temp_2D = squeeze(VTD_median_2(o,:,:));
                                                    temp_2D = temp_2D./max(temp_2D(:));
                                                    vessels_processed_binaryWithinMask(o,:,:)=imbinarize(temp_2D);
                                                %     VTD_binarized(o,:,:)= thresholdLocally(temp_2D);
                                                    clc; display(['Segmenting, depth  ' num2str(o)]);
                                                end
%                                                 clearvars VTD_median_2
                                                % Remove small connected components

                                                % volumeThreshold = 100; % CHANGE THIS (or set to zero)

                                                %Remove Components:

                                                vessels_processed_binaryWithinMask = RemoveComponents(vessels_processed_binaryWithinMask, volumeThreshold, false, false);

                                                vessels_processed_binaryWithinMask = imbinarize(vessels_processed_binaryWithinMask);

                                                figure, imshow3D(cat(2,VTD_deshadowed./max(VTD_deshadowed(:)),vessels_processed_binaryWithinMask))
                                                figure, imshow3D(cat(2,shiftdim(VTD_deshadowed./max(VTD_deshadowed(:)),1),shiftdim(vessels_processed_binaryWithinMask,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                fprintf('Step 6 complete\n')
%                                                 clearvars VTD_deshadowed 
figure, imshow3D(cat(2,RawOCTATemp.(RawOCTAVarname.name),RawOCTATemp.(RawOCTAVarname.name).*~vessels_processed_binaryWithinMask))
figure, imshow3D(cat(2,shiftdim(RawOCTATemp.(RawOCTAVarname.name),1),shiftdim(RawOCTATemp.(RawOCTAVarname.name).*~vessels_processed_binaryWithinMask,1)))
if CheckIntermediates==1
                                                    pause =1;
                                                end
                                    %% Saving created vasculature maps 
                                    %[fullfile(pathBinarization,['vessels_processed_binary.mat'])]
                                        save(BatchOfFolders{countBatchFolder,8},'vessels_processed_binaryWithinMask','-mat','-v7.3')
                                        %% within lateral tumour mask saving will come next since it is common to both 
                                end
                                %% Visualizing all results
                                %% Raw
                                projection=squeeze(sum(cast(RawOCTATemp.(RawOCTAVarname.name),'double')));
                                set(figure,'Position',[100,100,800,600],'visible','on');
                                fs=70;  
                                imagesc(width_xProcRange,width_yProcRange,sqrt(projection),[766 1600]);
                                colormap 'hot'; 
                                title('Raw OCTA vasculature map (en-face)','FontWeight','Bold','FontSize',fs); 
                                xlabel('Width_x (mm)','FontWeight','Bold','FontSize',fs);
                                ylabel('Width_y (mm)','FontWeight','Bold','FontSize',fs);
                                axis tight; set(gca,'FontWeight','Bold','FontSize',fs-1);
                                set(gcf,'PaperUnits','inches','PaperPosition',[0 0 26 23])
                                  saveas(gcf,[pathBinarization '/RawsvOCTVasculature map.png'],'png')%visually assessing difference %we may look into the pseudo
                                toc
                                %% Processed
                                projection=squeeze(sum(cast(vessels_processed_binaryWithinMask(:,:,:),'double'),1));%(flipud(imrotate(squeeze(sum(cast(vessels_processed(:,:,:),'double'),1)),-90)));
                                set(figure,'Position',[100,100,800,600],'visible','on');
                                fs=70;  
                                imagesc(width_xProcRange,width_yProcRange,sqrt(projection))%,[0 1]);
                                colormap 'hot'; 
                                title('Post-processed OCT vasculature map (en-face)','FontWeight','Bold','FontSize',fs); 
                                xlabel('Width_x (mm)','FontWeight','Bold','FontSize',fs);
                                ylabel('Width_y (mm)','FontWeight','Bold','FontSize',fs);
                                axis tight; set(gca,'FontWeight','Bold','FontSize',fs-1);
                                set(gcf,'PaperUnits','inches','PaperPosition',[0 0 26 23])
                                 saveas(gcf,fullfile(pathBinarization,'Post-processedVasculature map.png'),'png')%[SaveLocation '/Post-processedVasculature map.png'],'png')
                                %% Colour depth encoded processed and binarized volume
                                %% ROI restricted transverse
                                saveFolderAndNameWithTransverseLimits=fullfile(pathBinarization,'DepthEncoded Post-processedVasculature map_OnlyVOI');    
                                    colourDepthEncodev4(vessels_processed_binaryWithinMask(1:round(1000/(umPerPix_For200PixDepthInTissue*200/size(vessels_processed_binaryWithinMask,1))),:,:),width_xProcRange,width_yProcRange,saveFolderAndNameWithTransverseLimits,umPerPix_For200PixDepthInTissue*200/size(vessels_processed_binaryWithinMask,1),cmap2);%DepthEncodedImWithTransverseLimits= colourDepthEncodev3(vessels_processed_binaryWithinMask,width_xProcRange,width_yProcRange,saveFolderAndNameWithTransverseLimits,umPerPix_For200PixDepthInAir*200/size(vessels_processed_binaryWithinMask,1));
                                    toc
                                elseif BinarizeVesselsNOW_0_no_1_manual_2_automatic==2
                                    %To be continued hopefully soon
                                end
                                                
                                
%% Applying previously determined coregistration operations
%Nevermind (only to do if notice that raw vasculature rotated causes
%memory issues for binarization (so perform operations on non-co-registered
%data then later co-register according to previously saved operations.
            end
end
                end
            end
            %% Next iteration of file selection
                countBatchFolder=countBatchFolder+1;
        FileSelectDirectory=fileparts(pathOCTVesRaw);
        BatchOfFolders{countBatchFolder,1}={};  
    end
%% Searching through folders automatically and semi-automatically for files
%% %%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif ManualSelFew_0_OR_SemiAutomatic_2_OR_FullAutomatic_3==2 || ManualSelFew_0_OR_SemiAutomatic_2_OR_FullAutomatic_3==3
    countBatchFolder=0;
    BatchOfFolders=cell([],5);
    %% raw OCTA auto selection
        for ind=1:length(allMice)
            FoundRawOCTA=0;
            for trialOCTARaw=1:length(RawVasculatureFileKeywordRaw)
                if contains(allMice(ind).name,RawVasculatureFileKeywordRaw{trialOCTARaw}) && ~contains(allMice(ind).folder,'Old') && ~contains(allMice(ind).folder,'old') && ~contains(allMice(ind).folder,'Quick') && ~contains(allMice(ind).folder,'quick') && contains(allMice(ind).folder,'Improved') && ~contains(allMice(ind).folder,'TumourDepth') && ~contains(allMice(ind).folder,'Backside')%'Raw_OCT_Volume') % ~isempty(strfind(all(ind).name,'Raw_OCT_Volume'))
                    pathOCTVesRaw=allMice(ind).folder;
                    filenameOCTVesRaw=allMice(ind).name;
                        FolderStructAndRawOCTA=fileparts(pathOCTVesRaw);
                       NameTimepointComboTemp=strsplit(pathOCTVesRaw,'\');%fileparts(fileparts(fileparts(pathOCTVesRaw)));
                        FolderConsidered=fullfile(NameTimepointComboTemp{1:4});
                        if contains(FolderStructAndRawOCTA,'pre')
                            TumourMaskAndStepsDir=fullfile(FolderConsidered,'Segmentation_TumourMaskCreation2D-3D','pre',NameTimepointComboTemp{end-1});
                        elseif contains(FolderStructAndRawOCTA,'post')
                            TumourMaskAndStepsDir=fullfile(FolderConsidered,'Segmentation_TumourMaskCreation2D-3D','post',NameTimepointComboTemp{end-1});
                        else
                            TumourMaskAndStepsDir=fullfile(FolderConsidered,'Segmentation_TumourMaskCreation2D-3D',NameTimepointComboTemp{end-1});
                        end
                                if ~exist(TumourMaskAndStepsDir,'dir')
                                    mkdir(TumourMaskAndStepsDir);
                                end
                        saveFolder=fullfile(TumourMaskAndStepsDir,MaskCreationFolder);

                            NameDayFormat=fullfile(NameTimepointComboTemp{3},NameTimepointComboTemp{4});%varies in depth if pre and post image%NameDayFormat=fullfile(NameTimepointComboTemp{end-4},NameTimepointComboTemp{end-3});
                            NameTimepointCombo=strsplit(NameTimepointComboTemp{end},'_');
                                MouseName=NameTimepointCombo{1};
                                Timepoint=NameTimepointCombo{2};
                                    TimepointVarNameDraft=strsplit(strrep(Timepoint,'-',''),' ');
                                    TimeDraft=strsplit(TimepointVarNameDraft{2},',');%,{'h';'m'})
                                    Time=[TimeDraft{1} 'h' TimeDraft{2} 'm' TimeDraft{3} 's'];%strrep(Timepoint,',',{'h';'m'})
                                    TimepointVarName{1}=['Day' TimepointVarNameDraft{1}]; 
                                    TimepointVarName{2}=['Time' Time];
%                                 MouseNameTimepoint=[MouseName,' ',Timepoint];
                        %% Timepoint calculation
                                %TimepointDataFolder=fileparts(fileparts(fileparts(fileparts(fileparts(BatchOfFolders{countBatchFolder,2})))))

                                [TimeElapsed, MouseName,Timepoint,InitialTimepointtxtFile]=CalcTimePostRTx(TumourMaskAndStepsDir, DirectoryVesselsData);
                                      for iii=1:length(DirectoryInitialTimepoints)
                                            if contains(DirectoryInitialTimepoints{iii},MouseName)
                                                IndexMouse=iii;
                                            end
                                      end
                                  DaysRounded=TimeElapsed.RelImgTimepointDaysRounded;
                                  DaysPrecise=TimeElapsed.RelImgTimepointDaysPrecise;%to convert into days with fraction
                                        if contains(FolderStructAndRawOCTA,'pre')
                                           MouseNameTimepoint=[MouseName sprintf('_{%dd pre}',DaysRounded)];% 'd_pre'];
                                        elseif contains(FolderStructAndRawOCTA,'post') 
                                           MouseNameTimepoint=[MouseName sprintf('_{%dd post}',DaysRounded)]; %'_{post}'];
                                        else
                                           MouseNameTimepoint=[MouseName sprintf('_{%dd}',DaysRounded)]; 
                                        end                                
                                
        %% Files checked to see if already processed 
%         if glass_1_Tissue_2_both_3_contour==1
%             glass_1_Tissue_2_contour={1,0}
%         elseif glass_1_Tissue_2_both_3_contour==2
%             glass_1_Tissue_2_contour={0,2}
%         elseif glass_1_Tissue_2_both_3_contour==3
%             glass_1_Tissue_2_contour={1,2}
%         end
%Initialization otherwise gets stuck when notices no second column to cell
%variables!
MaskCreationDraft=cell(2,1);
saveContour=cell(2,1);
SaveFilenameRawMaskApplied=cell(2,1);
SaveFilenameDataUnlimited_UnCoregT0=cell(2,1);
SaveFilenameDataCylindricalProj_UnCoregT0=cell(2,1);
SaveFilenameDataUnlimited=cell(2,1);
SaveFilenameDataCylindricalProj=cell(2,1);

            if glass_1_Tissue_2_both_3_contour==1 || glass_1_Tissue_2_both_3_contour==3              
                    MaskCreationDraft{1}=fullfile(saveFolder{1},['Glass removal intermediate steps']);%, replace(char(datetime),':','_')]);%careful if there is space after filename--not allowed in directory immediately before backslash                
                    mkdir(MaskCreationDraft{1});
                    saveContour{1}=fullfile(MaskCreationDraft{1},'zline_GlassBot_uncoregTime0-.mat');
                           % not done anymore
                           SaveFilenameRawMaskApplied{1}=fullfile(saveFolder{1},'RawVess_UnCoregTime0-_RotShift.mat');
                           SaveFilenameDataUnlimited_UnCoregT0{1}=[fullfile(saveFolder{1},[SaveFilenameUnrestricted{1} '_UnCoregT0.mat'])];
                           SaveFilenameDataCylindricalProj_UnCoregT0{1}=[fullfile(saveFolder{1},[SaveFilenameCylindricalProj '_UnCoregT0.mat'])];
                        if glass_1_Tissue_2_both_3_contour==1
                           if UnformatedDataSet==1
                               SaveFilenameDataUnlimited{1}=SaveFilenameDataUnlimited_UnCoregT0{1};
                               SaveFilenameDataCylindricalProj{1}=SaveFilenameDataCylindricalProj_UnCoregT0{1};
                           else
                               SaveFilenameDataUnlimited{1}=SaveFilenameDataUnlimited_UnCoregT0{1};
                               SaveFilenameDataCylindricalProj{1}=SaveFilenameDataCylindricalProj_UnCoregT0{1};
                               BinVasculatureFileKeyword={fullfile(saveFolder{1},'Bin Manual','BinVess_UnCoregTime0-_RotShift.mat')};
%                                SaveFilenameDataUnlimited{1}=[fullfile(saveFolder{1},[SaveFilenameUnrestricted{1} '.mat'])];
%                                SaveFilenameDataCylindricalProj{1}=[fullfile(saveFolder{1},[SaveFilenameCylindricalProj '.mat'])];
                           end
                        end
            end
            if glass_1_Tissue_2_both_3_contour==2 || glass_1_Tissue_2_both_3_contour==3   
                    MaskCreationDraft{2}=fullfile(saveFolder{2},['Tissue masking intermediate steps']);%, replace(char(datetime),':','_')]);%careful if there is space after filename--not allowed in directory immediately before backslash                
                    mkdir(MaskCreationDraft{2});
                    saveContour{2}=fullfile(MaskCreationDraft{2},'zline_TissueTop_uncoregTime0-.mat');
                        if -1<DaysPrecise && DaysPrecise<=0 %initial timepoint
                            if OnlyTissueLabelTimepoint0==0 %labelling each timepoint tissue  
                               SaveFilenameRawMaskApplied{2}=fullfile(saveFolder{2},'RawVess_CoregTime0-_isT0_TissueMaskApp.mat');
                               if glass_1_Tissue_2_both_3_contour==2 
                                    BinVasculatureFileKeyword={fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_NotInZ_TissueMaskApp.mat')};%BinVasculatureFileKeyword=fullfile(saveFolder{2
                               elseif glass_1_Tissue_2_both_3_contour==3
                                    BinVasculatureFileKeyword={fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_isT0_TissueMaskApp.mat')};
                               end
                            elseif OnlyTissueLabelTimepoint0==1 
                                if glass_1_Tissue_2_both_3_contour==3    
                                    SaveFilenameRawMaskApplied{2}=fullfile(saveFolder{2},'RawVess_CoregTime0-_isT0_TissueMaskApp.mat');
                                    BinVasculatureFileKeyword={fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_isT0_TissueMaskApp.mat')};
                                elseif glass_1_Tissue_2_both_3_contour==2    
                                    SaveFilenameRawMaskApplied{2}='';
                                    BinVasculatureFileKeyword={};% not worth doing if no coregistration in depth using glass
                                end
                            end
                           SaveFilenameDataUnlimited_UnCoregT0{2}=[fullfile(saveFolder{2},[SaveFilenameUnrestricted{2} '_isT0_UnCoregT0.mat'])];
                           SaveFilenameDataCylindricalProj_UnCoregT0{2}=[fullfile(saveFolder{2},[SaveFilenameCylindricalProj '_isT0_UnCoregT0.mat'])];
                           SaveFilenameDataUnlimited{2}=[fullfile(saveFolder{2},[SaveFilenameUnrestricted{2} '_isT0.mat'])];
                           SaveFilenameDataCylindricalProj{2}=[fullfile(saveFolder{2},[SaveFilenameCylindricalProj '_isT0.mat'])];
                        else %other timepoints (TPx)
                            if OnlyTissueLabelTimepoint0==0 %labelling each timepoint tissue   
                               SaveFilenameRawMaskApplied{2}=fullfile(saveFolder{2},'RawVess_CoregTime0-_CurrentTP_TissueMaskApp.mat');
                               SaveFilenameDataUnlimited_UnCoregT0{2}=[fullfile(saveFolder{2},[SaveFilenameUnrestricted{2} '_CurrentTP_UnCoregT0.mat'])];
                               SaveFilenameDataCylindricalProj_UnCoregT0{2}=[fullfile(saveFolder{2},[SaveFilenameCylindricalProj '_CurrentTP_UnCoregT0.mat'])];
                               SaveFilenameDataUnlimited{2}=[fullfile(saveFolder{2},[SaveFilenameUnrestricted{2} '_CurrentTP.mat'])];
                               SaveFilenameDataCylindricalProj{2}=[fullfile(saveFolder{2},[SaveFilenameCylindricalProj '_CurrentTP.mat'])];
                               if glass_1_Tissue_2_both_3_contour==2 
                                    BinVasculatureFileKeyword={fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_NotInZ_TissueMaskApp.mat')};%BinVasculatureFileKeyword=fullfile(saveFolder{2
                               elseif glass_1_Tissue_2_both_3_contour==3
                                    BinVasculatureFileKeyword={fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_CurrentTP_TissueMaskApp.mat')};
                               end
                            elseif OnlyTissueLabelTimepoint0==1 
                                if glass_1_Tissue_2_both_3_contour==3    
                                    SaveFilenameRawMaskApplied{2}=fullfile(saveFolder{2},'RawVess_CoregTime0-_FromT0_TissueMaskApp.mat');
                                    BinVasculatureFileKeyword={fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_FromT0_TissueMaskApp.mat')};
                                elseif glass_1_Tissue_2_both_3_contour==2    
                                    SaveFilenameRawMaskApplied{2}='';
                                    BinVasculatureFileKeyword={};
                               end
                               SaveFilenameDataUnlimited_UnCoregT0{2}=[fullfile(saveFolder{2},[SaveFilenameUnrestricted{2} '_FromT0_UnCoregT0.mat'])];
                               SaveFilenameDataCylindricalProj_UnCoregT0{2}=[fullfile(saveFolder{2},[SaveFilenameCylindricalProj '_FromT0_UnCoregT0.mat'])];
                               SaveFilenameDataUnlimited{2}=[fullfile(saveFolder{2},[SaveFilenameUnrestricted{2} '_FromT0.mat'])];
                               SaveFilenameDataCylindricalProj{2}=[fullfile(saveFolder{2},[SaveFilenameCylindricalProj '_FromT0.mat'])];
                            end
                        end
            end

%% Now checking if files already exist (alternatively skips)                           
%if ~exist(savebotContour) && (Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1)% || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2)
MissingFilesForAutomation= (Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1) && ((glass_1_Tissue_2_both_3_contour==1 && ~exist(saveContour{1})) || (glass_1_Tissue_2_both_3_contour==2 && ~exist(saveContour{2})) || (glass_1_Tissue_2_both_3_contour==3 && ~exist(saveContour{1}) && ~exist(saveContour{2})))
if MissingFilesForAutomation==1
    fprintf('Missing 2D contours (tissue or glass mode according to setting), skipping\n')
    continue
else                           
                   AlreadyCompletedJustContouring= ((glass_1_Tissue_2_both_3_contour==1 && exist(saveContour{1})) || (glass_1_Tissue_2_both_3_contour==2 && exist(saveContour{2})) || (glass_1_Tissue_2_both_3_contour==3 && exist(saveContour{1}) && exist(saveContour{2}))) 
                   AlreadyCompletedMaskCreation=((glass_1_Tissue_2_both_3_contour==1 && exist(SaveFilenameDataUnlimited_UnCoregT0{1})) || (glass_1_Tissue_2_both_3_contour==2 && exist(SaveFilenameDataUnlimited{2})) || (glass_1_Tissue_2_both_3_contour==3 && exist(SaveFilenameDataUnlimited{2}))) %&& exist(SaveFilenameDataUnlimited{1})
        %% Binarization already performed? (whether or not stated BinVesselsAlreadyPrepared==1)
                        AllInFolderRawOCTAConsidered=dir(fullfile(pathOCTVesRaw ,'**'));
                           FoundBinOCTA=0;
                                for cc=1:length(AllInFolderRawOCTAConsidered)%AllInFolderConsidered)
                                    for trialOCTBin=1:length(BinVasculatureFileKeyword)
                                            if (contains(AllInFolderRawOCTAConsidered(cc).name,BinVasculatureFileKeyword{trialOCTBin}) && ~isequal(AllInFolderRawOCTAConsidered(cc).name,'.'))
                                                pathOCTVesBin=AllInFolderRawOCTAConsidered(cc).folder;
                                                filenameOCTVesBin=AllInFolderRawOCTAConsidered(cc).name;    
                                                FoundBinOCTA=1;
                                            break;
                                            end
                                    end
                                    if FoundBinOCTA==1
                                           break
                                    end
                                end
                                        AlreadyCompletedBinarizationIfapplicable=BinarizeVesselsNOW_0_no_1_manual_2_automatic==0|| (FoundBinOCTA && (BinarizeVesselsNOW_0_no_1_manual_2_automatic==1 || BinarizeVesselsNOW_0_no_1_manual_2_automatic==2))
                    %% Final check to determine whether should procede with processing
                        if  (AlreadyCompletedJustContouring && Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==0)|| (AlreadyCompletedMaskCreation && (Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2))&& AlreadyCompletedBinarizationIfapplicable% && exist(fullfile(saveFolder,'CheckedOrientationsL12.txt'))%exist(fullfile(saveFolder,'CheckedOrientations.txt'))
                           fprintf('Already completed\n')
                           continue %skip this iteration of for loop and go to next iteration since already done previously                           
                       else %elseif~exist(fullfile(saveFolder,'CheckedOrientationsL11.txt'))%elseif ~exist(SaveFilenameDataUnlimited) && ~exist(fullfile(saveFolder,'CheckedOrientations.txt')) 
                           %% Analysis Folder creation
                                for i=1:length(saveFolder)
                                    if ~exist(saveFolder{i},'dir')
                                        mkdir(saveFolder{i});
                                    end
                                end
                    countBatchFolder=countBatchFolder+1;
                    AllInFolderConsidered=dir(fullfile(FolderStructAndRawOCTA ,'**'));
                    %Fileparts=strsplit(FolderConsidered,'\');
                    BatchOfFolders{countBatchFolder,1}=fullfile(pathOCTVesRaw,filenameOCTVesRaw); %OCT file found and recorded

                    FoundRawOCTA=1;
                        %% Which Mouse timepoint 0 file to refer to? and index
                                    TimepointTrueAndRel=sprintf('%s_%.1fd',Timepoint,TimeElapsed.RelImgTimepointDaysPrecise);

                        if ~(-1<DaysPrecise && DaysPrecise<=0)
                            try
% GoodFile=inputgl('Shall we continue trying to process this file?');
                        if glass_1_Tissue_2_both_3_contour==1 || glass_1_Tissue_2_both_3_contour==3
                                        [SegmentationFolderTimepoint0Temp{1},IndexMouse]=findSegmentationtimepoint0_Folderv2(MouseName,Timepoint,BatchOfFolders,countBatchFolder,DirectoryInitialTimepoints,InitialTimepointtxtFile,DirectoriesBareSkinMiceKeyword,saveContour{1},MaskCreationFolder{1});%SaveFilenameRawMaskApplied--not necessarily already done
                                if ~contains(SegmentationFolderTimepoint0Temp{1},'Manual_With_WO_Glass2')%the case when you are just starting timepoint 0- processing)
                                    SegmentationFolderTimepoint0{1}=fullfile(SegmentationFolderTimepoint0Temp{1},'Manual_With_WO_Glass2');
                                else
                                    SegmentationFolderTimepoint0{1}=SegmentationFolderTimepoint0Temp{1};
                                end
                        end
                        if glass_1_Tissue_2_both_3_contour==2 || glass_1_Tissue_2_both_3_contour==3
                                        [SegmentationFolderTimepoint0Temp{2},IndexMouse]=findSegmentationtimepoint0_Folderv2(MouseName,Timepoint,BatchOfFolders,countBatchFolder,DirectoryInitialTimepoints,InitialTimepointtxtFile,DirectoriesBareSkinMiceKeyword,saveContour{2},MaskCreationFolder{2});%SaveFilenameRawMaskApplied--not necessarily already done
                                if ~contains(SegmentationFolderTimepoint0Temp{2},'Manual_OnlyTissue')%the case when you are just starting timepoint 0- processing)
                                    SegmentationFolderTimepoint0{2}=fullfile(SegmentationFolderTimepoint0Temp{2},'Manual_OnlyTissue');
                                else
                                    SegmentationFolderTimepoint0{2}=SegmentationFolderTimepoint0Temp{2};
                                end
                        end
                            catch
                                fprintf('Timepoint0- file for requested segmentation style not yet performed. Skipping\n')
                                continue
                            end
                       else%Day 0 pre
                           if glass_1_Tissue_2_both_3_contour==1 || glass_1_Tissue_2_both_3_contour==3
                                SegmentationFolderTimepoint0{1}=fullfile(fileparts(InitialTimepointtxtFile),'Manual_With_WO_Glass2');
                           end
                           if glass_1_Tissue_2_both_3_contour==2 || glass_1_Tissue_2_both_3_contour==3
                            SegmentationFolderTimepoint0{2}=fullfile(fileparts(InitialTimepointtxtFile),'Manual_OnlyTissue');
                           end
                           for ii=1:length(DirectoryInitialTimepoints)
                                if contains(DirectoryInitialTimepoints{ii},MouseName)
                                    IndexMouse=ii;
                                end
                           end
                        end
                       
                                for ii=1:length(SegmentationFolderTimepoint0)
                                    if ~isempty(SegmentationFolderTimepoint0{ii})
                                        indxNotEmpty=ii
                                        break;
                                    end
                                end
                                
                                            if (-1<DaysPrecise && DaysPrecise<=0)
                                                Timepoint0=[TimepointTrueAndRel '_RefT0'];
                                            else
                                                for ii=1:length(SegmentationFolderTimepoint0)
                                                    if ~isempty(SegmentationFolderTimepoint0{ii})
                                                        Timepoint0Temp=strsplit(SegmentationFolderTimepoint0{ii},'\');
                                                        Timepoint0=sprintf('%s_0.0d_RefT0',Timepoint0Temp{4},TimeElapsed.RelImgTimepointDaysPrecise);
                                                        indxNotEmpty=ii
                                                        break
                                                    end
                                                end
                                            end
                                            %Timepoint0Temp=strsplit(RawFolderTimepoint0,'\');
                                            %if contains(RawFolderTimepoint0,'pre')
                                            %Timepoint0=[TimepointTrueAndRel '_RefT0'];
                                        MouseNameTimepoint0=[MouseName ' ' Timepoint0];
                             timepoint0ProcDir=dir(fullfile(fileparts(SegmentationFolderTimepoint0{indxNotEmpty}),'**'));
                              if glass_1_Tissue_2_both_3_contour==2 || glass_1_Tissue_2_both_3_contour==3
                                timepoint0AlreadyProcQuestion= (sum(contains({timepoint0ProcDir(:).name},'zline_GlassBot_uncoregTime0-.mat'))+sum(contains({timepoint0ProcDir(:).name},'zline_TissueTop_uncoregTime0-.mat')))>1%>0;
                             elseif glass_1_Tissue_2_both_3_contour==1
                                timepoint0AlreadyProcQuestion= (sum(contains({timepoint0ProcDir(:).name},'zline_GlassBot_uncoregTime0-.mat'))+sum(contains({timepoint0ProcDir(:).name},'zline_TissueTop_uncoregTime0-.mat')))>0%>0;
                              end
                                    if ~(-1<DaysPrecise && DaysPrecise<=0) %If not considering processing timepoint 0-, asking whether timepoint 0- was previously processed or not yet
                                        if timepoint0AlreadyProcQuestion==1
                                            fprintf('Timepoint 0- already processed, good to go!\n')
                                        else
                                            fprintf('Timepoint 0- not already processed, skipping this timepoint for now...\n')
                                            continue
                                        end
                                    end
                    %% binarized OCTA loading
                    if BinVesselsAlreadyPrepared==1
                        FoundBinOCTA=0;
                        for cc=1:length(AllInFolderRawOCTAConsidered)%AllInFolderConsidered)
                            for trialOCTBin=1:length(BinVasculatureFileKeyword)
                                if (contains(AllInFolderRawOCTAConsidered(cc).name,BinVasculatureFileKeyword{trialOCTBin}) && ~isequal(AllInFolderRawOCTAConsidered(cc).name,'.'))
                                    BatchOfFolders{countBatchFolder,2}=fullfile(AllInFolderRawOCTAConsidered(cc).folder,AllInFolderRawOCTAConsidered(cc).name);%[svOCTFileKeywordPostRaw{1},'.mat']);
                                    pathOCTVesBin=AllInFolderRawOCTAConsidered(cc).folder;
                                    filenameOCTVesBin=AllInFolderRawOCTAConsidered(cc).name;    
                                    FoundBinOCTA=1;
                                break;
                                end
                            end
                            if FoundBinOCTA==1
                                    break
                            end
                        end
                        if exist(BatchOfFolders{countBatchFolder,2},'file')==2 %automatic search worked
                            FoundBinOCTA=1;
                        else
                             [filenameOCTABin,pathOCTABin]=uigetfile('*.mat',sprintf('Please select BINARIZED OCTA data file for %s',MouseNameTimepoint),pathOCTVesRaw);%fileparts(fileparts(fileparts(fileparts(pathOCT)))));   
                             if pathOCTABin==0%still no selection
                                       fprintf('Skipping\n')% error('Please select an stOCT file for me... please!')
                                        FoundBinOCTA=0;
                                        continue
                             else

                                    FoundBinOCTA=1;
                             end
                        end
                    else %have not yet created a bin vessel map for example
                        FoundBinOCTA=1;%just say that to proceed
                            filenameOCTVesBin=[];
                            pathOCTVesBin=[];
                    end
                        %% struct OCT loading
            if FoundBinOCTA==1
                FoundstOCT=0;
                  %if contains(DirectoryVesselsData,'DLF')%~(exist(fullfile(saveFolder,'CheckedOrientationsL12.txt')) || ~(exist(fullfile(saveFolder,'CheckedOrientationsL11.txt')) || exist(fullfile(saveFolder,'CheckedOrientations.txt')))%No need for visual reference   
                                 if exist(fullfile(FolderStructAndRawOCTA,'structpath.mat'))%already defined path- especially for DLF data--separate drives
                                    load(fullfile(FolderStructAndRawOCTA,'structpath.mat'))%loads variable: savedPath
                                    BatchOfFolders{countBatchFolder,3}=fullfile(savedPath);
                                    FoundstOCT=1;
                                 else
                                           for SubFolderSearchInd=1:length(AllInFolderConsidered) %searching through current folder for the appropriate flu or opt file
                                                        for trialstOCT=1:length(stOCTFileKeyword)
                                                            if contains(AllInFolderConsidered(SubFolderSearchInd).name,stOCTFileKeyword{trialstOCT}) && contains(AllInFolderConsidered(SubFolderSearchInd).folder,'Improved')
                                                                FoundstOCT=1;
                                                                BatchOfFolders{countBatchFolder,3}=fullfile(AllInFolderConsidered(SubFolderSearchInd).folder,AllInFolderConsidered(SubFolderSearchInd).name);
                                                                pathStOCT=AllInFolderConsidered(SubFolderSearchInd).folder;
                                                                filenameStOCT=AllInFolderConsidered(SubFolderSearchInd).name;
                                                                break
                                                            end
                                                        end
                                                        if FoundstOCT==1
                                                            break
                                                        end
                                           end

                                            if FoundstOCT==0%going manual if not found automatically
                                                [filenameStOCT,pathStOCT]=uigetfile('*.mat',sprintf('Please select stOCT data file for %s',MouseNameTimepoint),pathOCTVesRaw);%fileparts(fileparts(fileparts(fileparts(pathOCT)))));        
                                                if pathStOCT==0%still no selection
                                                   fprintf('Skipping\n')% error('Please select an stOCT file for me... please!')
                                                    FoundstOCT=0;
                                                    continue
                                                else
                                                    FoundstOCT=1;
                                                    %load(fullfile(pathstOCT,filenamestOCT))%stOCT_data=matfile(fullfile(pathstOCT,filenamestOCT));%load(fullfile(pathsvOCT,filenamesvOCT));%save it into the folder since it was somehow out of place
        %                                            svOCT_data =VTD_processed
        %                                             save(fullfile(saveFolder,[stOCTFileKeyword{1} '_Used.mat']),'stOCT_data');                                    
                                                    BatchOfFolders{countBatchFolder,3}=fullfile(pathStOCT,filenameStOCT);
                                                    savedPath=fullfile(pathStOCT,filenameStOCT);
                                                    save(fullfile(FolderStructAndRawOCTA,'structpath.mat'),'savedPath')%so it is more quickly found automatically later on
                                                end
                                            end
                                 end
                    %end                    
                  %else             
                      %FoundstOCT=1;%Just saying it was to load 2D mask              
                  %end

                    if FoundstOCT==1 
                        %% 2D Tumour mask selection/creation if applicable
                                OptFluSegmentationFolder=fullfile(TumourMaskAndStepsDir,'2D OCT-bri/flu Co-registration + Tumour Mask');
                                    if ~exist(OptFluSegmentationFolder,'dir')
                                            mkdir(OptFluSegmentationFolder);
                                    end
                                OCTLateralTimepointCoregistrationFolder=fullfile(TumourMaskAndStepsDir,'3D Time OCT Co-registration intermediate');
                                    if ~exist(OCTLateralTimepointCoregistrationFolder,'dir')
                                            mkdir(OCTLateralTimepointCoregistrationFolder);
                                    end    
                                FoundTumourMask2DButCorrectAlignment=0;%Initialized variable which determines whether coregistered drawn 2D tumour mask created or not    
                        fprintf('Folder is %s \n',fullfile(NameTimepointComboTemp{end-2:end}));
                        if PredrawnTumourMask==1 %if previously created mask will look for it
%                             if contains(MouseName,DirectoriesBareSkinMiceKeyword)
%                             
%                             else
                                OptFluSegmentationFolderDir=dir(OptFluSegmentationFolder);
                                OptFluSegmentationFolderFiles={OptFluSegmentationFolderDir(:).name};
                                FoundMask2D=0;
                                    for SubFolderSearchInd=1:length(OptFluSegmentationFolderFiles) %searching through current folder for the appropriate flu or opt file
                                                        for trialMask2D=1:length(predrawnTumourMaskFileKeyword)
                                                            if contains(OptFluSegmentationFolderFiles{SubFolderSearchInd},predrawnTumourMaskFileKeyword{trialMask2D})
                                                                FoundMask2D=1;
                                                                BatchOfFolders{countBatchFolder,4}=fullfile(OptFluSegmentationFolder,OptFluSegmentationFolderFiles{SubFolderSearchInd});
                                                                path2DMask=OptFluSegmentationFolder;
                                                                filename2DMask=OptFluSegmentationFolderFiles{SubFolderSearchInd};
                                                                break
                                                            end
                                                        end
                                                        if FoundMask2D==1 %the tumour masks are in descending order of intermediate creation advancement
                                                            break;
                                                        end
                                    end
                                if FoundMask2D==0
                                    [filename2DMask,path2DMask]=uigetfile(OptFluSegmentationFolder,'Please select previously created tumour mask file (if none just cancel).')
                                    if isequal(filename2DMask,0) || isequal(path2DMask,0)%not found this previously drawn mask
                                        createTumourMaskQuestion=input('Shall we create one and extract all the metrics (fast,<8min)? y/n \n','s')
                                            if ~isequal(createTumourMaskQuestion,'y')|| isempty(createTumourMaskQuestion)
                                                fprintf('Skipping\n')
                                                continue%error('Please select a pre-drawn 2D tumour mask for me... please!')
                                            end
                                    else
                                        FoundMask2D=1;
                                        createTumourMaskQuestion='n';
                                        BatchOfFolders{countBatchFolder,4}=fullfile(path2DMask,filename2DMask);
                                    end
                                end
                                            if isequal(filename2DMask,'TumourMask2D_aligned_coregTime0.mat')
                                                    FoundTumourMask2DButCorrectAlignment=1; %if it is named this way, it was created with the script for aligning
                                                    createTumourMaskQuestion='n';
                                            elseif isequal(filename2DMask,0) 
                                                createTumourMaskQuestion='y';
                                                    FoundTumourMask2DButCorrectAlignment=0;
                                            else
                                                createTumourMaskQuestion='y';
                                                    FoundTumourMask2DButCorrectAlignment=2;%some other mask intermediate    
                                            end
                        end
                                
                                %if PredrawnTumourMask~=1 || isequal(createTumourMaskQuestion,'y')|| FoundTumourMask2DButCorrectAlignment==0 || FoundMask2D==0
                                    
                                
                                  %% Dose received up to considered timepoint  
                                  
                                DoseCohort=TotalDoses{IndexMouse};
                                    if contains(DoseCohort,'noRTx','IgnoreCase',true) 
                                        DoseReceivedUpToTP=0;
                                    elseif contains(DoseCohort,'3x12Gy MWF','IgnoreCase',true)        
                                        if DaysRounded<=0
                                            if contains(FolderStructAndRawOCTA,'pre')
                                                DoseReceivedUpToTP=0; 
                                            elseif contains(FolderStructAndRawOCTA,'post')
                                                DoseReceivedUpToTP=12;%Could also make it DoseReceivedUpToDayConsidered=DoseReceivedUpToDayConsidered+12;
                                            else
                                                DoseReceivedUpToTP=0;
                                            end
                                        elseif DaysRounded<=2%caldays(2)%2 %only looks for this condition if the first is not met according to the logic of if and elseif conditionals
                                            if contains(FolderStructAndRawOCTA,'pre')
                                                DoseReceivedUpToTP=12;
                                            elseif contains(FolderStructAndRawOCTA,'post')
                                                DoseReceivedUpToTP=24;
                                            else
                                                DoseReceivedUpToTP=12;
                                            end
                                        elseif DaysRounded<=4 %only looks for this condition if the first is not met according to the logic of if and elseif conditionals
                                            if contains(FolderStructAndRawOCTA,'pre')
                                                DoseReceivedUpToTP=24;
                                            elseif contains(FolderStructAndRawOCTA,'post')
                                                DoseReceivedUpToTP=36;
                                            else
                                                DoseReceivedUpToTP=24;
                                            end      
                                        end
                                    end
                                    
                                        
                                    for iv=1:length(saveFolder)
%                                        if ~exist(fullfile(saveFolder{iv},'MouseTimepointInfo.txt'))
                                        fid = fopen(fullfile(saveFolder{iv},'MouseTimepointInfo.txt'), 'wt');
                                            fprintf(fid, 'Mouse: %s \nTimepoint: %s \nTimepointRel: %sday(s) \nDoseReceivedUpToTP: %.1f \nPlanned dose: %s',MouseName,Timepoint,TimeElapsed.RelImgTimepointDaysPrecise,DoseReceivedUpToTP,DoseCohort);%'Jake said: %f\n', sqrt(1:10));
                                            fclose(fid);
                                    end
                                %% 2D/3D coregistration, Gross tumour response metrics and longitudinal coregistration
                                    % If this step was already performed it
                                    % can be skipped
                                    if AlreadyCompletedJustContouring==0 || AlreadyCompletedMaskCreation==0
                                        toc
                                        if LateralorFullCoregPreTisContour==0
                                            BatchOfFolders = VOIorTumourMaskPrep_Metextraction_fun19_TP0Bef_CoregMaybeL8r(GlassThickness_200PixDepth,DataCroppedNotResizedInDepth,ReferencePixDepth,BatchOfFolders,countBatchFolder,MouseName,NameDayFormat,NameTimepointComboTemp,DirectoryInitialTimepoints,DirectoryVesselsData,DirectoryDataLetter,TimepointTrueAndRel,TimepointVarName,FolderConsidered,DirectoriesBareSkinMiceKeyword,OptFluSegmentationFolder,MaskCreationDraft,saveFolder,pathOCTVesRaw,filenameOCTVesRaw,pathOCTVesBin,filenameOCTVesBin,pathStOCT,filenameStOCT,RawVasculatureFileKeywordRaw,TryAutomaticAllignment,exposureTimes_BriFlu,IndexMouse,num_contoured_slices,OSremoval,TumourMaskAndStepsDir,OCTLateralTimepointCoregistrationFolder,FoundTumourMask2DButCorrectAlignment,SaveFilenameDataUnlimited,SaveFilenameDataCylindricalProj,SaveFilenameDataUnlimited_UnCoregT0,SaveFilenameDataCylindricalProj_UnCoregT0,BinVesselsAlreadyPrepared,Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2,VisualizeResults,glass_1_Tissue_2_both_3_contour,DoseReceivedUpToTP,DaysPrecise,SegmentationFolderTimepoint0,indxNotEmpty,MouseNameTimepoint0,OnlyTissueLabelTimepoint0,InitialTimepointtxtFile,ActiveMemoryOffload);                                                                        
                                        else
                                            BatchOfFolders = VOIorTumourMaskPrep_Metext_LongCoreg_fun16_CoregBefContTis(GlassThickness_200PixDepth,DataCroppedNotResizedInDepth,ReferencePixDepth,BatchOfFolders,countBatchFolder,MouseName,NameDayFormat,NameTimepointComboTemp,DirectoryInitialTimepoints,DirectoryVesselsData,DirectoryDataLetter,TimepointTrueAndRel,TimepointVarName,FolderConsidered,DirectoriesBareSkinMiceKeyword,OptFluSegmentationFolder,MaskCreationDraft,saveFolder,pathOCTVesRaw,filenameOCTVesRaw,pathOCTVesBin,filenameOCTVesBin,pathStOCT,filenameStOCT,RawVasculatureFileKeywordRaw,TryAutomaticAllignment,exposureTimes_BriFlu,IndexMouse,num_contoured_slices,OSremoval,TumourMaskAndStepsDir,OCTLateralTimepointCoregistrationFolder,FoundTumourMask2DButCorrectAlignment,SaveFilenameDataUnlimited,SaveFilenameDataCylindricalProj,SaveFilenameDataUnlimited_UnCoregT0,SaveFilenameDataCylindricalProj_UnCoregT0,BinVesselsAlreadyPrepared,Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2,VisualizeResults,glass_1_Tissue_2_both_3_contour,DoseReceivedUpToTP,DaysPrecise,SegmentationFolderTimepoint0,indxNotEmpty,MouseNameTimepoint0,OnlyTissueLabelTimepoint0,InitialTimepointtxtFile,ActiveMemoryOffload);                                    
                                                %VOIorTumourMaskPrep_Metext_LongCoreg_fun16_CoregBefContTis(GlassThickness_200PixDepth,ReferencePixDepth,BatchOfFolders,countBatchFolder,MouseName,NameDayFormat,NameTimepointComboTemp,DirectoryInitialTimepoints,DirectoryVesselsData,TimepointTrueAndRel,TimepointVarName,FolderConsidered,DirectoriesBareSkinMiceKeyword,OptFluSegmentationFolder,MaskCreationDraft,saveFolder,pathOCTVesRaw,filenameOCTVesRaw,pathOCTVesBin,filenameOCTVesBin,pathStOCT,filenameStOCT,RawVasculatureFileKeywordRaw,TryAutomaticAllignment,exposureTimes_BriFlu,IndexMouse,num_contoured_slices,OSremoval,TumourMaskAndStepsDir,OCTLateralTimepointCoregistrationFolder,FoundTumourMask2DButCorrectAlignment,SaveFilenameDataUnlimited,SaveFilenameDataCylindricalProj,SaveFilenameDataUnlimited_UnCoregT0,SaveFilenameDataCylindricalProj_UnCoregT0,BinVesselsAlreadyPrepared,Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2,VisualizeResults,glass_1_Tissue_2_both_3_contour,DoseReceivedUpToTP,DaysPrecise,SegmentationFolderTimepoint0,indxNotEmpty,MouseNameTimepoint0,OnlyTissueLabelTimepoint0,InitialTimepointtxtFile,ActiveMemoryOffload);                                    
                                        end
                                         toc
                                    end                                                     
                                     %% Tissue or glass masks already produced, just loading them
                                        if BinarizeVesselsNOW_0_no_1_manual_2_automatic==1 || BinarizeVesselsNOW_0_no_1_manual_2_automatic==2 %manual vessel segmentation
                                            %Nevermind-->Using data
                                            %uncoregistered to Timepoint 0-
                                            %as the geometry of the volume
                                            %is simpler (not rotated)%extra
                                            %steps
                                            load(ColormapDirectory)
                                            if glass_1_Tissue_2_both_3_contour==1
                                                %Raw OCTA used
                                                    BatchOfFolders{countBatchFolder,6}=fullfile(saveFolder{1},'RawVess_UnCoregTime0-_RotShift.mat');
                                                %Toward 3D mask
                                                    BatchOfFolders{countBatchFolder,7}=SaveFilenameDataCylindricalProj_UnCoregT0{1};
                                                    %pathBinarization=fullfile(saveFolder{1},'Binarization Manual');
                                                    BatchOfFolders{countBatchFolder,8}=fullfile(saveFolder{1},'Bin Manual','BinVess_UnCoregTime0-_RotShift.mat');%BinOCTAOutPut
                                                    pathBinarization=fullfile(saveFolder{1},'Bin Manual');
                                            elseif glass_1_Tissue_2_both_3_contour==2
                                                if OnlyTissueLabelTimepoint0==0 %if drawing it manually for each timepoint--worth saving tissue mask                                         
                                                    %Raw OCTA used
                                                        BatchOfFolders{countBatchFolder,6}=fullfile(saveFolder{2},'RawVess_CoregTime0-_NotInZ_TissueMaskApp.mat');% since will be using coreg to T0 to draw tissue mask
                                                    %Toward 3D mask
                                                        BatchOfFolders{countBatchFolder,7}=SaveFilenameDataUnlimited{2};%SaveFilenameDataUnlimited{2}; We do want coreg T0 because coreg T0 will assist in drawing of tissue mask ignore previous--> %use uncoregistered version for in case current method of co-registration to be updated
                                                        %pathBinarization=fullfile(saveFolder{2},'Binarization');
                                                        BatchOfFolders{countBatchFolder,8}=fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_NotInZ_TissueMaskApp.mat');
                                                        pathBinarization=fullfile(saveFolder{2},'Bin Manual');
                                                end
                                            elseif glass_1_Tissue_2_both_3_contour==3
                                                if OnlyTissueLabelTimepoint0==0 %if drawing it manually for each timepoint--worth saving tissue mask                                         
                                                    if (-1<DaysPrecise && DaysPrecise<=0)
                                                        %Raw OCTA used
                                                            BatchOfFolders{countBatchFolder,6}=fullfile(saveFolder{2},'RawVess_CoregTime0-_isT0_TissueMaskApp.mat')  
                                                            BatchOfFolders{countBatchFolder,8}=fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_isT0_TissueMaskApp.mat');
                                                    else
                                                        %Raw OCTA used
                                                            BatchOfFolders{countBatchFolder,6}=fullfile(saveFolder{2},'RawVess_CoregTime0-_CurrentTP_TissueMaskApp.mat')
                                                            BatchOfFolders{countBatchFolder,8}=fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_CurrentTP_TissueMaskApp.mat')
                                                    end
                                                        %Toward 3D mask
                                                            BatchOfFolders{countBatchFolder,7}=SaveFilenameDataUnlimited_UnCoregT0{2}; 
                                                            pathBinarization=fullfile(saveFolder{2},'Bin Manual');
                                                elseif OnlyTissueLabelTimepoint0==1
                                                    if (-1<DaysPrecise && DaysPrecise<=0)
                                                        %Raw OCTA used
                                                            BatchOfFolders{countBatchFolder,6}=fullfile(saveFolder{2},'RawVess_CoregTime0-_isT0_TissueMaskApp.mat')
                                                            BatchOfFolders{countBatchFolder,8}=fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_isT0_TissueMaskApp.mat');
                                                    else
                                                        %Raw OCTA used
                                                            BatchOfFolders{countBatchFolder,6}=fullfile(saveFolder{2},'RawVess_CoregTime0-_FromT0_TissueMaskApp.mat')
                                                            BatchOfFolders{countBatchFolder,8}=fullfile(saveFolder{2},'Bin Manual','BinVess_CoregTime0-_FromT0_TissueMaskApp.mat');
                                                    end
                                                    %Toward 3D mask
                                                        BatchOfFolders{countBatchFolder,7}=SaveFilenameDataUnlimited{2};% only case when cortegistration necessary (otherwise mask cannot be applied)
                                                end
                                                pathBinarization=fullfile(saveFolder{2},'Bin Manual');
                                            end
                                            
                                            RawOCTATemp=matfile(BatchOfFolders{countBatchFolder,6});%svOCTBin=matfile(BatchOfFolders{countBatchFolder,1});
                                                RawOCTAVarname=whos('-file',BatchOfFolders{countBatchFolder,6});
                                            mask_3DTemp=matfile(BatchOfFolders{countBatchFolder,7});%svOCTBin=matfile(BatchOfFolders{countBatchFolder,1});
                                                mask_3DVarname=whos('-file',BatchOfFolders{countBatchFolder,7});
                                            
                                %% Obtaining dimensions of file for image preparation    
                                    DimsData=size(RawOCTATemp.(RawOCTAVarname.name));
                                    
                                    if ~isempty(strfind(BatchOfFolders{countBatchFolder,1},'3x3mm'))
                                        width_xProcRange=linspace(0,3,DimsData(2));%size(RawOCTATemp.(RawOCTAVarname.name),2));
                                        width_yProcRange=linspace(0,3,DimsData(3));%size(RawOCTATemp.(RawOCTAVarname.name),3));
                                    elseif ~isempty(strfind(BatchOfFolders{countBatchFolder,1},'3x6mm'))
                                        width_xProcRange=linspace(0,3,DimsData(2));
                                        width_yProcRange=linspace(0,6,DimsData(3));
                                    elseif ~isempty(strfind(BatchOfFolders{countBatchFolder,1},'4x4mm'))
                                        width_xProcRange=linspace(0,4,DimsData(2));
                                        width_yProcRange=linspace(0,4,DimsData(3));
                                    elseif ~isempty(strfind(BatchOfFolders{countBatchFolder,1},'6x6mm'))
                                        width_xProcRange=linspace(0,6,DimsData(2));
                                        width_yProcRange=linspace(0,6,DimsData(3));
                                    elseif ~isempty(strfind(BatchOfFolders{countBatchFolder,1},'9x9mm'))
                                        width_xProcRange=linspace(0,9,DimsData(2));
                                        width_yProcRange=linspace(0,9,DimsData(3));
                                    else
                                        width_xProcRange=linspace(0,6,DimsData(2));
                                        width_yProcRange=linspace(0,6,DimsData(3));
                                    end
                                toc
                                        end

                                %% Manual vessel segmentation now if not performed apriori (step to perform coregistration to timepoint 0- would have to still be applied afterwards in this case)
                                if BinarizeVesselsNOW_0_no_1_manual_2_automatic==1
                                    %% Run VTD Processing Code (Valentin code) + otsu thresholding in depth
                                        % Step 1: Morphological processing (open/close + median
                                        % filter)--Usually no need to change  --also implemented in Step 4
                                        % (2nd median filter) --smoothens
                                            num_rounds = 1; %CHANGE THIS--> barely makes a difference
                                            opening_closing_parameter = 15;%15 %CHANGE THIS
                                            median_filtering_parameter = 4;%2 %CHANGE THIS
                                        % Step 2: Hard thresholding --Not so sure about keeping this (can be
                                        % made linear as a function of depth)
                                            thresh_superficial = 3500; %CHANGE THIS
                                            thresh_deep = 1000; %Minimum threshold level %CHANGE THIS
                                        % Step 3: Deshadowing
                                            deshadowing_para = 20; %15-17% CHANGE THIS % Decrease this number to increase the strength of deshadowing 
                                        % Step 4: 2nd median filter
                                        % Step 5: Binarization as a function of depth via Otsu's method
                                        % Step 6: Removal of small artifacts
                                            volumeThreshold = 1000; % CHANGE THIS (or set to zero)
                                            
                                    %VTD_processed = VTD_ProcessingWithVisualization(svOCT.sv3D_uint16.*mask_3D_compressedTop,[0 0 0 0 0 0 0]);%VTD_Processing(raw_data);%does not use incorrect approximation of axial resolution except for VVD calculation
                                    %no change of dimensions since only temporary resizing just to help
                                    %with various post-processing without rounding errors
                                if ProcessFullFOV_0_no_1_yes==1%if ProcessFullFOV_0_no_1_yes==1 || ProcessFullFOV_0_no_1_yes==2 
                                    %% Segmentation functions on full vasculature data in entire FOV
%                                         vessels_processed_binaryWithoutTransverseLimits=ManualVesselBinarizer(RawOCTATemp.(RawOCTAVarname.name),num_rounds,...
%                                         opening_closing_parameter,median_filtering_parameter, thresh_superficial,...
%                                         thresh_deep,deshadowing_para,volumeThreshold);
                                            %% Denoising ----------------------------------------   
                                                % num_rounds = 1; %CHANGE THIS
                                                % opening_closing_parameter = 15; %CHANGE THIS
                                                % median_filtering_parameter = 2; %CHANGE THIS
                                                % % I found that the above numbers work well for almost all OCT volumes so
                                                % % try adjusting some of the other paremters first.
                                                VTD_1 = RawOCTATemp.(RawOCTAVarname.name);

                                                for roundOfFilter = 1:1:num_rounds

                                                    % Morphological Processing - Morphological Opening/Closing
                                                    VTD_top_hat=zeros(size(VTD_1,1),size(VTD_1,2),size(VTD_1,3));
                                                    for o=1:size(VTD_1,3)
                                                        s = imtophat(VTD_1(:,:,o),strel('disk',opening_closing_parameter));
                                                        k=imtophat(VTD_1(:,:,o),strel('disk',1));
                                                        B_scan_dn=s-k;
                                                        VTD_top_hat(:,:,o)=B_scan_dn(:,:);
                                                        clc; display(['Morphological opening/closing, frame  ' num2str(o)]);
                                                    end
                                                    %Noresizing from raw (z,x,y) 500,1152,1200 
                                                    % Morphological Processing - Median Filter
                                                    VTD_median=zeros(size(VTD_top_hat,1),size(VTD_top_hat,2),size(VTD_top_hat,3));
                                                    for w=1:size(VTD_top_hat,2)
                                                        ST=squeeze(VTD_top_hat(:,w,:));
                                                        STT_temp=medfilt2(ST,[median_filtering_parameter median_filtering_parameter]);
                                                        VTD_median(:,w,:)=STT_temp(:,:);
                                                        clc; display(['Median filtering, frame  ' num2str(w)]);
                                                    end
                                                    %No resizing from raw (z,x,y) 500,1152,1200 
                                                    VTD_1 = VTD_median;

                                                end

                                                VTD_median = VTD_1;

                                                figure, imshow3D(cat(2,RawOCTATemp.(RawOCTAVarname.name),VTD_median))
                                                figure, imshow3D(cat(2,shiftdim(RawOCTATemp.(RawOCTAVarname.name),1),shiftdim(VTD_median,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                fprintf('Step 1 complete\n')
                                                %% Hard Thresholding ----------------------------------------

                                                close all
%                                                 clearvars VTD_1

                                                % thresh_superficial = 1000; %CHANGE THIS
                                                % thresh_deep = 1000; %Minimum threshold level %CHANGE THIS

                                                VTD_thresh = zeros(size(VTD_median,1),size(VTD_median,2),size(VTD_median,3));

                                                r=flip(1*linspace(thresh_deep,thresh_superficial,size(VTD_median,1)));% Threshold as a function of depth

                                                for u=1:size(VTD_median,1)
                                                 ST=squeeze(VTD_median(u,:,:));
                                                 ST(ST<r(u))=0;
                                                 VTD_thresh(u,:,:)=ST(:,:);
                                                 clc; display(['Applying depth-decaying threshold, depth  ' num2str(u)]);
                                                end

                                                figure, imshow3D(cat(2,VTD_median,VTD_thresh))
                                                figure, imshow3D(cat(2,shiftdim(VTD_median,1),shiftdim(VTD_thresh,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                %No resizing from raw (z,x,y) 500,1152,1200

%                                                 figure, plot(r)
%                                                 hold on
%                                                 xlabel('depth','fontsize',15)
%                                                 ylabel('threshold','fontsize',15)

                                                %% Step down exponential filter for deshadowing ------------------------

                                                % deshadowing_para = 17; % CHANGE THIS % Decrease this number to increase the strength of deshadowing 

                                                close all
%                                                 clearvars VTD_median

                                                Depth=size(VTD_thresh,1);
                                                VTD_deshadowed=zeros(size(VTD_thresh,1),size(VTD_thresh,2),size(VTD_thresh,3));
                                                parfor i=1:size(VTD_deshadowed,3)
                                                B=VTD_thresh(:,:,i); 
                                                [ D ] = deshadowing_functionv2( B, Depth , deshadowing_para);
                                                VTD_deshadowed(:,:,i)=D;
                                                display(['De-shadowing, frame  ' num2str(i)]);
                                                end

                                                figure, imshow3D(cat(2,VTD_thresh,VTD_deshadowed))
                                                figure, imshow3D(cat(2,shiftdim(VTD_thresh,1),shiftdim(VTD_deshadowed,1)))
                                                
                                                fprintf('Step 3 complete\n')
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                %% Second Morphological Processing --------------------------------------

%                                                 clearvars VTD_thresh
                                                VTD_1 = VTD_deshadowed;
                                                % Morfological Processing - Morphological Opening/Closing
                                                VTD_top_hat=zeros(size(VTD_1,1),size(VTD_1,2),size(VTD_1,3));
                                                for o=1:size(VTD_1,3)
                                                    s = imtophat(VTD_1(:,:,o),strel('disk',opening_closing_parameter));
                                                    k=imtophat(VTD_1(:,:,o),strel('disk',1));
                                                    B_scan_dn=s-k;
                                                    VTD_top_hat(:,:,o)=B_scan_dn(:,:);
                                                    clc; display(['Morphological opening/closing, frame  ' num2str(o)]);
                                                end

%                                                 clearvars VTD_1
                                                % Morfological Processing - Median Filter
                                                VTD_median_2=zeros(size(VTD_top_hat,1),size(VTD_top_hat,2),size(VTD_top_hat,3));
                                                for w=1:size(VTD_top_hat,2)
                                                    ST=squeeze(VTD_top_hat(:,w,:));
                                                    STT_temp=medfilt2(ST,[median_filtering_parameter median_filtering_parameter]);
                                                    VTD_median_2(:,w,:)=STT_temp(:,:);
                                                    clc; display(['Median filtering, frame  ' num2str(w)]);
                                                end
                                                figure, imshow3D(cat(2,VTD_deshadowed,VTD_median_2))
                                                figure, imshow3D(cat(2,shiftdim(VTD_deshadowed,1),shiftdim(VTD_median_2,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                % VTD_median_2 = VTD_deshadowed; % If this step is to be skipped
%                                                 clearvars VTD_top_hat
% Additional hard thresholding just in case --seemed to help for BSOrth1
% r=flip(1*linspace(2000,5000,size(VTD_median,1)));
% for u=1:size(VTD_median_2,1)
% ST=squeeze(VTD_median_2(u,:,:));
% ST(ST<r(u))=0;
% VTD_thresh2(u,:,:)=ST(:,:);
% clc; display(['Applying depth-decaying threshold, depth  ' num2str(u)]);
% end
% figure, imshow3D(cat(2,shiftdim(VTD_median_2,1),shiftdim(VTD_thresh2,1)))
% VTD_median_2=VTD_thresh2
                                                %% Otsu's thresholding --------------------------------------------------

                                                close all

                                                vessels_processed_binaryWithoutTransverseLimits = zeros(size(VTD_median_2,1),size(VTD_median_2,2),size(VTD_median_2,3));
                                                for o=1:size(vessels_processed_binaryWithoutTransverseLimits,1)
                                                    temp_2D = squeeze(VTD_median_2(o,:,:));
                                                    temp_2D = temp_2D./max(temp_2D(:));
                                                    vessels_processed_binaryWithoutTransverseLimits(o,:,:)=imbinarize(temp_2D);
                                                %     VTD_binarized(o,:,:)= thresholdLocally(temp_2D);
                                                    clc; display(['Segmenting, depth  ' num2str(o)]);
                                                end
%                                                 clearvars VTD_median_2
                                                % Remove small connected components

                                                % volumeThreshold = 100; % CHANGE THIS (or set to zero)

                                                %Remove Components:

                                                vessels_processed_binaryWithoutTransverseLimits = RemoveComponents(vessels_processed_binaryWithoutTransverseLimits, volumeThreshold, false, false);

                                                vessels_processed_binaryWithoutTransverseLimits = imbinarize(vessels_processed_binaryWithoutTransverseLimits);

                                                figure, imshow3D(cat(2,VTD_deshadowed./max(VTD_deshadowed(:)),vessels_processed_binaryWithoutTransverseLimits))
                                                figure, imshow3D(cat(2,shiftdim(VTD_deshadowed./max(VTD_deshadowed(:)),1),shiftdim(vessels_processed_binaryWithoutTransverseLimits,1)))
                                                fprintf('Step 6 complete\n')
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                               % clearvars VTD_deshadowed
                                    %% Saving created vasculature maps 
                                    if ~exist(pathBinarization,'dir')
                                        mkdir(pathBinarization)
                                    end
                                        save([fullfile(pathBinarization,['vessels_processed_binaryWithoutTransverseLimits.mat'])],'vessels_processed_binaryWithoutTransverseLimits','-mat','-v7.3')
                                    %% Colour depth encoded processed and binarized volume
                                        %% Full transverse
                                            saveFolderAndNameWithoutTransverseLimits=fullfile(pathBinarization,'DepthEncoded Post-processedVasculature map_Full');
                                               colourDepthEncodev4(vessels_processed_binaryWithoutTransverseLimits(1:round(400/(umPerPix_For200PixDepthInTissue*200/size(vessels_processed_binaryWithoutTransverseLimits,1))),:,:),width_xProcRange,width_yProcRange,saveFolderAndNameWithoutTransverseLimits,umPerPix_For200PixDepthInTissue*200/size(vessels_processed_binaryWithoutTransverseLimits,1),cmap2);
%                                              temp=    
% load('D:\Processing code\OCT\1) SvOCT processing\Codes_for_Ottawa\cmap2.mat')
% %                                                 figure, imagesc(fliplr(temp))
%                                                 colormap(cmap2)
                                                toc
                                %% Applying lateral mask
%                                     vessels_processed_binary=vessels_processed_binaryWithoutTransverseLimits.*logical(mask_3DTemp.(mask_3DVarname.name));
%                                     save(BatchOfFolders{countBatchFolder,8},'vessels_processed_binary','-mat','-v7.3')
%                                         saveFolderAndNameWithTransverseLimits=fullfile(pathBinarization,'DepthEncoded Post-processedVasculature map_OnlyVOI.png');    
%                                         colourDepthEncodev3(vessels_processed_binary,width_xProcRange,width_yProcRange,saveFolderAndNameWithTransverseLimits,umPerPix_For200PixDepthInAir*200/size(vessels_processed_binary,1));
%                                 
                                        clearvars vessels_processed_binaryWithoutTransverseLimits
                                    toc
                                end
                                %%
                                if ProcessFullFOV_0_no_1_yes==0 || ProcessFullFOV_0_no_1_yes==1 %If doing both maybe can apply lateral mask separately? Or not because of median filters around edges
                                    %% Segmentation functions on full vasculature data in entire FOV
%                                         vessels_processed_binary=ManualVesselBinarizer(RawOCTATemp.(RawOCTAVarname.name).*logical(mask_3DTemp.(mask_3DVarname.name)),num_rounds,...
%                                         opening_closing_parameter,median_filtering_parameter, thresh_superficial,...
%                                         thresh_deep,deshadowing_para,volumeThreshold);
                                            %% Denoising ----------------------------------------   
                                                % num_rounds = 1; %CHANGE THIS
                                                % opening_closing_parameter = 15; %CHANGE THIS
                                                % median_filtering_parameter = 2; %CHANGE THIS
                                                % % I found that the above numbers work well for almost all OCT volumes so
                                                % % try adjusting some of the other paremters first.
                                                VTD_1 = RawOCTATemp.(RawOCTAVarname.name).*logical(mask_3DTemp.(mask_3DVarname.name));

                                                for roundOfFilter = 1:1:num_rounds

                                                    % Morphological Processing - Morphological Opening/Closing
                                                    VTD_top_hat=zeros(size(VTD_1,1),size(VTD_1,2),size(VTD_1,3));
                                                    for o=1:size(VTD_1,3)
                                                        s = imtophat(VTD_1(:,:,o),strel('disk',opening_closing_parameter));
                                                        k=imtophat(VTD_1(:,:,o),strel('disk',1));
                                                        B_scan_dn=s-k;
                                                        VTD_top_hat(:,:,o)=B_scan_dn(:,:);
                                                        clc; display(['Morphological opening/closing, frame  ' num2str(o)]);
                                                    end
                                                    %Noresizing from raw (z,x,y) 500,1152,1200 
                                                    % Morphological Processing - Median Filter
                                                    VTD_median=zeros(size(VTD_top_hat,1),size(VTD_top_hat,2),size(VTD_top_hat,3));
                                                    for w=1:size(VTD_top_hat,2)
                                                        ST=squeeze(VTD_top_hat(:,w,:));
                                                        STT_temp=medfilt2(ST,[median_filtering_parameter median_filtering_parameter]);
                                                        VTD_median(:,w,:)=STT_temp(:,:);
                                                        clc; display(['Median filtering, frame  ' num2str(w)]);
                                                    end
                                                    %No resizing from raw (z,x,y) 500,1152,1200 
                                                    VTD_1 = VTD_median;

                                                end

                                                VTD_median = VTD_1;

                                                figure, imshow3D(cat(2,RawOCTATemp.(RawOCTAVarname.name),VTD_median))
                                                figure, imshow3D(cat(2,shiftdim(RawOCTATemp.(RawOCTAVarname.name),1),shiftdim(VTD_median,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                fprintf('Step 1 complete\n')
                                                %% Hard Thresholding ----------------------------------------

                                                close all
%                                                 clearvars VTD_1

                                                % thresh_superficial = 1000; %CHANGE THIS
                                                % thresh_deep = 1000; %Minimum threshold level %CHANGE THIS

                                                VTD_thresh = zeros(size(VTD_median,1),size(VTD_median,2),size(VTD_median,3));

                                                r=flip(1*linspace(thresh_deep,thresh_superficial,size(VTD_median,1)));% Threshold as a function of depth

                                                for u=1:size(VTD_median,1)
                                                 ST=squeeze(VTD_median(u,:,:));
                                                 ST(ST<r(u))=0;
                                                 VTD_thresh(u,:,:)=ST(:,:);
                                                 clc; display(['Applying depth-decaying threshold, depth  ' num2str(u)]);
                                                end

                                                figure, imshow3D(cat(2,VTD_median,VTD_thresh))
                                                figure, imshow3D(cat(2,shiftdim(VTD_median,1),shiftdim(VTD_thresh,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                %No resizing from raw (z,x,y) 500,1152,1200 

%                                                 figure, plot(r)
%                                                 hold on
%                                                 xlabel('depth','fontsize',15)
%                                                 ylabel('threshold','fontsize',15)

                                                %% Step down exponential filter for deshadowing ------------------------

                                                % deshadowing_para = 17; % CHANGE THIS % Decrease this number to increase the strength of deshadowing 

                                                close all
                                                 clearvars VTD_median

                                                Depth=size(VTD_thresh,1);
                                                VTD_deshadowed=zeros(size(VTD_thresh,1),size(VTD_thresh,2),size(VTD_thresh,3));
                                                parfor i=1:size(VTD_deshadowed,3)
                                                B=VTD_thresh(:,:,i); 
                                                [ D ] = deshadowing_functionv2( B, Depth , deshadowing_para);
                                                VTD_deshadowed(:,:,i)=D;
                                                display(['De-shadowing, frame  ' num2str(i)]);
                                                end

                                                figure, imshow3D(cat(2,VTD_thresh,VTD_deshadowed))
                                                figure, imshow3D(cat(2,shiftdim(VTD_thresh,1),shiftdim(VTD_deshadowed,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                fprintf('Step 3 complete\n')

                                                %% Second Morphological Processing --------------------------------------

                                                clearvars VTD_thresh
                                                VTD_1 = VTD_deshadowed;
                                                % Morfological Processing - Morphological Opening/Closing
                                                VTD_top_hat=zeros(size(VTD_1,1),size(VTD_1,2),size(VTD_1,3));
                                                for o=1:size(VTD_1,3)
                                                    s = imtophat(VTD_1(:,:,o),strel('disk',opening_closing_parameter));
                                                    k=imtophat(VTD_1(:,:,o),strel('disk',1));
                                                    B_scan_dn=s-k;
                                                    VTD_top_hat(:,:,o)=B_scan_dn(:,:);
                                                    clc; display(['Morphological opening/closing, frame  ' num2str(o)]);
                                                end

                                                 clearvars VTD_1 s k
                                                % Morfological Processing - Median Filter
                                                VTD_median_2=zeros(size(VTD_top_hat,1),size(VTD_top_hat,2),size(VTD_top_hat,3));
                                                for w=1:size(VTD_top_hat,2)
                                                    ST=squeeze(VTD_top_hat(:,w,:));
                                                    STT_temp=medfilt2(ST,[median_filtering_parameter median_filtering_parameter]);
                                                    VTD_median_2(:,w,:)=STT_temp(:,:);
                                                    clc; display(['Median filtering, frame  ' num2str(w)]);
                                                end
%                                                figure, imshow3D(cat(2,VTD_deshadowed,VTD_median_2))
%                                                figure, imshow3D(cat(2,shiftdim(VTD_deshadowed,1),shiftdim(VTD_median_2,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                end
                                                % VTD_median_2 = VTD_deshadowed; % If this step is to be skipped
                                                 clearvars VTD_top_hat
                                                %% Otsu's thresholding --------------------------------------------------

                                                close all

                                                vessels_processed_binaryWithinMask = zeros(size(VTD_median_2,1),size(VTD_median_2,2),size(VTD_median_2,3));
                                                for o=1:size(vessels_processed_binaryWithinMask,1)
                                                    temp_2D = squeeze(VTD_median_2(o,:,:));
                                                    temp_2D = temp_2D./max(temp_2D(:));
                                                    vessels_processed_binaryWithinMask(o,:,:)=imbinarize(temp_2D);
                                                %     VTD_binarized(o,:,:)= thresholdLocally(temp_2D);
                                                    clc; display(['Segmenting, depth  ' num2str(o)]);
                                                end
                                                 clearvars VTD_median_2
                                                % Remove small connected components

                                                % volumeThreshold = 100; % CHANGE THIS (or set to zero)

                                                %Remove Components:

                                                vessels_processed_binaryWithinMask = RemoveComponents(vessels_processed_binaryWithinMask, volumeThreshold, false, false);

                                                vessels_processed_binaryWithinMask = imbinarize(vessels_processed_binaryWithinMask);

 %                                               figure, imshow3D(cat(2,VTD_deshadowed./max(VTD_deshadowed(:)),vessels_processed_binaryWithinMask))
 %                                               figure, imshow3D(cat(2,shiftdim(VTD_deshadowed./max(VTD_deshadowed(:)),1),shiftdim(vessels_processed_binaryWithinMask,1)))
                                                if CheckIntermediates==1
                                                    pause = 1;
                                                    close all
                                                end
                                                fprintf('Step 6 complete\n')
                                                clearvars VTD_deshadowed 
                                    %% Saving created vasculature maps
                                    FolderCheck = BatchOfFolders{countBatchFolder,8}(1:end-35);
                                    if not(isfolder(FolderCheck))
                                        mkdir(FolderCheck)
                                    end
    
                                        save(BatchOfFolders{countBatchFolder,8},'vessels_processed_binaryWithinMask','-mat','-v7.3')
                                        %% within lateral tumour mask saving will come next since it is common to both 
                                end
                                %% Visualizing all results
                                %% Raw
                                projection=squeeze(sum(cast(RawOCTATemp.(RawOCTAVarname.name),'double')));
                                set(figure,'Position',[100,100,800,600],'visible','on');
                                fs=70;  
                                imagesc(width_xProcRange,width_yProcRange,sqrt(projection),[766 1600]);
                                colormap 'hot'; 
                                title('Raw OCTA vasculature map (en-face)','FontWeight','Bold','FontSize',fs); 
                                xlabel('Width_y (mm)','FontWeight','Bold','FontSize',fs);
                                ylabel('Width_x (mm)','FontWeight','Bold','FontSize',fs);
                                axis tight; set(gca,'FontWeight','Bold','FontSize',fs-1);
                                set(gcf,'PaperUnits','inches','PaperPosition',[0 0 26 23])
                                  saveas(gcf,[pathBinarization '/RawsvOCTVasculature map.png'],'png')%visually assessing difference %we may look into the pseudo
                                toc
                                %% Processed
                                projection=squeeze(sum(cast(vessels_processed_binaryWithinMask(:,:,:),'double'),1));%(flipud(imrotate(squeeze(sum(cast(vessels_processed(:,:,:),'double'),1)),-90)));
                                set(figure,'Position',[100,100,800,600],'visible','on');
                                fs=70;  
                                imagesc(width_xProcRange,width_yProcRange,sqrt(projection))%,[0 1]);
                                colormap 'hot'; 
                                title('Post-processed OCT vasculature map (en-face)','FontWeight','Bold','FontSize',fs); 
                                xlabel('Width_y (mm)','FontWeight','Bold','FontSize',fs);
                                ylabel('Width_x (mm)','FontWeight','Bold','FontSize',fs);
                                axis tight; set(gca,'FontWeight','Bold','FontSize',fs-1);
                                set(gcf,'PaperUnits','inches','PaperPosition',[0 0 26 23])
                                 saveas(gcf,fullfile(pathBinarization,'Post-processedVasculature map.png'),'png')%[SaveLocation '/Post-processedVasculature map.png'],'png')
                                %% Colour depth encoded processed and binarized volume
                                %% ROI restricted transverse
                                saveFolderAndNameWithTransverseLimits=fullfile(pathBinarization,'DepthEncoded Post-processedVasculature map_OnlyVOI');    
                                    colourDepthEncodev4(vessels_processed_binaryWithinMask(1:round(1000/(umPerPix_For200PixDepthInTissue*200/size(vessels_processed_binaryWithinMask,1))),:,:),width_xProcRange,width_yProcRange,saveFolderAndNameWithTransverseLimits,umPerPix_For200PixDepthInTissue*200/size(vessels_processed_binaryWithinMask,1),cmap2);%colourDepthEncodev3(vessels_processed_binaryWithinMask,width_xProcRange,width_yProcRange,saveFolderAndNameWithTransverseLimits,umPerPix_For200PixDepthInAir*200/size(vessels_processed_binaryWithinMask,1));
                                    toc
                                elseif BinarizeVesselsNOW_0_no_1_manual_2_automatic==2
                                    %To be continued hopefully soon
                                end
                                                
                                
%% Applying previously determined coregistration operations
%Nevermind (only to do if notice that raw vasculature rotated causes
%memory issues for binarization (so perform operations on non-co-registered
%data then later co-register according to previously saved operations.
%% Preparing next iteration of processing
                            countBatchFolder=countBatchFolder+1;
                            clearvars MaskCreationDraft saveFolder savebotContour SaveFilenameRawMaskApplied SaveFilenameDataUnlimited_UnCoregT0 SaveFilenameDataCylindricalProj_UnCoregT0 SaveFilenameDataUnlimited SaveFilenameDataCylindricalProj SegmentationFolderTimepoint0
            
                    end    
            end
                       end
end
        break;%in case more than 1 raw vessels file
                end
                if FoundRawOCTA==1
                    break;
                end
            end
        end
end

