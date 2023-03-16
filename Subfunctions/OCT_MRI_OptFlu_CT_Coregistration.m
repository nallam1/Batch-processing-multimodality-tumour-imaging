%% Multi-modal Co-registration pipeline
%% Loading all data for co-registration
Modalities={'Brightfield';'CT';'Fluorescence';'MRI';'OCTA'}%histology
Directory={'F:\LSPN and DSWC paper up to Feb 28 2023\DSWC + tools paper'}
ModalityImg={fullfile('Brightfield-fluorescence\1122H3M7','Opt+markers_Superposition.png');...
            fullfile('MRI\Jan27_2023\1122_H3M7\sagt2w','**');...
            fullfile('CT\1122H3M7 Jan 30 2023','**');...
            fullfile('OCT\Cohort 4\1122H3M7\January 30, 2023\setting4_svOCT_24f_6x6mm\1122H3M7_30-Jan-2023 13,53,04_ProcVers1_FixOSremv','SV_volume.mat')};%'RAW_svOCT.mat'%'Opt+AIP_1122H3M7__January 30, 2023.png')...}
for int=1:length(ModalityImg)
    ModalityImg{int}=fullfile(Directory,ModalityImg{int})
end
%% Co-register Brightfield to OCTA
OCTA=matfile(ModalityImg{4});
x=whos(OCTA_2D,'file');
OCTA_2D=squeeze(sum(OCTA.(x.name),1)); % OCT axial slice projection into 2D plan (this will not be transformed in any way
DirectoryCoregistrationData=fullfile(fileparts(ModalityImg{1}),'Co-registration intermediates');
BriFlu_2D=rgb2gray(imread(ModalityImg{1})); % Pre-transformation brightfield/fluorescence

[transform2D_Coregistration_BFOCT,Rfixed_BFOCT]=CoReg_Modalities(1,DirectoryCoregistrationData,OCTA_2D,BriFlu_2D,TryAutomatic,PreviouslyAlignedFound)%,ProcessingDate)%PredrawnTumourMask,,alignedPredrawn
%% Co-register MRI to Brightfield (and then apply geometric transformation above)
MRI_Struct=[];
MRI_StructDir=dir(ModalityImg{3})
for int=1:length(MRI_StructDir)
    if ~isequal(MRI_StructDir{int},'.') || ~isequal(MRI_StructDir{int},'..')
        MRI_Struct(int,:,:)=dicomread(MRI_StructDir{int});
    end
end
MRI_Struct_2D=squeeze(sum(MRI_Struct,1)); % Pre-transformation MRI sagittal slice projection into 2D plan
DirectoryCoregistrationData=fullfile(fileparts(ModalityImg{2}),'Co-registration intermediates');
[transform2D_Coregistration_MRIBF,Rfixed_MRIBF]=CoReg_Modalities(2,DirectoryCoregistrationData,BriFlu_2D,MRI_Struct_2D,TryAutomatic,PreviouslyAlignedFound)%,ProcessingDate)%PredrawnTumourMask,,alignedPredrawn
%% Co-register CT to Brightfield (and then apply geometric transformation above)
CT_Struct=[];
CT_StructDir=dir(ModalityImg{3})
for int=1:length(CT_StructDir)
    if ~isequal(CT_StructDir{int},'.') || ~isequal(CT_StructDir{int},'..')
        CT_Struct(int,:,:)=dicomread(CT_StructDir{int});
    end
end
CT_Struct_2D=squeeze(sum(CT_Struct,1)); % Pre-transformation CT sagittal slice projection into 2D plan
DirectoryCoregistrationData=fullfile(fileparts(ModalityImg{3}),'Co-registration intermediates');
[transform2D_Coregistration_CtBF,Rfixed_CTBF]=CoReg_Modalities(3,DirectoryCoregistrationData,BriFlu_2D,CT_Struct_2D,TryAutomatic,PreviouslyAlignedFound)%,ProcessingDate)%PredrawnTumourMask,,alignedPredrawn