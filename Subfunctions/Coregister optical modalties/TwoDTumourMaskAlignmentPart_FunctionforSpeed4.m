
function [transform2D_OptFlu_OCT,Rfixed,CorregistrationIsGood]=TwoDTumourMaskAlignmentPart_FunctionforSpeed4(TumourMaskAndMetricsDir,OCTA_data2D,CoregisteringFile,TryAutomatic,PreviouslyAlignedFound)%,ProcessingDate)%PredrawnTumourMask,,alignedPredrawn
fprintf('Aligning selected brightfield/fluorescence image to transverse projection of svOCT.\n')
%%By Nader A.
    %% Loading OCTA data
%          RawOCTA=load(RawOCTAFile);
%          RawOCTAVarname=whos('-file',RawOCTAFile);
%              OCTA_data2D=squeeze(sum(RawOCTA.(RawOCTAVarname.name),1));%vessels_processed_binary%sv3D_uint16; %shiftdim(raw_data,1); %Adjust the martrix dimensions for easier indexing through slices
%             OCTA_data2D=OCTA_data2D/max(OCTA_data2D,[],'all');
%              [xOCT,yOCT]=size(OCTA_data2D);
%              clearvars RawOCTA
    %% Loading brightfield or fluorescence
    originalOptFlu=imread(CoregisteringFile);%imread(fullfile(pathFlu,filenameFlu));
    %% potential rough transforms
    RotTransform=@(th) [cosd(th) -sind(th) 0;
                        sind(th)  cosd(th) 0;
                           0          0    1];
    RefTransform=@(th) [cosd(2*th)  sind(2*th) 0;
                        sind(2*th) -cosd(2*th) 0;
                           0          0        1];  
    %% Rough alignment
     RightOrientation= 'n';
    if PreviouslyAlignedFound
        load(fullfile(TumourMaskAndMetricsDir,'ManualRegistration2D-AffineTransformation.mat'),'transform2D_OptFlu_OCT','-mat');
        RoughTransform=transform2D_OptFlu_OCT{1};%loading the previous attempt
    else 
     RoughTransform=affine2d(diag(ones(1,3),0));%Initial transform
    end
      while isequal(RightOrientation,'n')|| isequal(RightOrientation,'N')%=='n'
        tempRoughTransformed=imwarp(originalOptFlu,RoughTransform);
        figure, imshowpair(tempRoughTransformed,OCTA_data2D,'montage')
                RightOrientationQ=sprintf('Right orientation? n otherwise type literally anything else or just press enter for yes\n');%,'s'];
                                    RightOrientationA = inputdlg(RightOrientationQ,'Confirm transverse mask alignment');%[1 2; 1 2]
                                        RightOrientation=RightOrientationA{1};%input('Right orientation? n otherwise type literally anything else or just press enter for yes\n','s');
                                     if ~isequal(RightOrientation,'n') && ~isequal(RightOrientation,'N')%RightOrientation~='n' || RightOrientation~='N' %isempty(RightOrientation)
                                                RightOrientation= 'Y';
                                     elseif (isequal(RightOrientation,'n') || isequal(RightOrientation,'N'))% && countReorientationAtmt2>1
                                            figure, imshowpair(originalOptFlu,OCTA_data2D,'montage')
                                            operation=[];
                                             while isempty(operation) || ~(isinteger(int8(operation)) && (0<operation) && (9>operation))
                                               operationQ=sprintf('What operation?\n 1: Rotate Transverse clockwise (-90deg)\n 2: Rotate Transverse counterclockwise (+90deg)\n 3: Rotate Transverse counterclockwise (+180deg)\n 4: Flip up down (reflect across axis 2)\n 5: Flip Left/Right (reflect across axis 3)\n 6: Flip Left/Right and up/down (reflect across axis 3)\n 7: Rotate Transverse counterclockwise (+90deg) then reflect up/down \n 8: Rotate Transverse counterclockwise (+90deg) then reflect left/right');%[%input('What operation?\n 1: Rotate Transverse clockwise (-90deg)\n 2: Rotate Transverse counterclockwise (+90deg)\n 3: Rotate Transverse counterclockwise (+180deg)\n 4: Flip up down (reflect across axis 2)\n 5: Flip Left/Right (reflect across axis 3)\n 6: Flip Left/Right and up/down (reflect across axis 3)') 
                                                    operationA=inputdlg(operationQ,'Operations options for alignment');
                                                    operation=str2double(operationA{1});
                                                 %operation=input('What operation?\n 1: Rotate Transverse clockwise (-90deg)\n 2: Rotate Transverse counterclockwise (+90deg)\n 3: Rotate Transverse counterclockwise (+180deg)\n 4: Flip up down (reflect across axis 2)\n 5: Flip Left/Right (reflect across axis 3)\n 6: Flip Left/Right and up/down (reflect across axis 3)') 
                                                 switch operation
                                                     case 1
                                                        RoughTransform=affine2d(RotTransform(-90));
                                                         %sv3D_uint16=imrotate3(sv3D_uint16,-90,[0,1,0],'nearest','loose','FillValues',0);%imrotate3(,-90,[0,1,0],'nearest','loose','FillValues',0);%flip(sv3D_uint16,2);%imrotate3(flip(flip(sv3D_uint16,2),3),90,[0,1,0],'nearest','loose','FillValues',0);%imrotate3(,-90,[0,1,0],'nearest','loose','FillValues',0);%since flipped during processing %Rotating vessels for visualization (not used later on) just for ease instread of rotating structural and segmented now (mask rotated later on during interpolation)                     
                                                     case 2
                                                        RoughTransform=affine2d(RotTransform(90)); 
                                                     case 3
                                                        RoughTransform=affine2d(RotTransform(180));
                                                     case 4
                                                        RoughTransform=affine2d(RefTransform(0));%Ref up/down
                                                     case 5
                                                        RoughTransform=affine2d(RefTransform(90));%Ref left/right
                                                     case 6
                                                        RoughTransform=affine2d(RefTransform(90)*RefTransform(0));%Ref both
                                                     case 7
                                                        RoughTransform=affine2d(RotTransform(90)*RefTransform(0));%Rotate 90deg then Ref up/down
                                                     case 8
                                                        RoughTransform=affine2d(RotTransform(90)*RefTransform(90));%Rotate 90deg then Ref left/right
                                                 end
                                             end
                                     end
                                     close all;
      end
%         Rot90Transform=[0 1 0;
%                         -1  0 0;
%                         0  0 1];
%         lrReflTransform=[-1 0 0;
%                           0 1 0;
%                           0 0 1];
%         RoughTransform=affine2d(lrReflTransform*RescalelTransform*Rot90Transform);
        
% %         xOF=size(originalOptFlu,2);
% %             vx=xOF\xOCT;
% %         yOF=size(originalOptFlu,1);
% %             vy=yOF\yOCT;
% %         RescalelTransform=[vx 0 0;
% %                            0 vy 0;
% %                            0  0 1]
%         lrReflTransform=[-1 0 0;
%                           0 1 0;
%                           0 0 1];
%         RoughTransform=affine2d(lrReflTransform*RescalelTransform*Rot90Transform);
        %RoughTransform=affine2d(lrReflTransform*Rot90Transform);
        VeryRoughAlignmentOptFlu=imwarp(originalOptFlu,RoughTransform);
%         VeryRoughAlignmentOptFlu=fliplr(imrotate(imresize(originalOptFlu,size(svOCT_data2D)),90));%Since y axis different from svOCT
%         %Detect and extract features from the original and the transformed images.
%             ptsOriginal  = detectSURFFeatures(originalOptFlu);
%             ptsDistorted = detectSURFFeatures(VeryRoughAlignmentOptFlu);
%             [featuresOriginal,validPtsOriginal] = extractFeatures(originalOptFlu,ptsOriginal);
%             [featuresDistorted,validPtsDistorted] = extractFeatures(VeryRoughAlignmentOptFlu,ptsDistorted);
%         %Match and display features between the images.
%             index_pairs = matchFeatures(featuresOriginal,featuresDistorted);
%             matchedPtsOriginal  = validPtsOriginal(index_pairs(:,1));
%             matchedPtsDistorted = validPtsDistorted(index_pairs(:,2));
%             figure 
%             showMatchedFeatures(originalOptFlu,VeryRoughAlignmentOptFlu,matchedPtsOriginal,matchedPtsDistorted)
%             title('Matched SURF Points With Outliers');
%         %Exclude the outliers, estimate the transformation matrix, and display the results.
%             [tform,inlierIdx] = estimateGeometricTransform2D(matchedPtsDistorted,matchedPtsOriginal,'similarity');
%             inlierPtsDistorted = matchedPtsDistorted(inlierIdx,:);
%             inlierPtsOriginal  = matchedPtsOriginal(inlierIdx,:);
%             figure 
%             showMatchedFeatures(originalOptFlu,VeryRoughAlignmentOptFlu,inlierPtsOriginal,inlierPtsDistorted)
%             title('Matched Inlier Points')
%         %Use the estimated transformation to recover and display the original image from the distorted image (confirming transform.
%             outputView = imref2d(size(originalOptFlu));
%             Ir = imwarp(VeryRoughAlignmentOptFlu,tform,'OutputView',outputView);
%             figure 
%             imshow(Ir); 
%             title('Recovered Image');
        %         if ProcessingDate=='Valentin_older_with_rotation'
%             fluorescence_data=flip(rot90(fluorescence_data,1),2);
%         end
    %fluorescence_data=fluorescence_dataTemp.flu;
%         if PredrawnTumourMask==1
%             load(BatchOfFolders{folderIndx,3});%OCTFile%fullfile(path2DMask,filename2DMask))
%         end
% if PredrawnTumourMask==1 && alignedPredrawn==1
%     %%no need to align and drawn 2D fluorescence mask        
% else
%% Align the fluorescence and OCT images

    user='n';   
    attempt=0;
    if TryAutomatic==0
        attempt=attempt+1;%skip automatic attempt
    end
    while user~='y'
        attempt=attempt+1;
    %while loop to make this faster
    close all
    
    moving = VeryRoughAlignmentOptFlu;
    fixed = OCTA_data2D;
    if attempt<=1%2
        moving = rgb2gray(VeryRoughAlignmentOptFlu);
          
%         tform = imregcorr(moving,fixed);
%         moving1=imwarp(moving1,tform);
        [optimizer, metric]=imregconfig('Multimodal');
        if attempt==1 %skipped if no automatic
            optimizer.MaximumIterations = 1000; %More likely to converge if higher than 100 (default)
                optimizer.GrowthFactor=1.0005; %rate at which search radius grows (smaller than 1.05 (default) will lead to higher accuracy
                optimizer.InitialRadius = 1e-9; %initial search radius size (smaller than 6.25e-3 (default) may lead to higher accuracy
        end
%             if attempt==2% || attempt==3 
%                 %keyboard %user input
%                 optimizer.MaximumIterations = 1000; %More likely to converge if higher than 100 (default)
%                 optimizer.GrowthFactor=1.005; %rate at which search radius grows (smaller than 1.05 (default) will lead to higher accuracy
%                 optimizer.InitialRadius = 1e-9; %initial search radius size (smaller than 6.25e-3 (default) may lead to higher accuracy
%             end
        transform2DIntermediate =imregtform(moving, fixed, 'Similarity', optimizer, metric);%imregtform(moving1, fixed, 'Similarity', optimizer, metric)*tform;%imregister(moving,fixed,'Similarity',optimizer, metric);%'affine'
        Rfixed = imref2d(size(fixed));
        registered_coregisteringRef = imwarp(moving,transform2DIntermediate,'OutputView',Rfixed);
%     elseif attempt==4
%         moving = rgb2gray(fluorescence_data);
%         registrationEstimator(moving,fixed)
    elseif attempt==2 && PreviouslyAlignedFound%==1--no if exists can take a range of values over or equal to 2%seen first %3
        load(fullfile(TumourMaskAndMetricsDir,'registered_fluorescence_Brightfield_toOCT.mat'),'registered_coregisteringRef','-mat')
        load(fullfile(TumourMaskAndMetricsDir,'ManualRegistration2D-FOV.mat'),'Rfixed','-mat');
        load(fullfile(TumourMaskAndMetricsDir,'ManualRegistration2D-AffineTransformation.mat'),'transform2D_OptFlu_OCT','-mat');
        load(fullfile(TumourMaskAndMetricsDir,'ManualRegistration2D-MovingPoints.mat'),'mp','-mat');
        load(fullfile(TumourMaskAndMetricsDir,'ManualRegistration2D-FixedPoints.mat'),'fp','-mat');
    elseif attempt>=2  
        [mp,fp] = cpselect(moving,fixed,'Wait',true);% When you are done modifying the control points, export them to the workspace by selecting Export Points to Workspace from the File menu.
        transform2DIntermediate = fitgeotrans(mp,fp,'Similarity');%'affine'
        Rfixed = imref2d(size(fixed));
        registered_coregisteringRef = imwarp(moving,transform2DIntermediate,'OutputView',Rfixed);
    end
    figure('Units','characters','Position',[10 1 180 100]);
    confirmfig=tiledlayout(6,4);
    nexttile(1,[4,4]),
    imshowpair(fixed,registered_coregisteringRef,'blend')
    %figure('Units','characters','Position',[1 60 120 50]);
    nexttile(17,[2,4])
    imshowpair(fixed,registered_coregisteringRef,'montage')
    
    title(confirmfig,[{'Attempted alignment'}, {'brightfield/epifluorescence - OCT'}])
    
    userQ=sprintf('Alignment ok (y/n)?');
                                    userA = inputdlg(userQ,'Confirm quality of created transverse tumour mask');%[1 2; 1 2]
                                        user=userA{1};%input('Right orie
    %user = input('Alignment ok (y/n)?','s');
    
    
    end
    saveas(gcf,fullfile(TumourMaskAndMetricsDir,'CoregistrationOfOpticalModalitiesOptFluOCT.png'))
    
        CorregistrationIsGood=1;
        
    if ~(attempt==2 && PreviouslyAlignedFound)
        transform2D_OptFlu_OCT{1}=RoughTransform;
        transform2D_OptFlu_OCT{2}=transform2DIntermediate;%affine2d(transform2DIntermediate.T*RoughTransform.T);%NO Issue is First transform was a similarity transform and  this was
    end
%     save(fullfile(NewFolder,'registered_fluorescence_Brightfield_toOCT.mat'),'registered_fluorescence','-mat')
%     save(fullfile(NewFolder,'AffineTransformation.mat'),'t','-mat');
%     save(fullfile(NewFolder,'MovingPoints.mat'),'mp','-mat');
%     save(fullfile(NewFolder,'FixedPoints.mat'),'fp','-mat');
        save(fullfile(TumourMaskAndMetricsDir,'registered_fluorescence_Brightfield_toOCT.mat'),'registered_coregisteringRef','-mat')
        save(fullfile(TumourMaskAndMetricsDir,'ManualRegistration2D-FOV.mat'),'Rfixed','-mat');
    if attempt<=1%2
        save(fullfile(TumourMaskAndMetricsDir,'AutomaticRegistration2D-optimizerSettings.mat'),'optimizer','-mat')
        save(fullfile(TumourMaskAndMetricsDir,'AutomaticRegistration2D-metricSettings.mat'),'transform2D_OptFlu_OCT','-mat');
    elseif attempt==2 && PreviouslyAlignedFound==1
        %old was ok
    elseif attempt>=2%3    
        save(fullfile(TumourMaskAndMetricsDir,'ManualRegistration2D-AffineTransformation.mat'),'transform2D_OptFlu_OCT','-mat');
        save(fullfile(TumourMaskAndMetricsDir,'ManualRegistration2D-MovingPoints.mat'),'mp','-mat');
        save(fullfile(TumourMaskAndMetricsDir,'ManualRegistration2D-FixedPoints.mat'),'fp','-mat');
    end
    close all
% %% Contour the tumor in the flourescence image 
% % Place contour drawn from fluorescence onto OCT Speckle variance map
% if PredrawnTumourMask==1   
%     tumor_maskUnregistered=fineContouredI; % loaded above
%     tumor_mask2D=imwarp(tumor_maskUnregistered,t,'OutputView',Rfixed);
% %     tumor_mask = rot90(flip(tumor_mask)); %Change the mask dimensions to be in the same orientation as the original raw data
%     
%     figure,imshowpair(registered_fluorescence,tumor_mask2D,'Montage')
%     keyboard
%     close all
% else
%     for step = 2
%         figure (1)
%         imshow(registered_fluorescence)
%         %imshow(OCT_data_2D) 
%         title('Contour the tumor')
%         user_roi = drawassisted;
%         tumor_mask2D = createMask(user_roi);
%         keyboard
%             close all
%     end
% end
end