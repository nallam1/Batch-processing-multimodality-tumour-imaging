 %% Preface
% This code allows the user to extract tumour volume and tumour viability
% from fluorescence and brightfield images of window chambered mice taken longiutdinally
% over one timepoint at a time. It also generates the tumour mask to be used
% This is the functional version of the main/central code (which can batchprocess).
% clear;
% close all;
% clc;
function FluorescenceSegmentationAndMetricsFunc_v24_with_Contour_v8(MouseName,TimepointTrueAndRel,TimepointVarName,Transform2D,ReferenceZoom,GrossResponseDir,OptFluSegmentationFolder,predrawnTumourMaskFilepath,FluFile,SegmentingFile,RawsvOCT2D,DoseReceivedUpToTP,DaysPrecise,SegmentationFolderTimepoint0NotEmpty,MouseNameTimepoint0)%RawsvOCTFile
%tic; %timing % [tumor_mask]=
%% User input--Do not change unless trying to do batch processing
        Supervision=1; %After each generated mask it will ask if you are satisfied or not
        Nautomation_of_image_thresholding=2; % 1 if the images are all significantly different and so user input in contouring could help, 0 if background seems significnatly different from target ROI. If 2 decide on a case to case basis.  %the initial value selected to reset to every time. 
        %NautomationMet=1;%in case you opt to go for the decide at every run method "Nautomation_of_image_thresholding=2", there are 2 methods for the manual thresholding
        performFineThresholding=2;%1 if using Otsu's method or 0 if not doing anything (just depending on coarse user drawn ROI definition
%% Initializing data structure for storing all mice extracted metrics
        MiceData=[];%this structure will store all structures of mice data (each struct has its own name) which will store dates, doses, and relative volume values in terms of cubic pixels (for every mouse, for every monitored date) 
        MiceTumourResponseDataFile=fullfile(GrossResponseDir,'LongitudinalGrossTumourResponseMetrics.mat');
        if exist(MiceTumourResponseDataFile,'file')
            load(MiceTumourResponseDataFile);
        end

        
%             MiceData.(Name).(Timepoint).Day=[];
%             MiceData.(Name).(Timepoint).TotalDoseToDate=[];
            MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).Rel_Area=[];
            MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).Rel_Area_3=[];%same as volume without inferring depth just yet
            MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).Rel_Vols_3_1=[];%method 3_1 calculation of Vol (long and short axis) in pixels^3
            MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).Rel_Vols_3_2=[];%method 3_2 calculation of Vol (average diameter calculated from area ~circle) in pixels^3
        %     MiceData2.Timepoint.Vols_3_1=[];%method 3_1 calculation of Vol (long and short axis) in mm^3
        %     MiceData2.Timepoint.Vols_3_2=[];%method 3_2 calculation of Vol (average diameter calculated from area ~circle) in mm^3
            MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).Rel_Viability=[];%Quantifying average intensity of fluorescence in tumour only (out of all bright spots)
            MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).Rel_ViabilityCoregistered=[];
            MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).TimeSinceStartOfTreatment=DaysPrecise;
            MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).DoseReceivedUpToTimepoint=DoseReceivedUpToTP;
            
%% starting processing
if isempty(predrawnTumourMaskFilepath) %if some mask not previously drawn
%% Extraction of image for segmentation in several styles      
       image1Segmentation= imread(SegmentingFile);
       [image2Draft, colourmap] = rgb2ind(image1Segmentation,256);%imports image into given name as a 2D matrix of number of pixels pre row * per column
       %colourmap helps with later epifluorescence viability colourmap 
       %must first change to indexed image, as jpg is true colour image
        fprintf('\nImage loaded! \n\n')
        
% MiceData.(mouseName).(Timepoint).TotalDoseToDate=dose;

