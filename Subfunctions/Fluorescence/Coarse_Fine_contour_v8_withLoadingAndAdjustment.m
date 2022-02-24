function [coarseContouredI,coarseContouredIGrey, fineContouredI,binaryImageDrawn, xy_drawn]= Coarse_Fine_contour_v8_withLoadingAndAdjustment(PrefixFLU_BRI,image_for_reference,colourmap, image_to_be_contoured,filenameT,Nautomation,performFineThresholding,CoarseROI_Question,fineContouring_Question,binaryImageDrawn, xy_drawn,OptFluSegmentationFolder)
%% Description
    %Ask user to coarsely contour image and/or further automatic fine automatic
    %thresholding (the user is prompted beforehand based on a given image to
    %answer whether they feel manual coarse contouring and/or automatic fine 
    %thresholding is necessary/can be done based on their judgement--only 
    %necessary if contrast of ROI to background is poor). This 
    %function following contouring sets everything outside the Region of
    %Interest (ROI) to zero intensity.
    %The user can save and import drawn contours, but this has yet to be worked
    %out (maybe not very necessary)


%% Asking user to coarsely contour first
if Nautomation==1 || CoarseROI_Question== 1%"Manual"%Nautomation is for direct entry the other way is decide through the app GUI
        figure,
        imshow(image_to_be_contoured);%Image_to_be_contoured);
        axis on;
        title('Original Image', 'FontSize', 12);
        set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
        
        message = sprintf('Left click and hold to begin drawing.\nSimply lift the mouse button to finish');
        uiwait(msgbox(message));
        h = drawassisted();%imfreehand;
        %h = roipoly(I);
        %pos = h.Position;
        %DrawnContourPos=h.Position; --fine too
        binaryImageDrawn = h.createMask();
        
        close gcf
        binaryImageDrawnName=fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI,char(filenameT),' ROI mask.mat']);

if sum(binaryImageDrawn,'all')>0 %so making sure you did not simply cancel out of mask creation
                save(binaryImageDrawnName,'binaryImageDrawn');%save everything about the drawn ROI mask
                xy_drawnIntermediate=bwboundaries(binaryImageDrawn);
        xy_drawn=[xy_drawnIntermediate{1}(:,2),xy_drawnIntermediate{1}(:,1)];%xy_drawnIntermediate{1};%
end
%             end
                %xy = h.getPosition;
   end

if CoarseROI_Question== 3 || CoarseROI_Question== 4 %"Load ROI" %%not complete--for loading contour masks if needed
    %%somehow make manipulatable ROI once loaded? YES
    xy_drawnIntermediate=bwboundaries(binaryImageDrawn);
    xy_drawnPrevious=[xy_drawnIntermediate{1}(:,2),xy_drawnIntermediate{1}(:,1)];%xy_drawnIntermediate{1};%
    figure,
        imshow(image_to_be_contoured);%Image_to_be_contoured);
        axis on;
        title('Original Image', 'FontSize', 12);
        set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
        
        message = sprintf('Left click and hold to begin drawing.\nSimply lift the mouse button to finish');
        uiwait(msgbox(message));
        h2= drawassisted('Position',[xy_drawnPrevious],'InteractionsAllowed','all')%drawassisted();%imfreehand;
        %h = roipoly(I);
        %pos = h.Position;
        binaryImageDrawn = h2.createMask();
        
        close gcf
        binaryImageDrawnName=fullfile(OptFluSegmentationFolder,[PrefixFLU_BRI, char(filenameT),' ROI mask.mat']);
    if sum(binaryImageDrawn,'all')>0 %so making sure you did not simply cancel out of mask creation
                save(binaryImageDrawnName,'binaryImageDrawn');%save everything about the drawn ROI mask
                xy_drawnIntermediate=bwboundaries(binaryImageDrawn);
        xy_drawn=[xy_drawnIntermediate{1}(:,2),xy_drawnIntermediate{1}(:,1)];%xy_drawnIntermediate{1};%
    end
end
%if (Nautomation==1 && NautomationMet==1) || (CoarseROI_Question== "Manual" && Manual_Question=="Method1") || CoarseROI_Question== "Load ROI"
if Nautomation==1 || CoarseROI_Question==1  || CoarseROI_Question==3 || CoarseROI_Question==4%"Manual""Load ROI"

        coarseContouredI=image_for_reference;%ind2rgb(image_for_reference,colourmap);%the image loaded was an index type image, so converting it to true colour (RGB image)
        coarseContouredIGrey=rgb2gray(coarseContouredI); %extracting only intensity values in grayscale
        coarseContouredI(~binaryImageDrawn)=0;%setting everything outside rough contour to zero
        coarseContouredIGrey(~binaryImageDrawn)=0;
%figure,imshow(coarseContouredIGrey)
        %marking where user drew line
