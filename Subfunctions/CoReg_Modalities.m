
function [transform2D_Coregistration,Rfixed,CorregistrationIsGood]=CoReg_Modalities(DirectoryCoregistrationData,ImageFixed,ImageToBeCoregistered,TryAutomatic,PreviouslyAlignedFound)%,ProcessingDate)%PredrawnTumourMask,,alignedPredrawn
if modalitySet==1
    fprintf(['Aligning selected brightfield/fluorescence image to transverse projection of OCTA.\n'])%fprintf(['Aligning selected %s to tansverse projection of OCTA.\n'])%brightfield/fluorescence image to transverse projection of svOCT.\n'])
    CODE_Coreg='BF-OCT';
elseif modalitySet==2
    fprintf(['Aligning selected MRI scan sagittal slice projection to raw brightfield/fluorescence image.\n'])
    CODE_Coreg='MRI-BF';
elseif modalitySet==3
    fprintf(['Aligning selected CT scan transverse projection to raw brightfield/fluorescence image.\n'])
    CODE_Coreg='CT-BF';
end
%%By Nader A.
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
        load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-AffineTransformation_%s.mat',CODE_Coreg)),'transform2D_Coregistration','-mat');

        RoughTransform=transform2D_Coregistration{1};%loading the previous attempt
    else 
     RoughTransform=affine2d(diag(ones(1,3),0));%Initial transform
    end
      while isequal(RightOrientation,'n')|| isequal(RightOrientation,'N')%=='n'
        tempRoughTransformed=imwarp(ImageToBeCoregistered,RoughTransform);
        figure, imshowpair(tempRoughTransformed,ImageFixed,'montage')
                RightOrientationQ=sprintf('Right orientation? n otherwise type literally anything else or just press enter for yes\n');%,'s'];
                                    RightOrientationA = inputdlg(RightOrientationQ,'Confirm transverse mask alignment');%[1 2; 1 2]
                                        RightOrientation=RightOrientationA{1};%input('Right orientation? n otherwise type literally anything else or just press enter for yes\n','s');
                                     if ~isequal(RightOrientation,'n') && ~isequal(RightOrientation,'N')%RightOrientation~='n' || RightOrientation~='N' %isempty(RightOrientation)
                                                RightOrientation= 'Y';
                                     elseif (isequal(RightOrientation,'n') || isequal(RightOrientation,'N'))% && countReorientationAtmt2>1
                                            figure, imshowpair(ImageToBeCoregistered,ImageFixed,'montage')
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

      VeryRoughAlignedImg=imwarp(ImageToBeCoregistered,RoughTransform);
    
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
    
    moving = VeryRoughAlignedImg;
    fixed = ImageFixed;
    if attempt<=1%2
        moving = rgb2gray(VeryRoughAlignedImg);
          
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
        load(fullfile(DirectoryCoregistrationData,sprintf('registered_%s.mat',CODE_Coreg)),'registered_coregisteringRef','-mat')
        load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-FOV_%s.mat',CODE_Coreg)),'Rfixed','-mat');
        load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-AffineTransformation_%s.mat',CODE_Coreg)),'transform2D_Coregistration','-mat');
        load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-MovingPoints_%s.mat',CODE_Coreg)),'mp','-mat');
        load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-FixedPoints_%s.mat',CODE_Coreg)),'fp','-mat');
%         elseif modalitySet==2
%             load(fullfile(DirectoryCoregistrationData,'registered_MRI-BF.mat'),'registered_coregisteringRef','-mat')
%             load(fullfile(DirectoryCoregistrationData,'ManualRegistration2D-FOV_MRI-BF.mat'),'Rfixed','-mat');
%             load(fullfile(DirectoryCoregistrationData,'ManualRegistration2D-AffineTransformation_MRI-BF.mat'),'transform2D_Coregistration','-mat');
%             load(fullfile(DirectoryCoregistrationData,'ManualRegistration2D-MovingPoints_MRI-BF.mat'),'mp','-mat');
%             load(fullfile(DirectoryCoregistrationData,'ManualRegistration2D-FixedPoints_MRI-BF.mat'),'fp','-mat'); 
%         elseif modalitySet==3
%             load(fullfile(DirectoryCoregistrationData,'registered_CT-BF.mat'),'registered_coregisteringRef','-mat')
%             load(fullfile(DirectoryCoregistrationData,'ManualRegistration2D-FOV_CT-BF.mat'),'Rfixed','-mat');
%             load(fullfile(DirectoryCoregistrationData,'ManualRegistration2D-AffineTransformation_CT-BF.mat'),'transform2D_Coregistration','-mat');
%             load(fullfile(DirectoryCoregistrationData,'ManualRegistration2D-MovingPoints_CT-BF.mat'),'mp','-mat');
%             load(fullfile(DirectoryCoregistrationData,'ManualRegistration2D-FixedPoints_CT-BF.mat'),'fp','-mat'); 
%         end
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
    if modalitySet==1
        title(confirmfig,[{'Attempted alignment'}, {'brightfield/epifluorescence - OCT'}])
    elseif modalitySet==2
        title(confirmfig,[{'Attempted alignment'}, {'MRI - brightfield/epifluorescence '}])
    elseif modalitySet==3
        title(confirmfig,[{'Attempted alignment'}, {'CT - brightfield/epifluorescence '}])
    end
    
    userQ=sprintf('Alignment ok (y/n)?');
                                    userA = inputdlg(userQ,'Confirm quality of created transverse tumour mask');%[1 2; 1 2]
                                        user=userA{1};%input('Right orie
    %user = input('Alignment ok (y/n)?','s');
    
    
    end
        saveas(gcf,fullfile(DirectoryCoregistrationData,sprintf('CoregistrationOfOpticalModalities_%s.png',CODE_Coreg))
        CorregistrationIsGood=1;
        
    if ~(attempt==2 && PreviouslyAlignedFound)
        transform2D_Coregistration{1}=RoughTransform;
        transform2D_Coregistration{2}=transform2DIntermediate;%affine2d(transform2DIntermediate.T*RoughTransform.T);%NO Issue is First transform was a similarity transform and  this was
    end
%     save(fullfile(NewFolder,'registered_fluorescence_Brightfield_toOCT.mat'),'registered_fluorescence','-mat')
%     save(fullfile(NewFolder,'AffineTransformation.mat'),'t','-mat');
%     save(fullfile(NewFolder,'MovingPoints.mat'),'mp','-mat');
%     save(fullfile(NewFolder,'FixedPoints.mat'),'fp','-mat');
            save(fullfile(DirectoryCoregistrationData,sprintf('registered_%s.mat',CODE_Coreg)),'registered_coregisteringRef','-mat')%fluorescence_Brightfield_toOCT
            save(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-FOV_%s.mat',CODE_Coreg)),'Rfixed','-mat');
        
    if attempt<=1%2
        save(fullfile(DirectoryCoregistrationData,sprintf('AutomaticRegistration2D-optimizerSettings_%s.mat',CODE_Coreg)),'optimizer','-mat')
        save(fullfile(DirectoryCoregistrationData,sprintf('AutomaticRegistration2D-metricSettings_%s.mat',CODE_Coreg)),'transform2D_Coregistration','-mat');
    elseif attempt==2 && PreviouslyAlignedFound==1
        %old was ok
    elseif attempt>=2%3    
        save(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-AffineTransformation_%s.mat',CODE_Coreg)),'transform2D_Coregistration','-mat');
        save(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-MovingPoints_%s.mat',CODE_Coreg)),'mp','-mat');
        save(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-FixedPoints_%s.mat',CODE_Coreg)),'fp','-mat');
    end
    close all
end
