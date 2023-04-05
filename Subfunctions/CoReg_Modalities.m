
function [transform2D_Coregistration,Rfixed,CorregistrationIsGood]=CoReg_Modalities(CODE_Coreg,DirectoryCoregistrationData,ImageFixed,ImageToBeCoregistered,TryAutomatic,PreviouslyAlignedFound,warpType,AddedTransformInput)%,ProcessingDate)%PredrawnTumourMask,,alignedPredrawn
if isequal(CODE_Coreg,'BF-OCT')
    fprintf(['Aligning selected brightfield/fluorescence image to transverse projection of OCTA.\n'])%fprintf(['Aligning selected %s to tansverse projection of OCTA.\n'])%brightfield/fluorescence image to transverse projection of svOCT.\n'])
elseif isequal(CODE_Coreg,'MRI-BF')
    fprintf(['Aligning selected MRI scan sagittal slice projection to raw brightfield/fluorescence image.\n'])
elseif isequal(CODE_Coreg,'CT-BF')
    fprintf(['Aligning selected CT scan transverse projection to raw brightfield/fluorescence image.\n'])
end
switch warpType
    case 1
        TransType="similarity";%TransType not used just for reference
    case 2
        TransType="reflectivesimilarity";
    case 3
        TransType="affine";
    case 4
        TransType="projective";	
    case 5
        TransType="polynomial";
        degree=AddedTransformInput;
    case 6
        TransType="pwl";
    case 7
        TransType="lwm";
        NumPtPairsInWeiMeanSet=AddedTransformInput;
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
     if ~exist(DirectoryCoregistrationData,'dir')
         mkdir(DirectoryCoregistrationData);
     end
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
                opts.WindowStyle = 'normal';
                                    RightOrientationA = inputdlg(RightOrientationQ,'Confirm coarse alignment of images',1,{''},opts);%[1 2; 1 2]
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
    
