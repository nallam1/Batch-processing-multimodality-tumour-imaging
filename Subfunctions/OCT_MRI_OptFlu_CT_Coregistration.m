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
%% Co-register Brightfield to OCTA
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
%% Co-register MRI to Brightfield (and then apply geometric transformation above)
CODE_Coreg='MRI-BF';
MRI_Struct=[];
MRI_StructDir=dir(ModalityImg{2});
MRI_StructDirFiles={MRI_StructDir.name};
for int=1:length(MRI_StructDirFiles)
    if ~isequal(MRI_StructDirFiles{int},'.') && ~isequal(MRI_StructDirFiles{int},'..') && contains(MRI_StructDirFiles{int},'.dcm')
        MRI_Struct(int,:,:)=dicomread(fullfile(fileparts(ModalityImg{2}),MRI_StructDirFiles{int}));
    end
end
DirectoryCoregistrationData=fullfile(fileparts(ModalityImg{2}),'Co-registration intermediates');
%default first choice of sagittal slice
SliceSel=1;
RightSlice= 'n';
    while isequal(RightSlice,'n')|| isequal(RightSlice,'N')
        MRI_Struct_2D=squeeze(MRI_Struct(SliceSel,:,:));%squeeze(sum(MRI_Struct,1)); % Pre-transformation MRI sagittal slice projection into 2D plane
        RightSliceQ=sprintf('Satisfactory sagittal slice? n otherwise type literally anything else or just press enter for yes\n');
            RightSliceA = inputdlg(RightSliceQ,'Confirm sagittal slice selection');%[1 2; 1 2]
                RightSlice=RightSliceA{1};
             if ~isequal(RightSlice,'n') && ~isequal(RightSlice,'N')
                        RightSlice= 'Y';
             elseif (isequal(RightSlice,'n') || isequal(RightSlice,'N'))% && countReorientationAtmt2>1
                    figure, imshowpair(ImageToBeCoregistered,ImageFixed,'montage')
                    SliceSel=[];
                        while isempty(SliceSel) || ~(isinteger(int8(SliceSel)) && (0<SliceSel) && (size(MRI_Struct,1)>SliceSel))
                            SliceSelQ=sprintf('What slice?\n 1 - %d',size(MRI_Struct,1)) 
                            SliceSelA=inputdlg(SliceSelQ,'Operations options for alignment');
                            SliceSel=str2double(SliceSelA{1});
                        end
                 close all
             end
    end
    save(fullfile(DirectoryCoregistrationData,sprintf('ChoiceOfSagittalSliceMRI_%s.mat',CODE_Coreg)),'transform2D_Coregistration','-mat');
MRI_Struct_2DIso=imresize(MRI_Struct_2D,size_OCTA_2D);

%%
if exist(fullfile(DirectoryCoregistrationData,sprintf('registered_%s.mat',CODE_Coreg)))
    PreviouslyAlignedFound=1;
else
    PreviouslyAlignedFound=0;
end
TryAutomatic=0;

[transform2D_Coregistration_MRIBF,Rfixed_MRIBF]=CoReg_Modalities(CODE_Coreg,DirectoryCoregistrationData,BriFlu_2D_Iso,MRI_Struct_2DIso,TryAutomatic,PreviouslyAlignedFound)%,ProcessingDate)%PredrawnTumourMask,,alignedPredrawn
%% Co-register CT to Brightfield (and then apply geometric transformation above)
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
%coronal





CT_Struct_2DIso=imresize(CT_Struct_2D,size_OCTA_2D);


if exist(fullfile(DirectoryCoregistrationData,sprintf('registered_%s.mat',CODE_Coreg)))
    PreviouslyAlignedFound=1;
else
    PreviouslyAlignedFound=0;
end
TryAutomatic=0;

[transform2D_Coregistration_CtBF,Rfixed_CTBF]=CoReg_Modalities(CODE_Coreg,DirectoryCoregistrationData,BriFlu_2D_Iso,CT_Struct_2DIso,TryAutomatic,PreviouslyAlignedFound)%,ProcessingDate)%PredrawnTumourMask,,alignedPredrawn