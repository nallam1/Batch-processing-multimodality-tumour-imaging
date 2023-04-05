function RawOCT_UnCoregT0_RotatedShifted=glassAutoExcluderv4(Raw_stOCT,GlassThickness_200PixDepth,ReferencePixDepth,DataCroppedNotResizedInDepth,savefilepath,OS_removal)%,ErrorPermittedAxially,ErrorPermittedLaterally)
%% Automatic glass delineation then removal
% It looks for the best fit of the top most line of brightest pixels
% (interface) then extrapolates to perform glass removal
%glassAutoExcluderv2(Patch_stack_Complex,GlassThickness_200PixDepth,ReferencePixDepth,DataCroppedNotResizedInDepth,'F:\SBRT project March-June 2021\L0R4\Apr 9 2021\OCT\High resolution scan_setting5_9x9mm\TestNoMotionArtifacts',OS_removal)
Dims=size(squeeze(Raw_stOCT));
if length(Dims)==3 %just stOCT
    BMmode=0;
    NumBscans=1;
    NumYsteps=Dims(3);
elseif length(Dims)==4 %still all B-scans present
    BMmode=1;
    NumBscans=Dims(3);
    NumYsteps=Dims(4);
end
DepthExtent=Dims(1);
xWidth=Dims(2);
FloorOmissionMask=ones(Dims);%initializing the matrix to dot multiply to remove glass (different from when matrix is predefined during manual contouring)
%in case only detects top interface? (like too much ezudate around inner?
%Future acquire larger depth of field from above?
%issue of wrap-around artifacts? Or will appear too blurry to be "straigh
%line"?
if DataCroppedNotResizedInDepth==1% was data cropped or is it unaltered from usual 500pix in depth acquired scan and possibly just resized
    GlassThickness=GlassThickness_200PixDepth*500/ReferencePixDepth; %200/500*10.8=4.32 so +/-2 pix difference axially error permitted
%     %% take this out and call the errorpermitted... into the glass autoexcluder function
%     ErrorPermittedAxially=ceil(z_res)/(500/ReferencePixDepth)
%     ErrorPermittedLaterally= -- from savefolderpath name take out 6x9 part or whatever and use smallest value--always value of x
else
    GlassThickness=GlassThickness_200PixDepth*DepthExtent/ReferencePixDepth;
end
%% 1) Preparing intensity image for processing
if ~isreal(Raw_stOCT)%is complex?
    Raw_stOCT=abs(Raw_stOCT);
end
%% Visualize pre-glass removal
%if BMmode==1 
%   figure, imshow3D(squeeze(mean(Raw_stOCT,3)))%imshow3D(squeeze(mean(abs(Patch_stack_Complex),3)))
%elseif BMmode==0
%   figure, imshow3D(Raw_stOCT)%imshow3D(squeeze(mean(abs(Patch_stack_Complex),3)))
%end
%% Settings for glass detection
    % Frangi vesselness filter
            opt.FrangiScaleRange=[1 3];
            opt.FrangiScaleRatio=1;
            opt.FrangiBetaOne=1;
            opt.FrangiBetaTwo=20;
            opt.BlackWhite=false;
    % oversaturation removal set outside --might be confusing to add another one here?        
%% Initialization of data with motion mitigated and all frames aligned        
RawOCT_UnCoregT0_RotatedShifted=Raw_stOCT;%Initialized
%clearvars RawOCT    
ManualApprovalOfRefFrame=0;% In order to ensure glass bottom interface is at least correctly tracked in the first series of repeated B-scans (tbis will probably give a representative range of where the glass moves (oscillates)

Previous_Glass_Bot_Interface_Ystep_Bscan=[];%Initialize B-scan glass with respect to which to perform alignment %rotate and translate last step 
for yStep=1:NumYsteps%parfor yStep=1:NumYsteps
    for BScanrep=1:NumBscans
        %% Extracting frame to be analyzed
        fprintf('Processing B-scan yStep=%d, BScanrep=%d\n',yStep,BScanrep);
        if BMmode==1 
            frmRaw=squeeze(Raw_stOCT(:,:,BScanrep,yStep));
        elseif BMmode==0
            frmRaw=squeeze(Raw_stOCT(:,:,BScanrep,yStep));
        end
        %% Applying oversaturation removal and intensity normalization to 1
            frmOS=removeOversaturation4(frmRaw,OS_removal);%0.003);
        %% Add sharpening filter?
        %% Applying Frangi filter to improve contrast on glass
            imageStraightEmphasized=FrangiFilter2D(double(frmOS),opt);
        %% Applying Hough transform and line detection function    
            EdgesFoundScan=detectLines(imageStraightEmphasized);
