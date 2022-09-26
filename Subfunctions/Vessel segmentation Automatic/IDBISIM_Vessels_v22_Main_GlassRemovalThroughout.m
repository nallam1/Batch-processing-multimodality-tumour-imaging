%%Main desc.:
% ID space decorrrelation-iSNR space fitting for locally adaptive SNR based
% thresholding of decorrelation OCT
% by Nader A.
% based on: [1] Zhang Y et al. “Automatic 3D adaptive vessel segmentation based on linear relationship between intensity and complex-decorrelation in optical coherence tomography angiography”. Quant Imaging Med Surg. (2021)
% [2] Huang et al. “SNR-Adaptive OCT Angiography Enabled by Statistical Characterization of Intensity and Decorrelation With Multi-Variate Time Series Model”. IEEE Trans Med Imaging. (2019)
% [3] Nam AS et al. “Complex differential variance algorithm for optical coherence tomography angiography.” Biomed Opt Express. (2014)

%% Make sure to set Java Heap memory to max (instead of default to avoid memory issues)
%% Or nevermind it seems to have no effect
clear
clc
tstart=tic %Defined to be able to keep track of time elapsed across functions
%% 0) User input
%Processing scripts
ProcScriptDirectory='D:\git\BatchProcessOptical_OCT-BRI-FLU'%'D:\Processing code\OCT\1) SvOCT processing\Codes_for_Ottawa\Main for bulk processing-Nader'