% NewDirectory=fullfile(currentdir,'Processed Fluorescence');
%         mkdir(NewDirectory);
%         cd(NewDirectory)
filenameT=[MouseName ' ' TimepointTrueAndRel];%[mouseName+" after "+int2str(dose)+"Gy, flu_{"+string(Timepoints(k,:))+"}"];%For the sake of reformatting titles
%["WC"+int2str(MiceFolderInd)+" after "+int2str(dose)+"Gy, flu_{"+string(Timepoints(k,:))+"}"];%For the sake of reformatting titles


    f2 = figure('visible','off');
    imshow(image2Draft)
    saveas(f2, fullfile(OptFluSegmentationFolder,[filenameT ' format 2.jpg']),'jpg')%figure format 2 for app

image2_O=imread(fullfile(OptFluSegmentationFolder,[filenameT ' format 2.jpg'])); %First saved as a true colour format image
[Cheight,Cwidth]=size(image2Draft);
[InCheight,InCwidth,RGBplanes]=size(image2_O);


image2_1=rgb2gray(image2_O);
countXmax=0;y=round(size(image2_1,1)/2);%starting halfway up image
    for x=round(size(image2_1,2)/2):round(size(image2_1,2))%first half of image
    if image2_1(y,x)==255
    countXmax=countXmax+1;
    end
    end
countXmin=0;yy=round(size(image2_1,1)/2);%starting halfway up image
    for xx=1:round(size(image2_1,2)/2)%first half of image
    if image2_1(yy,xx)==255
    countXmin=countXmin+1;
    end
    end
    
countYmin=0;xx=round(size(image2_1,2)/2);%starting halfway up image
    for yy=1:round(size(image2_1,1)/2)%first half of image
    if image2_1(yy,xx)==255
    countYmin=countYmin+1;
    end
    end
countYmax=0;x=round(size(image2_1,2)/2);%starting halfway up image
    for y=round(size(image2_1,1)/2):round(size(image2_1,1))%first half of image
    if image2_1(y,x)==255
    countYmax=countYmax+1;
    end
    end
    xscale=InCwidth-(countXmin+countXmax);
    yscale=InCheight-(countYmin+countYmax);
    image2_2=image2_O(countYmin:countYmin+yscale-1,countXmin:countXmin+xscale-1,:);
    image2Segmentation=imresize(image2_2,[Cheight Cwidth]);%figure format 2 for app
    %figure,imshow(imfuse(image1,image2))%test overlay
 

%% continue executing the image processing
        %global imageGr
        image3Segmentation=ind2gray(image2Draft,colourmap);
        %     f3 = figure('visible','off');
        %     imshow(image3)
        %     saveas(f3, [filenameT+' format 3'],'jpg')%figure format 3 for app
        %Extraction of different colour planes