%         % Get coordinates of the boundary of the freehand drawn region.
%             drawingBoundaries = bwboundaries(binaryImageDrawn);
%             xy_drawn=drawingBoundaries{1}; % Get n by 2 array of x,y coordinates.
%             x = xy_drawn(:, 2); % Columns.
%             y = xy_drawn(:, 1); % Rows.
%             subplot(2, 2, 1),imshow(Image_to_be_contoured), title('Original image with user marking'); % Plot over original image.
%             hold on; % Don't blow away the image.
%             plot(x, y,'b','LineWidth', 2);
%             drawnow; % Force it to draw immediately.
            %subplot(2,2,2),imshow(coarseContouredI), title('Coarse removal of background')
                %[fineContouredI,xy_drawn]=ImageProcessing(coarseContouredI);
                %% Automatically performing fine contour
                if performFineThresholding==1 || fineContouring_Question==1%"On"
                %imageT=0.12; %maximize before observable background, then iteratively improve between this step and step with imfill 'hole'
                 [,counts]=imhist(coarseContouredIGrey);
                 imageT=otsuthresh(counts);
                 imageBWT=imbinarize(coarseContouredIGrey, imageT);%
                 
                                     %% Shape based filtering  2 + visualization if needed
                        % figure;
                        se=strel('disk',25); %structure filtration based on disk of radius 25 pixels (so smoothens and removes small accidentally contoured sub-structures
                        %larger se, can be too large for objects, hence causing them to disappear
                        %(filled out, smoothened into background)
                        fineContouredI= imopen(imageBWT,se); %fineContouredI= imopen(Ifilled,se); %another morphological operator
                        %(acts on shape of image, takes structuarel element (of your choosing to 
                        %process based on)
                        %It helps smoothen image, less noise in contour (by convoluting with shape
                        %(as long as it fits)
                        
                elseif performFineThresholding==0 || fineContouring_Question==0%"Off"
                imageBWT=coarseContouredIGrey;
                disp('here')
                
            fineContouredI=imageBWT; 
%figure,imshow(imageBWT)
                end
            
%imageBWT=imbinarize(coarseContouredI,'adaptive');%other method if need be
end
%% Images are all fairly similar so a simple standard thresholding would work directly
if Nautomation==0 || CoarseROI_Question==2% "No, thanks" %can directly go to fine thresholding
                %subplot(2,2,1),imshow(Image_to_be_contoured), title('Original image')
                binaryImageDrawn=[];    
                xy_drawn=[];
                coarseContouredI=image_for_reference;   
                coarseContouredIGrey=rgb2gray(image_to_be_contoured);
               % imageBWT=coarseContouredIGrey; 
                %[fineContouredI,xy_drawn]=ImageProcessing(coarseContouredI);
            %% Automatically performing fine contour
            if performFineThresholding==1 || fineContouring_Question==1%"On"
            %imageT=0.12; %maximize before observable background, then iteratively improve between this step and step with imfill 'hole'
             [,counts]=imhist(coarseContouredIGrey);
             imageT=otsuthresh(counts);%implementation of otsu's method of fine contouring in addition 
             imageBWT=imbinarize(coarseContouredIGrey, imageT);%im2bw
             %% Shape based filtering on BW images + visualization if needed +filling gaps
                % figure;
                imageBWT=imfill(imageBWT,'holes');%fills gaps background black, here not necessary 
                % imshow(Ifilled)
                % ti3=['Filled Image: ',char(filenameT)];
                % title(ti3)
                                        %% Shape based filtering  2 + visualization if needed
                        % figure;
                        se=strel('disk',25); %structure filtration based on disk of radius 25 pixels (so smoothens and removes small accidentally contoured sub-structures
                        %larger se, can be too large for objects, hence causing them to disappear
                        %(filled out, smoothened into background)
                        fineContouredI= imopen(imageBWT,se); %fineContouredI= imopen(Ifilled,se); %another morphological operator
                        %(acts on shape of image, takes structuarel element (of your choosing to 
                        %process based on)
                        %It helps smoothen image, less noise in contour (by convoluting with shape
                        %(as long as it fits)
                        
            elseif performFineThresholding==0 || fineContouring_Question==0%"Off"
            imageBWT=coarseContouredIGrey;
                h=msgbox('Please select 5 points representing background',...
                 'Identify background');
                figure, imshow(imageBWT);
                    for n=1:5 %draw 5 points
                      pt=drawpoint();
                        x=round(pt.Position(1));
                        y=round(pt.Position(2));
                      BackgroundIntensity(n)=imageBWT(y,x);
                    end
                  BackgroundIntensityMean=mean(BackgroundIntensity);
            
            %BackgroundIntensity=%max([imageBWT(1,1),imageBWT(end,1),imageBWT(1,end),imageBWT(end,end)])
            imageBWT(imageBWT>BackgroundIntensityMean)=1;
            imageBWT(imageBWT<=BackgroundIntensityMean)=0;
            %ginput and pick points for background?
            fineContouredI=imageBWT; 
            end
            %imageBWT=imbinarize(coarseContouredI,'adaptive');%other method if need be

end



end