addpath(genpath(ProcScriptDirectory))
addpath(genpath('D:\'))

%Raw data file select style
RawDataDirectory='F:\SBRT project March-June 2021'%'H:\March-June 2022 experiments'%'G:\PDXovo';%'G:\SBRT project March-June 2021'
cd(RawDataDirectory)
addpath(genpath(RawDataDirectory))
ManualSel_0_OR_ListFiles_1_OR_SemiAut_2_OR_FullAutomatic_3=1;
MatlabVer=2020;%version of Matlab being used %only matters if the year is before/after 2014
PerformSegmentation_0_No_1_Yes=0;%added temporarily Aug 16 2022, as a means for testing without glass-removal code being fully implemented, and noise floor measured for ID-BISIM algorithm--maybe take noise floor as a few pixels above bottom since bottom sometimes has weird artifacts (based on what was seen while performing attenuation coefficient distribution computations).

if ManualSel_0_OR_ListFiles_1_OR_SemiAut_2_OR_FullAutomatic_3==1
    Mice={'L0R4'}%{'0322H3M2';'0322H3M3'}%{'L0R4'}%{'L0R1';'L0R2';'L0R3';'L0R4';'L1R1';'L1R2';'L1R3';'L2R2';'L2R4';'BS1';'BS2';'BS3'};%{'PDXovo-786B';'PDXovo-786C'};%%{'L2R2';'L2R4'};%{'L1R1';'L1R3'};
    Timepoints={'Apr 9 2021'}%{'Jun 6 2022';'Jun 15 2022';'Jul 26 2022';'Jul 29 2022';'Aug 5 2022'}%{'Apr 9 2021'}%{'Apr 9 2021';'Apr 16 2021';'Apr 23 2021';'Apr 13 2021'};%'Apr 5 2021';'Apr 7 2021';'Apr 12 2021';'Apr 13 2021';'Apr 14 2021';'Apr 15 2021';'Apr 17 2021';'Apr 19 2021';'Apr 20 2021';'Apr 21 2021';'Apr 22 2021';'Apr 24 2021';'Apr 26 2021';'Apr 28 2021'}%{'Apr 22 2021';}%{'Apr 5 2021';'Apr 7 2021';'Apr 12 2021';'Apr 13 2021';'Apr 14 2021';'Apr 15 2021';'Apr 17 2021';'Apr 17 2021';'Apr 19 2021';'Apr 20 2021';'Apr 21 2021';'Apr 22 2021'};%{'Apr 5 2021';'Apr 7 2021';'Apr 9 2021';'Apr 12 2021';'Apr 13 2021';'Apr 14 2021';'Apr 15 2021';'Apr 16 2021';'Apr 17 2021';'Apr 17 2021';'Apr 19 2021';'Apr 20 2021';'Apr 21 2021'};
    %{'Apr 27 2021'};%
    Directories=[];
    %NumFiles_max=NumMice*NumTime;%may not all have all timepoints
elseif ManualSel_0_OR_ListFiles_1_OR_SemiAut_2_OR_FullAutomatic_3==2
    Directories={'G:\PDXovo\PDXovo-786C\Apr 30 2021'; 'G:\PDXovo\PDXovo-786C\May 1 2021'};
else
    Directories=[];
end

Patching=1;%%if 9x9 must be patched it seems for memory reasons: Requested 500x1164x8x2400 (83.3GB) array exceeds maximum array size preference. Creation of arrays greater than this limit may take a long
%time and cause MATLAB to become unresponsive.

TallorNot=0;%can be ignored (this was an attempt to reduce memory usage
OS_removal=0.03;%Keep it raw %0.003--empirically found to remove oversaturation from glass but not best
%Not used if go through the largeData processing (PatchedorNot==2)
TimeRepsPerYstepToUse=5;
if TimeRepsPerYstepToUse<2
    error('Choose at least 2 repetitions per y-step')
end

iSNR_physicalPix="Pix" %"Phys" or "Pix"
BISIM_physicalPix="Pix" %"Phys" or "Pix"

%Sliding VOI dimensions iSNR
if iSNR_physicalPix=="Phys"
    %By physical dimensions
    iSNR_size_zVOIum=24; %~FWHM of 24um recommended by " Complex differential variance algorithm for optical coherence tomography angiography."
elseif iSNR_physicalPix=="Pix"
    %By number of voxels
    iSNR_size_zVOIpix=5; %~FWHM of 24um recommended by " Complex differential variance algorithm for optical coherence tomography angiography."
end
%Sliding VOI dimensions BISIM
%By physical dimensions
if BISIM_physicalPix=="Phys"
    BISIM_size_xVOIum=180;
    %     BISIM_size_yVOIum=7.5;%BISIM_size_yVOIum=180;
    BISIM_size_zVOIum=20; %~FWHM of 24um recommended by " Complex differential variance algorithm for optical coherence tomography angiography."
    %By number of voxels
elseif BISIM_physicalPix=="Pix"
    BISIM_size_xVOIpix=35;
    %     BISIM_size_yVOIpix=1;
    BISIM_size_zVOIpix=35; %~FWHM of 24um recommended by " Complex differential variance algorithm for optical coherence tomography angiography."
end
%% Alpha threshold optimization range initialization
NumAlphaVals=90;
RangeOfAlhaThreshFunc=@(minAlpha,maxAlpha) linspace(minAlpha,maxAlpha,NumAlphaVals); %linspace(1.00,90,NumAlphaVals);%RangeOfDThresh=linspace(1.00,0,NumAlphaVals);%for specificity of selection of alpha parameters
RangeOfAlhaThreshFunc=RangeOfAlhaThreshFunc(1,90);

%% 1) All Files to be processed
[NumberFilesToProcess,BatchOfFolders]=BatchSelection(RawDataDirectory,Directories,Mice,Timepoints,ManualSel_0_OR_ListFiles_1_OR_SemiAut_2_OR_FullAutomatic_3,MatlabVer);
for DataFolderInd=1:NumberFilesToProcess
    %% 2) Determining number of patches
    [DimsDataPatchRaw_pix,DimsDataFull_pix,DimsDataFull_um,numStacks,files1,files2, files1Cont,files2Cont, FolderToCreateCheck]=AnalyzeRawDataDims(BatchOfFolders,DataFolderInd);
    mem=memory
    memLim=mem.MemAvailableAllArrays-5e9;
    if ((contains(BatchOfFolders{DataFolderInd},'9x9mm') && TimeRepsPerYstepToUse>4)) || (prod([DimsDataFull_pix(1),DimsDataFull_pix(2),TimeRepsPerYstepToUse,DimsDataFull_pix(4)]))> memLim && Patching~=1  %prod([DimsDataFull_pix(1),DimsDataFull_pix(2),TimeRepsPerYstepToUse,DimsDataFull_pix(4)])>prod([500,1152,2,2400])))
        fprintf('Large memory load detected, readjusting processing for efficiency.\n')
        Patching=2;% in case automatically decided to patch for memory reasons
    end
    %DimsDataFull_pix(4)=DimsDataFull_pix(4)/2;%rescaling before entering
    %loop--August 14 2022, I think it is best to make this change only
    %after having performed CDV processing--correct!
    %Maybe a workaround could be to just load every other frame along y
    if Patching==1 || Patching==2
        meanStruct=cell(numStacks,1);
        D3DPatch=cell(numStacks,1);%D3D_Patch
        vessels_processed_binary=cell(numStacks,1);
        iSNRFramey=cell(numStacks,1);%iSNRFramey=zeros(Patches,DimsDataFull_pix(4));
        BISIMFramey=[];%zeros(numStacks,DimsDataFull_pix(4));
        Alpha1_F=[];%zeros(numStacks,DimsDataFull_pix(4));
        Alpha2_F=[];%zeros(numStacks,DimsDataFull_pix(4));
        %         iSNRFramey=cell(Patches,1);
        %         BISIMFramey=cell(Patches,1);
    elseif Patching==0
        PatchesIntermediate=numStacks;
        %meanStruct=single(zeros(DimsDataFull_pix(1),DimsDataFull_pix(2),DimsDataFull_pix(4)));
        %         D3D=single(zeros(DimsDataFull_pix(1),DimsDataFull_pix(2),DimsDataFull_pix(4)));
        %Define Later vessels_processed_binary=single(zeros(DimsDataFull_pix(1),DimsDataFull_pix(2),DimsDataFull_pix(4)));
        %Define Later iSNRFramey=single(zeros(DimsDataFull_pix(1),DimsDataFull_pix(2),DimsDataFull_pix(4)));%iSNRFramey=zeros(DimsDataFull_pix(4),1);
        BISIMFramey=zeros(DimsDataFull_pix(4),1);
        Alpha1_F=zeros(DimsDataFull_pix(4),1);
        Alpha2_F=zeros(DimsDataFull_pix(4),1);
        numStacks=1;%since performing all in 1 step
        %     elseif Patching==2
        %         PatchesIntermediate=numStacks;
        % %         D3D=single(zeros(DimsDataFull_pix(1),DimsDataFull_pix(2),DimsDataFull_pix(4)));
        %         vessels_processed_binary=[];%single(zeros(DimsDataFull_pix(1),DimsDataFull_pix(2),DimsDataFull_pix(4)));
        %         iSNRFramey=[];%single(zeros(DimsDataFull_pix(1),DimsDataFull_pix(2),DimsDataFull_pix(4)));%iSNRFramey=zeros(DimsDataFull_pix(4),1);
        %         BISIMFramey=[];%zeros(DimsDataFull_pix(4),1);
        %         Alpha1_F=[]%zeros(DimsDataFull_pix(4),1);
        %         Alpha2_F=[]%zeros(DimsDataFull_pix(4),1);
        %         numStacks=1;%since performing all in 1 step
        %         %% imresizen??-Maybe not to avoid reduction resolution
    end
