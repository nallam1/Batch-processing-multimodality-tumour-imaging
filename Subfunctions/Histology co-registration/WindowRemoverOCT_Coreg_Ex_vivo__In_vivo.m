function mask_3D_NoGlass=WindowRemoverOCT_Coreg_Ex_vivo__In_vivo(StOCTMatFileToProcess,Varname,num_contoured_slices,NickName,saveFolder,AutoProcess,autoLineDector,OS_removal,GlassThickness_200PixDepth,DataCroppedNotResizedInDepth,ReferencePixDepth)%,umPerPix_For200PixDepth)
%% by Nader A.
%% Description
% num_contoured_slices: How many contours must be drawn--> If glass only 2
% are necessary (first and last slice).
% Import using matfile() both "stOCT" and "svOCT" (structural and speckle variance
% OCT respectively) files, make sure to imresize3 the "stOCT" file to be the
% same size as the svOCT file. "SaveFilenameDataGlassTrace(Top/Bot)" is the name of
% the saved top/bottom glass trace (stored in a draft subfolder "FolderConsideredSaveDraft"
% in the final folder where the binarized vasculature map will be saved:
% "saveFolder")
% At the end it outputs both the traces and the contoured-out-glass mask
%% Instructions
% It will guide request for contouring, place first vertex on your left going
% towards right, guidance images provided on left and image to be contoured
% on right. When satisfied just press "enter" otherwise type "n" then "enter".
% Contour out top of glass surface (since this is the first clearest
% interface.

%% Saving directories defined
FolderConsideredSaveDraft=fullfile(saveFolder,NickName);
if ~exist(FolderConsideredSaveDraft,'dir')
    mkdir(FolderConsideredSaveDraft);
end
SaveFilenameDataWindowTraceTop = fullfile(FolderConsideredSaveDraft,'zline_WindowTop_NoRotTransYet.mat');
SaveFilenameDataWindowTraceBot = fullfile(FolderConsideredSaveDraft,'zline_WindowBot_NoRotTransYet.mat');
SaveFilenameData3DMaskGlassInc = fullfile(FolderConsideredSaveDraft,'mask3D_WindowInc_NoRotTransYet.mat');
SaveFilenameData3DMaskGlassExc = fullfile(FolderConsideredSaveDraft,'mask3D_WindowExc_NoRotTransYet.mat');    
if ~exist(SaveFilenameDataWindowTraceTop,'file') || ~exist(SaveFilenameDataWindowTraceBot,'file')
    AutoProcess=0;%if not available simply will not try to load them
end
%% data loading
% Raw_stOCT=StOCTMatFileToProcess.(Varname)
% StOCTMatFileToProcess=matfile(StOCTMatFileToProcessFilepath);
Dims=size(StOCTMatFileToProcess.(Varname));
StEnFace=squeeze(sum(StOCTMatFileToProcess.(Varname),1));
%mask_3D_compressed = zeros(Dims(1), Dims(2), num_contoured_slices); %initialize the 3D compressed mask
    zline_GlassTrace_TopSurf=cell(num_contoured_slices,1);
    zline_GlassTrace_BotSurf=zline_GlassTrace_TopSurf;
    slices=round(linspace(round(Dims(3)/6),round(Dims(3)*5/6),num_contoured_slices))%Dims(3)
        n=0;%slice count
%         changeStruct=[];%Initialized since if later decide to set Oversaturation removal to 0 needs to remain for all later B-scans
%% Contour out the Glass in stOCT volume (just underneath the glass)
% if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==0 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2 
if AutoProcess==0
    if autoLineDector==0
    while n<num_contoured_slices%for n=1:num_contoured_slices % For loop does not work if I am tyring to extend the limit-- test example:for x=1:y
        n=n+1;
        SliceN=slices(n);
                    tempst=removeOversaturation4(squeeze(StOCTMatFileToProcess.(Varname)(:,:,SliceN)),OS_removal);
        Goodtogo='n';
        attempt=0;
        while Goodtogo=='n'
            %% Visualization + B-scan to label
            figure('Units','characters','Position',[50 20 200 50]);
            RatioScales=1;
                t = tiledlayout(4,7);
                    nexttile([2,3])%[2,3]
                        hImTop=imagesc(fliplr(imrotate(StEnFace,-90)));
                            hold on
                            plot([0 Dims(3)], [ceil(SliceN*RatioScales) ceil(SliceN*RatioScales)],'Color','r','LineWidth',2)
                            hold off
                        title(sprintf('OCTA en-face view positioning'))    
                    nexttile([4,4])
                            hIm=imagesc(tempst)%imagesc(refIm);
                            colormap(gray)
                        title(sprintf('Contour top surface of glass on stOCT slice = %d.\n Simply enter 2 points (or more if glass is broken) then press enter.\n If unhappy with view, press Esc for more options.',SliceN))
                        
                  title(t,NickName)%fileparts(fileparts(saveFolder)))%fileparts(fileparts(SaveFilenameData500um))))
                    set(gcf, 'Position', get(0,'Screensize'));
               if n==1 %%initial frame based on previously drawn timepoint
                   if attempt==0
                       if exist(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',SliceN)))     
                           load(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',SliceN)))
                           user_roi = drawpolyline('Position',[LastDrawn],'InteractionsAllowed','all');
                       else
                           user_roi = drawpolyline;
                       end
                       %saving it regardlesss for the first attempt at
                       %first slice to later fine tune
                       mask_1D = createMask(user_roi);%just the hand drawn line on 2D black overlay of image
                                    mask_2D=mask_1D;%zeros(size(temp));
                                        %%filling incomplete parts of line
                                        LastDrawn=user_roi.Position;
                                        save(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',SliceN)),'LastDrawn');
                   else
                       UsePrev={};%'n';
                       opts.WindowStyle='normal'
                       UsePrevQ=inputdlg('Use previously drawn? y or type literally anything else or just press enter for no','',[1,50],{''},opts);
                       UsePrev=UsePrevQ{1};
                            if isempty(UsePrev)||(~isequal(UsePrev,'y')&&~isequal(UsePrev,'Y'))
                                UsePrev= 'n';
                            elseif isequal(UsePrev,'y')||isequal(UsePrev,'Y')
                                UsePrev= 'y';
                            end
                               if isequal(UsePrev,'y') && exist(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',SliceN)))     
                                   load(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',SliceN)))
                                   user_roi = drawpolyline('Position',[LastDrawn],'InteractionsAllowed','all');
                               else
                                   user_roi = drawpolyline;
                               end
                   end
               else %for following slices 
                   UsePrev={};%'n';
                   %UsePrevQ=inputdlg('Use previously drawn? y or type literally anything else or just press enter for no';
                   opts.WindowStyle='normal'
                       UsePrevQ=inputdlg('Use previously drawn? y or type literally anything else or just press enter for no','',[1,50],{''},opts);
                       UsePrev=UsePrevQ{1};
                        if isempty(UsePrev)||(~isequal(UsePrev,'y')&&~isequal(UsePrev,'Y'))
                            UsePrev= 'n';
                        elseif isequal(UsePrev,'y')||isequal(UsePrev,'Y')
                            UsePrev= 'y';
                        end
                   if isequal(UsePrev,'y') && exist(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',SliceN)))     
                       load(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',SliceN)))
                       user_roi = drawpolyline('Position',[LastDrawn],'InteractionsAllowed','all');
                   else%based on previous slice
                       load(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',slices(n-1))))
                       user_roi = drawpolyline('Position',[LastDrawn],'InteractionsAllowed','all');
                   end
               end
                Goodtogo={};   
                opts.WindowStyle='normal'
                       GoodtogoQ=inputdlg(sprintf('Good to go?\n n or type literally anything else or just press enter for yes\n'),'Glass trace',[1,50],{''},opts);
                       %GoodtogoQ=inputdlg(sprintf('Good to go?\n n or type
                       %literally anything else or just press enter for
                       %yes\n'),'Glass trace');%now to be able to interact
                       %with the window
                Goodtogo=GoodtogoQ{1};
                if isempty(Goodtogo)
                    Goodtogo= 'Y';
                end
                
                if isequal(Goodtogo,'n')||isequal(Goodtogo,'N')
                   changeStructCond='n';
                   changeStruct={};%[];
                   while isequal(changeStructCond,'n')%~(0<=changeStructCond && changeStructCond<=1) && (isempty(changeStructCond)~=1)
                    changeStructQ=inputdlg(sprintf('Change settings?\n Simply press enter to leave as is,\n Enter 0 for no oversaturation removal,\n Enter the fraction of top intensity to remove,\n Or Enter a number >=1 to select a different frame to contour.'),'How to redo?')
                    if ~isempty(changeStructQ{1})
                        changeStruct=str2double(changeStructQ{1});
                    end
                    if isempty(changeStructQ{1})
                        changeStruct=changeStruct;%Just here for reference %it will simply default to whatever it changed to last time
                    end
                    if isempty(changeStruct)
%                         if isequal(LoadOrMatfile,'Matfile')
                            tempst=removeOversaturation4(squeeze(StOCTMatFileToProcess.(Varname)(:,:,SliceN)),OS_removal);
%                         elseif isequal(LoadOrMatfile,'Load')
%                             tempst=removeOversaturation4(squeeze(StOCTMatFileToProcess.(Varname)(:,:,SliceN)),OSremoval);
%                         end
                        changeStructCond='y';
                        break;
                    elseif (0<=changeStruct && changeStruct<1)
                        OS_removal=changeStruct;
%                         if isequal(LoadOrMatfile,'Matfile')
                            tempst=removeOversaturation4(squeeze(StOCTMatFileToProcess.(Varname)(:,:,SliceN)),OS_removal);
%                         elseif isequal(LoadOrMatfile,'Load')
%                             tempst=removeOversaturation4(squeeze(StOCTMatFileToProcess.(Varname)(:,:,SliceN)),OSremoval);
%                         end
                        changeStructCond='y';
                    elseif changeStruct>=1
                        if changeStruct>Dims(3) || changeStruct<slices(n)
                            changeStructCond='n';
                        else
                            SliceN=changeStruct;
                            slices(n)=changeStruct;
%                                 if isequal(LoadOrMatfile,'Matfile')
                                    tempst=removeOversaturation4(squeeze(StOCTMatFileToProcess.(Varname)(:,:,SliceN)),OS_removal);
%                                 elseif isequal(LoadOrMatfile,'Load')
%                                     tempst=removeOversaturation4(squeeze(StOCTMatFileToProcess.(Varname)(:,:,SliceN)),OSremoval);
%                                 end
                            changeStructCond='y';
                        end
%                     elseif changeStruct==0
%                         if isequal(LoadOrMatfile,'Matfile')
%                             tempst=squeeze(StOCTMatFileToProcess.(Varname)(:,:,SliceN));
%                         elseif isequal(LoadOrMatfile,'Load')
%                             tempst=squeeze(StOCTMatFileToProcess.(Varname)(:,:,SliceN));
%                         end
%                         changeStructCond='y';
                    end
                    
                   end
                else
                    ToporBotDrawn={};%[];
                    ToporBotDrawnQ=inputdlg(sprintf('Top or Bottom glass interface traced?\n Type t or simply press enter for top otherwise type b for bottom\n'),'Top or bottom?');
                    ToporBotDrawn=ToporBotDrawnQ{1};
                    if isempty(ToporBotDrawn)
                        ToporBotDrawn='t';
                    end
                end
                attempt=attempt+1;
        end        
        %% Saving Drawn contour and creating 2D Mask for current B-scan 
                                fprintf('Iteration %d of %d\n', n,num_contoured_slices);%gcf
                                saveas(hIm,char(fullfile(FolderConsideredSaveDraft,sprintf('ContouringGlassTopSurf%d.png',SliceN))),'png');
                                mask_1D = createMask(user_roi);%just the hand drawn line on 2D black overlay of image
                                    mask_2D=mask_1D;%zeros(size(temp));
                                        %%filling incomplete parts of line
                                        LastDrawn=user_roi.Position;
                                        save(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',SliceN)),'LastDrawn');
                                        %fprintf('Saving as default tumour mask for this mouse (which may be altered a bit timepoint to timepoint for consistency)\n');                                                
                                        %save(fullfile(OneTimePointFolder,sprintf('ROI_drawn_Top_slice%d.mat',SliceN)),'LastDrawn');

                        %                 keyboard
%% Fine but can do better since this is glass--> straight
%                                         for x=1:round(user_roi.Position(1,1))%ceil(user_roi.Position(1,1))
%                                             mask_2D(single(round(user_roi.Position(1,2))),x)=1; %all z x positions up to where the line was started 
%                                         end
%                                         for x=single(round(user_roi.Position(end,1))):size(tempst,2)%floor(user_roi.Position(end,1))) otherwise engths incompatible
%                                             mask_2D(single(round(user_roi.Position(end,2))),x)=1; %all z x positions up to where the line was started
%                                         end
%% Extrapolate glass interface (when cannot see full interface (low backscatter)
    
slope=[];
InterceptTopGlass=[];
if isequal(ToporBotDrawn,'t')
    if size(user_roi.Position,1)>2
        BrokenGlass=1;
        %% top && bottom
        for indx=1:(size(user_roi.Position,1)-1)
            slope(indx)=(user_roi.Position(indx+1,2)-user_roi.Position(indx,2))/(user_roi.Position(indx+1,1)-user_roi.Position(indx,1));
            InterceptTopGlass(indx)=user_roi.Position(indx,2)-slope(indx)*user_roi.Position(indx,1);
                if DataCroppedNotResizedInDepth==1
                    InterceptBotGlass(indx)=InterceptTopGlass(indx)+GlassThickness_200PixDepth*500/ReferencePixDepth;%;%user_roi.Position(1,2)-slope*user_roi.Position(1,1);
                else
                    InterceptBotGlass(indx)=InterceptTopGlass(indx)+GlassThickness_200PixDepth*size(tempst,1)/ReferencePixDepth;%;%user_roi.Position(1,2)-slope*user_roi.Position(1,1);
                end
            if indx==1
                rangex=1:ceil(user_roi.Position(indx+1,1));%1:floor(user_roi.Position(indx+1,1));
            elseif indx==(size(user_roi.Position,1)-1)
                rangex=ceil(user_roi.Position(indx,1)):size(tempst,2);%ceil(user_roi.Position(indx,1)):size(tempst,2);
            else%in between if 4 or more vertices
                rangex=(ceil(user_roi.Position(indx,1))+1):ceil(user_roi.Position(indx+1,1));%floor(user_roi.Position(indx,1)):ceil(user_roi.Position(indx+1,1));
            end
            zlineTop(rangex)=slope(indx)*[rangex]+InterceptTopGlass(indx);
            zlineBot(rangex)=slope(indx)*[rangex]+InterceptBotGlass(indx);
        end
            
    elseif size(user_roi.Position,1)==2
        BrokenGlass=0;
        %% top
            slope=(user_roi.Position(end,2)-user_roi.Position(1,2))/(user_roi.Position(end,1)-user_roi.Position(1,1));
            InterceptTopGlass=user_roi.Position(1,2)-slope*user_roi.Position(1,1);
                zlineTop=slope*[1:size(tempst,2)]+InterceptTopGlass;%round only at the end
        %% bottom
        if DataCroppedNotResizedInDepth==1
            InterceptBotGlass=InterceptTopGlass+GlassThickness_200PixDepth*500/ReferencePixDepth;%;%user_roi.Position(1,2)-slope*user_roi.Position(1,1); 
        else
            InterceptBotGlass=InterceptTopGlass+GlassThickness_200PixDepth*size(tempst,1)/ReferencePixDepth;%;%user_roi.Position(1,2)-slope*user_roi.Position(1,1);
        end
                zlineBot=slope*[1:size(tempst,2)]+InterceptBotGlass;%round only at the end %18*size(tempst,1)/200
    end
elseif isequal(ToporBotDrawn,'b')
    if size(user_roi.Position,1)>2
        BrokenGlass=1;
        %% top && bottom
        for indx=1:(size(user_roi.Position,1)-1)
            slope(indx)=(user_roi.Position(indx+1,2)-user_roi.Position(indx,2))/(user_roi.Position(indx+1,1)-user_roi.Position(indx,1));
            InterceptBotGlass(indx)=user_roi.Position(indx,2)-slope(indx)*user_roi.Position(indx,1);
                if DataCroppedNotResizedInDepth==1
                    InterceptTopGlass(indx)=InterceptBotGlass(indx)-GlassThickness_200PixDepth*500/ReferencePixDepth;%;%user_roi.Position(1,2)-slope*user_roi.Position(1,1); 
                else
                    InterceptTopGlass(indx)=InterceptBotGlass(indx)-GlassThickness_200PixDepth*size(tempst,1)/ReferencePixDepth;%;%user_roi.Position(1,2)-slope*user_roi.Position(1,1);
                end
            if indx==1
                rangex=1:ceil(user_roi.Position(indx+1,1));%1:floor(user_roi.Position(indx+1,1));
            elseif indx==(size(user_roi.Position,1)-1)
                rangex=ceil(user_roi.Position(indx,1)):size(tempst,2);%ceil(user_roi.Position(indx,1)):size(tempst,2);
            else%in between if 4 or more vertices
                rangex=(ceil(user_roi.Position(indx,1))+1):ceil(user_roi.Position(indx+1,1));%floor(user_roi.Position(indx,1)):ceil(user_roi.Position(indx+1,1));
            end
            zlineTop(rangex)=slope(indx)*[rangex]+InterceptTopGlass(indx);
            zlineBot(rangex)=slope(indx)*[rangex]+InterceptBotGlass(indx);
        end
            
    elseif size(user_roi.Position,1)==2 
        BrokenGlass=0;
        %% bottom                              
            slope=(user_roi.Position(end,2)-user_roi.Position(1,2))/(user_roi.Position(end,1)-user_roi.Position(1,1));
            InterceptBotGlass=user_roi.Position(1,2)-slope*user_roi.Position(1,1);
                zlineBot=slope*[1:size(tempst,2)]+InterceptBotGlass;%round only at the end
        %% top
            if DataCroppedNotResizedInDepth==1
                InterceptTopGlass=InterceptBotGlass-GlassThickness_200PixDepth*500/ReferencePixDepth;%umPerPix_For200PixDepth;%user_roi.Position(1,2)-slope*user_roi.Position(1,1);
            else
                InterceptTopGlass=InterceptBotGlass-GlassThickness_200PixDepth*size(tempst,1)/ReferencePixDepth;%umPerPix_For200PixDepth;%user_roi.Position(1,2)-slope*user_roi.Position(1,1);
            end                
                zlineTop=slope*[1:size(tempst,2)]+InterceptTopGlass;%round only at the end                                    
    end
end
%
%                                     % For visualization
%                                     mask_2D=zeros(size(mask_2D));
%                                         for x=1:size(tempst,2)
%                                             %DrawnSideContour=find(mask_1D(:,x),1)
%                                              z=size(tempst,1);
%                                             while z>=zlineBot(x) %(everythinfg below line)
%                                                 mask_2D(z,x)=1;
%                                                 z=z-1;
%                                             end
%                                         end
%                                         figure, imshow(mask_2D)
%                                 close all
                                
                                zline_GlassTrace_TopSurf{n}=zlineTop;
                                
                                zline_GlassTrace_BotSurf{n}=zlineBot;%average width of DSWC glass ~0.19mm and converted via umPerPix_For200PixDepth, also consistent with manual pixel count
%                                 fprintf('Processing bottom contour of slice %d by simple projection of top contour down by %dum\n', SliceN,DepthToSample_um)
    
if BrokenGlass==1
    JumpExpectedToNextSlice=ceil(Dims(3)/6);%abs(ceil(diff([slices(n+1),slices(n)])/2));
    if (slices(n)+JumpExpectedToNextSlice)>slices(end)%getting past the point of too many slices
        NotEnoughContours={};%[];
                NotEnoughContoursQ=inputdlg(sprintf('Would you like to use more contours?\n Type y or simply press enter for yes otherwise type n for negation\n'),'Enough contours?');
                NotEnoughContours=NotEnoughContoursQ{1};
                if isempty(NotEnoughContours)
                    NotEnoughContours='y';
                end
        if isequal(NotEnoughContours,'y')
            %Adding slices to contour
            %shifting all slices previously decided upon up an index since we are now introducing an extra contouring step
            for numofSliceRemaining=num_contoured_slices:-1:n+1
                slices(numofSliceRemaining+1)=slices(numofSliceRemaining);
            end
            num_contoured_slices=num_contoured_slices+1;
            slices(n+1)=slices(n)+JumpExpectedToNextSlice;
        else
            slices=slices(1:n);
            num_contoured_slices=length(slices);%end it
        end
    else%Not yet at the point of too many slices
            %Adding slices to contour --> no questions asked
            %shifting all slices previously decided upon up an index since we are now introducing an extra contouring step
            for numofSliceRemaining=num_contoured_slices:-1:n+1
                slices(numofSliceRemaining+1)=slices(numofSliceRemaining);
            end
            num_contoured_slices=num_contoured_slices+1;
            slices(n+1)=slices(n)+JumpExpectedToNextSlice;%diff([slices(n+1),slices(n)])/2;
    end
end

    end
        %% Saving traces
                save(SaveFilenameDataWindowTraceTop,'zline_GlassTrace_TopSurf','-v7.3');
                save(SaveFilenameDataWindowTraceBot,'zline_GlassTrace_BotSurf','-v7.3');
mask_3D_NoGlass=[];
    elseif autoLineDector==1
           %glassAutoExcluderv4(Raw_stOCT,GlassThickness_200PixDepth,ReferencePixDepth,DataCroppedNotResizedInDepth,savefilepath,OS_removal) 
    end
end
% end
if  AutoProcess==1%Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1 ||
    load(SaveFilenameDataWindowTraceTop)
    load(SaveFilenameDataWindowTraceBot)
end

% if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2
    %% Creating no glass mask interpolating across contours drawn in previous steps
    %% From Top surface of glass
    mask_3D_GlassInc=ones([Dims]);
    %Interpolating just over the drawn top surface
    GlassMaskTopSurface=zeros(size(mask_3D_GlassInc,2),size(mask_3D_GlassInc,3));
        for n=1:num_contoured_slices-1
            slopeyz_perXSlice{n}=-diff([zline_GlassTrace_TopSurf{n+1};zline_GlassTrace_TopSurf{n}],1,1)/(slices(n+1)-slices(n));%positive slope means later y slices are lower
            Interceptyz_perXSlice{n}=zline_GlassTrace_TopSurf{n}-slopeyz_perXSlice{n}*slices(n);%Do not transpose by zline_GlassTrace_TopSurf{1}(:)
                    if n==1 && num_contoured_slices==2 %First pair of points for contour based on 2 slices
                        rangey=1:size(mask_3D_GlassInc,3); 
                    elseif n==1 && num_contoured_slices>2 %First pair of points for contour based on >2 slices
                        rangey=1:slices(n+1);%1:floor(user_roi.Position(indx+1,1));
                    elseif n==(num_contoured_slices-1)
                        rangey=slices(n):size(mask_3D_GlassInc,3);%ceil(user_roi.Position(indx,1)):size(tempst,2);
                    else%in between if 4 or more vertices
                        rangey=(slices(n):slices(n+1));%floor(user_roi.Position(indx,1)):ceil(user_roi.Position(indx+1,1));
                    end
                        for x=1:size(mask_3D_GlassInc,2)%taking step by step along x drawing top of yz slice
                            GlassMaskTopSurface(x,rangey)=slopeyz_perXSlice{n}(x)*[rangey]+Interceptyz_perXSlice{n}(x);%=slopeyz_perXSlice(x)*[1:size(mask_3D_GlassInc,3)]+Interceptyz_perXSlice(x);
                        end
                        %Since no longer going from first to last frame (sampling at 1 and 1/2frames (maybe later 1/3 and 2/3) as they might be the cleanest %GlassMaskTopSurface(x,(slices(n):slices(n+1)))=linspace(zline_GlassTrace_TopSurf{n}(x),zline_GlassTrace_TopSurf{n+1}(x),(slices(n+1)-slices(n)+1));
        end

        for y=1:size(mask_3D_GlassInc,3)%along its y dimension just called z as it is the 3rd dimension being added
            for x=1:size(mask_3D_GlassInc,2)
                    z= 1;%size(mask_3DTempTop,1);%Where it starts search(very top of B-scan)
                while z<GlassMaskTopSurface(x,y) %(everythinfg below line is 1)
                    mask_3D_GlassInc(z,x,y)=0;%corrected%note that usually z,x,y here just labelled for consistence with 2D and then adding a dimension
                    z=z+1;
                end
            end
        end
        
        mask_3D_GlassInc=cast(mask_3D_GlassInc,'uint16');
        save(SaveFilenameData3DMaskGlassInc,'mask_3D_GlassInc','-v7.3');
        
    %% From bottom surface Of Glass
     mask_3D_NoGlass=ones([Dims]);
    %Interpolating just over the drawn top surface glass shifted down
    GlassMaskBotSurface=zeros(size(mask_3D_NoGlass,2),size(mask_3D_NoGlass,3));
        for n=1:num_contoured_slices-1
            slopeyz_perXSlice{n}=-diff([zline_GlassTrace_BotSurf{n+1};zline_GlassTrace_BotSurf{n}],1,1)/(slices(n+1)-slices(n));%positive slope means later y slices are lower
            Interceptyz_perXSlice{n}=zline_GlassTrace_BotSurf{n}-slopeyz_perXSlice{n}*slices(n);%Do not transpose by zline_GlassTrace_BotSurf{1}(:)
                    if n==1 && num_contoured_slices==2
                        rangey=1:size(mask_3D_NoGlass,3);
                    elseif n==1 && num_contoured_slices>2
                        rangey=1:slices(n+1);%1:floor(user_roi.Position(indx+1,1));
                    elseif n==(num_contoured_slices-1)
                        rangey=slices(n):size(mask_3D_NoGlass,3);%ceil(user_roi.Position(indx,1)):size(tempst,2);
                    else%in between if 4 or more vertices
                        rangey=(slices(n):slices(n+1));%floor(user_roi.Position(indx,1)):ceil(user_roi.Position(indx+1,1));
                    end
                        for x=1:size(mask_3D_NoGlass,2)%taking step by step along x drawing top of yz slice
                            GlassMaskBotSurface(x,rangey)=slopeyz_perXSlice{n}(x)*[rangey]+Interceptyz_perXSlice{n}(x);%=slopeyz_perXSlice(x)*[1:size(mask_3D_GlassInc,3)]+Interceptyz_perXSlice(x);
                        end
                        %Since no longer going from first to last frame (sampling at 1 and 1/2frames (maybe later 1/3 and 2/3) as they might be the cleanest %GlassMaskBotSurface(x,(slices(n):slices(n+1)))=linspace(zline_GlassTrace_BotSurf{n}(x),zline_GlassTrace_BotSurf{n+1}(x),(slices(n+1)-slices(n)+1));
        end

        for y=1:size(mask_3D_NoGlass,3)%along its y dimension just called z as it is the 3rd dimension being added
            for x=1:size(mask_3D_NoGlass,2)
                    z= 1;%size(mask_3DTempTop,1);%Where it starts search(very top of B-scan)
                while z<GlassMaskBotSurface(x,y) %(everythinfg below line is 1)
                    mask_3D_NoGlass(z,x,y)=0;%corrected%note that usually z,x,y here just labelled for consistence with 2D and then adding a dimension
                    z=z+1;
                end
            end
        end

     mask_3D_NoGlass = cast(mask_3D_NoGlass,'uint16');
     save(SaveFilenameData3DMaskGlassExc,'mask_3D_NoGlass','-v7.3');
% end     
end