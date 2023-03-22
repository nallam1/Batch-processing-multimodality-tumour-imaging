%% Multi-modal Co-registration pipeline
%% Loading all data for co-registration
Modalities={'Brightfield';'CT';'Fluorescence';'MRI';'OCTA'}%histology
Directory={'F:\LSPN and DSWC paper up to Feb 28 2023\DSWC + tools paper'}
ModalityImg={fullfile('Brightfield-fluorescence\1122H3M7','Opt+markers_Superposition.jpg');...
            fullfile('MRI\Jan27_2023\1122_H3M7\sagt2w','**');...
            fullfile('CT\1122H3M7 Jan 30 2023','**');...
            fullfile('OCT\Cohort 4\1122H3M7\January 30, 2023\setting4_svOCT_24f_6x6mm\1122H3M7_30-Jan-2023 13,53,04_ProcVers1_FixOSremv','SV_volume.mat')};%'RAW_svOCT.mat'%'Opt+AIP_1122H3M7__January 30, 2023.png')...}
for int=1:length(ModalityImg)
    ModalityImg(int)=fullfile(Directory,ModalityImg{int})
end
%% 1) Co-register Brightfield to OCTA
CODE_Coreg='BF-OCT';
OCTA=matfile(ModalityImg{4});
x=whos(OCTA);%,'file');
OCTA_Data2D=squeeze(sum(OCTA.(x.name),1)); % OCT axial slice projection into 2D plan (this will not be transformed in any way
OCTA_2D=(OCTA_Data2D/max(OCTA_Data2D,[],'all')).^4;
size_OCTA_2D=[length(OCTA_2D),length(OCTA_2D)];
OCTA_2DIso=imresize(OCTA_2D,size_OCTA_2D)
DirectoryCoregistrationData=fullfile(fileparts(ModalityImg{1}),'Co-registration intermediates');
BriFlu_2D=imread(ModalityImg{1});%rgb2gray( % Pre-transformation brightfield/fluorescence
BriFlu_2D_Iso=imresize(BriFlu_2D,[size_OCTA_2D]);
if exist(fullfile(DirectoryCoregistrationData,sprintf('registered_%s.mat',CODE_Coreg)))
    PreviouslyAlignedFound=1;
else
    PreviouslyAlignedFound=0;
end
TryAutomatic=0;
   
[transform2D_Coregistration_BFOCT,Rfixed_BFOCT]=CoReg_Modalities(CODE_Coreg,DirectoryCoregistrationData,OCTA_2DIso,BriFlu_2D_Iso,TryAutomatic,PreviouslyAlignedFound)%,ProcessingDate)%PredrawnTumourMask,,alignedPredrawn
%% 2) Co-register MRI to Brightfield (and then apply geometric transformation above)
CODE_Coreg='MRI-BF';
MRI_Struct=[];
MRI_StructDir=dir(ModalityImg{2});
MRI_StructDirFiles={MRI_StructDir.name};
for int=1:length(MRI_StructDirFiles)
    if ~isequal(MRI_StructDirFiles{int},'.') && ~isequal(MRI_StructDirFiles{int},'..') && contains(MRI_StructDirFiles{int},'.dcm')
        MRI_Struct(int,:,:)=dicomread(fullfile(fileparts(ModalityImg{2}),MRI_StructDirFiles{int}));
    end
end
%% default first choice of sagittal slice
if exist(fullfile(DirectoryCoregistrationData,sprintf('ChoiceOfSagittalSliceMRI_%s.mat',CODE_Coreg)),'file')
    load(fullfile(DirectoryCoregistrationData,sprintf('ChoiceOfSagittalSliceMRI_%s.mat',CODE_Coreg)));
else
    SliceSelMRI=1;