%           EdgesFoundScan=detectLines(frmOS);
            if yStep==1 %storing frames with detectiond
                EdgesFoundScanCopy{BScanrep}=EdgesFoundScan;
                FrameCopy(:,:,BScanrep)=frmOS;
            end
        %% Visualize detections
        %Optional but required for first few frames to confirm range of
        %motion
        %figure,imagesc(frmOS),displayResults(EdgesFoundScan)
        %figure,imagesc(frmRaw),displayResults(EdgesFoundScan)
        %% Visualize all B-scans stitched together
%         for y=1:800
% for ind=1:8
% catStructure(:,:,8*(y-1)+(ind))=Structure(:,:,ind,y);
            %% Checking first repeated set of B-scans (at 1 y-step) for accuracy of detections manually  
            %Check also at 2/3 in (maybe range of motion changes?)
            if ManualApprovalOfRefFrame~=NumBscans%add a chek that the frames are sequential?
                GoodGlassTrackingQ={};%'n';
                    figure, t=tiledlayout('flow'),
                    for FrameToDisp=1:BScanrep
                        nexttile, title(sprintf('Bscan %d',FrameToDisp)), imagesc(squeeze(FrameCopy(:,:,FrameToDisp))),displayResults(EdgesFoundScanCopy{FrameToDisp})
                    end
                    set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
                       QBox.WindowStyle='normal'
                       UsePrevQ=inputdlg('Is the current glass tracking fine?','',[1,50],{''},QBox);
                       GoodGlassTrackingQ=UsePrevQ{1};
                            if (isequal(GoodGlassTrackingQ,'n')||isequal(GoodGlassTrackingQ,'N'))
                                ManualApprovalOfRefFrame= 0; %reset to 0 and change setting
                                error('The settings for automatic glass tracking requires readjustment see line 41 of glassAutoExcluder');
                            elseif isempty(GoodGlassTrackingQ)||isequal(GoodGlassTrackingQ,'y')||isequal(GoodGlassTrackingQ,'Y')
                                ManualApprovalOfRefFrame= ManualApprovalOfRefFrame+1;
                                close gcf
                            end
            end
        %% Ensuring only bottom glass surface is selected and extracting info about line detection to enable extrapolation of line
        if isempty(EdgesFoundScan.lines) %no glass (line) detections?
            fprintf('\n     No lines detected yStep=%d, BScanrep=%d\n\n',yStep,BScanrep);
            %Using previous frame data --> should roughly work since all
            %part of same patch even
            Current_Glass_Bot_Interface_Ystep_Bscan=Previous_Glass_Bot_Interface_Ystep_Bscan; %[GlassBot_slope,Error_m,GlassBot_intercept,Error_b];%[1:Dims(2)]*GlassBot_slope+GlassBot_intercept;%No need to save in memory just perform rigid transform
        else
        %Track just the lowest line no need to detect whether both
        %interfaces identified (since both being in depth of field is
        %variable
        %Considers only If too high?
            
            GlassBot_slope=[];
            GlassBot_intercept=[]; %saving only the one which is the lowest (or the one within the expected depth range?--could be good to detection is in fact lowest interface of glass, but not good if say lowest interface unclear? Or if below expected depth during motion
                for LineDetectedIndx=1:length(EdgesFoundScan.lines)
                    consLine=EdgesFoundScan.lines(LineDetectedIndx);%considered line
                    consLine_slope=(consLine.point2(2)-consLine.point1(2))/(consLine.point2(1)-consLine.point1(1));
                    consLine_intercept=consLine.point2(2)-consLine.point2(1)*consLine_slope;
                        if isempty(GlassBot_slope) && isempty(GlassBot_intercept)%either one not yet defined for the considered frame since this is the first iteration over all detected lines
                            GlassBot_slope=consLine_slope;
%                                 Error_m=GlassBot_slope*(sqrt((ErrorPermittedAxially/(consLine.point2(2)-consLine.point1(2)))^2+(ErrorPermittedLaterally/(consLine.point2(1)-consLine.point1(1)))^2));
                            GlassBot_intercept=consLine_intercept;
%                                 Error_b=sqrt(ErrorPermittedAxially^2+(GlassBot_slope*ErrorPermittedLaterally))^2;
                        elseif GlassBot_intercept>consLine_intercept %if another line is found lower than the first than take that line as being the bottom interface of the glass
                            GlassBot_slope=consLine_slope;
%                                 Error_m=GlassBot_slope*(sqrt((ErrorPermittedAxially/(consLine.point2(2)-consLine.point1(2)))^2+(ErrorPermittedLaterally/(consLine.point2(1)-consLine.point1(1)))^2));%error in defined slope according to pixelization 
                            GlassBot_intercept=consLine_intercept;
%                                 Error_b=sqrt(ErrorPermittedAxially^2+(GlassBot_slope*ErrorPermittedLaterally))^2;%error in defined intercept
                        end
                end   
            Current_Glass_Bot_Interface_Ystep_Bscan=[GlassBot_slope,GlassBot_intercept];%,Error_m,Error_b];%%[GlassBot_slope,Error_m,GlassBot_intercept,Error_b];%[1:Dims(2)]*GlassBot_slope+GlassBot_intercept;%No need to save in memory just perform rigid transform
                %Whether to keep the detected line as a reference for the
                %following frame
                if isempty(Previous_Glass_Bot_Interface_Ystep_Bscan) %In case it is the first frame process
                    Previous_Glass_Bot_Interface_Ystep_Bscan=Current_Glass_Bot_Interface_Ystep_Bscan;%Setting the current frame as reference for following frame in case of no detections.
                elseif sign(Previous_Glass_Bot_Interface_Ystep_Bscan(1))==sign(Current_Glass_Bot_Interface_Ystep_Bscan(1))%preliminary check if slopes are consistent (thus indicating that the glass is in fact being tracked
                    %if (Info_Glass_Bot_Interface_Ystep_Bscan_current-GlassThickness)<0%checking if top interface accidentally detected   
                    AcceptableRange=[(mean(InfoGlassTraces(1,:,:),'all')-std(InfoGlassTraces(1,:,:),'all')),(mean(InfoGlassTraces(1,:,:),'all')+std(InfoGlassTraces(1,:,:),'all'))];
                    
                    if min(AcceptableRange)<Current_Glass_Bot_Interface_Ystep_Bscan(1) && max(AcceptableRange)<Current_Glass_Bot_Interface_Ystep_Bscan(1)
                    Previous_Glass_Bot_Interface_Ystep_Bscan=Current_Glass_Bot_Interface_Ystep_Bscan;
                    
                    To fix here to ensure capture within
                elseif sign(Previous_Glass_Bot_Interface_Ystep_Bscan(1))~=sign(Current_Glass_Bot_Interface_Ystep_Bscan(1))
                    Current_Glass_Bot_Interface_Ystep_Bscan=Previous_Glass_Bot_Interface_Ystep_Bscan;%if current frame slope and intercept incorrect
                end
                InfoGlassTraces(:,BScanrep,yStep)=[GlassBot_slope,GlassBot_intercept];
                %Use this to flag certain frames? for potential errors (no
                %detection for example or severely discrepant from other slides and to be omitted)
        end
                
            Line1D_Glass_Bot_Interface_Ystep_Bscan_current=-Current_Glass_Bot_Interface_Ystep_Bscan(1)*[1:xWidth]+Current_Glass_Bot_Interface_Ystep_Bscan(2);
%             Slice2D_Glass_Bot_Interface_Ystep_Bscan_current=ones(DepthExtent,xWidth);
%             %creating glass mask per frame (thus not storing the full 3D mask in the memory)
%             for xInd=1:xWidth
% %                 zInd=1;
% %                 while GlassNot&& zInd<=DepthExtent%for zInd=1:DepthExtent
% %                     zInd
% %                     if Line1D_Glass_Bot_Interface_Ystep_Bscan_current(xInd)
%                         Slice2D_Glass_Bot_Interface_Ystep_Bscan_current(1:Line1D_Glass_Bot_Interface_Ystep_Bscan_current(xInd),xInd)=0;
%             end
            %% Shift rotate frame
            if BMmode==1
                for xInd=1:xWidth%Dims(2)%going through each A-scan
                    %Determine z-shift required based
                    zShiftReq=ceil(Line1D_Glass_Bot_Interface_Ystep_Bscan_current(xInd));%-1%level of bottom of glass marked automatically ideally   
                    RawOCT_UnCoregT0_RotatedShifted(:,xInd,BScanrep,yStep)=circshift(Raw_stOCT(:,xInd,BScanrep,yStep),-zShiftReq,1);
                    FloorOmissionMask(:,xInd,BScanrep,yStep)=[ones(Dims(1)-zShiftReq,1); zeros(zShiftReq,1)];%(end-zShiftReq+1:end,xInd,yStep)=zeros(zShiftReq,1);%(ones;zeros()];%circshift(mask_3DGlass(:,xInd,yStep),zShiftReq,1);
                    %instead of storing FloorOmissionMask, can later just
                    %multiply here directly though may be slower?
                end
            elseif BMmode==0
                for xInd=1:xWidth%Dims(2)%going through each A-scan
                    %Determine z-shift required
                    zShiftReq=ceil(Line1D_Glass_Bot_Interface_Ystep_Bscan_current(xInd));%-1%level of bottom of glass marked automatically ideally 
                    RawOCT_UnCoregT0_RotatedShifted(:,xInd,yStep)=circshift(Raw_stOCT(:,xInd,yStep),-zShiftReq,1);
                    FloorOmissionMask(:,xInd,yStep)=[ones(DepthExtent-zShiftReq,1); zeros(zShiftReq,1)];%(end-zShiftReq+1:end,xInd,yStep)=zeros(zShiftReq,1);%(ones;zeros()];%circshift(mask_3DGlass(:,xInd,yStep),zShiftReq,1);
                    %instead of storing FloorOmissionMask, can later just
                    %multiply here directly though may be slower?
                end
            end
            %% Visualize rotation shift and removal of glass completely
               %figure,
               %imagesc(squeeze(Raw_stOCT_UnCoregT0_RotatedShifted(:,:,BScanrep,yStep)));
                    
            %have it somehow identify where most of the points are or maybe omit crop out regions of significantly broken up slopes--> around edges of frame 
%                 Error_b=sqrt(ErrorPermittedAxially^2+(GlassBot_slope*ErrorPermittedLaterally)^2)
%                 Error_m=GlassBot_slope*(sqrt(ErrorPermittedAxially^2+ErrorPermittedLaterally^2))
%                 if isempty(Glass_Bot_Interface_Ystep_Bscan_All)
%                     Glass_Bot_Interface_Ystep_Bscan_All=Glass_Bot_Interface_Ystep_Bscan_current;%reference frame to which all the rest are to be aligned
%                 end%elseif ~(abs(Glass_Bot_Interface_Ystep_Bscan_current(1)-Glass_Bot_Interface_Ystep_Bscan_All(1))<=(Glass_Bot_Interface_Ystep_Bscan_current(2)+Glass_Bot_Interface_Ystep_Bscan_All(2)))||~(abs(Glass_Bot_Interface_Ystep_Bscan_current(3)-Glass_Bot_Interface_Ystep_Bscan_All(3))<=(Glass_Bot_Interface_Ystep_Bscan_current(4)+Glass_Bot_Interface_Ystep_Bscan_All(4)))%isequal(Glass_Bot_Interface_Ystep_Bscan_All,Glass_Bot_Interface_Ystep_Bscan_current)%or give it some tolerance?
                    %Keeping transforms separate for simplicity? Speed?
%                     SlopeDiff=abs(Glass_Bot_Interface_Ystep_Bscan_current(1)-Glass_Bot_Interface_Ystep_Bscan_All(1));
%                     if ~(SlopeDiff<=(Glass_Bot_Interface_Ystep_Bscan_current(2)+Glass_Bot_Interface_Ystep_Bscan_All(2)))
%                        %If slope different then rotate
%                        atan(SlopeDiff)
%                        Glass_Bot_Interface_Ystep_Bscan_current(3)=%changes after the rotation
%                     end
%                     
%                     if ~(abs(Glass_Bot_Interface_Ystep_Bscan_current(3)-Glass_Bot_Interface_Ystep_Bscan_All(3))<=(Glass_Bot_Interface_Ystep_Bscan_current(4)+Glass_Bot_Interface_Ystep_Bscan_All(4)))
%                        % if intercept off then translate along x and y
%                         
%                     end
                   
                    %elseif isequal(Glass_Bot_Interface_Ystep_Bscan_All,Glass_Bot_Interface_Ystep_Bscan_current)%or give it some tolerance?
                    
            %Rotate flatten all only at the end, now just have all lines
            %allign
            %EdgesFoundScan=edge(squeeze(Raw_stOCT(:,:,yStep)),'canny');
            % Visualization
            %figure, imagesc(squeeze(Raw_stOCT(:,:,yStep)));
            %figure, imshowpair(EdgesFoundScan,squeeze(Raw_stOCT(:,:,yStep)),'montage');
            %Use the line from top allign next y=mx+b with prior y=mx+b best of abilities? Or simply rotate and remove glass and so all necessarily aligned? I think the latter but still may need best fit to maintain glass interface
            %% 2) Find top most interface then rotate 
            %Do not make into separate step for after finding glass on
            %every single frame (too much offset to the memory).
%         parfor yStep=1:ylim%going through all B-scans 
%             for xInd=1:xWidth%Dims(2)%going through each A-scan
%                 %Determine z-shift required
%                 zShiftReq=-(find(EdgesFoundScan(:,xInd,yStep)>0,1,'first')-1)%level of top of glass marked automatically ideally
%                 Raw_stOCT_UnCoregT0_RotatedShifted(:,xInd,yStep)=circshift(Raw_stOCT_UnCoregT0_RotatedShifted(:,xInd,yStep),zShiftReq,1);
%                 FloorOmissionMask(:,xInd,yStep)=[ones(Dims(1)-zShiftReq-1,1); zeros(zShiftReq,1)];%(end-zShiftReq+1:end,xInd,yStep)=zeros(zShiftReq,1);%(ones;zeros()];%circshift(mask_3DGlass(:,xInd,yStep),zShiftReq,1);
%             end
%         end
        end
    end
  
        %% since top containing window chamber glass is now wrapped around to the bottom, that needs to be remove
            RawOCT_UnCoregT0_RotatedShifted=RawOCT_UnCoregT0_RotatedShifted.*FloorOmissionMask;
%% Saving final OCT data with all frames hopefully aligned 
            save(fullfile(savefilepath,sprintf('patchRawOCT_BMmode_%.0d_UnCoregT0_RotatedShiftedv2',BMmode)),'RawOCT_UnCoregT0_RotatedShifted','-v7.3');
        clearvars FloorOmissionMask
%         RawStructtemp.StOCT_UnCoregT0_RotatedShifted=StOCT_UnCoregT0_RotatedShifted;
        
end
% % Sample image
% im=imread('https://www.mathworks.com/matlabcentral/answers/uploaded_files/123386/GFP1C28cropped.jpg');
% figure
% subtightplot(2,2,1), imshow(im)
% subtightplot(2,2,3), imshow(edge(im,'canny'))
% % Enhance fillaments with Frangi vesselness filter
% opt.FrangiScaleRange=[1 3];
% opt.FrangiScaleRatio=1;
% opt.FrangiBetaOne=1;
% opt.FrangiBetaTwo=20;
% opt.BlackWhite=false;
% [im_2,im_s]=FrangiFilter2D(double(im),opt);
% subtightplot(2,2,2), imshow(im_2)
% subtightplot(2,2,4), imshow(edge(im_2,'canny'))