%% Align the moving image to the fixed image

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
    elseif attempt==2 && warpType~=0 && PreviouslyAlignedFound%==1--no if exists can take a range of values over or equal to 2%seen first %3
        load(fullfile(DirectoryCoregistrationData,sprintf('registered_%s.mat',CODE_Coreg)),'registered_coregisteringRef','-mat')
        load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-FOV_%s.mat',CODE_Coreg)),'Rfixed','-mat');
        load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-AffineTransformation_%s.mat',CODE_Coreg)),'transform2D_Coregistration','-mat');
        load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-MovingPoints_%s.mat',CODE_Coreg)),'mp','-mat');
        load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-FixedPoints_%s.mat',CODE_Coreg)),'fp','-mat');
    elseif attempt>=2 || warpType==0
        if exist(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-MovingPoints_%s.mat',CODE_Coreg)),'file') % in case from older version or accidentally only mp and fp saved.
            load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-MovingPoints_%s.mat',CODE_Coreg)),'mp','-mat');
            load(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-FixedPoints_%s.mat',CODE_Coreg)),'fp','-mat');
            mpPrev=mp;
            fpPrev=fp;
%             cpstructOld.inputPoints= fp;
%             cpstructOld.basePoints= mp;
%             cpstructOld.inputBasePairs=repmat((1:size(mp,1))', [1,2]);
%             cpstructOld.ids=(1:size(mp,1))';
%             cpstructOld.inputIdPairs=repmat((1:size(mp,1))', [1,2]);
%             cpstructOld.baseIdPairs=repmat((1:size(mp,1))', [1,2]);
%             cpstructOld.isInputPredicted= zeros(size(mp,1),1);
%             cpstructOld.isBasePredicted= zeros(size(mp,1),1);

%             save(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-ContPtSelSes_%s.mat',CODE_Coreg)),'cpstructOld','-mat');
            
            [mp,fp] = cpselect(moving,fixed,mpPrev,fp,'Wait',true);% When you are done modifying the control points, export them to the workspace by selecting Export Points to Workspace from the File menu.
                save(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-MovingPoints_%s.mat',CODE_Coreg)),'mp','-mat');
                save(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-FixedPoints_%s.mat',CODE_Coreg)),'fp','-mat');            
        else
            [mp,fp] = cpselect(moving,fixed,'Wait',true);% When you are done modifying the control points, export them to the workspace by selecting Export Points to Workspace from the File menu.
        end
        
%         if isequal(CODE_Coreg,'BF-OCT')
            if warpType==0
                transform2DIntermediateTemp{1} = fitgeotrans(mp,fp,'similarity');
                    title1='1) similarity';
                transform2DIntermediateTemp{2} = fitgeotrans(mp,fp,'nonreflectivesimilarity');
                    title2='2) nonreflectivesimilarity';
                transform2DIntermediateTemp{3} = fitgeotrans(mp,fp,'affine');
                    title3='3) affine';
                transform2DIntermediateTemp{4} = fitgeotrans(mp,fp,'projective');
                    title4='4) projective';
                transform2DIntermediateTemp{5} = fitgeotrans(mp,fp,'polynomial',2);
                    title5='5) polynomial2';
                transform2DIntermediateTemp{6} = fitgeotrans(mp,fp,'polynomial',3);
                    title6='6) polynomial3';
                transform2DIntermediateTemp{7} = fitgeotrans(mp,fp,'polynomial',4);
                    title7='7) polynomial4';
                try
                    ErrorCaught=0;
                    transform2DIntermediateTemp{8} = fitgeotrans(mp,fp,'pwl');
                    title8='8) pwl';
                catch
                    ErrorCaught=1;
                    NumPtPairsInWeiMeanQ2=sprintf('Sorry pwl does not work here, number of control pts considered in lwm? >=6');
                    opts.WindowStyle = 'normal';
                        NumPtPairsInWeiMeanA2 = inputdlg(NumPtPairsInWeiMeanQ2,'Choosing geometric transform',1,{''},opts);%[1 2; 1 2]
                            NumPtPairsInWeiMean5=str2num(NumPtPairsInWeiMeanA2{1});
                    transform2DIntermediateTemp{8} = fitgeotrans(mp,fp,'lwm',NumPtPairsInWeiMean5);%36
                    title8=sprintf('8) lwm%d',NumPtPairsInWeiMean5);
                end
                NumPtPairsInWeiMean1=6;
                transform2DIntermediateTemp{9} = fitgeotrans(mp,fp,'lwm',6);
                    title9='9) lwm6';
                NumPtPairsInWeiMean2=12;
                transform2DIntermediateTemp{10}= fitgeotrans(mp,fp,'lwm',12);
                    title10='10) lwm12';
                NumPtPairsInWeiMean3=18;
                transform2DIntermediateTemp{11}= fitgeotrans(mp,fp,'lwm',18);
                    title11='11) lwm18';
                NumPtPairsInWeiMeanQ1=sprintf('Number of control pts considered in lwm? >=6');
                    opts.WindowStyle = 'normal';
                        NumPtPairsInWeiMeanA1 = inputdlg(NumPtPairsInWeiMeanQ1,'Choosing geometric transform',1,{''},opts);%[1 2; 1 2]
                            NumPtPairsInWeiMean4=str2num(NumPtPairsInWeiMeanA1{1});
                    transform2DIntermediateTemp{12} = fitgeotrans(mp,fp,'lwm',NumPtPairsInWeiMean4);%36
                    title12=sprintf('12) lwm%d',NumPtPairsInWeiMean4);
            elseif warpType==1
                transform2DIntermediate= fitgeotrans(mp,fp,'similarity');
            elseif warpType==2
                transform2DIntermediate= fitgeotrans(mp,fp,'nonreflectivesimilarity');
            elseif warpType==3
                transform2DIntermediate= fitgeotrans(mp,fp,'affine');
            elseif warpType==4
                transform2DIntermediate= fitgeotrans(mp,fp,'projective');
            elseif warpType==5
                transform2DIntermediate= fitgeotrans(mp,fp,'polynomial',degree);
            elseif warpType==6
                try    
                    transform2DIntermediate= fitgeotrans(mp,fp,'pwl');
                    title8='8) pwl';
                catch
                    NumPtPairsInWeiMeanQ=sprintf('Sorry pwl does not work here, number of control pts considered in lwm? >=6');
                    opts.WindowStyle = 'normal';
                        NumPtPairsInWeiMeanA = inputdlg(NumPtPairsInWeiMeanQ,'Choosing geometric transform',1,{''},opts);%[1 2; 1 2]
                            NumPtPairsInWeiMean5=str2num(NumPtPairsInWeiMeanA{1});
                    transform2DIntermediate = fitgeotrans(mp,fp,'lwm',NumPtPairsInWeiMean5);%36
                end
            elseif warpType==7
                transform2DIntermediate= fitgeotrans(mp,fp,'lwm',NumPtPairsInWeiMeanSet);
            
                
%             elseif warpType==5 %explicity given
%                 transform2DIntermediate = fitgeotrans(mp,fp,TransType,degree);
%             elseif warpType==7
%                 transform2DIntermediate = fitgeotrans(mp,fp,TransType,NumPtPairsInWeiMean);
%             else
%                 transform2DIntermediate = fitgeotrans(mp,fp,TransType);%'projective');%'similarity'%'affine'%'projective'
            end
%         elseif isequal(CODE_Coreg,'MRI-BF')
%             transform2DIntermediate = fitgeotrans(mp,fp,'similarity');%'affine'
            Rfixed = imref2d(size(fixed));
        if warpType>=1
            registered_coregisteringRef = imwarp(moving,transform2DIntermediate,'OutputView',Rfixed);
        else
            for index=1:length(transform2DIntermediateTemp)
                registered_coregisteringRefTemp{index} = imwarp(moving,transform2DIntermediateTemp{index},'OutputView',Rfixed);
            end
        end
    end
    if warpType>=1
        figure('Units','characters','Position',[10 1 180 100]);
        confirmfig=tiledlayout(6,4);
        nexttile(1,[4,4]),
        imshowpair(fixed,registered_coregisteringRef,'blend')%'falsecolor'% 'checkerboard'
        %figure('Units','characters','Position',[1 60 120 50]);
        nexttile(17,[2,4])
        imshowpair(fixed,registered_coregisteringRef,'montage')
        if isequal(CODE_Coreg,'BF-OCT')
            title(confirmfig,[{'Attempted alignment'}, {'brightfield/epifluorescence - OCT'}])
        elseif isequal(CODE_Coreg,'MRI-BF')
            title(confirmfig,[{'Attempted alignment'}, {'MRI - brightfield/epifluorescence '}])
        elseif isequal(CODE_Coreg,'CT-BF')
            title(confirmfig,[{'Attempted alignment'}, {'CT - brightfield/epifluorescence '}])
        else
            title(confirmfig,[{'Attempted alignment'}, {CODE_Coreg}])
        end
    
    userQ=sprintf('Alignment ok (y/n)?');
    opts.WindowStyle = 'normal';
        userA = inputdlg(userQ,'Confirm quality of created transverse tumour mask',1,{''},opts);%[1 2; 1 2]
            user=userA{1};%input('Right orie
    %user = input('Alignment ok (y/n)?','s');
    if ~isequal(user,'y') && ~isequal(user,'Y')
        warpType=0;% now it will show all processing options
    end
    else % warpType=0;% now it will show all processing options
        figure('Units','characters','Position',[10 1 360 100]);
        SelectPreffig=tiledlayout(3,4);
        if isequal(CODE_Coreg,'BF-OCT')
            title(SelectPreffig,[{'Attempted alignment'}, {'brightfield/epifluorescence - OCT'}])
        elseif isequal(CODE_Coreg,'MRI-BF')
            title(SelectPreffig,[{'Attempted alignment'}, {'MRI - brightfield/epifluorescence '}])
        elseif isequal(CODE_Coreg,'CT-BF')
            title(SelectPreffig,[{'Attempted alignment'}, {'CT - brightfield/epifluorescence '}])
        else
            title(SelectPreffig,[{'Attempted alignment'}, {CODE_Coreg}])
        end
        nexttile,imshowpair(fixed,registered_coregisteringRefTemp{1},'blend'),title(sprintf('%s',title1))
        nexttile,imshowpair(fixed,registered_coregisteringRefTemp{2},'blend'),title(sprintf('%s',title2))
        nexttile,imshowpair(fixed,registered_coregisteringRefTemp{3},'blend'),title(sprintf('%s',title3))
        nexttile,imshowpair(fixed,registered_coregisteringRefTemp{4},'blend'),title(sprintf('%s',title4))
        nexttile,imshowpair(fixed,registered_coregisteringRefTemp{5},'blend'),title(sprintf('%s',title5))
        nexttile,imshowpair(fixed,registered_coregisteringRefTemp{6},'blend'),title(sprintf('%s',title6))
        nexttile,imshowpair(fixed,registered_coregisteringRefTemp{7},'blend'),title(sprintf('%s',title7))
        nexttile,imshowpair(fixed,registered_coregisteringRefTemp{8},'blend'),title(sprintf('%s',title8))
        nexttile,imshowpair(fixed,registered_coregisteringRefTemp{9},'blend'),title(sprintf('%s',title9))
        nexttile,imshowpair(fixed,registered_coregisteringRefTemp{10},'blend'),title(sprintf('%s',title10))
        nexttile,imshowpair(fixed,registered_coregisteringRefTemp{11},'blend'),title(sprintf('%s',title11))
        nexttile,imshowpair(fixed,registered_coregisteringRefTemp{12},'blend'),title(sprintf('%s',title12))
        
        Pref=-1;%Preference not yet defined
        while Pref<0 || Pref>12
        PreferenceQ=sprintf('Any Preferred? 0:none (and change control pts), 1,2,3,4,5,6,7,8,9,10,11,12');
    opts.WindowStyle = 'normal';
        PreferenceA = inputdlg(PreferenceQ,'Choosing geometric transform',1,{''},opts);%[1 2; 1 2]
            Pref=str2num(PreferenceA{1}); 
        end
        if Pref==1
            warpType=1;
        elseif Pref==2
            warpType=2;
        elseif Pref==3
            warpType=3;
        elseif Pref==4
            warpType=4;
        elseif Pref==5
            warpType=5;
            degree=2;
        elseif Pref==6
            warpType=5;
            degree=3;
        elseif Pref==7
            warpType=5;
            degree=4;
        elseif Pref==8 && ErrorCaught==0
            warpType=6;
        elseif Pref==8 && ErrorCaught==1
            warpType=7;
            NumPtPairsInWeiMeanSet=NumPtPairsInWeiMean5;
        elseif Pref==9
            warpType=7;
            NumPtPairsInWeiMeanSet=NumPtPairsInWeiMean1;
        elseif Pref==10
            warpType=7;
            NumPtPairsInWeiMeanSet=NumPtPairsInWeiMean2;
        elseif Pref==11
            warpType=7;
            NumPtPairsInWeiMeanSet=NumPtPairsInWeiMean3;
        elseif Pref==12
            warpType=7;
            NumPtPairsInWeiMeanSet=NumPtPairsInWeiMean4;

%         if warpType==0
%             keyboard;%dbcont to resume
%         end
        end
        user='n'
    end
    end
        if ~exist(DirectoryCoregistrationData,"dir")
            mkdir(DirectoryCoregistrationData);
        end
        saveas(gcf,fullfile(DirectoryCoregistrationData,sprintf('CoregistrationOfOpticalModalities_%s.png',CODE_Coreg)))
        CorregistrationIsGood=1;
        
    if ~(attempt==2 && PreviouslyAlignedFound)
        transform2D_Coregistration{1}=RoughTransform;
        transform2D_Coregistration{2}=transform2DIntermediate;%affine2d(transform2DIntermediate.T*RoughTransform.T);%NO Issue is First transform was a similarity transform and  this was
    end
            save(fullfile(DirectoryCoregistrationData,sprintf('registered_%s.mat',CODE_Coreg)),'registered_coregisteringRef','-mat')%fluorescence_Brightfield_toOCT
            save(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-FOV_%s.mat',CODE_Coreg)),'Rfixed','-mat');
        
    if attempt<=1%2
        save(fullfile(DirectoryCoregistrationData,sprintf('AutomaticRegistration2D-optimizerSettings_%s.mat',CODE_Coreg)),'optimizer','-mat')
        save(fullfile(DirectoryCoregistrationData,sprintf('manual-AutomaticRegistration2D-metricSettings_%s.mat',CODE_Coreg)),'transform2D_Coregistration','-mat');
    elseif attempt==2 && PreviouslyAlignedFound==1
        %old was ok
    elseif attempt>=2%3    
        save(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-AffineTransformation_%s.mat',CODE_Coreg)),'transform2D_Coregistration','-mat');
        save(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-MovingPoints_%s.mat',CODE_Coreg)),'mp','-mat');
        save(fullfile(DirectoryCoregistrationData,sprintf('ManualRegistration2D-FixedPoints_%s.mat',CODE_Coreg)),'fp','-mat');
    end
    close all
end
