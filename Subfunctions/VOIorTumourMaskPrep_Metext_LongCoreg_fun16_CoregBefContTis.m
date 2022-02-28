function BatchOfFolders= VOIorTumourMaskPrep_Metext_LongCoreg_fun16_CoregBefContTis(CurrentTimepoint,Timepoint0Analyzed,TumourMaskFrom_FLU_0_BRI_1,GlassThickness_200PixDepth,DataCroppedNotResizedInDepth,ReferencePixDepth,BatchOfFolders,countBatchFolder,MouseName,NameDayFormat,NameTimepointComboTemp,DirectoryInitialTimepoints,DirectoryVesselsData,DirectoryDataLetter,TimepointTrueAndRel,TimepointVarName,FolderConsidered,DirectoriesBareSkinMiceKeyword,OptFluSegmentationFolder,MaskCreationDraft,saveFolder,pathOCTVesRaw,filenameOCTVesRaw,pathOCTVesBin,filenameOCTVesBin,pathStOCT,filenameStOCT,RawVasculatureFileKeywordRaw,TryAutomaticAllignment,exposureTimes_BriFlu,IndexMouse,num_contoured_slices,OSremoval,TumourMaskAndStepsDir,OCTLateralTimepointCoregistrationFolder,FoundTumourMask2DButCorrectAlignment,SaveFilenameDataUnlimited,SaveFilenameDataCylindricalProj,SaveFilenameDataUnlimited_UnCoregT0,SaveFilenameDataCylindricalProj_UnCoregT0,BinVesselsAlreadyPrepared,Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2,VisualizeResults,Neither_0_glass_1_Tissue_2_both_3_contour,DoseReceivedUpToTP,DaysPrecise,SegmentationFolderTimepoint0,indxNotEmpty,MouseNameTimepoint0,OnlyTissueLabelTimepoint0,InitialTimepointtxtFile,ActiveMemoryOffload)
%Checking need for transverse view 2D tumour mask if applicable
if contains(MouseName,DirectoriesBareSkinMiceKeyword)%Bareskin mouse
    TumourMaskType='PrismVOI';%Just use some square ROI, but we would still be coregistering to timepoint 0
else %Tumour bearing mice
    TumourMaskType='TumourVOI';
end
%     if glass_1_Tissue_2_both_3_contour==1
%         SegFolder=OptFluSegmentationFolder{1};
%     elseif glass_1_Tissue_2_both_3_contour==2 || glass_1_Tissue_2_both_3_contour==3
%         SegFolder=OptFluSegmentationFolder{2};
%     end

if TumourMaskFrom_FLU_0_BRI_1==0
    PrefixFLU_BRI='FLU_';
elseif TumourMaskFrom_FLU_0_BRI_1==1
    PrefixFLU_BRI='BRI_';
end

if FoundTumourMask2DButCorrectAlignment==1 || FoundTumourMask2DButCorrectAlignment==2 %in case there was an issue in folder naming (saved elsewhere)-which seems to be the case at least in first L0R1 manually selected and saved
    MaskDir=fileparts(fileparts(BatchOfFolders{countBatchFolder,4}))
    TumourMaskAndStepsDir=MaskDir;
    OptFluSegmentationFolder=fileparts(BatchOfFolders{countBatchFolder,4});
    OCTLateralTimepointCoregistrationFolder=fullfile(MaskDir,'3D Time OCT Co-registration intermediate');
    %     if ~isempty(MaskCreationDraft{1})
    %         temp=strsplit(MaskCreationDraft{1},'\')
    %         MaskCreationDraft{1}=fullfile(MaskDir,temp{end-1:end});
    %     end
    %     if ~isempty(MaskCreationDraft{2})
    %         temp=strsplit(MaskCreationDraft{2},'\')
    %         MaskCreationDraft{2}=fullfile(MaskDir,temp{end-1:end});
    %     end
end

SegFolder=OptFluSegmentationFolder;

%% 1) Loading raw OCTA and reference brightfield/fluorescence image
RawOCTA_temp=matfile(fullfile(pathOCTVesRaw,filenameOCTVesRaw));
RawOCTAVarname=whos('-file',fullfile(pathOCTVesRaw,filenameOCTVesRaw));
DimsVesselsRaw3D=size(RawOCTA_temp.(RawOCTAVarname.name));%RawOCTA=RawOCTA_temp.(RawOCTAVarname.name);%single
OCTA_data2D=squeeze(sum(RawOCTA_temp.(RawOCTAVarname.name),1));%vessels_processed_binary%sv3D_uint16; %shiftdim(raw_data,1); %Adjust the martrix dimensions for easier indexing through slices
OCTA_data2D=OCTA_data2D/max(OCTA_data2D,[],'all');

if ~isempty(BatchOfFolders{countBatchFolder,4})%Did pre-create tumour mask 2D and do not need to quantify fluorescence
    FLU_BRI_proc=0;%no need to creat mask
    %% All files to be used
    BatchOfFolders{countBatchFolder,1}=fullfile(pathOCTVesRaw,filenameOCTVesRaw);%uigetdir(FileSelectDirectory,'Please select folders of datasets to be sv processed');
    if BinVesselsAlreadyPrepared==1
        BatchOfFolders{countBatchFolder,2}=fullfile(pathOCTVesBin,filenameOCTVesBin);
    end
    BatchOfFolders{countBatchFolder,3}=fullfile(pathStOCT,filenameStOCT);%uigetdir(FileSelectDirectory,'Please select folders of datasets to be sv processed');
    %% Load pre-drawn 2D mask (already from brightfield/fluorescence co-registered during manual vascular segmentation)
    mask2D=load(BatchOfFolders{countBatchFolder,4});
    MaskVarname=whos('-file',BatchOfFolders{countBatchFolder,4});
    TumourMask2D_aligned=imresize(mask2D.(MaskVarname.name),size(OCTA_data2D));
    clearvars mask2D
    %                                     if TumourMaskFrom_FLU_0_BRI_1==0
    %                                         save(fullfile(SegFolder,['FLU_TumourMask2D_aligned.mat']),'TumourMask2D_aligned','-v7.3')
    %                                     else
    %                                         save(fullfile(SegFolder,['BRI_TumourMask2D_aligned.mat']),'TumourMask2D_aligned','-v7.3')
    %                                     end
    save(fullfile(SegFolder,[PrefixFLU_BRI,'TumourMask2D_aligned.mat']),'TumourMask2D_aligned','-v7.3')
    if ~exist(fullfile(SegFolder,[PrefixFLU_BRI,'Mask2DPreCoregTime0-ForScaling.mat']))
        TumourMask2DPreCoregTime0=TumourMask2D_aligned;
        save(fullfile(SegFolder,[PrefixFLU_BRI,'Mask2DPreCoregTime0-ForScaling.mat']),'TumourMask2DPreCoregTime0','-v7.3')
    end
else
    FLU_BRI_proc=1;
    %% 2) Extracting scan dimensions
    if exist(fullfile(pathOCTVesRaw,'DimensionsFOVmm.mat'))
        load(fullfile(pathOCTVesRaw,'DimensionsFOVmm.mat'))
    else
        if sum(contains(NameTimepointComboTemp,'pre'),'all') || sum(contains(NameTimepointComboTemp,'post'),'all')
            FOVSizeTemp=strsplit(NameTimepointComboTemp{7},'_');
        else
            FOVSizeTemp=strsplit(NameTimepointComboTemp{6},'_');
        end
        FOVSizeTemp2=strsplit(FOVSizeTemp{end},'mm');
        FOVSizeTemp3=strsplit(FOVSizeTemp2{1},'x');
        xOCT_mm=str2num(FOVSizeTemp3{1});
        yOCT_mm=str2num(FOVSizeTemp3{2});
        DimensionsFOVmm=[xOCT_mm,yOCT_mm];
        save(fullfile(pathOCTVesRaw,'DimensionsFOVmm.mat'),'DimensionsFOVmm','-v7.3');
    end
    [xOCT_pix,yOCT_pix]=size(OCTA_data2D);
    PixSize=[DimensionsFOVmm]./[xOCT_pix,yOCT_pix];
    
    if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==0 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2
        if isequal(TumourMaskType,'TumourVOI')
            %% 3) Preparing multi-modal spatial coregistration in lateral plane
            PreviouslyAligned=0; %assumes initially not found
            %Co-registered optical/fluorescence for later reference
            TransverseOptFluRefFile=fullfile(SegFolder,'registered_fluorescence_Brightfield_toOCT.mat');
            %Had you already started performing coregistration then stopped and are now resuming
            PreviouslyAligned=exist(TransverseOptFluRefFile); %created in TwoDTumourMaskAlignmentPart_FunctionforSpeed3
            %Finding optical data used as reference during segmentation (identifying exudate)
            PotentialFolderTempOptFlu=fullfile(FolderConsidered,'Brightfield-Fluorescence');
            if exist(fullfile(SegFolder,'CoregisteringOptFluFilepath.mat')) %%&& useprevious work
                load(fullfile(SegFolder,'CoregisteringOptFluFilepath.mat'))
                CoregisteringOptFluFile=ChangeFilePaths(DirectoryDataLetter, CoregisteringOptFluFile);
            else
                [optFlufilenameForCoregistration,optFluFolderForCoregistration]=uigetfile('*.jpg','Please select image of tumour to be coregistered to raw svOCT transversely',PotentialFolderTempOptFlu);
                CoregisteringOptFluFile=fullfile(optFluFolderForCoregistration,optFlufilenameForCoregistration);
                if optFluFolderForCoregistration~=0
                    save(fullfile(SegFolder,'CoregisteringOptFluFilepath.mat'),'CoregisteringOptFluFile','-v7.3');
                end
            end
        end
    end
    %% All files to be used
    BatchOfFolders{countBatchFolder,1}=fullfile(pathOCTVesRaw,filenameOCTVesRaw);%uigetdir(FileSelectDirectory,'Please select folders of datasets to be sv processed');
    if BinVesselsAlreadyPrepared==1
        BatchOfFolders{countBatchFolder,2}=fullfile(pathOCTVesBin,filenameOCTVesBin);
    end
    BatchOfFolders{countBatchFolder,3}=fullfile(pathStOCT,filenameStOCT);%uigetdir(FileSelectDirectory,'Please select folders of datasets to be sv processed');
    if isequal(TumourMaskType,'TumourVOI')
        if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==0 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2
            BatchOfFolders{countBatchFolder,5}=TransverseOptFluRefFile;%fullfile(optFluFolderForCoregistration,optFlufilenameForCoregistration);
        end
    end
    if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==0 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2
        if FoundTumourMask2DButCorrectAlignment==0 % was this not at all already not?
            if isequal(TumourMaskType,'TumourVOI')
                %% 4) Multi-modal co-registration (opt-flu image selected to OCTA)
                CorregistrationOptFluIsGood=0;%regardless of previous mask existing to assesss whether happy with previous mask or not
                
                [transform2D_OptFlu_OCT,Rfixed,CorregistrationOptFluIsGood]=TwoDTumourMaskAlignmentPart_FunctionforSpeed4(SegFolder,OCTA_data2D,CoregisteringOptFluFile, TryAutomaticAllignment,PreviouslyAligned);
                optFluCoregistered=imwarp(imwarp(imread(CoregisteringOptFluFile),transform2D_OptFlu_OCT{1}),transform2D_OptFlu_OCT{2},'OutputView',Rfixed);%imread(BatchOfJustFolders{countx,3});
                TransverseOptFluRefImg=figure; imagesc(optFluCoregistered), TransverseOptFluRefImg.Visible='off';
                saveas(TransverseOptFluRefImg, fullfile(SegFolder,'TransverseOptFlu_coregtoOCT_PreTime0-.png'));
                save(fullfile(SegFolder,'TransverseOptFlu_coregtoOCT_PreTime0-.mat'),'optFluCoregistered','-v7.3');
                
                %% 5) 2D lateral Tumour/ROI mask creation file selection
                if CorregistrationOptFluIsGood==1
                    %                                     if isequal(TumourMaskType,'TumourVOI')
                    GrossResponseDir=fullfile(DirectoryVesselsData,'GrossResponseMetrics');
                    if ~exist(GrossResponseDir,'dir')
                        mkdir(GrossResponseDir);
                    end
                    %if isempty(BatchOfFolders{countBatchFolder,4}) && ~(exist(fullfile(SegFolder,['TumourMask2D_aligned.mat']))==2)  %If none pre created will generate one (including steps of first coregistering to OCT then segmenting contour
                    if exist(fullfile(SegFolder,[PrefixFLU_BRI,'SegmentingFilepath.mat'])) %%&& useprevious work
                        load(fullfile(SegFolder,[PrefixFLU_BRI,'SegmentingFilepath.mat']))
                        SegmentingFile=ChangeFilePaths(DirectoryDataLetter, SegmentingFile);%adapting to whichever directory usb port for data is saved on
                    else
                        [optFlufilenameForSegmentation,optFluFolderForSegmentation]=uigetfile('*.jpg','Please select image of tumour to be segmented (coregistered to raw OCTA en face) transversely',PotentialFolderTempOptFlu);
                        SegmentingFile=fullfile(optFluFolderForSegmentation,optFlufilenameForSegmentation);
                        if optFluFolderForSegmentation~=0
                            save(fullfile(SegFolder,[PrefixFLU_BRI,'SegmentingFilepath.mat']),'SegmentingFile','-v7.3');
                        end
                    end
                    optFluFolderForSegmentation=fileparts(SegmentingFile);
                    optFluFolderForSegmentationdir=dir([optFluFolderForSegmentation,'*.jpg']);
                    PotentialFluFiles={optFluFolderForSegmentationdir(:).name};
                    if exist(fullfile(SegFolder,'FluFilepath.mat'))
                        load(fullfile(SegFolder,'FluFilepath.mat'))
                        FluFile=ChangeFilePaths(DirectoryDataLetter, FluFile);
                    else
                        if contains(PotentialFluFiles,['flu' exposureTimes_BriFlu(IndexMouse) '.jpg'])
                            FluFile=fullfile(optFluFolderForSegmentation,['flu' exposureTimes_BriFlu(IndexMouse) '.jpg']);%For viability metric
                        else
                            [Fluname, Flupath]=uigetfile('*.jpg','Please select image of tumour to be quantified for gross tumour response.',optFluFolderForSegmentation);
                            FluFile=fullfile(Flupath, Fluname);
                        end
                        if Flupath~=0
                            save(fullfile(SegFolder,'FluFilepath.mat'),'FluFile','-v7.3');
                        end
                    end
                    %% 6A) 2D transverse mask creation (tumour segmentation) with previously determined affine transform applied and quantification
                    if ~isempty(indxNotEmpty)
                        FluorescenceSegmentationAndMetricsFunc_v24_with_Contour_v8(CurrentTimepoint,Timepoint0Analyzed,PrefixFLU_BRI,MouseName,TimepointTrueAndRel,TimepointVarName,transform2D_OptFlu_OCT,Rfixed,GrossResponseDir,SegFolder,[],FluFile,SegmentingFile,OCTA_data2D,DoseReceivedUpToTP,DaysPrecise,SegmentationFolderTimepoint0{indxNotEmpty},MouseNameTimepoint0);%RawsvOCTFile
                    else
                        FluorescenceSegmentationAndMetricsFunc_v24_with_Contour_v8(CurrentTimepoint,Timepoint0Analyzed,PrefixFLU_BRI,MouseName,TimepointTrueAndRel,TimepointVarName,transform2D_OptFlu_OCT,Rfixed,GrossResponseDir,SegFolder,[],FluFile,SegmentingFile,OCTA_data2D,DoseReceivedUpToTP,DaysPrecise,[],MouseNameTimepoint0);%RawsvOCTFile
                    end
                    %                         elseif ~isempty(BatchOfFolders{countBatchFolder,4}) && FoundTumourMask2DButCorrectAlignment==0%If already created some mask but not yet quantified
                    %                             %% 6) 2D transverse mask creation (tumour segmentation) with previously determined affine transform applied and quantification % no need to reload reference flu
                    %FluorescenceSegmentationAndMetricsFunc_v23_with_Contour_v7(MouseName,Timepoint,TimepointVarName,transform2D_OptFlu_OCT,Rfixed,GrossResponseDir,OptFluSegmentationFolder,BatchOfFolders{countBatchFolder,4},FluFile,SegmentingFile,OCTA_data2D);%RawsvOCTFile
                    %end
                    if exist(fullfile(SegFolder,[PrefixFLU_BRI,'TumourMask2D_aligned.mat']))%did it get created successfully?
                        fprintf('Tumour mask 2D successfully created.\n');
                    else
                        error('Tumour mask 2D not successfully created.\n');
                    end
                    
                else
                    error('retry coregistration')
                end
            elseif isequal(TumourMaskType,'PrismVOI')
                %% 6B) 2D Mask creation for bare skin window chambers (no tumours to segment)
                TumourMask2D_aligned=zeros([DimsVesselsRaw3D(2),DimsVesselsRaw3D(3)]);%(x,y)
                %                      PixPermm_x=DimsVesselsRaw3D(2)/width_x;
                %                      PixPermm_y=DimsVesselsRaw3D(3)/width_y;
                ExtractedSquareRangex=(round(DimensionsFOVmm(1)/6/PixSize(1))):(round(5*DimensionsFOVmm(1)/6/PixSize(1)));%(round(width_x/6):round(5*width_x/6))*PixPermm_x;
                ExtractedSquareRangey=(round(DimensionsFOVmm(2)/6/PixSize(2))):(round(5*DimensionsFOVmm(2)/6/PixSize(2)));%(round(width_y/6):round(5*width_y/6))*PixPermm_x;
                TumourMask2D_aligned(ExtractedSquareRangex,ExtractedSquareRangey)=1;
                save(fullfile(SegFolder,[PrefixFLU_BRI,'TumourMask2D_aligned.mat']),'TumourMask2D_aligned','-v7.3')
            end
        elseif FoundTumourMask2DButCorrectAlignment==2 % at least an intermediate was somehow created
            if isequal(TumourMaskType,'TumourVOI')
                if ~exist(fullfile(SegFolder,'TransverseOptFlu_coregtoOCT_PreTime0-.mat'))
                    %% 6.1) Multi-modal co-registration (opt-flu image selected to OCTA)
                    CorregistrationOptFluIsGood=0;%regardless of previous mask existing to assesss whether happy with previous mask or not
                    
                    [transform2D_OptFlu_OCT,Rfixed,CorregistrationOptFluIsGood]=TwoDTumourMaskAlignmentPart_FunctionforSpeed4(SegFolder,OCTA_data2D,CoregisteringOptFluFile, TryAutomaticAllignment,PreviouslyAligned);
                    optFluCoregistered=imwarp(imwarp(imread(CoregisteringOptFluFile),transform2D_OptFlu_OCT{1}),transform2D_OptFlu_OCT{2},'OutputView',Rfixed);%imread(BatchOfJustFolders{countx,3});
                    TransverseOptFluRefImg=figure, imagesc(optFluCoregistered), TransverseOptFluRefImg.Visible='off'
                    saveas(TransverseOptFluRefImg, fullfile(SegFolder,'TransverseOptFlu_coregtoOCT_PreTime0-.png'));
                    save(fullfile(SegFolder,'TransverseOptFlu_coregtoOCT_PreTime0-.mat'),'optFluCoregistered','-v7.3');
                end
            end
            %% 6.2) Load pre-drawn or just drawn 2D mask (already from brightfield/fluorescence co-registered during manual vascular segmentation)
            mask2D=load(BatchOfFolders{countBatchFolder,4});
            MaskVarname=whos('-file',BatchOfFolders{countBatchFolder,4});
            TumourMask2D_aligned=imresize(mask2D.(MaskVarname.name),size(OCTA_data2D));
            clearvars mask2D
            save(fullfile(SegFolder,[PrefixFLU_BRI,'TumourMask2D_aligned.mat']),'TumourMask2D_aligned','-v7.3')
            if ~exist(fullfile(SegFolder,[PrefixFLU_BRI,'Mask2DPreCoregTime0-ForScaling.mat']))
                TumourMask2DPreCoregTime0=TumourMask2D_aligned;
                save(fullfile(SegFolder,[PrefixFLU_BRI,'Mask2DPreCoregTime0-ForScaling.mat']),'TumourMask2DPreCoregTime0','-v7.3')
            end
        end
    end