%% Visualization of these extracted individual colour planes if needed
        % figure;
        % imshowpair(image,imageGr,'Montage');
        % title('Original image vs gray-scale image')

        
    %% Contouring and Black & White thresholding 
    Satisfied=0;
    countAttempts=0;       
    if Supervision==1 
        while Satisfied==0 
            %%initialized for the next step of image processing
    %         CoarseROI_Question=[];
    %         fineContouring_Question=[];
            binaryImageDrawn=[];
            xy_drawnIntermediate=[];
            xy_drawn=[];

            if Nautomation_of_image_thresholding==2 %%in case you decided that image ROI selection will be decided previously to be on a case to case basis
                %Question_to_user_4_App(image1Segmentation,image2Segmentation,image3Segmentation,filenameT)
                %uiwait(gcf)
                [CoarseROI_Question,fineContouring_Question,ImageX,binaryImageDrawn]=ChooseImageStyleOptFluStyleSegmentv2(image1Segmentation,image2Segmentation,image3Segmentation,filenameT,OptFluSegmentationFolder,SegmentationFolderTimepoint0NotEmpty,MouseNameTimepoint0);
                xy_drawnIntermediate=bwboundaries(binaryImageDrawn);
                if isempty(xy_drawnIntermediate)==0
                    xy_drawn=xy_drawnIntermediate{1};
                end

            end

            %% Tumour Mask creation Manual
            [coarseContouredIPrealignment,coarseContouredIGreyPrealignment, fineContouredIPrealignment,binaryImageDrawn,xy_drawn]=Coarse_Fine_contour_v8_withLoadingAndAdjustment(image1Segmentation,colourmap,ImageX,filenameT,Nautomation_of_image_thresholding,performFineThresholding,CoarseROI_Question,fineContouring_Question, binaryImageDrawn,xy_drawn,OptFluSegmentationFolder);
            figSatisfied=figure; 
            tiledlayout(3,2)
            nexttile
                imshow(fineContouredIPrealignment)
                    %brighten(.5)
            nexttile
                imshowpair(image1Segmentation,fineContouredIPrealignment)
            nexttile(3,[2,2])%at position 3 in 3x2 layout image occupies 2x2 square
                imshow(image1Segmentation)

            %Saving figures Info
            if CoarseROI_Question==1
                coarse='-LoadedFromPreviousROI';
            elseif CoarseROI_Question==2
                coarse='-ManuallyDrawn';
            elseif CoarseROI_Question==3
                coarse='-FullyAutomatic';
            end

            if performFineThresholding==1 || fineContouring_Question==1
            ftiIntermediate=fullfile(OptFluSegmentationFolder,char([filenameT,'-intermediate', coarse, '-With1FineAutomaticThresholding.jpg']));
            title(char([filenameT,'-intermediate', coarse, '-With1FineAutomaticThresholding']))
                ftiFinal=fullfile(OptFluSegmentationFolder,char([filenameT ,'-Final',coarse, '-With1FineAutomaticThresholding.jpg']));
            saveas(gcf,ftiIntermediate,'jpg')
            else
            ftiIntermediate=fullfile(OptFluSegmentationFolder,char([filenameT, '-intermediate',coarse, '-Without0FineAutomaticThresholding.jpg']));
            title(char([filenameT,'-intermediate', coarse, '-With1FineAutomaticThresholding']))
                ftiFinal=fullfile(OptFluSegmentationFolder,char([filenameT ,'-Final',coarse, '-Without0FineAutomaticThresholding.jpg']));
            saveas(gcf,ftiIntermediate,'jpg')
            end

                if countAttempts==0
                            SatisfiedQ=sprintf('Are you satisfied with the contour? 1/0 \n');
                                        SatisfiedA = inputdlg(SatisfiedQ,'Confirm quality of created transverse tumour mask');%[1 2; 1 2]
                                            Satisfied=str2double(SatisfiedA{1});%input('Right orientation? n otherwise type literally anything else or just press enter for yes\n','s');
                                    %Satisfied=input('Are you satisfied with the contour? 1/0 \n');
                    while isempty(Satisfied) ||(Satisfied~=1 && Satisfied~=0)
                        SatisfiedA = inputdlg(SatisfiedQ,'Confirm quality of created transverse tumour mask');%Satisfied=input('Are you satisfied with the contour? Please type 1/0 \n');
                        Satisfied=str2double(SatisfiedA{1});
                    end
                else
                        SatisfiedQ=sprintf('Any better? 1/0 \n');
                                        SatisfiedA = inputdlg(SatisfiedQ,'Confirm quality of created transverse tumour mask');%[1 2; 1 2]
                                            Satisfied=str2double(SatisfiedA{1});%input('Right orie
                    %Satisfied=input('Any better? 1/0 \n');
                    while isempty(Satisfied) ||(Satisfied~=1 && Satisfied~=0)
                        SatisfiedA = inputdlg(SatisfiedQ,'Confirm quality of created transverse tumour mask');%Satisfied=input('Are you satisfied with the contour? Please type 1/0 \n');
                        Satisfied=str2double(SatisfiedA{1});%Satisfied=input('Any better? Please type 1/0 \n');
                    end
                end
                close(figSatisfied)
        end
    % else %fully automatic or no supervision
    %         %%initialized for the next step of image processing
    %         CoarseROI_Question=[];
    %         fineContouring_Question=[];
    %         binaryImageDrawn=[];
    %         xy_drawnIntermediate=[];
    %         xy_drawn=[];
    % 
    %         if Nautomation_of_image_thresholding==2 %%in case you decided that image ROI selection will be decided previously to be on a case to case basis
    %             fig=Question_to_user_2_App(image1Segmentation,image2Segmentation,image3Segmentation,filenameT)
    %             xy_drawnIntermediate=bwboundaries(binaryImageDrawn);
    %             if isempty(xy_drawnIntermediate)==0
    %                 xy_drawn=xy_drawnIntermediate{1};
    %             end
    %             if CoarseROI_Question =="Manual"
    %                 ImageX=[];%image to be contoured contouring
    %             f=Manual_Contouring_method_1v2(image1Segmentation,image2Segmentation,image3Segmentation,filenameT);
    %             elseif CoarseROI_Question =="No, thanks"
    %                 ImageX=image1Segmentation;
    %             end
    % 
    %         end
    %         %% Tumour Mask creation Automatic
    %         [coarseContouredI,coarseContouredIGrey, fineContouredI,binaryImageDrawn,xy_drawn]=Coarse_Fine_contour_v5(image2Draft,map,ImageX,filenameT,Nautomation_of_image_thresholding,performFineThresholding,CoarseROI_Question,fineContouring_Question, binaryImageDrawn,xy_drawn);
    AlreadyAligned=0;
    end
else
    xy_drawn=[];
    tempMask2D=load(predrawnTumourMaskFilepath);
    FindVarName=whos('-file', predrawnTumourMaskFilepath);
    fineContouredIPrealignment=tempMask2D.(FindVarName.name);
    if contains(predrawnTumourMaskFilepath,'TumourMask2D_aligned.mat')
        AlreadyAligned=1;
    else
        AlreadyAligned=0;
    end
    clearvars tempMask2D
end
%% Pre-alignment (black and white image aligned for calculations of area/vol)
%% Feature extraction 
            %Works especially well for binary images
            %Iregion= regionprops(Iopenned,'MajorAxisLength','MinorAxisLength');
            if AlreadyAligned==0
                IregionCoarse= regionprops(imwarp(fineContouredIPrealignment,Transform2D{1}),'centroid');%aligning the black and white image not fully just roughly via rotations
                [LabelledPre, numObjects]=bwlabel(imwarp(fineContouredIPrealignment,Transform2D{1}), 8);%labels Black and White image, via 8 level connectivity (or level connectivity (which adjacent pixels considered neighbours--> are the directly diagonal pixels also considered part of the same object?--then 8)
            else
                IregionCoarse= regionprops(fineContouredIPrealignment,'centroid');%aligning the black and white image
                [LabelledPre, numObjects]=bwlabel(fineContouredIPrealignment, 8);%labels Black and White image, via 8 level connectivity (or level connectivity (which adjacent pixels considered neighbours--> are the directly diagonal pixels also considered part of the same object?--then 8)
            end
            %stats is a structure consisting of all given listed extracted properties
            %for every one of the 18 objects in the image (in Labelled).

             statsPre=regionprops(LabelledPre,'MajorAxisLength','MinorAxisLength',...
                 'Area','BoundingBox');%extracting properties for all identified objects
% Good idea to use the measurements from this stage, since same Zoom
% (objectives) always used) and always doing best to consistently replicate
% focus inter-timepoint (ophtamologist method of focus back and forth on
% whichever seems crispest in some location over time-- blurring may have
% impact on Otsu's method (or maybe even manual?) segmentation technique(s)
            L=[statsPre.MajorAxisLength];
            W=[statsPre.MinorAxisLength];
            area=[statsPre.Area];
            d_ave=sqrt(area*4/pi);%mean([L,W]);--average diameter more accurate
            MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).Rel_Area=area;
            MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).Rel_Area_3=L*W*pi/4;
            MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).Rel_Vols_3_1=L*W^2*pi/2; %compute the relative volume of the oblate ellipsoid mouse tumour according to the Jackson Lab approximation at this day (k) for this mouse (n)
            MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).Rel_Vols_3_2=L*W*d_ave*pi/2; %taking Length, width and assuming heigh is average diameter
            % MiceData2(n).Date(k).Vols_3_1=conv_Pix3_2_mm3(L*W^2/2); %in mm^3
            % MiceData2(n).Date(k).Vols_3_2=conv_Pix3_2_mm3(L*W*d_ave/2); %in mm^3
   