end
RightSlice= 'n';
    while isequal(RightSlice,'n')|| isequal(RightSlice,'N')
        MRI_Struct2D=squeeze(MRI_Struct(SliceSelMRI,:,:));%squeeze(sum(MRI_Struct,1)); % Pre-transformation MRI sagittal slice projection into 2D plane
        MRI_Struct2D=(MRI_Struct2D./max(MRI_Struct2D,[],'all'));
        figure, imagesc(MRI_Struct2D),
        %colormap
        RightSliceQ=sprintf('Satisfactory sagittal slice? n otherwise type literally anything else or just press enter for yes\n');
            RightSliceA = inputdlg(RightSliceQ,'Confirm sagittal slice selection',1,{''},'on');%[1 2; 1 2]
                %RightSliceA.opts.WindowStyle = 'normal'
                RightSlice=RightSliceA{1};
             if ~isequal(RightSlice,'n') && ~isequal(RightSlice,'N')
                        RightSlice= 'Y';
             elseif (isequal(RightSlice,'n') || isequal(RightSlice,'N'))% && countReorientationAtmt2>1
                    figure, imshow3D(shiftdim(MRI_Struct,1));%volumeViewer(MRI_Struct)
                    SliceSelMRI=[];
                        while isempty(SliceSelMRI) || ~(isinteger(int8(SliceSelMRI)) && (0<SliceSelMRI) && (size(MRI_Struct,1)>SliceSelMRI))
                            SliceSelQ=sprintf('What slice?\n 1 - %d',size(MRI_Struct,1)); 
                            opts.WindowStyle = 'normal'
                            SliceSelA=inputdlg(SliceSelQ,'Operations options for alignment',1,{''},opts)%SliceSelA=inputdlg(SliceSelQ,'Operations options for alignment',1,{''},'on','WindowStyle','normal');
                            SliceSelMRI=str2double(SliceSelA{1});
                        end
                 close all
             end
    end
%% Co-registration based on fiducials on MRI scan with brightfield scan

DirectoryCoregistrationData=fullfile(fileparts(ModalityImg{2}),'Co-registration intermediates',CODE_Coreg);
if ~exist(DirectoryCoregistrationData,'dir')
    mkdir(DirectoryCoregistrationData);
end

    save(fullfile(DirectoryCoregistrationData,sprintf('ChoiceOfSagittalSliceMRI_%s.mat',CODE_Coreg)),'SliceSelMRI','-mat');
% MRI_Struct_2DIso=imresize(MRI_Struct2D,size_OCTA_2D);
if exist(fullfile(DirectoryCoregistrationData,sprintf('registered_%s.mat',CODE_Coreg)))
    PreviouslyAlignedFound=1;
else
    PreviouslyAlignedFound=0;
end
TryAutomatic=0;

[transform2D_Coregistration_MRIBF,Rfixed_MRIBF]=CoReg_Modalities(CODE_Coreg,DirectoryCoregistrationData,BriFlu_2D_Iso,MRI_Struct2D,TryAutomatic,PreviouslyAlignedFound)%,ProcessingDate)%PredrawnTumourMask,,alignedPredrawn
%% Applying geometric transform for co-registering MRI-BF
% load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-FOV_%s.mat',CODE_Coreg));
% load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-AffineTransformation_%s.mat',CODE_Coreg)));
% Rfixed_MRIBF=Rfixed;
% transform2D_Coregistration_MRIBF=transform2D_Coregistration;
for int=1:size(MRI_Struct,1)
    MRI_StructCoreg(int,:,:)=imwarp(imwarp(squeeze(MRI_Struct(int,:,:)),transform2D_Coregistration_MRIBF{1}),transform2D_Coregistration_MRIBF{2},'OutputView',Rfixed_MRIBF);
end
figure, imshow3D(shiftdim(MRI_StructCoreg,1))
%% 3) Co-register CT to Brightfield (and then apply geometric transformation above)
CODE_Coreg='CT-BF';
CT_Struct=[];
CT_StructDir=dir(ModalityImg{3});
CT_StructDirFiles={CT_StructDir.name};
for int=1:length(CT_StructDir)
    if ~isequal(CT_StructDir{int},'.') && ~isequal(CT_StructDir{int},'..')
        CT_Struct(int,:,:)=dicomread(fullfile(fileparts(ModalityImg{3}),CT_StructDir{int}));
    end
end
DirectoryCoregistrationData=fullfile(fileparts(ModalityImg{3}),'Co-registration intermediates');
%CT_Struct_2D=squeeze(sum(CT_Struct,1)); % Pre-transformation CT sagittal slice projection into 2D plan
%% default first choice of coronal slice
if exist(fullfile(DirectoryCoregistrationData,sprintf('ChoiceOfCoronalSliceCT_%s.mat',CODE_Coreg)),'file')
    load(fullfile(DirectoryCoregistrationData,sprintf('ChoiceOfCoronalSliceCT_%s.mat',CODE_Coreg)));
else
    SliceSelCT=1;
