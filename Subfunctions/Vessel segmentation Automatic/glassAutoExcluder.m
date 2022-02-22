function Raw_stOCT_UnCoregT0_RotatedShifted=glassAutoExcluderv2(Raw_stOCT,GlassThickness_200PixDepth,ReferencePixDepth,DataCroppedNotResizedInDepth,savefilepath,OS_removal,ErrorPermittedAxially,ErrorPermittedLaterally)
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
xWidth=Dims(2);

FloorOmissionMask=ones(Dims);%initializing the matrix to dot multiply to remove glass (different from when matrix is predefined during manual contouring)
%% 1) Preparing intensity image for processing
if ~isreal(Raw_stOCT)%iscomplex
    Raw_stOCT=abs(Raw_stOCT);
end

    Raw_stOCT_UnCoregT0_RotatedShifted=Raw_stOCT;
    %clearvars RawOCT    
if BMmode==0
    Glass_Bot_Interface_Ystep_Bscan_All=[];%Initialize B-scan glass with respect to which to perform alignment %rotate and translate last step 
    for yStep=1:NumYsteps%parfor yStep=1:NumYsteps
        for BScanrep=1:NumBscans
            frmRaw=squeeze(Raw_stOCT(:,:,yStep));
            frmOS=removeOversaturation4(frmRaw,OS_removal);%0.003);
            EdgesFoundScan=detectLines(frmOS);   
            if isempty(EdgesFoundScan.lines)
                fprintf('\n No lines detected ystep=%d',yStep);
            end
            %Track just the lowest line no need to detect whether both
            %interfaces identified (since both being in depth of field is
            %variable
            %Considers only If too high?
            GlassBot_slope=[];
            GlassBot_intercept=[]; %saving only the one which is the lowest (or the one within the expected depth range?--could be good to detection is in fact lowest interface of glass, but not good if say lowest interface unclear? Or if below expected depth during motion
                for LineDetIndx=1:length(EdgesFoundScan.lines);
                    consLine=EdgesFoundScan.lines(LineDetIndx);%considered line
                    consLine_slope=(consLine.point2(2)-consLine.point1(2))/(consLine.point2(1)-consLine.point1(1));
                    consLine_intercept=consLine.point2(2)-consLine.point2(1)*consLine_slope;
                        if isempty(GlassBot_slope) && isempty(GlassBot_intercept)%either one for the first iteration over all detected lines
                            GlassBot_slope=consLine_slope;
                                Error_m=GlassBot_slope*(sqrt((ErrorPermittedAxially/(consLine.point2(2)-consLine.point1(2)))^2+(ErrorPermittedLaterally/(consLine.point2(1)-consLine.point1(1)))^2));
                            GlassBot_intercept=consLine_intercept;
                                Error_b=sqrt(ErrorPermittedAxially^2+(GlassBot_slope*ErrorPermittedLaterally))^2;
                        elseif GlassBot_intercept>consLine_intercept
                            GlassBot_slope=consLine_slope;
                                Error_m=GlassBot_slope*(sqrt((ErrorPermittedAxially/(consLine.point2(2)-consLine.point1(2)))^2+(ErrorPermittedLaterally/(consLine.point2(1)-consLine.point1(1)))^2));
                            GlassBot_intercept=consLine_intercept;
                                Error_b=sqrt(ErrorPermittedAxially^2+(GlassBot_slope*ErrorPermittedLaterally))^2;
                        end
                end
            Glass_Bot_Interface_Ystep_Bscan_current=[GlassBot_slope,Error_m,GlassBot_intercept,Error_b];%[1:Dims(2)]*GlassBot_slope+GlassBot_intercept;%No need to save in memory just perform rigid transform
%                 Error_b=sqrt(ErrorPermittedAxially^2+(GlassBot_slope*ErrorPermittedLaterally)^2)
%                 Error_m=GlassBot_slope*(sqrt(ErrorPermittedAxially^2+ErrorPermittedLaterally^2))
                if isempty(Glass_Bot_Interface_Ystep_Bscan_All)
                    Glass_Bot_Interface_Ystep_Bscan_All=Glass_Bot_Interface_Ystep_Bscan_current;%reference frame to which all the rest are to be aligned
                end%elseif ~(abs(Glass_Bot_Interface_Ystep_Bscan_current(1)-Glass_Bot_Interface_Ystep_Bscan_All(1))<=(Glass_Bot_Interface_Ystep_Bscan_current(2)+Glass_Bot_Interface_Ystep_Bscan_All(2)))||~(abs(Glass_Bot_Interface_Ystep_Bscan_current(3)-Glass_Bot_Interface_Ystep_Bscan_All(3))<=(Glass_Bot_Interface_Ystep_Bscan_current(4)+Glass_Bot_Interface_Ystep_Bscan_All(4)))%isequal(Glass_Bot_Interface_Ystep_Bscan_All,Glass_Bot_Interface_Ystep_Bscan_current)%or give it some tolerance?
                    %Keeping transforms separate for simplicity? Speed?
                    SlopeDiff=abs(Glass_Bot_Interface_Ystep_Bscan_current(1)-Glass_Bot_Interface_Ystep_Bscan_All(1));
                    if ~(SlopeDiff<=(Glass_Bot_Interface_Ystep_Bscan_current(2)+Glass_Bot_Interface_Ystep_Bscan_All(2)))
                       %If slope different then rotate
                       atan(SlopeDiff)
                       Glass_Bot_Interface_Ystep_Bscan_current(3)=%changes after the rotation
                    end
                    
                    if ~(abs(Glass_Bot_Interface_Ystep_Bscan_current(3)-Glass_Bot_Interface_Ystep_Bscan_All(3))<=(Glass_Bot_Interface_Ystep_Bscan_current(4)+Glass_Bot_Interface_Ystep_Bscan_All(4)))
                       % if intercept off then translate along x and y
                        
                    end
                   
                    %elseif isequal(Glass_Bot_Interface_Ystep_Bscan_All,Glass_Bot_Interface_Ystep_Bscan_current)%or give it some tolerance?
                    
            %Rotate flatten all only at the end, now just have all lines
            %allign
            %EdgesFoundScan=edge(squeeze(Raw_stOCT(:,:,yStep)),'canny');
            % Visualization
            %figure, imagesc(squeeze(Raw_stOCT(:,:,yStep)));
            %figure, imshowpair(EdgesFoundScan,squeeze(Raw_stOCT(:,:,yStep)),'montage');
            %Use the line from top allign next y=mx+b with prior y=mx+b best of abilities? Or simply rotate and remove glass and so all necessarily aligned? I think the latter but still may need best fit to maintain glass interface
            %% 2) Find top most interface then rotate 
            
            for xInd=1:xWidth%Dims(2)%going through each A-scan
                %Determine z-shift required
                zShiftReq=-(find(EdgesFoundScan(:,xInd,yStep)>0,1,'first')-1)%level of top of glass marked automatically ideally
                Raw_stOCT_UnCoregT0_RotatedShifted(:,xInd,yStep)=circshift(Raw_stOCT_UnCoregT0_RotatedShifted(:,xInd,yStep),zShiftReq,1);
                FloorOmissionMask(:,xInd,yStep)=[ones(Dims(1)-zShiftReq-1,1); zeros(zShiftReq,1)];%(end-zShiftReq+1:end,xInd,yStep)=zeros(zShiftReq,1);%(ones;zeros()];%circshift(mask_3DGlass(:,xInd,yStep),zShiftReq,1);
            end
            %have it somehow identify where most of the points are or maybe omit crop out regions of significantly broken up slopes--> around edges of frame 
        end
    end
elseif BMmode==1       
%later try 3D edge detection? Although harder with multiple B-scans
    for yStep=1:NumYsteps%parfor yStep=1:NumYsteps
        for BScanrep=1:NumBscans
            frmRaw=squeeze(Raw_stOCT(:,:,BScanrep,yStep));
            frmOS=removeOversaturation4(frmRaw,OS_removal);%0.003);
            EdgesFoundScan=detectLines(frmOS);   
            if isempty(EdgesFoundScan.lines)
                fprintf('\n No lines detected yStep=%d, BScanrep=',yStep,BScanrep);
            end
            %EdgesFoundScan=edge(squeeze(Raw_stOCT(:,:,Bscanrep,yStep)),'canny');
            %% Visualization
            %figure, imagesc(squeeze(Raw_stOCT(:,:,yStep)));
            %figure, imshowpair(EdgesFoundScan,squeeze(Raw_stOCT(:,:,yStep)),'montage');
            %a=removeOversaturation4(medfilt2(squeeze(Raw_stOCT(:,:,yStep)),[2,2]),0.003);%0.003