%     %% 3) Loading given patch or full volume of Complex data & determining dimensions of data set
%     [F_SubStack_Re,F_SubStack_Im,DimsDataFull_pixUsed,DimsDataPatch_pixUsed]=LoadRawDataFullFasterVariableTime5_un_patched_resized_Parfeval(BatchOfFolders,DataFolderInd,files1,files2,files1Cont,files2Cont, DimsDataPatchRaw_pix,DimsDataFull_pix, TimeRepsPerYstepToUse);
    %         WidthsPatchesForStitching=zeros(numDiv,1);
    %             for co=1:length(Patch_stack_Complex)
    %                 WidthsPatchesForStitching(co)=size(Patch_stack_Complex{co},2);
    %             end
    for PatchCount=1:numStacks%numStacks:-1:1
        
        Im1=sqrt(-1);
        fprintf('Creating the %d patches of complex data matrices.\n',numStacks)
        if Patching==0
             %% 3) Loading given patch or full volume of Complex data & determining dimensions of data set
            [F_SubStack_Re,F_SubStack_Im,DimsDataFull_pixUsed,DimsDataPatch_pixUsed]=LoadRawDataFullFasterVariableTime6_un_patched_resized_Parfeval(BatchOfFolders,DataFolderInd,files1,files2,files1Cont,files2Cont, DimsDataPatchRaw_pix,DimsDataFull_pix, TimeRepsPerYstepToUse,Patching,[],tstart);%Ignore patchcount since load all
             %[F_SubStack_Re,F_SubStack_Im,DimsDataFull_pixUsed,DimsDataPatch_pixUsed]=LoadRawDataFullFasterVariableTime5_un_patched_resized_Parfeval(BatchOfFolders,DataFolderInd,files1,files2,files1Cont,files2Cont, DimsDataPatchRaw_pix,DimsDataFull_pix, TimeRepsPerYstepToUse);
            fprintf('Stitching together complex data')
            Patch_stack_Complex=single(zeros(DimsDataFull_pixUsed));
            for ind3=PatchesIntermediate:-1:1
                Patch_stack_Complex(:,((DimsDataPatch_pixUsed(ind3,2)*(ind3-1))+(1:DimsDataPatch_pixUsed(ind3,2))),:,:)=single(fetchOutputs(F_SubStack_Re(ind3)))+Im1*single(fetchOutputs(F_SubStack_Im(ind3)));
                    %Aug 15 try to load every other frame?
                    %Aug 14 2022 realized resizing maybe causing weird artifacts in
                    %image?--yes since averages frames together than we take
                    %decorrelation from the averaged frame
                %Patch_stack_Complex(:,((DimsDataPatch_pixUsed(ind3,2)*ind3-1)+(1:DimsDataPatch_pixUsed(ind3,2))),:,:)=(imresizen(single(fetchOutputs(F_SubStack_Re(ind3))),[1 1 1 .5])+Im1*imresizen(single(fetchOutputs(F_SubStack_Im(ind3))),[1 1 1 .5]));
                %                         Patch_stack_Complex(:,((DimsDataPatch_pixUsed(ind3,2)*ind3-1)+(1:DimsDataPatch_pixUsed(ind3,2))),:,:)=(imresizen(single(fetchOutputs(F_SubStack_Re(ind3))),DimsDataPatch_pixUsed(ind3,:))+Im1*imresizen(single(fetchOutputs(F_SubStack_Im(ind3))),DimsDataPatch_pixUsed(ind3,:)));
                %                         Patch_stack_Re{idxFetchedRe}=imresizen(single(RealP),DimsDataFull_pix(1),[DimsDataFull_pix(2),DimsDataFull_pix(1),DimsDataFull_pix(4)/2]);%not necessairly in right order
                %                         Patch_stack_Im{idxFetchedIm}=imresizen(single(ImaginaryP),[DimsDataFull_pix(2),DimsDataFull_pix(1),DimsDataFull_pix(4)/2]);
                fprintf('Completing patch %d/%d \n', ind3,PatchesIntermediate)
            end
            %                         Full_stack_ReIm=[Patch_stack_Re{end:-1:1}]+Im1*[Patch_stack_Im{end:-1:1}];%[Full_stack_ReIm{end:-1:1}];%single(double(Patch_stack_Re(:,:,1:TimeRepsToUse,:))+sqrt(-1)*double(Patch_stack_Im(:,:,1:TimeRepsToUse,:)));
            %%Patch_stack_Complex=Patch_stack_Complex(:,:,:,1:2:end);%Aug 16 try to load every other frame?