end
    if isequal(TumourMaskType,'TumourVOI')
        load(fullfile(SegFolder,'TransverseOptFlu_coregtoOCT_PreTime0-.mat'));%reference image for brightfield fluorescence coregistration
    end
if Neither_0_glass_1_Tissue_2_both_3_contour~=0
%% 7) Depth Corregistration to Day 0 OCT (by glass removal and rotation
%DimsVesselsRaw3D=size(RawOCTALateralCoregistered)
%% Contour the top surface of OCT volume
% Removing empty space above tumour in window chamber and glass slip in the
% B-scan view--> slice by slice for 30 slices across (laterally (each slice is along the axial direction, but we look at a few every few 100microns along x or y))
%%No glass for PDXovo
if exist(fullfile(MaskCreationDraft{1},'zline_GlassTop_uncoregTime0-.mat')) && Neither_0_glass_1_Tissue_2_both_3_contour==1 || exist(fullfile(MaskCreationDraft{2},'zline_TissueTop_uncoregTime0-.mat')) && Neither_0_glass_1_Tissue_2_both_3_contour==2 || (exist(fullfile(MaskCreationDraft{1},'zline_GlassTop_uncoregTime0-.mat')) && exist(fullfile(MaskCreationDraft{2},'zline_TissueTop_uncoregTime0-.mat'))) && Neither_0_glass_1_Tissue_2_both_3_contour==3
    AutoProcess=1;
else
    AutoProcess=0;
end
%% 8) Identification of bottom surface of glass
%             if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==0 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2
if Neither_0_glass_1_Tissue_2_both_3_contour==1||Neither_0_glass_1_Tissue_2_both_3_contour==3
    if ~exist(fullfile(MaskCreationDraft{1},'mask3D_GlassExc_uncoregTime0-.mat'))
        mask_3DGlass=ContouringFunctionFilesLoadedOrMatFile12_RatioDimensions(DimsVesselsRaw3D,num_contoured_slices(1),[MouseName,' ',TimepointTrueAndRel],BatchOfFolders,countBatchFolder, fullfile(MaskCreationDraft{1},'zline_GlassTop_uncoregTime0-.mat'),fullfile(MaskCreationDraft{1},'zline_GlassBot_uncoregTime0-.mat'),fullfile(MaskCreationDraft{1},'mask3D_GlassInc_uncoregTime0-.mat'),fullfile(MaskCreationDraft{1},'mask3D_GlassExc_uncoregTime0-.mat'),saveFolder{1},MaskCreationDraft{1},'Matfile',AutoProcess,OSremoval,Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2,GlassThickness_200PixDepth,DataCroppedNotResizedInDepth,ReferencePixDepth);%,umPerPix_For200PixDepth);%             [mask_3D_NoGlass_NotCoreg]= ContouringFunctionFilesLoadedOrMatFile7_batchProc(num_contoured_slices_Top,[MouseName,' ',Timepoint],stOCTLateralCoregistered,vessels_processed_binaryLateralCoregistered,DimsVesselsRaw3D, fullfile(GlassRemovalDraft,'zline_GlassTop.mat'),fullfile(GlassRemovalDraft,'zline_GlassBot.mat'),fullfile(saveFolder,'mask_3D_YesGlassUnrotated.mat'),fullfile(saveFolder,'mask_3D_NoGlassUnrotated.mat'),saveFolder,GlassRemovalDraft,AutoProcess,OSremoval);
    else
        if (Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2)
            mask_3DGlassTemp=load(fullfile(MaskCreationDraft{1},'mask3D_GlassExc_uncoregTime0-.mat'))
            mask_3DGlassVarname=whos('-file',fullfile(MaskCreationDraft{1},'mask3D_GlassExc_uncoregTime0-.mat'))
            mask_3DGlass=mask_3DGlassTemp.(mask_3DGlassVarname.name);
            clearvars mask_3DGlassTemp
        end
    end