%% alignment
%         coarseContouredIPostalignment=imwarp(imwarp(coarseContouredIPrealignment,Transform2D{1}),Transform2D{2},'OutputView',ReferenceZoom);
%         coarseContouredIGreyPostalignment=imwarp(imwarp(coarseContouredIGreyPrealignment,Transform2D{1}),Transform2D{2},'OutputView',ReferenceZoom);
        if AlreadyAligned==0
            fineContouredIPostalignment=imwarp(imwarp(fineContouredIPrealignment,Transform2D{1}),Transform2D{2},'OutputView',ReferenceZoom);
            %fineContouredICoarsealignment=imwarp(fineContouredIPrealignment,Transform2D{1});
        else
            fineContouredIPostalignment=fineContouredIPrealignment;
            %fineContouredICoarsealignment=fineContouredIPrealignment;
        end
        %% saving version of the mask transformed but before alignment operation longitudinally 
        %followOutput = affineOutputView(size(fineContouredIPrealignment),Transform2D{2},'BoundsStyle','FollowOutput');
        TumourMask2DPreCoregTime0=imwarp(imwarp(fineContouredIPrealignment,Transform2D{1}),Transform2D{2});%,'OutputView',followOutput);
        save(fullfile(OptFluSegmentationFolder,['Mask2DPreCoregTime0-ForScaling.mat']),'TumourMask2DPreCoregTime0','-v7.3')
        clearvars TumourMask2DPreCoregTime0