%             DimsDataFull_pixUsed=size(Full_stack_ReIm);
        elseif Patching==1 || Patching==2
             %% 3) Loading given patch or full volume of Complex data & determining dimensions of data set
            [F_SubStack_Re,F_SubStack_Im,DimsDataFull_pixUsed,DimsDataPatch_pixUsed]=LoadRawDataFullFasterVariableTime6_un_patched_resized_Parfeval(BatchOfFolders,DataFolderInd,files1,files2,files1Cont,files2Cont, DimsDataPatchRaw_pix,DimsDataFull_pix, TimeRepsPerYstepToUse,Patching,PatchCount,tstart);
            fprintf('Keeping as separate complex data patches for memory efficiency.\n Completing patch %d/%d \n', PatchCount,numStacks)
            Patch_stack_Complex=single(fetchOutputs(F_SubStack_Re))+Im1*single(fetchOutputs(F_SubStack_Im));
            %Aug 14 2022 realized resizing maybe causing weird artifacts in
            %image?--yes since averages frames together than we take
            %decorrelation from the averaged frame
            %(imresizen(single(fetchOutputs(F_SubStack_Re)),[1 1 1 .5])+Im1*imresizen(single(fetchOutputs(F_SubStack_Im)),[1 1 1 .5]));
            %                         F_SubStack_Re(PatchCount)=[];
            %                         F_SubStack_Im(PatchCount)=[];
            %                 elseif Patching==2
            %                     fprintf('Keeping as separate complex data patches for memory efficiency.\n But loaded all at once (unlike Patching=1).\n')
            %                         Patch_stack_Complex=cell(numStacks,1);
            %                         for ind3=1:PatchesIntermediate
            %                             fprintf('Completing patch %d/%d \n', ind3,PatchesIntermediate)
            %                             %halving the pixel scale along y
            %                             Patch_stack_Complex{ind3}=(imresizen(single(fetchOutputs(F_SubStack_Re(ind3))),[1 1 1 .5])+Im1*imresizen(single(fetchOutputs(F_SubStack_Im(ind3))),[1 1 1 .5]));%Patch_stack_Re{ind3}+Im1*Patch_stack_Im{ind3};
            %                                 F_SubStack_Re(ind3)=[];
            %                                 F_SubStack_Im(ind3)=[];
            %                         end
        end
        toc(tstart)
        
             %% Remove glass here
        % Also add if ~exist(D3D) and if ~exist(glass exclusion mask) tumour
        % segmentation code
        %Patch_stack_Complex=glassAutoExcluderv1(Patch_stack_Complex
        
        
        %% 4) Sliding window VOI selection creation
        %Without overlap
        zScale_um2pix=DimsDataFull_um(1)/DimsDataFull_pix(1);
        xScale_um2pix=DimsDataFull_um(2)/DimsDataFull_pix(2);
        yScale_um2pix=DimsDataFull_um(3)/DimsDataFull_pix(4);
        
        if iSNR_physicalPix=="Phys"
            iSNR_size_zVOIpix=round(iSNR_size_zVOIum/zScale_um2pix);%round(DimsData(1)/N_zVOI);
        end
        if BISIM_physicalPix=="Phys"
            BISIM_size_zVOIpix=round(BISIM_size_zVOIum/zScale_um2pix);%round(DimsData(1)/N_zVOI);
            BISIM_size_xVOIpix=round(BISIM_size_xVOIum/xScale_um2pix);%round(DimsData(3)/N_xVOI);
        end
        %     yVOI_pix=1;%Searching single B-scan at a time
        %     yVOI_pix=round(size_yVOIum/yScale_um2pix);%round(DimsData(4)/N_yVOI);
        if Patching==1 || Patching==2
            iSNR_zNumVOIs=DimsDataFull_pixUsed(1)/iSNR_size_zVOIpix;
            %For BISIM computation on given B-scan (patched or not)
            BISIM_zNumVOIs=DimsDataFull_pixUsed(1)/BISIM_size_zVOIpix;
            BISIM_xNumVOIs=DimsDataFull_pixUsed(2)/BISIM_size_xVOIpix;
            
            RangeX_toSample=round(linspace(1,DimsDataFull_pixUsed(2),BISIM_xNumVOIs));
            RangeZ_toSample=round(linspace(1,DimsDataFull_pixUsed(1),BISIM_zNumVOIs));
        else
            iSNR_zNumVOIs=DimsDataFull_pixUsed(1)/iSNR_size_zVOIpix;
            %For BISIM computation on given B-scan (patched or not)
            BISIM_zNumVOIs=DimsDataFull_pixUsed(1)/BISIM_size_zVOIpix;
            BISIM_xNumVOIs=DimsDataFull_pixUsed(2)/BISIM_size_xVOIpix;
            
            RangeX_toSample=round(linspace(1,DimsDataFull_pixUsed(2),BISIM_xNumVOIs));
            RangeZ_toSample=round(linspace(1,DimsDataFull_pixUsed(1),BISIM_zNumVOIs));
        end
        
        RangeX_VOI_window=((-floor(BISIM_size_xVOIpix/2)):ceil(BISIM_size_xVOIpix/2)-1);
        RangeZ_VOI_window=((-floor(BISIM_size_zVOIpix/2)):ceil(BISIM_size_zVOIpix/2)-1);
        %     yNumVOIs=DimsData_pix(4)/yVOI_pix;
        
        %NumVOIs=prod(DimsData_pix(1),DimsData_pix(2),DimsData_pix(4))/prod(zVOI_pix,xVOI_pix,yVOI_pix);
        %% 5) 3D Complex Decorrelation signal
        
        %SubdivideProcessing=contains(BatchOfFolders(DataFolderInd),'9x9mm');
        if Patching==1 || Patching==2
            D3DPatch{PatchCount}(:,:,:)=ComplexDecorrelationFaster7_Tall(Patch_stack_Complex,DimsDataPatch_pixUsed,iSNR_size_zVOIpix,TallorNot,tstart);%zeros(DimsData_pix(1),DimsData_pix(2),DimsData_pix(4));