end
if Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed
    %% 9) Lateral Corregistration to Day 0 OCT if previously not done by 3D rigid transform
    %First coregister transversely (by looking at large vessels which do not change as quickly as microvasculature then adjust axially by looking at glass in ~firs B-scan and in ~final B-scan Try also this? https://www.mathworks.com/help/images/registering-multimodal-3-d-medical-images.html
    %If we are not dealing with the first timepoint 0- is determined
    
    if ~(-1<DaysPrecise && DaysPrecise<=0)% for TPx %if ~(sum(contains(DirectoryInitialTimepoints,NameDayFormat),'all') && contains(NameDayFormat,DirectoriesBareSkinMiceKeyword)) && ~(contains(NameDayFormat,DirectoryInitialTimepoints) && contains(BatchOfFolders{countBatchFolder,1},'pre'))%those with tumours have pre and post timepoints
        %% Determine specifically which mouse timepoint 0- should be loaded%for RefMiceCount=1:length(DirectoryInitialTimepoints) if contains(DirectoryInitialTimepoints{RefMiceCount},MouseName)
        for iv=1:length(RawVasculatureFileKeywordRaw)
            if exist(fullfile(fileparts(InitialTimepointtxtFile),RawVasculatureFileKeywordRaw{iv}))
                InitialTimepointFile=fullfile(fileparts(InitialTimepointtxtFile),RawVasculatureFileKeywordRaw{iv});
            end
        end
        if isempty(InitialTimepointFile)
            if exist(fullfile(fileparts(InitialTimepointtxtFile),'OCTA_path.mat'),'file')
                load(fullfile(fileparts(InitialTimepointtxtFile),'OCTA_path.mat'))
                InitialTimepointFile=ChangeFilePaths(DirectoryDataLetter, InitialTimepointFile);
            else
                [filenameOCTVesRaw_Time0,pathOCTVesRaw_Time0]=uigetfile(fullfile(DirectoryVesselsData,MouseName),'Please select RAW OCTA-processed data file for timepoint 0-');
                InitialTimepointFile=fullfile(pathOCTVesRaw_Time0,filenameOCTVesRaw_Time0);
                save(fullfile(fileparts(InitialTimepointtxtFile),'OCTA_path.mat'),'InitialTimepointFile','-v7.3')
                if filenameOCTVesRaw_Time0==0
                    error('No reference timepoint found')
                end
            end
        end
        
        if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==0 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2
            %% Now to perform user temporal lateral co-registration
            OCTLateralCoregFile=fullfile(TumourMaskAndStepsDir,'registered_OCT2DLateral_toOCTtime0.mat');
            OCTA2DPreviouslycoregistered=exist(OCTLateralCoregFile);
            %% Find transform corregister 2D to timepoint 0-
            [transform2DLateral,transform3DLateral_OCT_Time0Pre,R2Dfixed,R3Dfixed,~,~]=Two_ThreeDCoregisterOCT_FunctionforSpeed5(OCTLateralTimepointCoregistrationFolder,InitialTimepointFile,OCTA_data2D,TryAutomaticAllignment,OCTLateralCoregFile,OCTA2DPreviouslycoregistered,OptFluSegmentationFolder);
            if isequal(TumourMaskType,'TumourVOI')
                optFluCoregistered_ToTime0pre=imwarp(imwarp(optFluCoregistered,transform2DLateral{1}),transform2DLateral{2},'OutputView',R2Dfixed);%imread(BatchOfJustFolders{countx,3});
                TransverseOptFluRefImg=figure; imagesc(optFluCoregistered_ToTime0pre), TransverseOptFluRefImg.Visible='off';
                saveas(TransverseOptFluRefImg, fullfile(OCTLateralTimepointCoregistrationFolder,'TransverseOptFlu_coregtoOCT_coregtoTime0-.png'));
                clearvars TransverseOptFluRefImg
            end
            %if exist(fullfile(OptFluSegmentationFolder,'TumourMask2D_aligned.mat'))
            load(fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI,'TumourMask2D_aligned.mat']));
            %end
            TumourMask2D_aligned_coregTime0=imwarp(imwarp(TumourMask2D_aligned,transform2DLateral{1}),transform2DLateral{2},'OutputView',R2Dfixed);
            save(fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI,'TumourMask2D_aligned_coregTime0.mat']),'TumourMask2D_aligned_coregTime0','-v7.3')
        elseif Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1
            load(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration3DTime0--FOV.mat'));
            load(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration3DTime0--AffineTransformation.mat'));
        end
        BatchOfFolders{countBatchFolder,4}=fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI,'TumourMask2D_aligned_coregTime0.mat']);%already previously created under this name if did 0 or 2
        %% Tissue contouring will only be performed if have enough memory on computer (as determined by user)
        %(so if have enough memory to perform rotation and translation
        %operation for glass removal (Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1))
        %Hence computer will be safe to apply the rigid transforms to the full
        %data volumes prior to co-registration operation
        if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2
            if Neither_0_glass_1_Tissue_2_both_3_contour==1||Neither_0_glass_1_Tissue_2_both_3_contour==3
                % Creation of 3D mask pre coreg time0-, no need to save coreg
                % to time0-
                load(fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI,'TumourMask2D_aligned.mat']))
                tumor_maskProj3DRot=shiftdim(repmat(TumourMask2D_aligned,[1,1,DimsVesselsRaw3D(1)]),2);
                mask_3D_Unrestricted_UnCoregT0=logical(mask_3DGlass) & tumor_maskProj3DRot;%mask_3D_Top & %flip(mask_3D_Top & tumor_maskProj3DRot,3);
                mask_3D_CylindricalProjection_UnCoregT0=tumor_maskProj3DRot;
                save(SaveFilenameDataCylindricalProj_UnCoregT0{1},[PrefixFLU_BRI,'mask_3D_CylindricalProjection_UnCoregT0'],'-mat','-v7.3');
                save(SaveFilenameDataUnlimited_UnCoregT0{1},[PrefixFLU_BRI,'mask_3D_Unrestricted_UnCoregT0'],'-mat','-v7.3');
                clearvars tumor_maskProj3DRot mask_3D_Unrestricted_UnCoregT0 mask_3D_CylindricalProjection_UnCoregT0
                %                    if glass_1_Tissue_2_both_3_contour==1
                %Add rotation of tissue here if glass_1_Tissue_2_both_3_contour==3 %if glass_1_Tissue_2_both_3_contour==2||glass_1_Tissue_2_both_3_contour==3
                %% 10)
                %% rotation and translation of tissue to remove glass if glass was contoured (if applicable)
                %% Loading files
                Structure_UnCoregT0_RotatedShiftedTemp=matfile(fullfile(pathStOCT,filenameStOCT));%uigetdir(FileSelectDirectory,'Please select folders of datasets to be sv processed');
                stOCTVarname=whos('-file',BatchOfFolders{countBatchFolder,3});
                StOCT_UnCoregT0_RotatedShifted=imresize3(Structure_UnCoregT0_RotatedShiftedTemp.(stOCTVarname.name),DimsVesselsRaw3D);
                RawOCTA_UnCoregT0_RotatedShifted=RawOCTA_temp.(RawOCTAVarname.name);
                clearvars RawOCTA_temp Structure_UnCoregT0_RotatedShiftedTemp
                %try tall matrices for efficiency or doing struct on its own save then offload memory, etc.
                %mask_3D_NoGlass=imresize3(mask_3D_NoGlass,DimsVesselsRaw3D);
                FloorOmissionMask=mask_3DGlass;
                ylim=size(StOCT_UnCoregT0_RotatedShifted,3);
                xlim=size(StOCT_UnCoregT0_RotatedShifted,2);
                zlim=size(StOCT_UnCoregT0_RotatedShifted,1);
                if BinVesselsAlreadyPrepared==1
                    BinOCTA_UnCoregT0_RotatedShiftedTemp=matfile(BatchOfFolders{countBatchFolder,2});
                    BinOCTATime0Varname=whos('-file',BatchOfFolders{countBatchFolder,2});
                    BinOCTA_UnCoregT0_RotatedShifted=imresize3(BinOCTA_UnCoregT0_RotatedShiftedTemp.(BinOCTATime0Varname.name),DimsVesselsRaw3D);
                    clearvars BinOCTA_UnCoregT0_RotatedShiftedTemp
                    parfor yInd=1:ylim%going through all B-scans
                        for xInd=1:xlim%going through each A-scan
                            %Determine z-shift required
                            zShiftReq=-(find(mask_3DGlass(:,xInd,yInd)>0,1,'first')-1)%level of bottom of glass marked
                            StOCT_UnCoregT0_RotatedShifted(:,xInd,yInd)=circshift(StOCT_UnCoregT0_RotatedShifted(:,xInd,yInd),zShiftReq,1);
                            %StructureRotatedShifted(zlim-(zShiftReq-1):zlim,xInd,yInd)=0;
                            RawOCTA_UnCoregT0_RotatedShifted(:,xInd,yInd)=circshift(RawOCTA_UnCoregT0_RotatedShifted(:,xInd,yInd),zShiftReq,1);
                            BinOCTA_UnCoregT0_RotatedShifted(:,xInd,yInd)=circshift(BinOCTA_UnCoregT0_RotatedShifted(:,xInd,yInd),zShiftReq,1);
                            FloorOmissionMask(:,xInd,yInd)=circshift(mask_3DGlass(:,xInd,yInd),zShiftReq,1);
                        end
                    end
                else
                    parfor yInd=1:ylim%going through all B-scans
                        for xInd=1:xlim%going through each A-scan
                            %Determine z-shift required
                            zShiftReq=-(find(mask_3DGlass(:,xInd,yInd)>0,1,'first')-1)%level of bottom of glass marked
                            StOCT_UnCoregT0_RotatedShifted(:,xInd,yInd)=circshift(StOCT_UnCoregT0_RotatedShifted(:,xInd,yInd),zShiftReq,1);
                            %StructureRotatedShifted(zlim-(zShiftReq-1):zlim,xInd,yInd)=0;
                            RawOCTA_UnCoregT0_RotatedShifted(:,xInd,yInd)=circshift(RawOCTA_UnCoregT0_RotatedShifted(:,xInd,yInd),zShiftReq,1);
                            FloorOmissionMask(:,xInd,yInd)=circshift(mask_3DGlass(:,xInd,yInd),zShiftReq,1);
                        end
                    end
                end
                %% since top containing window chamber glass is now wrapped around to the bottom, that needs to be remove
                StOCT_UnCoregT0_RotatedShifted=double(StOCT_UnCoregT0_RotatedShifted).*double(FloorOmissionMask);
                save(fullfile(saveFolder{1},'RawStruct_UnCoregTime0-_RotShift.mat'),'StOCT_UnCoregT0_RotatedShifted','-v7.3');
                RawStructtemp.StOCT_UnCoregT0_RotatedShifted=StOCT_UnCoregT0_RotatedShifted;
                clearvars StOCT_UnCoregT0_RotatedShifted
                RawOCTA_UnCoregT0_RotatedShifted=double(RawOCTA_UnCoregT0_RotatedShifted).*double(FloorOmissionMask);
                save(fullfile(saveFolder{1},'RawVess_UnCoregTime0-_RotShift.mat'),'RawOCTA_UnCoregT0_RotatedShifted','-v7.3');
                RawVesstemp.RawOCTA_UnCoregT0_RotatedShifted=RawOCTA_UnCoregT0_RotatedShifted;
                clearvars RawOCTA_UnCoregT0_RotatedShifted
                if BinVesselsAlreadyPrepared==1
                    BinOCTA_UnCoregT0_RotatedShifted=logical(BinOCTA_UnCoregT0_RotatedShifted).*logical(FloorOmissionMask);
                    save(fullfile(saveFolder{1},'BinVess_UnCoregTime0-_RotShift.mat'),'BinOCTA_UnCoregT0_RotatedShifted','-v7.3');
                    BinVesstemp.BinOCTA_UnCoregT0_RotatedShifted=BinOCTA_UnCoregT0_RotatedShifted;
                    clearvars BinOCTA_UnCoregT0_RotatedShifted
                end
                if Neither_0_glass_1_Tissue_2_both_3_contour==3 && ActiveMemoryOffload==1%Multiple files processes
                    clearvars RawStructtemp RawVesstemp BinVesstemp mask_3DGlass%StOCT_UnCoregT0_RotatedShifted RawOCTA_UnCoregT0_RotatedShifted BinOCTA_UnCoregT0_RotatedShifted
                end
                clearvars FloorOmissionMask
            end
            %% 8.b) Identification of tissue surface if applicable
            % Doing now so the coregistration helps in the tracing
            if (Neither_0_glass_1_Tissue_2_both_3_contour==2||Neither_0_glass_1_Tissue_2_both_3_contour==3) && Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed 
                if OnlyTissueLabelTimepoint0==1
                    MaskCreationDraftTemp=strsplit(MaskCreationDraft{2},'\');
                    PotentialFile1=fullfile(SegmentationFolderTimepoint0{2},MaskCreationDraftTemp{end},'mask3D_TissueOnly_uncoregTime0-.mat');
                    PotentialFile2=fullfile(SegmentationFolderTimepoint0{2},MaskCreationDraftTemp{end},'mask3D_TissueAndAllBelow_uncoregTime0-.mat')% To check whether to take the time to recreate the mask or never previously created
                    if (-1<DaysPrecise && DaysPrecise<=0) && (~exist(PotentialFile1,'file')||~exist(PotentialFile2,'file'))
                        mask_3DTissue=ContouringFunctionFilesLoadedOrMatFile13_RatioDimensionsTis(DimsVesselsRaw3D,num_contoured_slices(2),[MouseName,' ',TimepointTrueAndRel],BatchOfFolders,countBatchFolder, fullfile(MaskCreationDraft{2},'zline_TissueTop_uncoregTime0-.mat'),fullfile(MaskCreationDraft{2},'zline_TissueBot_uncoregTime0-.mat'),fullfile(MaskCreationDraft{2},'mask3D_TissueAndAllBelow_uncoregTime0-.mat'),fullfile(MaskCreationDraft{2},'mask3D_TissueOnly_uncoregTime0-.mat'),saveFolder{2},MaskCreationDraft{2},'Matfile',AutoProcess,OSremoval,Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2);%,umPerPix_For200PixDepth);%             [mask_3D_NoGlass_NotCoreg]= ContouringFunctionFilesLoadedOrMatFile7_batchProc(num_contoured_slices_Top,[MouseName,' ',Timepoint],stOCTLateralCoregistered,vessels_processed_binaryLateralCoregistered,DimsVesselsRaw3D, fullfile(GlassRemovalDraft,'zline_GlassTop.mat'),fullfile(GlassRemovalDraft,'zline_GlassBot.mat'),fullfile(saveFolder,'mask_3D_YesGlassUnrotated.mat'),fullfile(saveFolder,'mask_3D_NoGlassUnrotated.mat'),saveFolder,GlassRemovalDraft,AutoProcess,OSremoval);
                    else Add the option in ContouringFunctionFilesLoadedOrMatFile13_RatioDimensionsTis to call timepoint 0 contours
                        if (Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2)
                            if exist(PotentialFile1,'file')%load(
                                Mask3DTissueTemp=matfile(PotentialFile1)
                                Mask3DTissueVarname=whos('-file',PotentialFile1);
                                mask_3DTissue=Mask3DTissueTemp.(Mask3DTissueVarname.name);
                                save(fullfile(MaskCreationDraft{2},'mask3D_TissueOnly_usedFromT0-Path.mat'),'PotentialFile1','-v7.3');%file copied from timepoint 0- just not yet rotated to fit within constraints of glass here
                            elseif exist(PotentialFile2,'file')%load(
                                Mask3DTissueTemp=matfile(PotentialFile2)
                                Mask3DTissueVarname=whos('-file',PotentialFile2);
                                mask_3DTissue=Mask3DTissueTemp.(Mask3DTissueVarname.name);
                                save(fullfile(MaskCreationDraft{2},'mask3D_TissueAndAllBelow_usedFromT0-Path.mat'),'PotentialFile2','-v7.3');%file copied from timepoint 0- just not yet rotated to fit within constraints of glass here
                            end
                            clearvars Mask3DTissueTemp
                        else
                            mask_3DTissue=[];
                        end
                    end
                elseif OnlyTissueLabelTimepoint0==0
                    PotentialFile1=fullfile(MaskCreationDraft{2},'mask3D_TissueAndAllBelow_uncoregTime0-.mat');
                    PotentialFile2=fullfile(MaskCreationDraft{2},'mask3D_TissueOnly_uncoregTime0-.mat');
                    if (~exist(PotentialFile1,'file')||~exist(PotentialFile2,'file')) && (Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2)
                        if Neither_0_glass_1_Tissue_2_both_3_contour==2
                            stOCTCoregLateral=
                            RawOCTACoregLateral=
                            BinOCTACoregLateral=
                            mask_3DTissue=ContouringFunctionFilesLoadedOrMatFile12_RatioDimensionsTis(DimsVesselsRaw3D,num_contoured_slices(2),[MouseName,' ',TimepointTrueAndRel],BatchOfFolders,countBatchFolder, fullfile(MaskCreationDraft{2},'zline_TissueTop_uncoregTime0-.mat'),fullfile(MaskCreationDraft{2},'zline_TissueBot_uncoregTime0-.mat'),fullfile(MaskCreationDraft{2},'mask3D_TissueAndAllBelow_uncoregTime0-.mat'),fullfile(MaskCreationDraft{2},'mask3D_TissueOnly_uncoregTime0-.mat'),saveFolder{2},MaskCreationDraft{2},'Matfile',AutoProcess,OSremoval,Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2);%,umPerPix_For200PixDepth);%             [mask_3D_NoGlass_NotCoreg]= ContouringFunctionFilesLoadedOrMatFile7_batchProc(num_contoured_slices_Top,[MouseName,' ',Timepoint],stOCTLateralCoregistered,vessels_processed_binaryLateralCoregistered,DimsVesselsRaw3D, fullfile(GlassRemovalDraft,'zline_GlassTop.mat'),fullfile(GlassRemovalDraft,'zline_GlassBot.mat'),fullfile(saveFolder,'mask_3D_YesGlassUnrotated.mat'),fullfile(saveFolder,'mask_3D_NoGlassUnrotated.mat'),saveFolder,GlassRemovalDraft,AutoProcess,OSremoval);
                            if Neither_0_glass_1_Tissue_2_both_3_contour==2
                                stOCTCoregFull=
                                RawOCTACoregFull=
                                BinOCTACoregFull=
                            end
                        else %Already created
                            if exist(PotentialFile1,'file')%load(
                                Mask3DTissueTemp=matfile(PotentialFile1)
                                Mask3DTissueVarname=whos('-file',PotentialFile1);
                                mask_3DTissue=Mask3DTissueTemp.(Mask3DTissueVarname.name);
                                save(fullfile(MaskCreationDraft{2},'mask3D_TissueOnly_usedFromT0-Path.mat'),'PotentialFile1','-v7.3');%file copied from timepoint 0- just not yet rotated to fit within constraints of glass here
                            elseif exist(PotentialFile2,'file')%load(
                                Mask3DTissueTemp=matfile(PotentialFile2)
                                Mask3DTissueVarname=whos('-file',PotentialFile2);
                                mask_3DTissue=Mask3DTissueTemp.(Mask3DTissueVarname.name);
                                save(fullfile(MaskCreationDraft{2},'mask3D_TissueAndAllBelow_usedFromT0-Path.mat'),'PotentialFile2','-v7.3');%file copied from timepoint 0- just not yet rotated to fit within constraints of glass here
                            end
                            clearvars Mask3DTissueTemp
                        end
                    end
                end
            end
            %% Application of tissue mask without co-registration --maybe no good anymore
            %                    if glass_1_Tissue_2_both_3_contour==2||glass_1_Tissue_2_both_3_contour==3 %no flattening of tissue (distort vessel shape similar to non-similarity affine transform
            %                     %% Tissue mask application if applicable
            %                        %% Loading files
            %                     if OnlyTissueLabelTimepoint0==0
            %                         StOCT_UnCoregT0_TissueMaskAppliedTemp=matfile(fullfile(pathStOCT,filenameStOCT));%uigetdir(FileSelectDirectory,'Please select folders of datasets to be sv processed');
            %                                     stOCTVarname=whos('-file',BatchOfFolders{countBatchFolder,3});
            %                             StOCT_UnCoregT0_TissueMaskApplied=imresize3(StOCT_UnCoregT0_TissueMaskAppliedTemp.(stOCTVarname.name),DimsVesselsRaw3D);
            %                         if glass_1_Tissue_2_both_3_contour==3
            %                             RawOCTA_temp=matfile(fullfile(pathOCTVesRaw,filenameOCTVesRaw));
            %                             RawOCTAVarname=whos('-file',fullfile(pathOCTVesRaw,filenameOCTVesRaw));
            %                         end
            %                         RawOCTA_UnCoregT0_TissueMaskApplied=RawOCTA_temp.(RawOCTAVarname.name);
            %                             clearvars RawOCTA_temp StOCT_UnCoregT0_TissueMaskAppliedTemp
            %
            %                         StOCT_UnCoregT0_TissueMaskApplied=double(StOCT_UnCoregT0_TissueMaskApplied).*double(mask_3DTissue);
            %                             save(fullfile(saveFolder{2},'RawStruct_UnCoregTime0-_CurrentTP_TissueMaskApp.mat'),'StOCT_UnCoregT0_TissueMaskApplied','-v7.3');
            %                                 RawStructtemp.StOCT_UnCoregT0_TissueMaskApplied=StOCT_UnCoregT0_TissueMaskApplied;
            %                                             clearvars StOCT_UnCoregT0_TissueMaskApplied
            %                         RawOCTA_UnCoregT0_TissueMaskApplied=double(RawOCTA_UnCoregT0_TissueMaskApplied).*double(mask_3DTissue);
            %                             save(fullfile(saveFolder{2},'RawVess_UnCoregTime0-_CurrentTP_TissueMaskApp.mat'),'RawOCTA_UnCoregT0_TissueMaskApplied','-v7.3');
            %                                 RawVesstemp.RawOCTA_UnCoregT0_TissueMaskApplied=RawOCTA_UnCoregT0_TissueMaskApplied;
            %                                             clearvars RawOCTA_UnCoregT0_TissueMaskApplied
            %                         if BinVesselsAlreadyPrepared==1
            %                             BinOCTA_UnCoregT0_TissueMaskAppliedTemp=matfile(BatchOfFolders{countBatchFolder,2});
            %                                        BinOCTATime0Varname=whos('-file',BatchOfFolders{countBatchFolder,2});
            %                                        BinOCTA_UnCoregT0_TissueMaskApplied=imresize3(BinOCTA_UnCoregT0_TissueMaskAppliedTemp.(BinOCTATime0Varname.name),DimsVesselsRaw3D);
            %                                        clearvars BinOCTA_UnCoregT0_TissueMaskAppliedTemp
            %                             BinOCTA_UnCoregT0_TissueMaskApplied=logical(BinOCTA_UnCoregT0_TissueMaskApplied).*logical(mask_3DTissue);
            %                             save(fullfile(saveFolder{2},'BinVess_UnCoregTime0-_CurrentTP_TissueMaskApp.mat'),'BinOCTA_UnCoregT0_TissueMaskApplied','-v7.3');
            %                                     BinVesstemp.BinOCTA_UnCoregT0_TissueMaskApplied=BinOCTA_UnCoregT0_TissueMaskApplied;
            %                                             clearvars BinOCTA_UnCoregT0_TissueMaskApplied
            %                         end
            %                     if glass_1_Tissue_2_both_3_contour==3 && ActiveMemoryOffload==1%Multiple files processes
            %                                 clearvars RawStructtemp RawVesstemp BinVesstemp mask_3DTissue%StOCT_UnCoregT0_TissueMaskApplied RawOCTA_UnCoregT0_TissueMaskApplied BinOCTA_UnCoregT0_TissueMaskApplied
            %                     end
            %                     end %Not worth doing if based on TP0-
            %                    end
            
            %% Regardless whether files previously loaded or not for the moment--maybe inefficient:
            %% Rotating tissue contour from current timepoint using current timepoint glass contour
            % or Timepoint0- tissue contour rotated using glass
            % contour from timepoint 0- (OCT data rotated in
            % glass_1_Tissue_2_both_3_contour==1 for
            % glass_1_Tissue_2_both_3_contour==3 and OnlyTissueLabelTimepoint0==1)
            if (Neither_0_glass_1_Tissue_2_both_3_contour==3) && Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed
                if exist(fullfile(MaskCreationDraft{1},'mask3D_GlassExc_uncoregTime0-.mat'))
                    if OnlyTissueLabelTimepoint0==1
                        if (-1<DaysPrecise && DaysPrecise<=0)
                            MaskCreationDraftTemp=strsplit(MaskCreationDraft{2},'\');
                            PotentialFile1=fullfile(SegmentationFolderTimepoint0{2},MaskCreationDraftTemp{end},'mask3D_TissueOnly_uncoregTime0-.mat');
                            PotentialFile2=fullfile(SegmentationFolderTimepoint0{2},MaskCreationDraftTemp{end},'mask3D_TissueAndAllBelow_uncoregTime0-.mat');
                            if ActiveMemoryOffload==1
                                if exist(PotentialFile1,'file')%load(
                                    Mask3DTissueTemp=matfile(PotentialFile1)
                                    Mask3DTissueVarname=whos('-file',PotentialFile1);
                                    Mask3DGlassTemp=matfile(fullfile(MaskCreationDraft{1},'mask3D_GlassExc_uncoregTime0-.mat'));
                                    Mask3DGlassVarname=whos('-file',fullfile(MaskCreationDraft{1},'mask3D_GlassExc_uncoregTime0-.mat'));
                                elseif exist(PotentialFile2,'file');%load(
                                    Mask3DTissueTemp=matfile(PotentialFile2);
                                    Mask3DTissueVarname=whos('-file',PotentialFile2);
                                    Mask3DGlassTemp=matfile(fullfile(MaskCreationDraft{1},'mask3D_GlassExc_uncoregTime0-.mat'));
                                    Mask3DGlassVarname=whos('-file',fullfile(MaskCreationDraft{1},'mask3D_GlassExc_uncoregTime0-.mat'));
                                end
                                mask_3DTissue_FromT0_CoregT0InZ=Mask3DTissueTemp.(Mask3DTissueVarname.name);
                                clearvars Mask3DTissueTemp
                                mask_3DGlass=Mask3DGlassTemp.(Mask3DGlassVarname.name);
                                clearvars Mask3DGlassTemp
                            else
                                mask_3DTissue_FromT0_CoregT0InZ=mask_3DTissue;
                                clearvars mask_3DTissue
                            end
                            
                            FloorOmissionMask=mask_3DGlass;
                            ylim=DimsVesselsRaw3D(3)
                            xlim=DimsVesselsRaw3D(2)
                            zlim=DimsVesselsRaw3D(1)
                            %                                                 ylim=size(StOCT_UnCoregT0_RotatedShifted,3);
                            %                                                 xlim=size(StOCT_UnCoregT0_RotatedShifted,2);
                            %                                                 zlim=size(StOCT_UnCoregT0_RotatedShifted,1);
                            parfor yInd=1:ylim%going through all B-scans
                                for xInd=1:xlim%going through each A-scan
                                    %Determine z-shift required
                                    zShiftReq=-(find(mask_3DGlass(:,xInd,yInd)>0,1,'first')-1)%level of bottom of glass marked
                                    %StructureRotatedShifted(zlim-(zShiftReq-1):zlim,xInd,yInd)=0;
                                    mask_3DTissue_FromT0_CoregT0InZ(:,xInd,yInd)=circshift(mask_3DTissue_FromT0_CoregT0InZ(:,xInd,yInd),zShiftReq,1);
                                    FloorOmissionMask(:,xInd,yInd)=circshift(mask_3DGlass(:,xInd,yInd),zShiftReq,1);
                                end
                            end
                            
                            
                            mask_3DTissue_FromT0_CoregT0InZ=logical(mask_3DTissue_FromT0_CoregT0InZ).*logical(FloorOmissionMask);
                            PathRotTissueMask=fullfile(SegmentationFolderTimepoint0{2},'TissueMask_isT0_CoregT0InZ.mat');
                            if (-1<DaysPrecise && DaysPrecise<=0) && ~exist(PathRotTissueMask,'file')%fullfile(SegmentationFolderTimepoint0{2},'TissueMask_CurrentTP_CoregT0InZ.mat'))%No difference so might as well save both at the same time
                                save(PathRotTissueMask,'mask_3DTissue_FromT0_CoregT0InZ','-v7.3');
                                %save(fullfile(SegmentationFolderTimepoint0{2},'TissueMask_CurrentTP_CoregT0InZ.mat'),'mask_3DTissue_FromT0_CoregT0InZ','-v7.3');
                            end
                            if exist(PathRotTissueMask,'file')%if the file from timepoint 0 already processed
                                save(fullfile(saveFolder{2},'TissueMask_isT0_CoregT0InZPath.mat'),'PathRotTissueMask');
                                save(fullfile(fileparts(InitialTimepointtxtFile),'TissueMask_isT0_CoregT0InZPath.mat'),'PathRotTissueMask');
                            end
                            if ActiveMemoryOffload==1 %clearing memory if applicable (not doing this will save time later in loading files
                                clearvars mask_3DTissue_FromT0_CoregT0InZ mask_3DGlass
                            else
                                tissueMaskTemp.mask_3DTissue_FromT0_CoregT0InZ=mask_3DTissue_FromT0_CoregT0InZ;
                                clearvars mask_3DTissue_FromT0_CoregT0InZ
                            end
                        elseif ~(-1<DaysPrecise && DaysPrecise<=0)
                            %                                 Do not imwarp mask_3DTissue_FromT0_CoregT0InZ since imwarp vessels from other timepoint already to timepoint0
                            %                                 Make sure coregT0InZ based on glass from T0 and not every new glass trace from  current timepoint
                            
                            PathRotTissueMask=fullfile(SegmentationFolderTimepoint0{2},'TissueMask_isT0_CoregT0InZ.mat');
                            if exist(PathRotTissueMask)%if the file from timepoint 0 already processed
                                save(fullfile(saveFolder{2},'TissueMask_isT0_CoregT0InZPath.mat'),'PathRotTissueMask');
                            end
                        end
                    else %If permitting drawing contour for every timepoint
                        PotentialFile1=fullfile(MaskCreationDraft{2},'mask3D_TissueOnly_uncoregTime0-.mat');
                        PotentialFile2=fullfile(MaskCreationDraft{2},'mask3D_TissueAndAllBelow_uncoregTime0-.mat');
                        if ActiveMemoryOffload==1
                            if exist(PotentialFile1,'file')%load(
                                Mask3DTissueTemp=matfile(PotentialFile1)
                                Mask3DTissueVarname=whos('-file',PotentialFile1);
                                Mask3DGlassTemp=matfile(fullfile(MaskCreationDraft{1},'mask3D_GlassExc_uncoregTime0-.mat'));
                                Mask3DGlassVarname=whos('-file',fullfile(MaskCreationDraft{1},'mask3D_GlassExc_uncoregTime0-.mat'));
                            elseif exist(PotentialFile2,'file')%load(
                                Mask3DTissueTemp=matfile(PotentialFile2);
                                Mask3DTissueVarname=whos('-file',PotentialFile2);
                                Mask3DGlassTemp=matfile(fullfile(MaskCreationDraft{1},'mask3D_GlassExc_uncoregTime0-.mat'));
                                Mask3DGlassVarname=whos('-file',fullfile(MaskCreationDraft{1},'mask3D_GlassExc_uncoregTime0-.mat'));
                            end
                            TissueMask_CurrentTP_CoregT0InZ=Mask3DTissueTemp.(Mask3DTissueVarname.name);
                            clearvars Mask3DTissueTemp
                            mask_3DGlass=Mask3DGlassTemp.(Mask3DGlassVarname.name);
                            clearvars Mask3DGlassTemp
                        else
                            TissueMask_CurrentTP_CoregT0InZ=mask_3DTissue;
                            clearvars mask_3DTissue
                        end
                        
                        FloorOmissionMask=mask_3DGlass;
                        ylim=DimsVesselsRaw3D(3)
                        xlim=DimsVesselsRaw3D(2)
                        zlim=DimsVesselsRaw3D(1)
                        parfor yInd=1:ylim%going through all B-scans
                            for xInd=1:xlim%going through each A-scan
                                %Determine z-shift required
                                zShiftReq=-(find(mask_3DGlass(:,xInd,yInd)>0,1,'first')-1)%level of bottom of glass marked
                                %StructureRotatedShifted(zlim-(zShiftReq-1):zlim,xInd,yInd)=0;
                                TissueMask_CurrentTP_CoregT0InZ(:,xInd,yInd)=circshift(TissueMask_CurrentTP_CoregT0InZ(:,xInd,yInd),zShiftReq,1);
                                FloorOmissionMask(:,xInd,yInd)=circshift(mask_3DGlass(:,xInd,yInd),zShiftReq,1);
                            end
                        end
                        TissueMask_CurrentTP_CoregT0InZ=logical(TissueMask_CurrentTP_CoregT0InZ).*logical(FloorOmissionMask);
                        if (-1<DaysPrecise && DaysPrecise<=0) && ~exist(fullfile(SegmentationFolderTimepoint0{2},'TissueMask_isT0_CoregT0InZ.mat'),'file')%No difference so might as well save both at the same time
                            save(fullfile(SegmentationFolderTimepoint0{2},'TissueMask_isT0_CoregT0InZ.mat'),'TissueMask_CurrentTP_CoregT0InZ','-v7.3');
                        else
                            PathRotTissueMask=fullfile(saveFolder{2},'TissueMask_CurrentTP_CoregT0InZ.mat'); %fileparts(MaskCreationDraft{2})
                            save(PathRotTissueMask,'TissueMask_CurrentTP_CoregT0InZ','-v7.3');
                        end
                        if ActiveMemoryOffload==1
                            clearvars TissueMask_CurrentTP_CoregT0InZ mask_3DGlass
                        else
                            tissueMaskTemp.TissueMask_CurrentTP_CoregT0InZ=TissueMask_CurrentTP_CoregT0InZ;
                            clearvars TissueMask_CurrentTP_CoregT0InZ mask_3DGlass
                        end
                        
                        % it will redo file for timepoint 0 as well
                        
                        %if exist(fullfile(MaskCreationDraft{2},'mask3D_TissueOnly_uncoregTime0-.mat')) %exist(TissueMask) && exist(glass mask) && ~exist(TissueMask_GlassRotated
                        
                    end
                end
            end
        end
        %% 10) Lateral Corregistration to Day 0 OCT if previously not done by 3D rigid transform
        %First coregister transversely (by looking at large vessels which do not change as quickly as microvasculature then adjust axially by looking at glass in ~firs B-scan and in ~final B-scan Try also this? https://www.mathworks.com/help/images/registering-multimodal-3-d-medical-images.html
        %If we are not dealing with the first timepoint 0- is determined
        %
        %                 if DaysPrecise~=0% for TPx %if ~(sum(contains(DirectoryInitialTimepoints,NameDayFormat),'all') && contains(NameDayFormat,DirectoriesBareSkinMiceKeyword)) && ~(contains(NameDayFormat,DirectoryInitialTimepoints) && contains(BatchOfFolders{countBatchFolder,1},'pre'))%those with tumours have pre and post timepoints
        %                     %% Determine specifically which mouse timepoint 0- should be loaded%for RefMiceCount=1:length(DirectoryInitialTimepoints) if contains(DirectoryInitialTimepoints{RefMiceCount},MouseName)
        %                                 for iv=1:length(RawVasculatureFileKeywordRaw)
        %                                     if exist(fullfile(fileparts(InitialTimepointtxtFile),RawVasculatureFileKeywordRaw{iv}))
        %                                         InitialTimepointFile=fullfile(fileparts(InitialTimepointtxtFile),RawVasculatureFileKeywordRaw{iv});
        %                                     end
        %                                 end
        %                                 if isempty(InitialTimepointFile)
        %                                     if exist(fullfile(fileparts(InitialTimepointtxtFile),'OCTA_path.mat'),'file')
        %                                         load(fullfile(fileparts(InitialTimepointtxtFile),'OCTA_path.mat'))
        %                                     else
        %                                         [filenameOCTVesRaw_Time0,pathOCTVesRaw_Time0]=uigetfile(fullfile(DirectoryVesselsData,MouseName),'Please select RAW OCTA-processed data file for timepoint 0-');
        %                                         InitialTimepointFile=fullfile(pathOCTVesRaw_Time0,filenameOCTVesRaw_Time0);
        %                                         save(fullfile(fileparts(InitialTimepointtxtFile),'OCTA_path.mat'),'InitialTimepointFile','-v7.3')
        %                                         if filenameOCTVesRaw_Time0==0
        %                                             error('No reference timepoint found')
        %                                         end
        %                                     end
        %                                 end
        %
        %                         if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==0 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2
        %                             %% Now to perform user temporal co-registration
        %                             OCTLateralCoregFile=fullfile(TumourMaskAndStepsDir,'registered_OCT2DLateral_toOCTtime0.mat');
        %                             OCTA2DPreviouslycoregistered=exist(OCTLateralCoregFile);
        %                             %% Find transform corregister 2D to timepoint 0-
        %                             [transform2DLateral,transform3DLateral_OCT_Time0Pre,R2Dfixed,R3Dfixed,~,~]=Two_ThreeDCoregisterOCT_FunctionforSpeed5(OCTLateralTimepointCoregistrationFolder,InitialTimepointFile,OCTA_data2D,TryAutomaticAllignment,OCTLateralCoregFile,OCTA2DPreviouslycoregistered,OptFluSegmentationFolder);
        %                             optFluCoregistered_ToTime0pre=imwarp(imwarp(optFluCoregistered,transform2DLateral{1}),transform2DLateral{2},'OutputView',R2Dfixed);%imread(BatchOfJustFolders{countx,3});
        %                                  TransverseOptFluRefImg=figure; imagesc(optFluCoregistered_ToTime0pre), TransverseOptFluRefImg.Visible='off';
        %                                  saveas(TransverseOptFluRefImg, fullfile(OCTLateralTimepointCoregistrationFolder,'TransverseOptFlu_coregtoOCT_coregtoTime0-.png'));
        %                                  clearvars TransverseOptFluRefImg
        %                                  %if exist(fullfile(OptFluSegmentationFolder,'TumourMask2D_aligned.mat'))
        %                                     load(fullfile(OptFluSegmentationFolder,'TumourMask2D_aligned.mat'));
        %                                  %end
        %                                 TumourMask2D_aligned_coregTime0=imwarp(imwarp(TumourMask2D_aligned,transform2DLateral{1}),transform2DLateral{2},'OutputView',R2Dfixed);
        %                                 save(fullfile(OptFluSegmentationFolder,['TumourMask2D_aligned_coregTime0.mat']),'TumourMask2D_aligned_coregTime0','-v7.3')
        %                         elseif Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1
        %                             load(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration3DTime0--FOV.mat'));
        %                             load(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration3DTime0--AffineTransformation.mat'));
        %                         end
        %
        %                                 BatchOfFolders{countBatchFolder,4}=fullfile(OptFluSegmentationFolder,'TumourMask2D_aligned_coregTime0.mat');%already previously created under this name if did 0 or 2
        %
        if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2
            %% Applying 3D coregistration (laterally) to all 3D scans (stOCT and OCTA (raw and if applicable binarized)) with masks
            %% Glass mode for TPx
            if Neither_0_glass_1_Tissue_2_both_3_contour==1 ||Neither_0_glass_1_Tissue_2_both_3_contour==3
                if ActiveMemoryOffload==1%glass_1_Tissue_2_both_3_contour==3 && ActiveMemoryOffload==1%previously deleted for memory
                    %% Loading glass removed files
                    %loading of glass removed struct, raw and bin here
                    RawStructtemp=matfile(fullfile(saveFolder{1},'RawStruct_UnCoregTime0-_RotShift.mat'));%,'StOCT_UnCoregT0_RotatedShifted','-v7.3');
                    RawStructVarname=whos('-file',fullfile(saveFolder{1},'RawStruct_UnCoregTime0-_RotShift.mat'));
                    RawVesstemp=matfile(fullfile(saveFolder{1},'RawVess_UnCoregTime0-_RotShift.mat'));%,'RawOCTA_UnCoregT0_RotatedShifted','-v7.3');
                    RawVessVarname=whos('-file',fullfile(saveFolder{1},'RawVess_UnCoregTime0-_RotShift.mat'));
                    if BinVesselsAlreadyPrepared==1
                        BinVesstemp=matfile(fullfile(saveFolder{1},'BinVess_UnCoregTime0-_RotShift.mat'));%,'BinOCTA_UnCoregT0_RotatedShifted','-v7.3');
                        BinVessVarname=whos('-file',fullfile(saveFolder{1},'BinVess_UnCoregTime0-_RotShift.mat'));
                    end
                elseif ActiveMemoryOffload==0
                    RawStructVarname=whos('-file',fullfile(saveFolder{1},'RawStruct_UnCoregTime0-_RotShift.mat'));
                    RawVessVarname=whos('-file',fullfile(saveFolder{1},'RawVess_UnCoregTime0-_RotShift.mat'));
                    if BinVesselsAlreadyPrepared==1
                        BinVessVarname=whos('-file',fullfile(saveFolder{1},'BinVess_UnCoregTime0-_RotShift.mat'));
                    end
                end
                
                %Co-register raw OCTA
                RawOCTA_CoregT0_RotatedShifted=double(imwarp(imwarp(RawVesstemp.(RawVessVarname.name),transform3DLateral_OCT_Time0Pre{1}),transform3DLateral_OCT_Time0Pre{2},'OutputView',R3Dfixed,'interp','cubic'));%double(imwarp(imwarp(RawOCTA_UnCoregT0_RotatedShifted,transform3DLateral_OCT_Time0Pre{1}),transform3DLateral_OCT_Time0Pre{2},'OutputView',R3Dfixed,'interp','cubic'));%Rout3);
                save(fullfile(saveFolder{1},'RawVess_CoregTime0-_RotShift.mat'),'RawOCTA_CoregT0_RotatedShifted','-v7.3');
                clearvars RawOCTA_UnCoregT0_RotatedShifted RawOCTA_CoregT0_RotatedShifted
                %Co-register stOCT
                Structure_CoregT0_RotatedShifted=double(imwarp(imwarp(RawStructtemp.(RawStructVarname.name),transform3DLateral_OCT_Time0Pre{1}),transform3DLateral_OCT_Time0Pre{2},'OutputView',R3Dfixed,'interp','cubic'));%Rout3);StOCT_UnCoregT0_RotatedShifted
                save(fullfile(saveFolder{1},'RawStruct_CoregTime0-_RotShift.mat'),'Structure_CoregT0_RotatedShifted','-v7.3');
                clearvars Structure_UnCoregT0_RotatedShifted Structure_CoregT0_RotatedShifted
                %Co-register binarized vessels if applicable
                if BinVesselsAlreadyPrepared==1%filenameOCTVesBin==1
                    BinOCTA_CoregT0_RotatedShifted=imwarp(imwarp(BinVesstemp.(BinVessVarname.name),transform3DLateral_OCT_Time0Pre{1}),transform3DLateral_OCT_Time0Pre{2},'OutputView',R3Dfixed,'interp','cubic');%Rout2);BinOCTA_UnCoregT0_RotatedShifted
                    save(fullfile(saveFolder{1},'BinVess_CoregTime0-_RotShift.mat'),'BinOCTA_CoregT0_RotatedShifted','-v7.3');
                    clearvars BinOCTA_UnCoregT0_RotatedShifted BinOCTA_CoregT0_RotatedShifted%RawOCTA_CoregT0_RotatedShifted
                end
                if Neither_0_glass_1_Tissue_2_both_3_contour==1
                    %% Creating 3D mask as conjunction of tumour lateral contour/ 2D ROI with glass exclusion in depth % still contains air tissue gap between glass and tissue
                    load(BatchOfFolders{countBatchFolder,4});
                    %MaskVarname=whos('-file',BatchOfFolders{countBatchFolder,4});%should be the coregistered one to timepoint 0- either way by this point
                    %mask2D.(MaskVarname.name)
                    % Mask Fully created no glass and rotated. Perform analysis to fixed depth from glass bottom
                    tumor_maskProj3DRot=shiftdim(repmat(TumourMask2D_aligned_coregTime0,[1,1,DimsVesselsRaw3D(1)]),2);
                    mask_3D_Unrestricted=logical(imwarp(imwarp(mask_3DGlass,transform3DLateral_OCT_Time0Pre{1}),transform3DLateral_OCT_Time0Pre{2},'OutputView',R3Dfixed,'interp','cubic')) & tumor_maskProj3DRot;%mask_3D_Top & %flip(mask_3D_Top & tumor_maskProj3DRot,3);
                    mask_3D_CylindricalProjection=tumor_maskProj3DRot;
                end
            end
            %% Tissue mode for TPx
            if (Neither_0_glass_1_Tissue_2_both_3_contour==2) && Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed 
                %no flattening of tissue (distort vessel shape similar to non-similarity affine transform
                if OnlyTissueLabelTimepoint0==0 %if drawing it manually for each timepoint--worth saving tissue mask
                    RawOCTA_CoregT0_TissueMaskApplied=double(imwarp(imwarp(RawOCTA_UnCoregT0_TissueMaskApplied,transform3DLateral_OCT_Time0Pre{1}),transform3DLateral_OCT_Time0Pre{2},'OutputView',R3Dfixed,'interp','cubic'));%Rout3);
                    save(fullfile(saveFolder{2},'RawVess_CoregTime0-_NotInZ_TissueMaskApp.mat'),'RawOCTA_CoregT0_TissueMaskApplied','-v7.3');
                    clearvars RawOCTA_UnCoregT0_TissueMaskApplied RawOCTA_CoregT0_TissueMaskApplied
                    StOCT_CoregT0_TissueMaskApplied =double(imwarp(imwarp(StOCT_UnCoregT0_TissueMaskApplied,transform3DLateral_OCT_Time0Pre{1}),transform3DLateral_OCT_Time0Pre{2},'OutputView',R3Dfixed,'interp','cubic'));%Rout3);
                    save(fullfile(saveFolder{2},'RawStruct_CoregTime0-_NotInZ_TissueMaskApp.mat'),'StOCT_CoregT0_TissueMaskApplied','-v7.3');
                    clearvars StOCT_CoregT0_TissueMaskApplied StOCT_UnCoregT0_TissueMaskApplied
                    if BinVesselsAlreadyPrepared==1
                        BinOCTA_CoregT0_TissueMaskApplied=double(imwarp(imwarp(BinOCTA_UnCoregT0_TissueMaskApplied,transform3DLateral_OCT_Time0Pre{1}),transform3DLateral_OCT_Time0Pre{2},'OutputView',R3Dfixed,'interp','cubic'));%Rout3);
                        save(fullfile(saveFolder{2},'BinVess_CoregTime0-_NotInZ_TissueMaskApp.mat'),'BinOCTA_CoregT0_TissueMaskApplied','-v7.3');
                        clearvars BinOCTA_UnCoregT0_TissueMaskApplied BinOCTA_CoregT0_TissueMaskApplied
                    end
                    %% Creating 3D mask as conjunction of tumour lateral contour/ 2D ROI with glass exclusion in depth %No rotation only
                    load(BatchOfFolders{countBatchFolder,4});
                    %MaskVarname=whos('-file',BatchOfFolders{countBatchFolder,4});%should be the coregistered one to timepoint 0- either way by this point
                    %mask2D.(MaskVarname.name)
                    % Mask Fully created no glass and rotated. Perform analysis to fixed depth from glass bottom
                    tumor_maskProj3DRot=shiftdim(repmat(TumourMask2D_aligned_coregTime0,[1,1,DimsVesselsRaw3D(1)]),2);
                    mask_3D_Unrestricted=logical(imwarp(imwarp(mask_3DTissue,transform3DLateral_OCT_Time0Pre{1}),transform3DLateral_OCT_Time0Pre{2},'OutputView',R3Dfixed,'interp','cubic')) & tumor_maskProj3DRot;%mask_3D_Top & %flip(mask_3D_Top & tumor_maskProj3DRot,3);
                    mask_3D_CylindricalProjection=tumor_maskProj3DRot;
                    % else%if glass_1_Tissue_2_both_3_contour==2 %not worth doing if based on TP0-
                end
                %% Tissue + glass mode for TPx
            elseif (Neither_0_glass_1_Tissue_2_both_3_contour==3) && Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed
                if ActiveMemoryOffload==1
                    %loading glass removed OCT files
                    %                                            load(fullfile(saveFolder{1},'RawVess_CoregTime0-_RotShift.mat'));
                    %                                            load(fullfile(saveFolder{1},'RawStruct_CoregTime0-_RotShift.mat'));
                    %                                                 if BinVesselsApplicable==1%filenameOCTVesBin==1
                    %                                                     load(fullfile(saveFolder{1},'BinVess_CoregTime0-_RotShift.mat'));
                    %                                                 end
                    RawStructtemp=matfile(fullfile(saveFolder{1},'RawStruct_CoregTime0-_RotShift.mat'));%,'StOCT_UnCoregT0_RotatedShifted','-v7.3');
                    RawStructVarname=whos('-file',fullfile(saveFolder{1},'RawStruct_CoregTime0-_RotShift.mat'));
                    RawVesstemp=matfile(fullfile(saveFolder{1},'RawVess_CoregTime0-_RotShift.mat'));%,'RawOCTA_UnCoregT0_RotatedShifted','-v7.3');
                    RawVessVarname=whos('-file',fullfile(saveFolder{1},'RawVess_CoregTime0-_RotShift.mat'));
                    if BinVesselsAlreadyPrepared==1
                        BinVesstemp=matfile(fullfile(saveFolder{1},'BinVess_CoregTime0-_RotShift.mat'));%,'BinOCTA_UnCoregT0_RotatedShifted','-v7.3');
                        BinVessVarname=whos('-file',fullfile(saveFolder{1},'BinVess_CoregTime0-_RotShift.mat'));
                    end
                    % cleared previously for memory
                else
                    RawStructVarname=whos('-file',fullfile(saveFolder{1},'RawStruct_CoregTime0-_RotShift.mat'));
                    RawVessVarname=whos('-file',fullfile(saveFolder{1},'RawVess_CoregTime0-_RotShift.mat'));
                    if BinVesselsAlreadyPrepared==1
                        BinVessVarname=whos('-file',fullfile(saveFolder{1},'BinVess_CoregTime0-_RotShift.mat'));
                    end
                end
                if OnlyTissueLabelTimepoint0==1
                    %                                             if DaysPrecise==0 % Well day 0 should not go through this part of the conditional (since we filter from the start time 0 vs other
                    %                                                PathRotTissueMask=fullfile(SegmentationFolderTimepoint0{2},'TissueMask_FromTime0-CoregT0InZ.mat');
                    %                                                if ~exist(mask_3DTissue_FromT0_CoregT0InZ,'var')
                    %                                                    load(PathRotTissueMask)
                    %                                                end
                    %                                             else%Not necessary but making sure file path was saved correctly
                    load(fullfile(saveFolder{2},'TissueMask_isT0_CoregT0InZPath.mat'))
                    PathRotTissueMask=ChangeFilePaths(DirectoryDataLetter, PathRotTissueMask);
                    if ActiveMemoryOffload==1%if ~exist('mask_3DTissue_FromT0_CoregT0InZ','var')%if not loaded in memory
                        tissueMaskTemp=matfile(PathRotTissueMask)
                        tissueMaskVarname=whos('-file',PathRotTissueMask)%load(PathRotTissueMask)%load(PathRotTissueMask)
                    else
                        tissueMaskVarname=whos('-file',PathRotTissueMask)
                    end%load(PathRotTissueMask)
                    
                    %                                             end
                    %no transforms to the mask since
                    %they all use the same mask
                    %                                         mask_3DTissue_FromT0_CoregT0=logical(tissueMaskTemp.(tissueMaskVarname.name));%mask_3DTissue_FromT0_CoregT0InZ);%logical(imwarp(imwarp(mask_3DTissue_FromT0_CoregT0InZ,transform3DLateral_OCT_Time0Pre{1}),transform3DLateral_OCT_Time0Pre{2},'OutputView',R3Dfixed,'interp','cubic'));%Rout3);
                    %                                         save(fullfile(saveFolder{2},'mask_3DTissue_FromT0_CoregT0.mat'),'mask_3DTissue_FromT0_CoregT0','-v7.3');
                    %% Applying mask
                    %To Co-registered Raw OCTA (from glass step above)
                    RawOCTA_CoregT0_RotatedShiftedTissueMaskApp=double(RawVesstemp.(RawVessVarname.name)).*tissueMaskTemp.(tissueMaskVarname.name);%mask_3DTissue_FromT0_CoregT0;%RawOCTA_CoregT0_RotatedShiftedRout3);
                    save(fullfile(saveFolder{2},'RawVess_CoregTime0-_FromT0_TissueMaskApp.mat'),'RawOCTA_CoregT0_RotatedShiftedTissueMaskApp','-v7.3');
                    clearvars RawOCTA_UnCoregT0_RotatedShifted RawOCTA_CoregT0_RotatedShifted
                    %To Co-registered stOCT (from glass step above)
                    Structure_CoregT0_RotatedShiftedTissueMaskApp=double(RawStructtemp.(RawStructVarname.name)).*tissueMaskTemp.(tissueMaskVarname.name);%mask_3DTissue_FromT0_CoregT0;%Rout3);
                    save(fullfile(saveFolder{2},'RawStruct_CoregTime0-_FromT0_TissueMaskApp.mat'),'Structure_CoregT0_RotatedShiftedTissueMaskApp','-v7.3');
                    clearvars Structure_UnCoregT0_RotatedShifted Structure_CoregT0_RotatedShifted
                    %To Co-registered binarized vessels if applicable
                    if BinVesselsAlreadyPrepared==1%filenameOCTVesBin==1
                        BinOCTA_CoregT0_RotatedShiftedTissueMaskApp=double(BinVesstemp.(BinVessVarname.name)).*tissueMaskTemp.(tissueMaskVarname.name);%mask_3DTissue_FromT0_CoregT0;%Rout3);
                        save(fullfile(saveFolder{2},'BinVess_CoregTime0-_FromT0_TissueMaskApp.mat'),'BinOCTA_CoregT0_RotatedShiftedTissueMaskApp','-v7.3');
                        clearvars BinOCTA_UnCoregT0_RotatedShifted BinOCTA_CoregT0_RotatedShifted%RawOCTA_CoregT0_RotatedShifted
                    end
                    %% Creating 3D mask as conjunction of tumour lateral contour/ 2D ROI with glass exclusion in depth
                    load(BatchOfFolders{countBatchFolder,4});
                    %MaskVarname=whos('-file',BatchOfFolders{countBatchFolder,4});%should be the coregistered one to timepoint 0- either way by this point
                    %mask2D.(MaskVarname.name)
                    % Mask Fully created no glass and rotated. Perform analysis to fixed depth from glass bottom
                    tumor_maskProj3DRot=shiftdim(repmat(TumourMask2D_aligned_coregTime0,[1,1,DimsVesselsRaw3D(1)]),2);
                    mask_3D_Unrestricted=logical(tissueMaskTemp.(tissueMaskVarname.name)) & tumor_maskProj3DRot;%;%mask_3DTissue_FromT0_CoregT0%mask_3D_Top & %flip(mask_3D_Top & tumor_maskProj3DRot,3);
                    mask_3D_CylindricalProjection=tumor_maskProj3DRot;
                elseif OnlyTissueLabelTimepoint0==0%Manually drawn tissue mask for each TP
                    PathRotTissueMask=fullfile(saveFolder{2},'TissueMask_CurrentTP_CoregT0InZ.mat');
                    if ActiveMemoryOffload==1%if ~exist('TissueMask_CurrentTP_CoregT0InZ','var')
                        tissueMaskTemp=matfile(PathRotTissueMask)
                        tissueMaskVarname=whos('-file',PathRotTissueMask)%load(PathRotTissueMask)%load(PathRotTissueMask)
                    else
                        tissueMaskVarname=whos('-file',PathRotTissueMask)
                    end%load(PathRotTissueMask)
                    
                    mask_3DTissue_CurrentTP_CoregT0=logical(imwarp(imwarp(tissueMaskTemp.(tissueMaskVarname.name),transform3DLateral_OCT_Time0Pre{1}),transform3DLateral_OCT_Time0Pre{2},'OutputView',R3Dfixed,'interp','cubic'));%TissueMask_CurrentTP_CoregT0InZ
                    save(fullfile(saveFolder{2},'TissueMask_CurrentTP_CoregT0.mat'),'mask_3DTissue_CurrentTP_CoregT0','-v7.3');
                    %% Applying mask
                    %To Co-registered Raw OCTA (from glass step above)
                    RawOCTA_CoregT0_RotatedShiftedTissueMaskApp=double(RawVesstemp.(RawVessVarname.name)).*tissueMaskTemp.(tissueMaskVarname.name);%mask_3DTissue_CurrentTP_CoregT0;%RawOCTA_CoregT0_RotatedShiftedRout3);
                    save(fullfile(saveFolder{2},'RawVess_CoregTime0-_CurrentTP_TissueMaskApp.mat'),'RawOCTA_CoregT0_RotatedShiftedTissueMaskApp','-v7.3');
                    clearvars RawOCTA_UnCoregT0_RotatedShifted RawOCTA_CoregT0_RotatedShifted
                    %To Co-registered stOCT (from glass step above)
                    Structure_CoregT0_RotatedShiftedTissueMaskApp=double(RawStructtemp.(RawStructVarname.name)).*tissueMaskTemp.(tissueMaskVarname.name);%mask_3DTissue_CurrentTP_CoregT0;%Rout3);
                    save(fullfile(saveFolder{2},'RawStruct_CoregTime0-_CurrentTP_TissueMaskApp.mat'),'Structure_CoregT0_RotatedShiftedTissueMaskApp','-v7.3');
                    clearvars Structure_UnCoregT0_RotatedShifted Structure_CoregT0_RotatedShifted
                    %To Co-registered binarized vessels if applicable
                    if BinVesselsAlreadyPrepared==1%filenameOCTVesBin==1
                        BinOCTA_CoregT0_RotatedShiftedTissueMaskApp=double(BinVesstemp.(BinVessVarname.name)).*tissueMaskTemp.(tissueMaskVarname.name);%mask_3DTissue_CurrentTP_CoregT0;%Rout3);
                        save(fullfile(saveFolder{2},'BinVess_CoregTime0-_CurrentTP_TissueMaskApp.mat'),'BinOCTA_CoregT0_RotatedShiftedTissueMaskApp','-v7.3');
                        clearvars BinOCTA_UnCoregT0_RotatedShifted BinOCTA_CoregT0_RotatedShifted%RawOCTA_CoregT0_RotatedShifted
                    end
                    %% Creating 3D mask as conjunction of tumour lateral contour/ 2D ROI with glass exclusion in depth
                    load(BatchOfFolders{countBatchFolder,4});
                    %MaskVarname=whos('-file',BatchOfFolders{countBatchFolder,4});%should be the coregistered one to timepoint 0- either way by this point
                    %mask2D.(MaskVarname.name)
                    % Mask Fully created no glass and rotated. Perform analysis to fixed depth from glass bottom
                    tumor_maskProj3DRot=shiftdim(repmat(TumourMask2D_aligned_coregTime0,[1,1,DimsVesselsRaw3D(1)]),2);
                    mask_3D_Unrestricted=logical(tissueMaskTemp.(tissueMaskVarname.name)) & tumor_maskProj3DRot;%%mask_3DTissue_CurrentTP_CoregT0%mask_3D_Top & %flip(mask_3D_Top & tumor_maskProj3DRot,3);
                    mask_3D_CylindricalProjection=tumor_maskProj3DRot;
                end
            end
        end
    elseif (-1<DaysPrecise && DaysPrecise<=0) %If it is timepoint 0- no temporal 3D co-registration affine transforms
        if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==0 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2
            load(fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI, 'TumourMask2D_aligned.mat']));%BatchOfFolders{countBatchFolder,4})%
            TumourMask2D_aligned_coregTime0=TumourMask2D_aligned;
            save(fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI, 'TumourMask2D_aligned_coregTime0.mat']),'TumourMask2D_aligned_coregTime0','-v7.3')
        end
        BatchOfFolders{countBatchFolder,4}=fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI, 'TumourMask2D_aligned_coregTime0.mat']);
        if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2
            %% NOT Applying 3D coregistration (laterally) to all 3D scans (stOCT and OCTA (raw and if applicable binarized)) with masks
            %% Glass mode for TP0-
            if Neither_0_glass_1_Tissue_2_both_3_contour==1 ||Neither_0_glass_1_Tissue_2_both_3_contour==3
                if ActiveMemoryOffload==1%glass_1_Tissue_2_both_3_contour==3 && ActiveMemoryOffload==1%previously deleted for memory
                    %% Loading glass removed files
                    %loading of glass removed struct, raw and bin here
                    %                                             load(fullfile(saveFolder{1},'RawStruct_UnCoregTime0-_RotShift.mat'));%,'StOCT_UnCoregT0_RotatedShifted','-v7.3');
                    %                                             load(fullfile(saveFolder{1},'RawVess_UnCoregTime0-_RotShift.mat'));%,'RawOCTA_UnCoregT0_RotatedShifted','-v7.3');
                    %                                                 if BinVesselsApplicable==1
                    %                                                     load(fullfile(saveFolder{1},'BinVess_UnCoregTime0-_RotShift.mat'));%,'BinOCTA_UnCoregT0_RotatedShifted','-v7.3');
                    %                                                 end
                    RawStructtemp=matfile(fullfile(saveFolder{1},'RawStruct_UnCoregTime0-_RotShift.mat'));%,'StOCT_UnCoregT0_RotatedShifted','-v7.3');
                    RawStructVarname=whos('-file',fullfile(saveFolder{1},'RawStruct_UnCoregTime0-_RotShift.mat'));
                    RawVesstemp=matfile(fullfile(saveFolder{1},'RawVess_UnCoregTime0-_RotShift.mat'));%,'RawOCTA_UnCoregT0_RotatedShifted','-v7.3');
                    RawVessVarname=whos('-file',fullfile(saveFolder{1},'RawVess_UnCoregTime0-_RotShift.mat'));
                    if BinVesselsAlreadyPrepared==1
                        BinVesstemp=matfile(fullfile(saveFolder{1},'BinVess_UnCoregTime0-_RotShift.mat'));%,'BinOCTA_UnCoregT0_RotatedShifted','-v7.3');
                        BinVessVarname=whos('-file',fullfile(saveFolder{1},'BinVess_UnCoregTime0-_RotShift.mat'));
                    end
                else
                    RawStructVarname=whos('-file',fullfile(saveFolder{1},'RawStruct_UnCoregTime0-_RotShift.mat'));
                    RawVessVarname=whos('-file',fullfile(saveFolder{1},'RawVess_UnCoregTime0-_RotShift.mat'));
                    if BinVesselsAlreadyPrepared==1
                        BinVessVarname=whos('-file',fullfile(saveFolder{1},'BinVess_UnCoregTime0-_RotShift.mat'));
                    end
                end
                
                %Co-register raw OCTA
                RawOCTA_CoregT0_RotatedShifted=double(RawVesstemp.(RawVessVarname.name));%RawOCTA_UnCoregT0_RotatedShifted Rout3);
                save(fullfile(saveFolder{1},'RawVess_CoregTime0-_RotShift.mat'),'RawOCTA_CoregT0_RotatedShifted','-v7.3');
                clearvars RawOCTA_UnCoregT0_RotatedShifted RawOCTA_CoregT0_RotatedShifted
                %Co-register stOCT
                Structure_CoregT0_RotatedShifted=double(RawStructtemp.(RawStructVarname.name));%StOCT_UnCoregT0_RotatedShifted Rout3);
                save(fullfile(saveFolder{1},'RawStruct_CoregTime0-_RotShift.mat'),'Structure_CoregT0_RotatedShifted','-v7.3');
                clearvars Structure_UnCoregT0_RotatedShifted Structure_CoregT0_RotatedShifted
                %Co-register binarized vessels if applicable
                if BinVesselsAlreadyPrepared==1%filenameOCTVesBin==1
                    BinOCTA_CoregT0_RotatedShifted=BinVesstemp.(BinVessVarname.name);%BinOCTA_UnCoregT0_RotatedShifted;%Rout2);
                    save(fullfile(saveFolder{1},'BinVess_CoregTime0-_RotShift.mat'),'BinOCTA_CoregT0_RotatedShifted','-v7.3');
                    clearvars BinOCTA_UnCoregT0_RotatedShifted BinOCTA_CoregT0_RotatedShifted%RawOCTA_CoregT0_RotatedShifted
                end
                if Neither_0_glass_1_Tissue_2_both_3_contour==1
                    %% Creating 3D mask as conjunction of tumour lateral contour/ 2D ROI with glass exclusion in depth % still contains air tissue gap between glass and tissue
                    load(BatchOfFolders{countBatchFolder,4});
                    %MaskVarname=whos('-file',BatchOfFolders{countBatchFolder,4});%should be the coregistered one to timepoint 0- either way by this point
                    %mask2D.(MaskVarname.name)
                    % Mask Fully created no glass and rotated. Perform analysis to fixed depth from glass bottom
                    tumor_maskProj3DRot=shiftdim(repmat(TumourMask2D_aligned_coregTime0,[1,1,DimsVesselsRaw3D(1)]),2);
                    mask_3D_Unrestricted=logical(mask_3DGlass) & tumor_maskProj3DRot;%mask_3D_Top & %flip(mask_3D_Top & tumor_maskProj3DRot,3);
                    mask_3D_CylindricalProjection=tumor_maskProj3DRot;
                end
            end
            %% Tissue mode for TP0-
            if (Neither_0_glass_1_Tissue_2_both_3_contour==2) && Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed
                %no flattening of tissue (distort vessel shape similar to non-similarity affine transform
                if OnlyTissueLabelTimepoint0==0 %if drawing it manually for each timepoint--worth saving tissue mask
                    RawOCTA_CoregT0_TissueMaskApplied=double(RawOCTA_UnCoregT0_TissueMaskApplied);%Rout3);
                    save(fullfile(saveFolder{2},'RawVess_CoregTime0-_NotInZ_TissueMaskApp.mat'),'RawOCTA_CoregT0_TissueMaskApplied','-v7.3');
                    clearvars RawOCTA_UnCoregT0_TissueMaskApplied RawOCTA_CoregT0_TissueMaskApplied
                    StOCT_CoregT0_TissueMaskApplied =double(StOCT_UnCoregT0_TissueMaskApplied);%Rout3);
                    save(fullfile(saveFolder{2},'RawStruct_CoregTime0-_NotInZ_TissueMaskApp.mat'),'StOCT_CoregT0_TissueMaskApplied','-v7.3');
                    clearvars StOCT_CoregT0_TissueMaskApplied StOCT_UnCoregT0_TissueMaskApplied
                    if BinVesselsAlreadyPrepared==1
                        BinOCTA_CoregT0_TissueMaskApplied=double(BinOCTA_UnCoregT0_TissueMaskApplied);%Rout3);
                        save(fullfile(saveFolder{2},'BinVess_CoregTime0-_NotInZ_TissueMaskApp.mat'),'BinOCTA_CoregT0_TissueMaskApplied','-v7.3');
                        clearvars BinOCTA_UnCoregT0_TissueMaskApplied BinOCTA_CoregT0_TissueMaskApplied
                    end
                    %% Creating 3D mask as conjunction of tumour lateral contour/ 2D ROI with glass exclusion in depth %No rotation only
                    load(BatchOfFolders{countBatchFolder,4});
                    %MaskVarname=whos('-file',BatchOfFolders{countBatchFolder,4});%should be the coregistered one to timepoint 0- either way by this point
                    %mask2D.(MaskVarname.name)
                    % Mask Fully created no glass and rotated. Perform analysis to fixed depth from glass bottom
                    tumor_maskProj3DRot=shiftdim(repmat(TumourMask2D_aligned_coregTime0,[1,1,DimsVesselsRaw3D(1)]),2);
                    mask_3D_Unrestricted=logical(mask_3DTissue) & tumor_maskProj3DRot;%mask_3D_Top & %flip(mask_3D_Top & tumor_maskProj3DRot,3);
                    mask_3D_CylindricalProjection=tumor_maskProj3DRot;
                    % else%if glass_1_Tissue_2_both_3_contour==2 %not worth doing if based on TP0-
                end
                %% Tissue + glass mode for TP0-
            elseif (Neither_0_glass_1_Tissue_2_both_3_contour==3) && Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed
                %% Loading if applicable
                if ActiveMemoryOffload==1% cleared previously for memory
                    %loading glass removed OCT files
                    %                                            load(fullfile(saveFolder{1},'RawVess_CoregTime0-_RotShift.mat'));
                    %                                            load(fullfile(saveFolder{1},'RawStruct_CoregTime0-_RotShift.mat'));
                    %                                                 if BinVesselsApplicable==1%filenameOCTVesBin==1
                    %                                                     load(fullfile(saveFolder{1},'BinVess_CoregTime0-_RotShift.mat'));
                    %                                                 end
                    % cleared previously for memory
                    RawStructtemp=matfile(fullfile(saveFolder{1},'RawStruct_CoregTime0-_RotShift.mat'));%,'StOCT_UnCoregT0_RotatedShifted','-v7.3');
                    RawStructVarname=whos('-file',fullfile(saveFolder{1},'RawStruct_CoregTime0-_RotShift.mat'));
                    RawVesstemp=matfile(fullfile(saveFolder{1},'RawVess_CoregTime0-_RotShift.mat'));%,'RawOCTA_UnCoregT0_RotatedShifted','-v7.3');
                    RawVessVarname=whos('-file',fullfile(saveFolder{1},'RawVess_CoregTime0-_RotShift.mat'));
                    if BinVesselsAlreadyPrepared==1
                        BinVesstemp=matfile(fullfile(saveFolder{1},'BinVess_CoregTime0-_RotShift.mat'));%,'BinOCTA_UnCoregT0_RotatedShifted','-v7.3');
                        BinVessVarname=whos('-file',fullfile(saveFolder{1},'BinVess_CoregTime0-_RotShift.mat'));
                    end
                else
                    RawStructVarname=whos('-file',fullfile(saveFolder{1},'RawStruct_CoregTime0-_RotShift.mat'));
                    RawVessVarname=whos('-file',fullfile(saveFolder{1},'RawVess_CoregTime0-_RotShift.mat'));
                    if BinVesselsAlreadyPrepared==1
                        BinVessVarname=whos('-file',fullfile(saveFolder{1},'BinVess_CoregTime0-_RotShift.mat'));
                    end
                end
                if OnlyTissueLabelTimepoint0==1
                    %                                             if DaysPrecise==0 % Well day 0 should not go through this part of the conditional (since we filter from the start time 0 vs other
                    %                                                PathRotTissueMask=fullfile(SegmentationFolderTimepoint0{2},'TissueMask_FromTime0-CoregT0InZ.mat');
                    %                                                if ~exist(mask_3DTissue_FromT0_CoregT0InZ,'var')
                    %                                                    load(PathRotTissueMask)
                    %                                                end
                    %                                             else%Not necessary but making sure file path was saved correctly
                    load(fullfile(saveFolder{2},'TissueMask_isT0_CoregT0InZPath.mat'))%load(fullfile(saveFolder{2},'TissueMask_FromTime0-CoregT0InZPath.mat'))
                    PathRotTissueMask=ChangeFilePaths(DirectoryDataLetter, PathRotTissueMask);
                    if ActiveMemoryOffload==1%if ~exist('mask_3DTissue_FromT0_CoregT0InZ','var')%if not loaded in memory
                        tissueMaskTemp=matfile(PathRotTissueMask)
                        tissueMaskVarname=whos('-file',PathRotTissueMask)%load(PathRotTissueMask)
                    else
                        tissueMaskVarname=whos('-file',PathRotTissueMask)
                    end
                    %                                             end
                    %no transforms to the mask since
                    %they all use the same mask -so
                    %just load that from timepoint 0-
                    %do not resave
                    %                                         mask_3DTissue_FromT0_CoregT0=logical(tissueMaskTemp.(tissueMaskVarname.name));%mask_3DTissue_FromT0_CoregT0InZlogical(imwarp(imwarp(mask_3DTissue_FromT0_CoregT0InZ,transform3DLateral_OCT_Time0Pre{1}),transform3DLateral_OCT_Time0Pre{2},'OutputView',R3Dfixed,'interp','cubic'));%Rout3);
                    %                                         save(fullfile(saveFolder{2},'mask_3DTissue_FromT0_CoregT0.mat'),'mask_3DTissue_FromT0_CoregT0','-v7.3');
                    %% Applying mask
                    %To Co-registered Raw OCTA (from glass step above)
                    if ~exist(fullfile(saveFolder{2},'RawVess_CoregTime0-_isT0_TissueMaskApp.mat'),'file')
                        RawOCTA_CoregT0_RotatedShiftedTissueMaskApp=double(RawVesstemp.(RawVessVarname.name)).*tissueMaskTemp.(tissueMaskVarname.name);%mask_3DTissue_FromT0_CoregT0;%Rout3);
                        save(fullfile(saveFolder{2},'RawVess_CoregTime0-_isT0_TissueMaskApp.mat'),'RawOCTA_CoregT0_RotatedShiftedTissueMaskApp','-v7.3');
                        clearvars RawOCTA_UnCoregT0_RotatedShifted RawOCTA_CoregT0_RotatedShifted
                    end
                    %To Co-registered stOCT (from glass step above)
                    if ~exist(fullfile(saveFolder{2},'RawStruct_CoregTime0-_isT0_TissueMaskApp.mat'),'file')
                        Structure_CoregT0_RotatedShiftedTissueMaskApp=double(RawStructtemp.(RawStructVarname.name)).*tissueMaskTemp.(tissueMaskVarname.name);%mask_3DTissue_FromT0_CoregT0;%Rout3);
                        save(fullfile(saveFolder{2},'RawStruct_CoregTime0-_isT0_TissueMaskApp.mat'),'Structure_CoregT0_RotatedShiftedTissueMaskApp','-v7.3');
                        clearvars Structure_UnCoregT0_RotatedShifted Structure_CoregT0_RotatedShifted
                    end
                    %To Co-registered binarized vessels if applicable
                    if BinVesselsAlreadyPrepared==1%filenameOCTVesBin==1
                        if ~exist(fullfile(saveFolder{2},'BinVess_CoregTime0-_isT0_TissueMaskApp.mat'),'file')
                            BinOCTA_CoregT0_RotatedShiftedTissueMaskApp=double(BinVesstemp.(BinVessVarname.name)).*tissueMaskTemp.(tissueMaskVarname.name);%mask_3DTissue_FromT0_CoregT0;%Rout3);
                            save(fullfile(saveFolder{2},'BinVess_CoregTime0-_isT0_TissueMaskApp.mat'),'BinOCTA_CoregT0_RotatedShiftedTissueMaskApp','-v7.3');
                            clearvars BinOCTA_UnCoregT0_RotatedShifted BinOCTA_CoregT0_RotatedShifted%RawOCTA_CoregT0_RotatedShifted
                        end
                    end
                    %% Creating 3D mask as conjunction of tumour lateral contour/ 2D ROI with glass exclusion in depth
                    load(BatchOfFolders{countBatchFolder,4});
                    %MaskVarname=whos('-file',BatchOfFolders{countBatchFolder,4});%should be the coregistered one to timepoint 0- either way by this point
                    %mask2D.(MaskVarname.name)
                    % Mask Fully created no glass and rotated. Perform analysis to fixed depth from glass bottom
                    tumor_maskProj3DRot=shiftdim(repmat(TumourMask2D_aligned_coregTime0,[1,1,DimsVesselsRaw3D(1)]),2);
                    mask_3D_Unrestricted=logical(tissueMaskTemp.(tissueMaskVarname.name)) & tumor_maskProj3DRot;%;%mask_3DTissue_FromT0_CoregT0%mask_3D_Top & %flip(mask_3D_Top & tumor_maskProj3DRot,3);
                    mask_3D_CylindricalProjection=tumor_maskProj3DRot;
                elseif OnlyTissueLabelTimepoint0==0%Manually drawn tissue mask for each TP
                    PathRotTissueMask=fullfile(saveFolder{2},'TissueMask_isT0_CoregT0InZ.mat');
                    if ActiveMemoryOffload==1%if ~exist('TissueMask_CurrentTP_CoregT0InZ','var')
                        tissueMaskTemp=matfile(PathRotTissueMask)
                        tissueMaskVarname=whos('-file',PathRotTissueMask)%load(PathRotTissueMask)%load(PathRotTissueMask)
                    else
                        tissueMaskVarname=whos('-file',PathRotTissueMask)
                    end
                    mask_3DTissue_CurrentTP_CoregT0=logical(tissueMaskTemp.(tissueMaskVarname.name));
                    save(fullfile(saveFolder{2},'TissueMask_isT0_CoregT0.mat'),'mask_3DTissue_CurrentTP_CoregT0','-v7.3');
                    clearvars tissueMaskTemp
                    %                                             end
                    %no transforms to the mask since
                    %they all use the same mask
                    %% Applying mask
                    %To Co-registered Raw OCTA (from glass step above)
                    if ~exist(fullfile(saveFolder{2},'RawVess_CoregTime0-_isT0_TissueMaskApp.mat'),'file')
                        RawOCTA_CoregT0_RotatedShiftedTissueMaskApp=double(RawVesstemp.(RawVessVarname.name)).*mask_3DTissue_CurrentTP_CoregT0;%RawOCTA_CoregT0_RotatedShiftedRout3);
                        save(fullfile(saveFolder{2},'RawVess_CoregTime0-_isT0_TissueMaskApp.mat'),'RawOCTA_CoregT0_RotatedShiftedTissueMaskApp','-v7.3');
                        clearvars RawOCTA_UnCoregT0_RotatedShifted RawOCTA_CoregT0_RotatedShifted
                    end
                    %To Co-registered stOCT (from glass step above)
                    if ~exist(fullfile(saveFolder{2},'RawStruct_CoregTime0-_isT0_TissueMaskApp.mat'),'file')
                        Structure_CoregT0_RotatedShiftedTissueMaskApp=double(RawStructtemp.(RawStructVarname.name)).*mask_3DTissue_CurrentTP_CoregT0;%Rout3);
                        save(fullfile(saveFolder{2},'RawStruct_CoregTime0-_isT0_TissueMaskApp.mat'),'Structure_CoregT0_RotatedShiftedTissueMaskApp','-v7.3');
                        clearvars Structure_UnCoregT0_RotatedShifted Structure_CoregT0_RotatedShifted
                    end
                    %To Co-registered binarized vessels if applicable
                    if BinVesselsAlreadyPrepared==1%filenameOCTVesBin==1
                        if ~exist(fullfile(saveFolder{2},'BinVess_CoregTime0-_isT0_TissueMaskApp.mat'),'file')
                            BinOCTA_CoregT0_RotatedShiftedTissueMaskApp=double(BinVesstemp.(BinVessVarname.name)).*mask_3DTissue_CurrentTP_CoregT0;%Rout3);
                            save(fullfile(saveFolder{2},'BinVess_CoregTime0-_isT0_TissueMaskApp.mat'),'BinOCTA_CoregT0_RotatedShiftedTissueMaskApp','-v7.3');
                            clearvars BinOCTA_UnCoregT0_RotatedShifted BinOCTA_CoregT0_RotatedShifted%RawOCTA_CoregT0_RotatedShifted
                        end
                    end
                    %% Creating 3D mask as conjunction of tumour lateral contour/ 2D ROI with glass exclusion in depth
                    load(BatchOfFolders{countBatchFolder,4});
                    %MaskVarname=whos('-file',BatchOfFolders{countBatchFolder,4});%should be the coregistered one to timepoint 0- either way by this point
                    %mask2D.(MaskVarname.name)
                    % Mask Fully created no glass and rotated. Perform analysis to fixed depth from glass bottom
                    tumor_maskProj3DRot=shiftdim(repmat(TumourMask2D_aligned_coregTime0,[1,1,DimsVesselsRaw3D(1)]),2);
                    mask_3D_Unrestricted=logical(mask_3DTissue_CurrentTP_CoregT0) & tumor_maskProj3DRot;%mask_3D_Top & %flip(mask_3D_Top & tumor_maskProj3DRot,3);
                    mask_3D_CylindricalProjection=tumor_maskProj3DRot;
                end
            end
        end
    end
    if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2
        MouseTimepoint=[MouseName,' ',TimepointTrueAndRel];
        if VisualizeResults==1
            %% Confirm vessels orientation with respect to structural mask
            
            %if exist(SaveFilenameDataUnlimited) && ~exist(fullfile(saveFolder,'CheckedOrientations.txt'))
            if Neither_0_glass_1_Tissue_2_both_3_contour==1
                if BinVesselsAlreadyPrepared==1
                    BinOCTATemp=matfile(fullfile(saveFolder{1},'BinVess_CoregTime0-_RotShift.mat'));
                    BinOCTAVarname=whos('-file',fullfile(saveFolder{1},'BinVess_CoregTime0-_RotShift.mat'));
                    BinOCTA=BinOCTATemp.(BinOCTAVarname.name);
                    DimsVessels3D=size(BinOCTA);
                    clearvars BinOCTATemp
                else
                    RawOCTATemp=matfile(fullfile(saveFolder{1},'RawVess_CoregTime0-_RotShift.mat'));%svOCTBin=matfile(BatchOfFolders{countBatchFolder,1});
                    RawOCTAVarname=whos('-file',fullfile(saveFolder{1},'BinVess_CoregTime0-_RotShift.mat'));
                    RawOCTA=RawOCTATemp.(RawOCTAVarname.name);
                    DimsVessels3D=size(RawOCTA);
                    clearvars RawOCTATemp
                end
            elseif Neither_0_glass_1_Tissue_2_both_3_contour==2 && Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed
                if OnlyTissueLabelTimepoint0==0
                    if BinVesselsAlreadyPrepared==1
                        BinOCTATemp=matfile(fullfile(saveFolder{2},'BinVess_CoregTime0-_NotInZ_TissueMaskApp.mat'));
                        BinOCTAVarname=whos('-file',fullfile(saveFolder{2},'BinVess_CoregTime0-_NotInZ_TissueMaskApp.mat'));
                        BinOCTA=imresize3(BinOCTATemp.(BinOCTAVarname.name),DimsVesselsRaw3D);
                        clearvars BinOCTATemp
                    else
                        RawOCTATemp=matfile(fullfile(saveFolder{2},'RawVess_CoregTime0-_NotInZ_TissueMaskApp.mat'));%svOCTBin=matfile(BatchOfFolders{countBatchFolder,1});
                        RawOCTAVarname=whos('-file',fullfile(saveFolder{2},'RawVess_CoregTime0-_NotInZ_TissueMaskApp.mat'));
                        RawOCTA=RawOCTATemp.(RawOCTAVarname.name);
                        DimsVessels3D=size(RawOCTA);
                        clearvars RawOCTATemp
                    end
                end
            elseif Neither_0_glass_1_Tissue_2_both_3_contour==3 && Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed
                if (-1<DaysPrecise && DaysPrecise<=0)
                    if BinVesselsAlreadyPrepared==1
                        BinOCTATemp=matfile(fullfile(saveFolder{2},'BinVess_CoregTime0-_isT0_TissueMaskApp.mat'));
                        BinOCTAVarname=whos('-file',fullfile(saveFolder{2},'BinVess_CoregTime0-_isT0_TissueMaskApp.mat'));
                        BinOCTA=imresize3(BinOCTATemp.(BinOCTAVarname.name),DimsVesselsRaw3D);
                        clearvars BinOCTATemp
                    else
                        RawOCTATemp=matfile(fullfile(saveFolder{2},'RawVess_CoregTime0-_isT0_TissueMaskApp.mat'));%svOCTBin=matfile(BatchOfFolders{countBatchFolder,1});
                        RawOCTAVarname=whos('-file',fullfile(saveFolder{2},'RawVess_CoregTime0-_isT0_TissueMaskApp.mat'));
                        RawOCTA=RawOCTATemp.(RawOCTAVarname.name);
                        DimsVessels3D=size(RawOCTA);
                        clearvars RawOCTATemp
                    end
                else
                    if OnlyTissueLabelTimepoint0==0
                        if BinVesselsAlreadyPrepared==1
                            BinOCTATemp=matfile(fullfile(saveFolder{2},'BinVess_CoregTime0-_CurrentTP_TissueMaskApp.mat'));
                            BinOCTAVarname=whos('-file',fullfile(saveFolder{2},'BinVess_CoregTime0-_CurrentTP_TissueMaskApp.mat'));
                            BinOCTA=imresize3(BinOCTATemp.(BinOCTAVarname.name),DimsVesselsRaw3D);
                            clearvars BinOCTATemp
                        else
                            RawOCTATemp=matfile(fullfile(saveFolder{2},'RawVess_CoregTime0-_CurrentTP_TissueMaskApp.mat'));%svOCTBin=matfile(BatchOfFolders{countBatchFolder,1});
                            RawOCTAVarname=whos('-file',fullfile(saveFolder{2},'RawVess_CoregTime0-_CurrentTP_TissueMaskApp.mat'));
                            RawOCTA=RawOCTATemp.(RawOCTAVarname.name);
                            DimsVessels3D=size(RawOCTA);
                            clearvars RawOCTATemp
                        end
                    elseif OnlyTissueLabelTimepoint0==1
                        if BinVesselsAlreadyPrepared==1
                            BinOCTATemp=matfile(fullfile(saveFolder{2},'BinVess_CoregTime0-_FromT0_TissueMaskApp.mat'));
                            BinOCTAVarname=whos('-file',fullfile(saveFolder{2},'BinVess_CoregTime0-_FromT0_TissueMaskApp.mat'));
                            BinOCTA=imresize3(BinOCTATemp.(BinOCTAVarname.name),DimsVesselsRaw3D);
                            clearvars BinOCTATemp
                        else
                            RawOCTATemp=matfile(fullfile(saveFolder{2},'RawVess_CoregTime0-_FromT0_TissueMaskApp.mat'));%svOCTBin=matfile(BatchOfFolders{countBatchFolder,1});
                            RawOCTAVarname=whos('-file',fullfile(saveFolder{2},'RawVess_CoregTime0-_FromT0_TissueMaskApp.mat'));
                            RawOCTA=RawOCTATemp.(RawOCTAVarname.name);
                            DimsVessels3D=size(RawOCTA);
                            clearvars RawOCTATemp
                        end
                    end
                end
            end
            %                             if ~isequal(DimsVesselsRaw3D,[size(mask_3D_Unrestricted)])%[200 760 766])
            %                                 fprintf('Resizing\n')
            %                                 vessels_processed_binaryLateralCoregistered=imresize3(vessels_processed_binaryLateralCoregistered,[200 760 766]);
            %                                 if CorregistrationNotSame
            %                                     save(fullfile(fileparts(BatchOfFolders{countBatchFolder,1}),'Coregistered_binarizedVessels.mat'),'vessels_processed_binary','-v7.3');
            %                                 else
            %                                     save(BatchOfFolders{countBatchFolder,1},'vessels_processed_binary','-v7.3');
            %                                 end
            
            %                                 DimsVesselsRaw3D=size(vessels_processed_binaryLateralCoregistered)
            %                             end
            %mask3D=matfile(SaveFilenameDataUnlimited);%SaveFilenameDataShallow)
            RightOrientation= 'n';
            close all
            %                            countReorientationAtmt3=0;
            while isequal(RightOrientation,'n')%=='n'
                f=figure;
                t=tiledlayout(2,3);
                if BinVesselsAlreadyPrepared==1
                    if Neither_0_glass_1_Tissue_2_both_3_contour==1
                        nexttile
                        h1=imshowpair(squeeze(sum(mask_3D_CylindricalProjection,2)),squeeze(sum(BinOCTA,2)));
                        title('Sagital (yz) plane')
                        nexttile
                        h2=imshowpair(squeeze(sum(mask_3D_CylindricalProjection,3)),squeeze(sum(BinOCTA,3)));
                        title('Coronal (xz) plane')
                        nexttile
                        h3=imshowpair(squeeze(sum(mask_3D_CylindricalProjection,1)),squeeze(sum(BinOCTA,1)));
                        title('Transverse (xy) plane')
                        
                        title(t,{[MouseTimepoint]; ['Overlay of binarized vessels and tumour mask']})
                        f.WindowState='maximize';
                        figure, imshow3D(cat(2,mask_3D_CylindricalProjection-BinOCTA,BinOCTA))
                    else
                        nexttile
                        h1=imshowpair(squeeze(sum(mask_3D_Unrestricted,2)),squeeze(sum(BinOCTA,2)));
                        title('Sagital (yz) plane')
                        nexttile
                        h2=imshowpair(squeeze(sum(mask_3D_Unrestricted,3)),squeeze(sum(BinOCTA,3)));
                        title('Coronal (xz) plane')
                        nexttile
                        h3=imshowpair(squeeze(sum(mask_3D_Unrestricted,1)),squeeze(sum(BinOCTA,1)));
                        title('Transverse (xy) plane')
                        
                        title(t,{[MouseTimepoint]; ['Overlay of binarized vessels and tumour mask']})
                        f.WindowState='maximize';
                        figure, imshow3D(cat(2,mask_3D_Unrestricted-BinOCTA,BinOCTA))
                    end
                else
                    if Neither_0_glass_1_Tissue_2_both_3_contour==1
                        nexttile
                        h1=imshowpair(squeeze(sum(mask_3D_Unrestricted,2)),squeeze(sum(RawOCTA,2)));
                        title('Sagital (yz) plane')
                        nexttile
                        h2=imshowpair(squeeze(sum(mask_3D_Unrestricted,3)),squeeze(sum(RawOCTA,3)));
                        title('Coronal (xz) plane')
                        nexttile
                        h3=imshowpair(squeeze(sum(mask_3D_Unrestricted,1)),squeeze(sum(RawOCTA,1)));
                        title('Transverse (xy) plane')
                        
                        title(t,{[MouseTimepoint]; ['Overlay of binarized vessels and tumour mask']})
                        f.WindowState='maximize';
                        figure, imshow3D(cat(2,mask_3D_Unrestricted-RawOCTA,RawOCTA))
                    else
                        nexttile
                        h1=imshowpair(squeeze(sum(mask_3D_CylindricalProjection,2)),squeeze(sum(RawOCTA,2)));
                        title('Sagital (yz) plane')
                        nexttile
                        h2=imshowpair(squeeze(sum(mask_3D_CylindricalProjection,3)),squeeze(sum(RawOCTA,3)));
                        title('Coronal (xz) plane')
                        nexttile
                        h3=imshowpair(squeeze(sum(mask_3D_CylindricalProjection,1)),squeeze(sum(RawOCTA,1)));
                        title('Transverse (xy) plane')
                        
                        title(t,{[MouseTimepoint]; ['Overlay of binarized vessels and tumour mask']})
                        f.WindowState='maximize';
                        figure, imshow3D(cat(2,mask_3D_CylindricalProjection-RawOCTA,RawOCTA))
                    end
                end
                if (isequal(RightOrientation,'n') || isequal(RightOrientation,'N')) %&& countReorientationAtmt3>1
                    operation=[];
                    while isempty(operation) || ~(isinteger(int8(operation)) && (0<=operation) && (8>operation))
                        operation=input('What operation?\n 0: All aligned\n 1: Return to depth mask alignment \n');
                        if isempty(operation)
                            operation=0;
                        end
                        switch operation
                            case 0
                                RightOrientation='Y';
                                if Neither_0_glass_1_Tissue_2_both_3_contour==1
                                    fid = fopen(fullfile(saveFolder{1},[PrefixFLU_BRI, 'CheckedOrientations.txt']), 'wt');
                                elseif (Neither_0_glass_1_Tissue_2_both_3_contour==2 ||Neither_0_glass_1_Tissue_2_both_3_contour==3) && Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed
                                    fid = fopen(fullfile(saveFolder{2},[PrefixFLU_BRI, 'CheckedOrientations.txt']), 'wt');
                                end
                                fprintf(fid, 'Vessels are in the right orientation with respect to this tumour mask');%'Jake said: %f\n', sqrt(1:10));
                                fclose(fid);
                                %                                         if countReorientationAtmt3>1
                                % %                                             vessels_processed_binary=vessels_processed_binary;
                                %                                             save(BatchOfFolders{countBatchFolder,1},'vessels_processed_binary','-v7.3')
                                %                                             %keyboard
                                %                                         end
                            case 1
                                error('Retry')
                        end
                    end
                end
                
                %end
            end
            if Neither_0_glass_1_Tissue_2_both_3_contour==1
                saveas(f,fullfile(saveFolder{1},[PrefixFLU_BRI, 'FinalMaskCreation.png']))
            elseif (Neither_0_glass_1_Tissue_2_both_3_contour==2 ||Neither_0_glass_1_Tissue_2_both_3_contour==3) && Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed
                saveas(f,fullfile(saveFolder{2},[PrefixFLU_BRI, 'FinalMaskCreation.png']))
            end
        end
        
        if (Neither_0_glass_1_Tissue_2_both_3_contour==2 ||Neither_0_glass_1_Tissue_2_both_3_contour==3) && Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed
            if OnlyTissueLabelTimepoint0==0 || (OnlyTissueLabelTimepoint0==1 && Neither_0_glass_1_Tissue_2_both_3_contour==3)
                %                                                             if DaysPrecise==0
                %                                                                 SaveFilenameDataUnlimitedTemp=strsplit(SaveFilenameDataUnlimited{2},'_');
                %                                                                 SaveFilenameDataCylindricalProjTemp=strsplit(SaveFilenameDataCylindricalProj{2},'_')
                %                                                                 if ~exist([SaveFilenameDataUnlimitedTemp{1:end-1},'_isT0.mat'],'file')||~exist([SaveFilenameDataCylindricalProjTemp{1:end-1},'_FromT0.mat'],'file')
                %                                                                     save([SaveFilenameDataUnlimitedTemp{1:end-1},'_isT0.mat'],'mask_3D_Unrestricted','-mat','-v7.3');
                %                                                                     save([SaveFilenameDataCylindricalProjTemp{1:end-1},'_isT0.mat'],'mask_3D_CylindricalProjection','-mat','-v7.3');
                %                                                                 end
                %                                                             else--changed
                %                                                             outside
                save(SaveFilenameDataUnlimited{2},['mask_3D_Unrestricted'],'-mat','-v7.3');
                save(SaveFilenameDataCylindricalProj{2},['mask_3D_CylindricalProjection'],'-mat','-v7.3');
                %                                                             end
            end
            
        else
            save(SaveFilenameDataUnlimited{1},['mask_3D_Unrestricted'],'-mat','-v7.3');
            save(SaveFilenameDataCylindricalProj{1},['mask_3D_CylindricalProjection'],'-mat','-v7.3');
        end
        
    end
    
end
end