% median_filtering_parameter=7
% thresh=mean(Raw_stOCT(:,:,yStep),'all');
%                 a0=Raw_stOCT(:,:,yStep)>thresh
%                a=squeeze(a0);%medfilt2(a0,[median_filtering_parameter,median_filtering_parameter]));%[2,2]
%             
%             figure, t=tiledlayout('flow')
%                 nexttile,EdgesFoundScan1=edge(a,'Sobel');
%                 imshow(EdgesFoundScan1),title('Sobel')
%                 nexttile,EdgesFoundScan2=edge(a,'Prewitt');
%                 imshow(EdgesFoundScan2),title('Prewitt')
%                 nexttile,EdgesFoundScan3=edge(a,'Roberts');
%                 imshow(EdgesFoundScan3),title('Roberts')
%                 nexttile,EdgesFoundScan4=edge(a,'log');
%                 imshow(EdgesFoundScan4),title('log')
%                 nexttile,EdgesFoundScan5=edge(a,'zerocross');
%                 imshow(EdgesFoundScan5),title('zerocross')
%                 nexttile,EdgesFoundScan6=edge(a,'canny');
%                 imshow(EdgesFoundScan6),title('canny')
%                 nexttile,EdgesFoundScan7=edge(a,'approxcanny');
%                 imshow(EdgesFoundScan7),title('approxcanny')

         
            %Use the line from top allign next y=mx+b with prior y=mx+b best of abilities? Or simply rotate and remove glass and so all necessarily aligned? I think the latter but still may need best fit to maintain glass interface
            %% 2) Find top most interface then rotate 
            
            for xInd=1:xWidth%Dims(2)%going through each A-scan
                %Determine z-shift required
                zShiftReq=-(find(EdgesFoundScan(:,xInd,BScanrep,yStep)>0,1,'first')-1)%level of top of glass marked automatically ideally
                Raw_stOCT_UnCoregT0_RotatedShifted(:,xInd,BScanrep,yStep)=circshift(Raw_stOCT_UnCoregT0_RotatedShifted(:,xInd,BScanrep,yStep),zShiftReq,1);
                FloorOmissionMask(:,xInd,BScanrep,yStep)=[ones(Dims(1)-zShiftReq-1,1); zeros(zShiftReq,1)];%(end-zShiftReq+1:end,xInd,yStep)=zeros(zShiftReq,1);%(ones;zeros()];%circshift(mask_3DGlass(:,xInd,yStep),zShiftReq,1);
                %FloorOmissionMask(Dims(1)-zShiftReq+1:Dims(1),xInd,Bscanrep,yStep)=zeros(zShiftReq,1);%FloorOmissionMask(end-zShiftReq+1:end,xInd,Bscanrep,yInd)%FloorOmissionMask(:,xInd,Bscanrep,yInd)=circshift(mask_3DGlass(:,xInd,Bscanrep,yStep),zShiftReq,1);
            end
            %have it somehow identify where most of the points are or maybe omit crop out regions of significantly broken up slopes--> around edges of frame 
        end
    end
end
Raw_stOCT_UnCoregT0_RotatedShifted=Raw_stOCT_UnCoregT0_RotatedShifted.*FloorOmissionMask;
        %% since top containing window chamber glass is now wrapped around to the bottom, that needs to be remove
        save(fullfile(savefilepath,sprintf('patchRawOCT_BM_%.0d_UnCoregT0_RotatedShifted',BMmode)),'RawOCT_UnCoregT0_RotatedShifted','-v7.3');
        clearvars FloorOmissionMask
%         RawStructtemp.StOCT_UnCoregT0_RotatedShifted=StOCT_UnCoregT0_RotatedShifted;
        
end
    