%             vessels_processed_binary{PatchCount}=single(zeros(size(D3D{PatchCount})));
%             iSNRFramey{PatchCount}=single(zeros(size(D3D{PatchCount})));
            Dims=DimsDataFull_pixUsed;%(PatchCount,:);
        elseif Patching==0
            D3D=ComplexDecorrelationFaster7_Tall(Patch_stack_Complex,DimsDataFull_pixUsed,iSNR_size_zVOIpix,TallorNot,tstart);%zeros(DimsData_pix(1),DimsData_pix(2),DimsData_pix(4));
            %vessels_processed_binary=single(zeros(size(D3D)));%
            Dims=DimsDataFull_pixUsed;
            %        elseif Patching==2
            %            delete(gcp('nocreate'))
            %              p=parpool(PatchesIntermediate);
            %              numDiv=PatchesIntermediate;
            %             fprintf('Computing complex decorrelation signal in %d patches in parallel\n',numDiv)
            %
            % %             DivideXStacks=round(linspace(1,DimsDataFull_pix(2),numDiv+1));%round(linspace(1,max(DimsDataPatch_pix),7));
            %             %WidthCons=length(Divide6Stacks(1):Divide6Stacks(2));% ReImStack_Replipatch=cell{7,1};%{X}
            % %             h = waitbar(0,'Evaluating D3D in each patch...');
            %             Output(1:numDiv)=parallel.FevalFuture;
            %
            %             %% Patching--> Replication Padding and initializing asynchronous parallel processing of the full complex signal patch by patch
            %             for X=numDiv:-1:1%1:numDiv %or during loading keep as 3 separate patches?
            % %                  WidthCons(X)=length(DivideXStacks(X):DivideXStacks(X+1));%constant either way
            %                 ReImStack_Replipatch=cast([repmat(Patch_stack_Complex{X}(1,:,:,:),floor(iSNR_size_zVOIpix/2),1,1,1);Patch_stack_Complex{X};repmat(Patch_stack_Complex{X}(end,:,:,:),ceil(iSNR_size_zVOIpix/2),1,1,1)],'single');%[repmat(Patch_stack_Complex(1,1:WidthCons(X),:,:),floor(iSNR_size_zVOIpix/2),1,1,1);Patch_stack_Complex(:,1:WidthCons(X),:,:);repmat(Patch_stack_Complex(end,1:WidthCons(X),:,:),ceil(iSNR_size_zVOIpix/2),1,1,1)],'single');
            %                 %repeat the top most layer of the data 5x above and later bottom most 5x, both as
            %                 %replication padding
            %                 Patch_stack_Complex{X}=[];
            % %                 Patch_stack_Complex(:,1:WidthCons(X),:,:)=[];
            %                 Output(X)=parfeval(@D3DAndNoiseparfeval,2,ReImStack_Replipatch,iSNR_size_zVOIpix,DimsDataPatch_pixUsed(X,:));%cast([repmat(ReImStack(1,1:WidthCons,:,:),floor(zVOI_pix/2),1,1,1);ReImStack(:,1:WidthCons,:,:);repmat(ReImStack(end,1:WidthCons,:,:),ceil(zVOI_pix/2),1,1,1)],'single'));
            %                 %tall();%D3DAndNoiseparfeval(ReImStack_Replipatch,iSNR_size_zVOIpix,DimsDataFull_pixUsed)
        end
    
        clearvars F_SubStack_Re F_SubStack_Im
        fprintf('Patch %d/%d, complex differential variance evaluated.\n',PatchCount,numStacks)
        toc(tstart)
    end
        %% Progress on each patch at evaluating D3D
        %             updateWaitbar = @(~) waitbar(mean({Output.State} == "finished"),h);
        %             updateWaitbarFutures = afterEach(Output,updateWaitbar,0);
        %                 afterAll(updateWaitbarFutures,@(~) delete(h),0);
        %% Partitioning memory for efficiency --done above, nevermind
        %             D3D=single(zeros(DimsDataPatch_pix(1),DimsDataPatch_pix(2),DimsDataPatch_pix(4)));
        %             meanStruct=single(zeros(DimsDataPatch_pix(1),DimsDataPatch_pix(2),DimsDataPatch_pix(4)));
        %               NoiseFloor=single(zeros(DimsDataFull_pix(2),DimsDataFull_pix(4)));
        %% Rerieve and stitch together
        clearvars ReImStack_Replipatch
        if Patching== 1 || Patching==2
            %D3D=zeros(DimsDataFull_pixUsed([1,2,4]));%[DimsDataFull_pixUsed(1),DimsDataFull_pixUsed(2),DimsDataFull_pixUsed(3)])
        %for X=numStacks:-1:1%numDiv:-1:1%1:numDiv