%         if ~isempty(binaryImageDrawn)
%             binaryImageDrawn=imwarp(imwarp(binaryImageDrawn,Transform2D{1}),Transform2D{2},'OutputView',ReferenceZoom);
%         end
        if ~isempty(xy_drawn)
            xy_drawn=imwarp(imwarp(xy_drawn,Transform2D{1}),Transform2D{2},'OutputView',ReferenceZoom);
        end
       
        
        %TumourMask2D_aligned=coarseContouredI;
        %save(fullfile(TumourMaskAndStepsDir,[predrawnTumourMaskFileKeyword, '.mat']),'fineContouredI','-mat')%Timepoints{k})),'fineContouredI','-mat')%sprintf('TumourMask2D-%s.mat',Timepoint)
        % elseif k>1
        % [coarseContouredI, fineContouredI,xy_drawn]=Coarse_Fine_contour(imageGr,filenameT,automation_of_image_thresholding);
        % end
        %close(fig,f,gcf)--not quite
%% Post alignment
    %% Feature extraction 
            %Works especially well for binary images
            %Iregion= regionprops(Iopenned,'MajorAxisLength','MinorAxisLength');
            Iregion= regionprops(fineContouredIPostalignment,'centroid');%regionprops(fineContouredIPostalignment,'centroid');
            [LabelledPost, numObjects]=bwlabel(fineContouredIPostalignment, 8);%labels Black and White image, via 8 level connectivity (or level connectivity (which adjacent pixels considered neighbours--> are the directly diagonal pixels also considered part of the same object?--then 8)
%             IregionFullalignment=regionprops(fineContouredIPostalignment,'centroid');
%             [LabelledPostFullalignment, numObjects]=bwlabel(fineContouredICoarsealignment, 8);%labels Black and White image, via 8 level connectivity (or level connectivity (which adjacent pixels considered neighbours--> are the directly diagonal pixels also considered part of the same object?--then 8)
%Makes more sense not to rely on resizing which may vary possibly a bit
%(affine transforms...)
%             %stats is a structure consisting of all given listed extracted properties
%             %for every one of the 18 objects in the image (in Labelled).
% 
%              statsPost=regionprops(LabelledPost,'MajorAxisLength','MinorAxisLength',...
%                  'Area','BoundingBox');%extracting properties for all identified objects
% 
%             L=[statsPost.MajorAxisLength];
%             W=[statsPost.MinorAxisLength];
%             area=[statsPost.Area];
%             d_ave=sqrt(area*4/pi);
%             MiceData.(TimepointVarName{1}).(TimepointVarName{2}).Rel_Vols_3_1=L*W^2/2; %compute the relative volume of the oblate ellipsoid mouse tumour according to the Jackson Lab approximation at this day (k) for this mouse (n)
%             MiceData.(TimepointVarName{1}).(TimepointVarName{2}).Rel_Vols_3_2=L*W*d_ave/2; %taking Length, width and assuming heigh is average diameter
%             % MiceData2(n).Date(k).Vols_3_1=conv_Pix3_2_mm3(L*W^2/2); %in mm^3
%             % MiceData2(n).Date(k).Vols_3_2=conv_Pix3_2_mm3(L*W*d_ave/2); %in mm^3
%             
%             %Works below but too small to fit text
            %% Adding visual cue for rectangular contour of tumour + visualization
    %contour rectangle
        OriginalI=imwarp(image1Segmentation,Transform2D{1});%imwarp(imwarp(image1Segmentation,Transform2D{1}),Transform2D{2},'OutputView',ReferenceZoom);%image1Segmentation;
        %figure, 
        %DataToShow=@()text(40,50,char("L = "+num2str(L)+"| W = "+num2str(W)+"| VoL_{Rel} = "+num2str(Rel_Vols(n,k))));
                    roundingSigFigs=max(length(sprintf('%.0f',L)),length(sprintf('%.0f',W)));
        DataToShow=@()text(-1000,780,sprintf('Metrics [pix]: \n Length = %.0f \n Width = %.0f \n Area = %.0f \n Diameter_{ave}= %.0f\n Volume = %.3e',L,W,area,d_ave,round(MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).Rel_Vols_3_2,roundingSigFigs,'significant')));%round(MiceData.(TimepointVarName{1}).(TimepointVarName{2}).Rel_Vols_3_2,roundingSigFigs,'significant')%%positioning barely works--not intuitive but does%DataToShow=@()text(-1000,780,sprintf('All in pixels: \nL_{Rel} = %.0f \nW_{Rel} = %.0f \nA_{Rel} = %.0f \nd_{ave Rel}= %.0f\nVoL_{Rel} = %.3e',L,W,area,d_ave,round(MiceData.(TimepointVarName{1}).(TimepointVarName{2}).Rel_Vols_3_2,roundingSigFigs,'significant')));%round(MiceData.(TimepointVarName{1}).(TimepointVarName{2}).Rel_Vols_3_2,roundingSigFigs,'significant')%%positioning barely works--not intuitive but does
            propsText={'fontweight','bold','color','m','fontsize',40,...
           'linewidth',3,'margin',5,'edgecolor',[0 1 1],'backgroundcolor','y'};
        ImageContouring=@()rectangle('Position',statsPre.BoundingBox);%it takes,x,y, width, height to draw rectangle %I could also add curvature factor to make rectangle into ellipse according to rectangle() parameters
            propsRectangle={'EdgeColor',[1,0,0],'linewidth',3};

        %     set(h,'EdgeColor', [.75,0,0]);
        %imgOut = insertInImage(OriginalI, {ImageContouring, DataToShow},{propsRectangle,propsText});
        imgOut = insertInImage(OriginalI, {DataToShow,ImageContouring},{propsText,propsRectangle});%for some reason it only works when change order and say both times

        % imshow(imgOut);
        % ti5=['Contoured image: ',char(filenameT)];
        % title(ti5)
%% Epifluorescence imaging to obtain ~viability/hypoxia map (superficially)

%fluoro
    FluImage=imwarp(imread(FluFile),Transform2D{1});%imwarp(imread(FluFile),Transform2D,'OutputView',ReferenceZoom);
%     image3Segmentation=imwarp(imwarp(image3Segmentation,Transform2D{1}),Transform2D{2},'OutputView',ReferenceZoom);%imwarp(image3Segmentation,Transform2D,'OutputView',ReferenceZoom);
    GrayScaleFluImage=rgb2gray(FluImage).*uint8(LabelledPre);%rgb2gray(Labelled.*double(FluImage));
        grayscaleIm=GrayScaleFluImage;%coarseContouredIGrey;%rgb2gray(OriginalI.*fineContouredI);%rgb2gray(OriginalI)%coarseContouredIcropped); %this part can be improved via apodization, I subtract 7 as determined by iteratively through trial and error 
        indIm=gray2ind(grayscaleIm);%Convert to index image--each index corresponds to an intensity value which can also be mapped to a colourmap
        rescaledindIm= floor(256/double(max(max(indIm))))*indIm;%could also use imadjust %histeq(coarseContouredIGrey,256);%spacing out the difference between pixel values--can maybe also use equalize on the histogram 
        %figure, subplot(1,2,1);imhist(histeq(coarseContouredIGrey,256)); subplot(1,2,2);imhist(floor(256/double(max(max(xImage))))*indIm);
        %For justifyig histogram equalization method used

        % Viability metric--average intensity over all pixels with at least 1
        % intensity (so that I do not account for possible differences in
        % magnification--may need apodization to remove airy rings
        countI=0;
        for pixelsInImage=1:size(grayscaleIm,1)*size(grayscaleIm,2)
        if grayscaleIm(pixelsInImage)>0
            countI=countI+1;
        end
        end
        Viability=sum(grayscaleIm,'all')/nnz(LabelledPre);%countI;
        MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).Rel_Viability=Viability;%Date(k).Rel_Viability=Viability;
 %fluoro       
        FluImage=imwarp(imwarp(imread(FluFile),Transform2D{1}),Transform2D{2},'OutputView',ReferenceZoom);%imwarp(imread(FluFile),Transform2D,'OutputView',ReferenceZoom);
