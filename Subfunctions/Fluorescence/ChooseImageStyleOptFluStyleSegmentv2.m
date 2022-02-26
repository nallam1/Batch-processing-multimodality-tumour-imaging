function [CoarseROI_Question,fineContouring_Question,ImageX,binaryImageDrawn]=ChooseImageStyleOptFluStyleSegmentv2(Timepoint0Analyzed,PrefixFLU_BRI,image1Segmentation,image2Segmentation,image3Segmentation,filenameT,OptFluSegmentationFolder,SegmentationFolderTimepoint0NotEmpty,MouseNameTimepoint0)
    ImageX=[];%image to be contoured contouring
    binaryImageDrawn=[];
    
    figure('Units','characters','Position',[300 30 60 25]);
        imshow(image1Segmentation);
        title(filenameT)
    if Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed 
        %% Technique for lateral tumour mask creation
        Opt3= exist(fullfile(fileparts(SegmentationFolderTimepoint0NotEmpty),'2D OCT-bri','flu Co-registration + Tumour Mask',[MouseNameTimepoint0, ' ROI mask.mat']));
        Opt4= exist(fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI, char(filenameT),' ROI mask.mat']));
        % option 5 loading last drawn timepoint (whichever you last drew
        % for current mouse?
        if Opt3 && Opt4
            CoarseROI_Questionprompt = sprintf('How to proceed with 2D contouring transversely? \n 1)Draw manually \n 2)No thanks (directly automatic)\n 3)Load Timepoint0- previously drawn\n 4)Load Last attempt drawn for this timepoint.');
        elseif Opt3
            CoarseROI_Questionprompt = sprintf('How to proceed with 2D contouring transversely? \n 1)Draw manually \n 2)No thanks (directly automatic)\n 3)Load Timepoint0- previously drawn');
        else
            CoarseROI_Questionprompt = sprintf('How to proceed with 2D contouring transversely? \n 1)Draw manually \n 2)No thanks (directly automatic)');
        end
    elseif Timepoint0Analyzed==0
        %% Technique for lateral tumour mask creation
        Opt4= exist(fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI, char(filenameT),' ROI mask.mat']));
        % option 5 loading last drawn timepoint (whichever you last drew
        % for current mouse?
        if Opt4
            CoarseROI_Questionprompt = sprintf('How to proceed with 2D contouring transversely? \n 1)Draw manually \n 2)No thanks (directly automatic)\n 4)Load Last attempt drawn for this timepoint.');
        else
            CoarseROI_Questionprompt = sprintf('How to proceed with 2D contouring transversely? \n 1)Draw manually \n 2)No thanks (directly automatic)');
        end
    end
    fineContouring_Questionprompt=['Perform automatic fine thresholding (Otsu method) 1/0'];
    prompt={CoarseROI_Questionprompt;fineContouring_Questionprompt};
    answer = inputdlg(prompt,'Tumour Segmentation options');%[1 2; 1 2]
    % Find nearest timepoint as well?
    %% Image used
    CoarseROI_Question = str2double(answer{1});
    fineContouring_Question = str2double(answer{2});
    
        if CoarseROI_Question ==1 || CoarseROI_Question ==3 || CoarseROI_Question ==4 %"Manual"  
            figure,
            t=tiledlayout(1,3)
            nexttile
                imshow(image1Segmentation)
                title('1')
            nexttile
                imshow(image2Segmentation)
                title('2')
            nexttile
                imshow(image3Segmentation)
                title('3')
            title(t,sprintf('Image options for %s',filenameT))
            
            answer3=[];
                while isempty(answer3) || (answer3~=1 && answer3~=2 && answer3~=3)  
                    prompt3={'What image should be used for manual segmentation? (1,2, or 3)'}
                    answer3 = str2double(inputdlg(prompt3,'Tumour segmentation image format'));%,[1 2]);%assignin difficult to make work%f=Manual_Contouring_method_1v2(image1Segmentation,image2Segmentation,image3Segmentation,filenameT)
                end
                    if answer3==1
                        ImageX=image1Segmentation;
                    elseif answer3==2
                        ImageX=image2Segmentation;
                    elseif answer3==3
                        ImageX=image3Segmentation;
                    end
        elseif CoarseROI_Question==2%"No, thanks"
            ImageX=image1Segmentation;
        elseif CoarseROI_Question ==4 && Opt4%exist(fullfile(OptFluSegmentationFolder,[char(filenameT),' ROI mask.mat']))
%             [name,path]=uigetfile('*.mat', 'Select the ROI mask previously created',OptFluSegmentationFolder)
%             load(fullfile(path,name))%(OptFluSegmentationFolder,[char(filenameT),' ROI mask']));%loadROI;
            load(fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI, char(filenameT),' ROI mask.mat']))
        end
        if Timepoint0Analyzed==1 %Is the analysis being conducted before timepoint 0- has been acquired and been processed 
            if CoarseROI_Question ==3 && Opt3%exist(fullfile(OptFluSegmentationFolder,[char(filenameT),' ROI mask.mat']))
%             [name,path]=uigetfile('*.mat', 'Select the ROI mask previously created',OptFluSegmentationFolder)
%             load(fullfile(path,name))%(OptFluSegmentationFolder,[char(filenameT),' ROI mask']));%loadROI;
            load(fullfile(fileparts(SegmentationFolderTimepoint0NotEmpty),'2D OCT-bri','flu Co-registration + Tumour Mask',[MouseNameTimepoint0,' ROI mask.mat']))
            end
        end
%     assignin('caller','name',n);
%     assignin('caller','age2050',a);
    close all
end