%             [ind3,iSNRPatch,D3DPatch]=fetchNext(Output);%meanStructPatch,NoiseFloorPatch
            %iSNRFramey(:,(sum(DimsDataPatch_pixUsed(end:-1:ind3,2))-DimsDataPatch_pixUsed(ind3,2))+(1:DimsDataPatch_pixUsed(ind3,2)),:)=iSNRPatch;
            %                 meanStruct(:,((WidthCons*ind3-1)+(1:WidthCons)),:)=meanStructPatch;
            %                 NoiseFloor(((WidthCons*ind3-1)+(1:WidthCons)),:)=NoiseFloorPatch;
            %D3D(:,(sum(DimsDataPatch_pixUsed(end:-1:ind3,2))-DimsDataPatch_pixUsed(ind3,2))+(1:DimsDataPatch_pixUsed(ind3,2)),:)=D3DPatch;
            D3D=MergePatches(D3DPatch);
            clearvars meanStructPatch NoiseFloorPatch D3DPatch
            toc(tstart)
        end
        %end

    %% saving raw OCTA results
    if Patching==1||Patching==2
        save(fullfile(FolderToCreateCheck,'D3DUnrotated.mat'),'D3D','-v7.3');
        %%save(fullfile(FolderToCreateCheck,'D3DUnrotatedSkipFrameY.mat'),'D3D','-v7.3');
        if PerformSegmentation_0_No_1_Yes==1
            vessels_processed_binary=single(zeros(DimsDataFull_pix(1),DimsDataFull_pix(2),DimsDataFull_pix(4)));%initializing
        end
    elseif Patching==0
        save(fullfile(FolderToCreateCheck,'D3DUnrotated.mat'),'D3D','-v7.3');
        if PerformSegmentation_0_No_1_Yes==1
            vessels_processed_binary=single(zeros(DimsDataFull_pix(1),DimsDataFull_pix(2),DimsDataFull_pix(4)));
            iSNRFramey=single(zeros(DimsDataFull_pix(1),DimsDataFull_pix(2),DimsDataFull_pix(4)));%iSNRFramey=zeros(DimsDataFull_pix(4),1);
        end
        %%save(fullfile(FolderToCreateCheck,'D3DUnrotatedSkipFrameY.mat'),'D3D','-v7.3');
    end
    
    %         for ind=1:xNumVOIs
    %             for ind=1:yNumVOIs
    %% 6) iSNR computation in sliding window and optimization of SNR adaptive threshold
    
    %     Time_Var_noise=zeros(DimsData_pix(4),1);
    %     Time_Var_noise=zeros(DimsData_pix(4),1);
    
    %     for yVOI=1:yNumVOIs%1:DimsData_pix(4) %step in y after finish sweeping along x and y
    %         %noise constant for all choices of ROI within the frame (single frame)
    %         RangeY_VOI=((yVOI-1)*yVOI_pix)+(1:yVOI_pix);
    %         Time_Var_noise=var(Main_stack_Re((end-zVOI_pix):end,:,:,RangeY_VOI)+Im1*Main_stack_Im((end-zVOI_pix):end,:,:,RangeY_VOI),3);%do complex product for variance?, also taking just bottom zVOI_pix pixels (-arbitrary) for computation of noise variance over time
    %         for zVOI=1:zNumVOIs%1:DimsData_pix(1) %step in z after finish sweeping along x
    %             RangeZ_VOI=((zVOI-1)*(zVOI_pix))+(1:zVOI_pix);
    %             for xVOI=1:xNumVOIs%xVOI=1:DimsData_pix(2) % Sweeping along x (left to right)
    %                 RangeX_VOI=((xVOI-1)*xVOI_pix)+(1:xVOI_pix);
    %                     Time_Mean_Signal=mean(Main_stack_Re(RangeZ_VOI,RangeX_VOI,RangeY_VOI)+Im1*Main_stack_Im(RangeZ_VOI,RangeX_VOI,RangeY_VOI),3);
    %                         iSNR(zVOI,xVOI,yVOI)=mean(Time_Var_noise./Time_Mean_Signal,'all');%(RangeZ_VOI,RangeX_VOI,RangeY_VOI)=Time_Var_noise./Time_Mean_Signal;
    %% or 6) Load noise Frame
    %     %find(contains(files2Cont,'bg'))
    %     fprintf('Determining Noise floor...\n')
    %                 fprintf('Loading Real Background data.\n')
    %                   Gfilename1=fullfile(files1,files1Cont{contains(files1Cont,'bg')});%([folder1 'b0_ch1.dat']); % 1st quadrature
    %                     di1=fopen(Gfilename1,'r');
    %                     LinearData_Re=fread(di1,'int16=>int16');
    %                         fclose(di1);
    %                 fprintf('Loading Imaginary Background data.\n')
    %                   Gfilename2=fullfile(files2,files2Cont{contains(files2Cont,'bg')});%([folder1 'b0_ch1.dat']); % 1st quadrature
    %                     di2=fopen(Gfilename2,'r');
    %                     LinearData_Im=fread(di2,'int16=>int16');
    %                         fclose(di2);
    %                 fprintf('Creating Full Noise frame.\n')
    %                     BgrFrame=single(reshape(LinearData_Im,DimsDataPatchRaw_pix(1), DimsDataPatchRaw_pix(2)))+sqrt(-1)*;
    
