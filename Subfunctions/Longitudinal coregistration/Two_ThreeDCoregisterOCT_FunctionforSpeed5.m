
function [transform2DLateral_OCT_Time0Pre,transform3DLateral_OCT_Time0Pre,R2Dfixed,R3Dfixed,OCTATime0_data2D,Dimensions3DTime0pix]=TwoDCoregisterOCT_FunctionforSpeed4(OCTLateralTimepointCoregistrationFolder,InitialTimepointFile,RawOCTAToCoregister,TryAutomatic,OCTLateralCoregFile,PreviouslyAlignedFound,OptFluSegmentationFolder)%,ProcessingDate)%PredrawnTumourMask,,alignedPredrawn
%TwoDCoregisterOCT_FunctionforSpeed3(OCTLateralTimepointCoregistrationFolder,InitialTimepointFile,OCTA_data2D,TryAutomaticAllignment,OCTLateralCoregFile,OCTA2DPreviouslycoregistered)
fprintf('Aligning selected OCT image to transverse projection of OCTA timepoint 0-.\n')
    %% Loading OCTA data
         RawOCTATime0Temp=matfile(InitialTimepointFile);
         RawOCTATime0Varname=whos('-file',InitialTimepointFile);
            Dimensions3DTime0pix=size(RawOCTATime0Temp.(RawOCTATime0Varname.name));
             OCTATime0_data2D=squeeze(sum(RawOCTATime0Temp.(RawOCTATime0Varname.name),1));%vessels_processed_binary%sv3D_uint16; %shiftdim(raw_data,1); %Adjust the martrix dimensions for easier indexing through slices
            OCTATime0_data2D=OCTATime0_data2D/max(OCTATime0_data2D,[],'all');
            clearvars RawOCTATime0Temp
        
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
        load(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration2DTime0--AffineTransformation.mat'),'transform2DLateral_OCT_Time0Pre','-mat');
        RoughTransform=transform2DLateral_OCT_Time0Pre{1};%loading the previous attempt
    else
     RoughTransform=affine2d(diag(ones(1,3),0));%Initial transform
    end
      while isequal(RightOrientation,'n')|| isequal(RightOrientation,'N')%=='n'
        tempRoughTransformed=imwarp(RawOCTAToCoregister,RoughTransform);
        figure, imshowpair(tempRoughTransformed,OCTATime0_data2D,'montage')
                RightOrientationQ=sprintf('Right orientation? n otherwise type literally anything else or just press enter for yes\n');%,'s'];
                                    RightOrientationA = inputdlg(RightOrientationQ,'Confirm transverse mask alignment');%[1 2; 1 2]
                                        RightOrientation=RightOrientationA{1};%input('Right orientation? n otherwise type literally anything else or just press enter for yes\n','s');
                                     if ~isequal(RightOrientation,'n') && ~isequal(RightOrientation,'N')%RightOrientation~='n' || RightOrientation~='N' %isempty(RightOrientation)
                                                RightOrientation= 'Y';
                                     elseif (isequal(RightOrientation,'n') || isequal(RightOrientation,'N'))% && countReorientationAtmt2>1
                                            figure, imshowpair(RawOCTAToCoregister,OCTATime0_data2D,'montage')
                                            operation=[];
                                             while isempty(operation) || ~(isinteger(int8(operation)) && (0<operation) && (9>operation))
                                               operationQ=sprintf('What operation?\n 1: Rotate Transverse clockwise (-90deg)\n 2: Rotate Transverse counterclockwise (+90deg)\n 3: Rotate Transverse counterclockwise (+180deg)\n 4: Flip up down (reflect across axis 2)\n 5: Flip Left/Right (reflect across axis 3)\n 6: Flip Left/Right and up/down (reflect across axis 3)\n 7: Rotate Transverse counterclockwise (+90deg) then reflect up/down \n 8: Rotate Transverse counterclockwise (+90deg) then reflect left/right');%[%input('What operation?\n 1: Rotate Transverse clockwise (-90deg)\n 2: Rotate Transverse counterclockwise (+90deg)\n 3: Rotate Transverse counterclockwise (+180deg)\n 4: Flip up down (reflect across axis 2)\n 5: Flip Left/Right (reflect across axis 3)\n 6: Flip Left/Right and up/down (reflect across axis 3)') 
                                                    operationA=inputdlg(operationQ,'Operations options for alignment');
                                                    operation=str2double(operationA{1});
                                                 %operation=input('What operation?\n 1: Rotate Transverse clockwise (-90deg)\n 2: Rotate Transverse counterclockwise (+90deg)\n 3: Rotate Transverse counterclockwise (+180deg)\n 4: Flip up down (reflect across axis 2)\n 5: Flip Left/Right (reflect across axis 3)\n 6: Flip Left/Right and up/down (reflect across axis 3)') 
                                                 switch operation
                                                     case 1
                                                        RoughTransform=	affine2d(RotTransform(-90));%affine2d%rigid2d
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
%applying transform
        VeryRoughAlignmentOptFlu=imwarp(RawOCTAToCoregister,RoughTransform);%RoughTransform*RawOCTAToCoregister

%% Align the fluorescence and OCT images
%keyboard
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
    fixed = OCTATime0_data2D;
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
        transform2DIntermediate =imregtform(moving, fixed, 'Rigid', optimizer, metric);%imregtform(moving1, fixed, 'Similarity', optimizer, metric)*tform;%imregister(moving,fixed,'Similarity',optimizer, metric);%'affine'
        R2Dfixed = imref2d(size(fixed));
        registered_coregisteringRef = imwarp(moving,transform2DIntermediate,'OutputView',R2Dfixed);
%     elseif attempt==4
%         moving = rgb2gray(fluorescence_data);
%         registrationEstimator(moving,fixed)
    elseif attempt==2 && PreviouslyAlignedFound%==1--no if exists can take a range of values over or equal to 2%seen first %3
        load(OCTLateralCoregFile,'registered_coregisteringRef','-mat')
        load(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration2DTime0--FOV.mat'),'R2Dfixed','-mat');
        load(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration3DTime0--FOV.mat'),'R3Dfixed','-mat');
        load(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration2DTime0--AffineTransformation.mat'),'transform2DLateral_OCT_Time0Pre','-mat');
        load(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration3DTime0--AffineTransformation.mat'),'transform3DLateral_OCT_Time0Pre','-mat');
        load(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration3DTime0--MovingPoints.mat'),'mp','-mat');
        load(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration3DTime0--FixedPoints.mat'),'fp','-mat');
        if size(mp,1)==3 %from previous mistake of creating 3D control points
            mp=mp(2:3,:)';
        end
        if size(fp,1)==3    
            fp=fp(2:3,:)';
        end
        
        
%         [R,T]=rigid_transform_3D(mp,fp);%find 3D rotation and translation transform to obtain alignment with timepoint 0- (fixed) from current scan (moving) 
%     Testing=1
%     %%
%     if Testing=1;
%     TRNew=affine3d(TRNew=affine3d([ R(5),   0, R(6), 0; ...
%                                        0,   1,    0, 0;...
%                                     R(8),   0, R(9), 0;...
%                                     T(3),   0, T(2), 1]);
%     %%
    elseif attempt>=2  
        [mp,fp] = cpselect(moving,fixed,'Wait',true);% When you are done modifying the control points, export them to the workspace by selecting Export Points to Workspace from the File menu.
%         mp=[ones(length(mp),1),mp]';
%         fp=[ones(length(fp),1),fp]';
        RTS = fitgeotrans(mp,fp,'nonreflectivesimilarity');%no more rescaling but 'Rigid' does not exist%Similarity %'affine'        
        
        R2Dfixed = imref2d(size(fixed));
        R3Dfixed = imref3d(Dimensions3DTime0pix);
        
        %[R,T]=rigid_transform_3D(mp,fp);%find 3D rotation and translation transform to obtain alignment with timepoint 0- (fixed) from current scan (moving) 
        %transform3DIntermediateRigid_temp=[R;T'];
        transform3DIntermediateRigid=affine3d([RTS.T(1),   0, RTS.T(2), 0; ...
                                                      0,   1,        0, 0;...
                                               RTS.T(4),   0, RTS.T(5), 0;...
                                               RTS.T(6),   0, RTS.T(3), 1]);
%         transform3DIntermediateRigid=affine3d([R(5),   0, R(6), 0; ...
%                                                   0,   1,    0, 0;...
%                                                R(8),   0, R(9), 0;...
%                                                T(3),   0, T(2), 1]);% affine3d([transform3DIntermediateRigid_temp,[0 0 0 1]']);
        transform2DIntermediate=RTS;
%                                affine2d([R(5), R(8),0; 
%                                          R(6), R(9),0;
%                                          T(2), T(3),1]);
        registered_coregisteringRef = imwarp(moving,transform2DIntermediate,'OutputView',R2Dfixed);
        
    end
    figure('Units','characters','Position',[10 1 180 100]);
    confirmfig=tiledlayout(6,4);
    nexttile(1,[4,4]),
    imshowpair(fixed,registered_coregisteringRef,'blend')
    %figure('Units','characters','Position',[1 60 120 50]);
    nexttile(17,[2,4])
    imshowpair(fixed,registered_coregisteringRef,'montage')
    
    title(confirmfig,[{'Attempted alignment'}, {'OCT Timepoint - OCT Time0pre'}])
    
    userQ=sprintf('Alignment ok (y/n)?');
                                    userA = inputdlg(userQ,'Confirm quality of created transverse tumour mask');%[1 2; 1 2]
                                        user=userA{1};%input('Right orie
    %user = input('Alignment ok (y/n)?','s');
    
    
    end
    saveas(gcf,fullfile(OCTLateralTimepointCoregistrationFolder,'CoregistrationOfOCTtoTime0-.png'))
    %OCTA3D=imwarp(imwarp(,transform3DLateral{1}),transform3DLateral{2},'OutputView',R3Dfixed);
    %figure, imagesc(squeeze(sum(OCTA3D,1)))
    
    
    
    if ~(attempt==2 && PreviouslyAlignedFound)
        transform2DLateral_OCT_Time0Pre{1}=RoughTransform;
        transform2DLateral_OCT_Time0Pre{2}=transform2DIntermediate;%affine2d(transform2DIntermediate.T*RoughTransform.T);%NO Issue is First transform was a similarity transform and  this was
        transform3DLateral_OCT_Time0Pre{1}=affine3d([RoughTransform.T(1),   0, RoughTransform.T(2), 0; ...
                                                                       0,   1,                   0, 0;...
                                                     RoughTransform.T(4),   0, RoughTransform.T(5), 0;...
                                                                       0,   0,                   0, 1]);
                                                    
%%
%% when squishing along z, it is as though 90deg rotation of image performed, so rotation matrix 2D is transposed for 3D equivalent and also made to be rotating around y-axis(except translations always at bottom
%%
        transform3DLateral_OCT_Time0Pre{2}=transform3DIntermediateRigid;                                                           
    end
  %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% To Do in later versions 
        % Remove the scaling matrix from the full affine transform matrix:
        % Ideas: 1) applying imperfect decomposition as outlined here: 
        % http://callumhay.blogspot.com/2010/10/decomposing-affine-transforms.html
        % or https://itk.org/pipermail/insight-users/2006-August/019025.html
        % All from https://stackoverflow.com/questions/10546320/remove-rotation-from-a-4x4-homogeneous-transformation-matrix
        % or 2) Given the area of the tumour mask pre-transform and post-transform (length and width) scale down the affine transform matrix to remove the scaling effect. 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%
        %% Load Tumour mask without affine trasnform to isolate effect of rescaling --not yet implemented for now will use 
        load(fullfile(OptFluSegmentationFolder,['Mask2DPreCoregTime0-ForScaling.mat']))
            TumourMask2DPreCoregTime0_roughAlignment=imwarp(TumourMask2DPreCoregTime0,transform2DLateral_OCT_Time0Pre{1});
            IM_pre=bwlabel(TumourMask2DPreCoregTime0_roughAlignment, 8);%labels Black and White image, via 8 level connectivity (or level connectivity (which adjacent pixels considered neighbours--> are the directly diagonal pixels also considered part of the same object?--then 8)
                stats_pre=regionprops(IM_pre,'MajorAxisLength','MinorAxisLength',...
                 'Area','BoundingBox');%extracting properties for all identified objects
                save(fullfile(OptFluSegmentationFolder,'Dims_MaskPreCoregTime0-ForScaling.mat'),'stats_pre','-v7.3')
                save(fullfile(OptFluSegmentationFolder,['Mask2DPreCoregTime0_roughAl-ForScaling.mat']),'TumourMask2DPreCoregTime0_roughAlignment','-v7.3')
%             L_pre=[stats_pre.MajorAxisLength];
%             W_pre=[stats_pre.MinorAxisLength];
%             area_pre=[stats_pre.Area];
        followOutput = affineOutputView(size(TumourMask2DPreCoregTime0),transform2DLateral_OCT_Time0Pre{2},'BoundsStyle','FollowOutput');
        TumourMask2DPostCoregTime0=imwarp(imwarp(TumourMask2DPreCoregTime0,transform2DLateral_OCT_Time0Pre{1}),transform2DLateral_OCT_Time0Pre{2},'OutputView',followOutput);
            IM_post=bwlabel(TumourMask2DPostCoregTime0, 8);%labels Black and White image, via 8 level connectivity (or level connectivity (which adjacent pixels considered neighbours--> are the directly diagonal pixels also considered part of the same object?--then 8)
                stats_post=regionprops(IM_post,'MajorAxisLength','MinorAxisLength',...
                 'Area','BoundingBox');%extracting properties for all identified objects
                save(fullfile(OptFluSegmentationFolder,'Dims_MaskPostCoregTime0-ForScaling.mat'),'stats_post','-v7.3')
                save(fullfile(OptFluSegmentationFolder,['Mask2DPostCoregTime0-ForScaling.mat']),'TumourMask2DPostCoregTime0','-v7.3')
            
        save(OCTLateralCoregFile,'registered_coregisteringRef','-mat')
        save(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration2DTime0--FOV.mat'),'R2Dfixed','-mat');
        save(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration3DTime0--FOV.mat'),'R3Dfixed','-mat')
    if attempt<=1%2
        save(fullfile(OCTLateralTimepointCoregistrationFolder,'AutomaticRegistration2DTime0--optimizerSettings.mat'),'optimizer','-mat')
        save(fullfile(OCTLateralTimepointCoregistrationFolder,'AutomaticRegistration2DTime0--metricSettings.mat'),'transform2DLateral_OCT_Time0Pre','-mat');
        OldCorregistrationIsGood=0;
    elseif attempt==2 && PreviouslyAlignedFound==1
        OldCorregistrationIsGood=1;
    elseif attempt>=2%3    
        save(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration2DTime0--AffineTransformation.mat'),'transform2DLateral_OCT_Time0Pre','-mat');
        save(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration3DTime0--AffineTransformation.mat'),'transform3DLateral_OCT_Time0Pre','-mat');
        save(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration3DTime0--MovingPoints.mat'),'mp','-mat');
        save(fullfile(OCTLateralTimepointCoregistrationFolder,'ManualRegistration3DTime0--FixedPoints.mat'),'fp','-mat');
        OldCorregistrationIsGood=0;
    end
    close all
end