end
RightSlice= 'n';
    while isequal(RightSlice,'n')|| isequal(RightSlice,'N')
        CT_Struct2D=squeeze(CT_Struct(SliceSelCT,:,:));%squeeze(sum(CT_Struct,1)); % Pre-transformation CT coronal slice projection into 2D plane
        CT_Struct2D=(CT_Struct2D./max(CT_Struct2D,[],'all'));
        figure, imagesc(CT_Struct2D),
        %colormap
        RightSliceQ=sprintf('Satisfactory sagittal slice? n otherwise type literally anything else or just press enter for yes\n');
            RightSliceA = inputdlg(RightSliceQ,'Confirm sagittal slice selection',1,{''},'on');%[1 2; 1 2]
                %RightSliceA.opts.WindowStyle = 'normal'
                RightSlice=RightSliceA{1};
             if ~isequal(RightSlice,'n') && ~isequal(RightSlice,'N')
                        RightSlice= 'Y';
             elseif (isequal(RightSlice,'n') || isequal(RightSlice,'N'))% && countReorientationAtmt2>1
                    figure, imshow3D(shiftdim(CT_Struct,1));%volumeViewer(CT_Struct)
                    SliceSelCT=[];
                        while isempty(SliceSelCT) || ~(isinteger(int8(SliceSelCT)) && (0<SliceSelCT) && (size(CT_Struct,1)>SliceSelCT))
                            SliceSelQ=sprintf('What slice?\n 1 - %d',size(CT_Struct,1)); 
                            opts.WindowStyle = 'normal'
                            SliceSelA=inputdlg(SliceSelQ,'Operations options for alignment',1,{''},opts)%SliceSelA=inputdlg(SliceSelQ,'Operations options for alignment',1,{''},'on','WindowStyle','normal');
                            SliceSelCT=str2double(SliceSelA{1});
                        end
                 close all
             end
    end
    save(fullfile(DirectoryCoregistrationData,sprintf('ChoiceOfCoronalSliceCT_%s.mat',CODE_Coreg)),'SliceSelCT','-mat');

if exist(fullfile(DirectoryCoregistrationData,sprintf('registered_%s.mat',CODE_Coreg)))
    PreviouslyAlignedFound=1;
else
    PreviouslyAlignedFound=0;
end
TryAutomatic=0;

[transform2D_Coregistration_CTBF,Rfixed_CTBF]=CoReg_Modalities(CODE_Coreg,DirectoryCoregistrationData,BriFlu_2D_Iso,CT_Struct_2D,TryAutomatic,PreviouslyAlignedFound)%,ProcessingDate)%PredrawnTumourMask,,alignedPredrawn
%% Applying geometric transform for co-registering CT-BF
% load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-FOV_%s.mat',CODE_Coreg));
% load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-AffineTransformation_%s.mat',CODE_Coreg)));
% Rfixed_CTBF=Rfixed;
% transform2D_Coregistration_CTBF=transform2D_Coregistration;
for int=1:size(CT_Struct,1)
    CT_StructCoreg(int,:,:)=imwarp(imwarp(squeeze(CT_Struct(int,:,:)),transform2D_Coregistration_CTBF{1}),transform2D_Coregistration_CTBF{2},'OutputView',Rfixed_CTBF);
end
figure, imshow3D(shiftdim(CT_StructCoreg,1))

%% Final co-registration from MRI and CT to OCTA
for int=1:size(MRI_StructCoreg,1)
    MRI_StructCoregVF(int,:,:)=imwarp(imwarp(squeeze(MRI_StructCoreg(int,:,:)),transform2D_Coregistration_BFOCT{1}),transform2D_Coregistration_BFOCT{2},'OutputView',Rfixed_BFOCT);
end
figure, imshow3D(shiftdim(MRI_StructCoregVF,1))
    MRI_Struct_2D_cVF=squeeze(MRI_StructCoregVF(SliceSelMRI,:,:));
    MRI_Struct_2D_cVF=(MRI_Struct_2D_cVF./max(MRI_Struct_2D_cVF,[],'all'));

for int=1:size(CT_StructCoreg,1)
    CT_StructCoregVF(int,:,:)=imwarp(imwarp(squeeze(CT_StructCoreg(int,:,:)),transform2D_Coregistration_BFOCT{1}),transform2D_Coregistration_BFOCT{2},'OutputView',Rfixed_BFOCT);
end
figure, imshow3D(shiftdim(CT_StructCoregVF,1))
    CT_Struct_2D_cVF=squeeze(CT_StructCoregVF(SliceSelCT,:,:));
    CT_Struct_2D_cVF=(CT_Struct_2D_cVF./max(CT_Struct_2D_cVF,[],'all'));

BriFlu_2D_cVF=imwarp(imwarp(squeeze(BriFlu_2D_Iso,transform2D_Coregistration_BFOCT{1}),transform2D_Coregistration_BFOCT{2},'OutputView',Rfixed_BFOCT);

figure, t=tiledlayout
nextile, imagesc(OCTA_2DIso), title('OCTA')
nextile, imagesc(BriFlu_2D_cVF), title('BF')
nextile, imagesc(MRI_Struct_2D_cVF), title('MRI')
nextile, imagesc(CT_Struct_2D_cVF), title('CT')