if PerformSegmentation_0_No_1_Yes==1
    %% 7) Executing ID-BISIM automatic thresholding algorithm
    %     delete(gcp('nocreate'))
    % tic
    delete(gcp('nocreate'))
    p=parpool(6);%parpool(12);%3 workers, 6 seems better in all then 3 in all (less workers makes this step faster but not next
    %Instantiating the future instances to be placed in parallel processing
    %queue
    Dims=DimsDataFull_pixUsed;
    F_QueueOfFrames(1:Dims(4))=parallel.FevalFuture;
    %     F_BISIMFramey(1:Dims(4))=parallel.FevalFuture;
    %     F_Alpha1_F(1:Dims(4))=parallel.FevalFuture;
    %     F_Alpha2_F(1:Dims(4))=parallel.FevalFuture;
    %     F_iSNRFramey(1:Dims(4))=parallel.FevalFuture;
    %     F_vessels_processed_binaryY(1:Dims(4))=parallel.FevalFuture;
    fprintf('Initializing all y steps to be segmented via ID-BISIM algorithm\n')
    if Patching==1 ||Patching==2
        %         iSNRFramey{PatchCount}=zeros(DimsDataPatch_pixUsed(4),1);%zeros(DimsData_pix(1),DimsData_pix(2),DimsData_pix(4));
        %         BISIMFramey{PatchCount}=zeros(DimsDataPatch_pixUsed(4),1);
        for y=1:Dims(4)%parfor y=1:Dims(4)
            FrameStructy=removeOversaturation3(squeeze(abs(Patch_stack_Complex{PatchCount}(:,:,:,y)),OS_removal));%magnitude correct to get structural and here considering certain number of repetitions
            FrameD3Dy=squeeze(D3D{PatchCount}(:,:,y));
            F_QueueOfFrames(y)=parfeval(@ID_BISIM_Algorithm_iSNRPerVoxel_iSNRrescaled_PerFrame,5,FrameStructy,FrameD3Dy,NumAlphaVals,Dims,iSNR_size_zVOIpix,BISIM_size_zVOIpix,BISIM_size_xVOIpix,RangeZ_toSample,RangeX_toSample,RangeZ_VOI_window,RangeX_VOI_window,RangeOfAlhaThreshFunc);
            %         [BISIMFramey(PatchCount,y),Alpha1_F(PatchCount,y),Alpha2_F(PatchCount,y),iSNRFramey(PatchCount,y),vessels_processed_binary{PatchCount}(:,:,y)]=parfeval(@ID_BISIM_Algorithm_perFrame,5,FrameStructy,FrameD3Dy,NumAlphaVals,Dims,BISIM_size_zVOIpix,BISIM_size_xVOIpix,RangeZ_toSample,RangeX_toSample,RangeOfDThresh);
        end%[F_BISIMFramey(y),F_Alpha1_F(y),F_Alpha2_F(y),F_iSNRFramey(y),F_vessels_processed_binaryY(y)]
        
    elseif Patching==0
        for y=1:Dims(4)%parfor y=1:Dims(4)
            FrameStructy=removeOversaturation3(squeeze(abs(Patch_stack_Complex(:,:,:,y))),OS_removal);
            FrameD3Dy=squeeze(D3D(:,:,y));
            F_QueueOfFrames(y)=parfeval(@ID_BISIM_Algorithm_iSNRPerVoxel_iSNRrescaled_PerFrame,5,FrameStructy,FrameD3Dy,NumAlphaVals,Dims,iSNR_size_zVOIpix,BISIM_size_zVOIpix,BISIM_size_xVOIpix,RangeZ_toSample,RangeX_toSample,RangeZ_VOI_window,RangeX_VOI_window,RangeOfAlhaThreshFunc);
        end%[F_BISIMFramey(y),F_Alpha1_F(y),F_Alpha2_F(y),F_iSNRFramey(y),F_vessels_processed_binaryY(y)]
%     elseif Patching==2
%         for y=1:Dims(4)%parfor y=1:Dims(4)
%             %FrameStructy=removeOversaturation3(squeeze(meanStruct(:,:,y))),OS_removal);
%             FrameD3Dy=squeeze(D3D(:,:,y));
%             F_QueueOfFrames(y)=parfeval(@ID_BISIM_Algorithm_iSNRPerVoxel_iSNRrescaled_PerFrame_LargeData,5,squeeze(iSNRFramey(:,:,y)),FrameD3Dy,NumAlphaVals,BISIM_size_zVOIpix,BISIM_size_xVOIpix,RangeZ_toSample,RangeX_toSample,RangeZ_VOI_window,RangeX_VOI_window,RangeOfAlhaThreshFunc);
%         end%[F_BISIMFramey(y),F_Alpha1_F(y),F_Alpha2_F(y),F_iSNRFramey(y),F_vessels_processed_binaryY(y)]
    end
    
    toc(tstart)
    %% retrieving data
    
    if Patching==1
        for y=1:Dims(4)
            [indY,out1,out2,out3,out4,out5]=fetchNext(F_QueueOfFrames);
            BISIMFramey(PatchCount,indY)=out1;
            Alpha1_F(PatchCount,indY)=out2;
            Alpha2_F(PatchCount,indY)=out3;%Alpha2_F(PatchCount,y)=val; since not loaded in order
            iSNRFramey(PatchCount,:,:,indY)=out4;%not y
            vessels_processed_binary{PatchCount}(:,:,indY)=out5;
            
            fprintf('******\nIn y=%d for considered patch %d, Optimal alpha values: alpha1=%d and alpha2=%d\n******\n',indY,PatchCount,Alpha1_F(PatchCount,indY),Alpha2_F(PatchCount,indY));
        end
    else
        for y=1:Dims(4)
            [indY,out1,out2,out3,out4,out5]=fetchNext(F_QueueOfFrames);
            BISIMFramey(indY)=out1;
            Alpha1_F(indY)=out2;
            Alpha2_F(indY)=out3;%Alpha2_F(PatchCount,y)=val; since not loaded in order
            iSNRFramey(:,:,indY)=out4;%not y
            vessels_processed_binary(:,:,indY)=out5;
            
            fprintf('******\nIn y=%d, Optimal alpha values: alpha1=%d and alpha2=%d\n******\n',indY,Alpha1_F(indY),Alpha2_F(indY));
        end
    end
    toc(tstart)