%     image3Segmentation=imwarp(imwarp(image3Segmentation,Transform2D{1}),Transform2D{2},'OutputView',ReferenceZoom);%imwarp(image3Segmentation,Transform2D,'OutputView',ReferenceZoom);
    GrayScaleFluImage=rgb2gray(FluImage).*uint8(LabelledPost);%rgb2gray(Labelled.*double(FluImage));
        grayscaleIm=GrayScaleFluImage;%coarseContouredIGrey;%rgb2gray(OriginalI.*fineContouredI);%rgb2gray(OriginalI)%coarseContouredIcropped); %this part can be improved via apodization, I subtract 7 as determined by iteratively through trial and error 
        indIm=gray2ind(grayscaleIm);%Convert to index image--each index corresponds to an intensity value which can also be mapped to a colourmap
        rescaledindIm= floor(256/double(max(max(indIm))))*indIm;%could also use imadjust %histeq(coarseContouredIGrey,256);%spacing out the difference between pixel values--can maybe also use equalize on the histogram 
        %figure, subplot(1,2,1);imhist(histeq(coarseContouredIGrey,256)); subplot(1,2,2);imhist(floor(256/double(max(max(xImage))))*indIm);
        %For justifyig histogram equalization method used

        % Viability metric--average intensity over all pixels with at least 1
        % intensity (so that I do not account for possible differences in
        % magnification--may need apodization to remove airy rings
        countI=0;
        for pixelsInImage=1:size(grayscaleIm,1)*size(grayscaleIm,2)
        if grayscaleIm(pixelsInImage)>0
            countI=countI+1;
        end
        end
        Viability=sum(grayscaleIm,'all')/nnz(LabelledPost);%countI;
        
        MiceData.(MouseName).(TimepointVarName{1}).(TimepointVarName{2}).Rel_ViabilityCoregistered=Viability;
%% Figure
        figure,
        FIG=tiledlayout(3,3);
        if (Nautomation_of_image_thresholding==0 || CoarseROI_Question==2) && ~isempty(xy_drawn)%"Manual"
        %subplot(2, 2, 1),
        nexttile(1),%image3Segmentation
            imshow(rescaledindIm), ti1=[{'Grey-scale of original image'},{'with user marking'}];
            title(ti1); %ti1=[{'Grey-scale of original image ',char(filenameT)},{'with user marking'}];title(ti1); % Plot over original image.
                    hold on; % Don't blow away the image.
                    x = xy_drawn(:, 1)%Already flipped xy_drawn(:, 2); % Columns.
                    y = xy_drawn(:, 2); %Columns now %Before essentially transpose was Rows.
                    plot(x, y,'r','LineWidth', 2);
                    drawnow; % Force it to draw immediately.
        else
        %subplot(2, 2, 1),
        nexttile(1),%image3Segmentation
        imshow(rescaledindIm), ti1=['Grey-scale of original image'];% ti1=['Grey-scale of original image ',char(filenameT)];
        title(ti1);
        end

%         %subplot(2,2,2),
%         nexttile,imshow(fineContouredIPostalignment), ti2=[{'Mask refined thresholding'}];%,{'for image '},char(filenameT)];
%         title(ti2);

        

        nexttile(2),%subplot(2,2,4),
        imshow(rescaledindIm);

        colormap(gca, 'jet'); 
        limits = [0,255];
        c = colorbar;
        axis on;
        conv_f = 0.0056;%conversion factor pixels to mm
        xt=xticks*conv_f;
        yt=yticks*conv_f;
        xticklabels(string(int2str(xt')));
        yticklabels(string(int2str(yt')));
        xlabel('Width [mm]')
        ylabel('Length [mm]')
        set(gca,'clim',limits([1,end]))
        colorbar(gca);

        ti2=[{'Epifluorescence Intensity'},{'Colourmap'}];%: ',char(filenameT)}];
        title(ti2)
       
        nexttile(6,[2,1]),%subplot(2,2,3),
        imshow(imgOut);
        ti3=['Contoured epifluorescence image'];%,char(filenameT)];
        title(ti3)
        
        nexttile(3),
        TumourMask2D_aligned=logical(fineContouredIPostalignment);%same as LabelledPost%createMask(fineContouredI);
            imshowpair(TumourMask2D_aligned,RawsvOCT2D);
            ti5=['Superposition: Raw svOCT & tumour mask'];% ',char(filenameT)];
            title(ti5)
        nexttile(4,[2,2]),
            imshowpair(TumourMask2D_aligned,RawsvOCT2D,'montage');
            ti6=['Montage: Raw svOCT & tumour mask'];% ',char(filenameT)];
            title(ti6)
        
        title(FIG,[{'Tumour transverse segmentation and extracted information'},{[char(filenameT)]}])
        set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
        
        
        

        %Saving figuresInfo
       saveas(gcf,ftiFinal,'jpg')
       
        %gmap = rgb2gray(map);
        %Nautomation_of_image_thresholding=Nautomation_of_image_thresholdingI;
        %with new colour map
        
%% Save MiceData
% mkdir(fullfile(Directory,date))
% cd(fullfile(Directory,date))
%         if performFineThresholding==1
%         MiceTumourResponseDataFile=char([fullfile(Directory,date,MiceTumourResponseDataFile), ' with fine automatic thresholding'])
%         else
%         MiceTumourResponseDataFile=char([fullfile(Directory,date,MiceTumourResponseDataFile), ' without fine automatic thresholding'])
%         end    

        save(MiceTumourResponseDataFile, 'MiceData','-v7.3');
        
%         tumor_mask=imwarp(tumor_mask,transform2D);
        save(fullfile(OptFluSegmentationFolder,['TumourMask2D_aligned.mat']),'TumourMask2D_aligned','-v7.3')
% %% Export to spreadsheet
%         if performFineThresholding==1
%         fileSpreadSheet=char([fullfile(Directory,date,fileSpreadSheet), ' with fine automatic thresholding.xlsx'])
%         else
%         fileSpreadSheet=char([fullfile(Directory,date,fileSpreadSheet), ' without fine automatic thresholding.xlsx'])
%         end    
% 
%         save_to_spreadsheet(MiceTumourResponseDataFile, NumMice, fileSpreadSheet,Mice);
%toc; %timing for the full execution
end
                 