%% 8) Saving binarization results
%clearvars D3D_Patch
if Patching==1
    D3D=MergePatches(D3D);
    save(fullfile(FolderToCreateCheck,'D3DUnrotated.mat'),'D3D','-v7.3');
elseif Patching==2 || Patching==0
    save(fullfile(FolderToCreateCheck,'D3DUnrotated.mat'),'D3D','-v7.3');
    D3D=imrotate3(fliplr(D3D),90,[0,1,0]);%this adds a voxel during rotation
end
D3D=cast(D3D,'single');%)%'uint16');--removes decimals otherwise!!!
save(fullfile(FolderToCreateCheck,'D3Dsingle.mat'),'D3D','-v7.3');

if Patching==1
    vessels_processed_binary=logical(MergePatches(vessels_processed_binary));
else
    vessels_processed_binary=logical(imrotate3(fliplr(vessels_processed_binary),90,[0,1,0]));
end
%vessels_processed_binary=single(vessels_processed_binary);
save(fullfile(FolderToCreateCheck,'vessels_processed_binary.mat'),'vessels_processed_binary','-v7.3');
%clearvars vessels_processed_binary_Patch


toc(tstart)
end
end
% Computing difference between vectors for all alpha_t values

%based on k means clustering
% %             ClassesCoord=zeros(90,3,2);%For all values of M (the reference alpha T) stores the 3 separating classes (not exactly corresponding to alpha 1 and 2) based on the difference in vector value from the reference M vector value
% %                 %or Otsu's method?
% %             for M=1:90
% %                 Diff_vector_struct=zeros(89,1);
% %                 for L=1:90
% %                     if M~=L
% %                         Diff_vector_struct(L,1)=sum(sqrt((vector_struct(M,:,:,1)-vector_struct(L,:,:,1)).^2+(vector_struct(M,:,:,2)-vector_struct(L,:,:,2)).^2),'all');
% %                         Diff_vector_struct(L,2)=L;
% %                     end
% %                 end
% %                 %Identifying three clusters for 3 classes see "Automatic 3D adaptive vessel segmentation based on linear relationship between intensity and complex-decorrelation in optical coherence tomography angiography"
% %                 %all for single frame y
% %                   [idx,ClassesCoord(M,:,:)] = kmeans(Diff_vector_struct,3);
% %                    %take the mean after each 3 classes obtained to ensure
% %                    %best choice, or maybe randomly choose index M from
% %                    %which to compute best values separating 3 classes
% %             end
% %             %Determined alpha1 and alpha2 values
% %             alpha1=mean(median([ClassesCoord(:,1,2),ClassesCoord(:,2,2)]));
% %             alpha2=mean(median([ClassesCoord(:,2,2),ClassesCoord(:,3,2)]));
