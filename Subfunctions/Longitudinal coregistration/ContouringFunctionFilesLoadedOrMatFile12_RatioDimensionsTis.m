function mask_3D_TissueOnly=ContouringFunctionFilesLoadedOrMatFile12_RatioDimensionsTis(DimsVesselsRaw3D,num_contoured_slices,MouseTimepoint,BatchOfFolders,countBatchFolder,SaveFilenameDataTissueTraceTop,SaveFilenameDataTissueTraceBot,SaveFilenameData3DMaskTissueAndAllBelow,SaveFilenameData3DMaskTissueOnly,saveFolder,FolderConsideredSaveDraft,LoadOrMatfile,AutoProcess,OSremoval,Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2)%,umPerPix_For200PixDepth)
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

%% Contour out the tissue interface in stOCT volume (but only timepoint 0 due to uncertainty with exudate over time) and assuming the same contour over time
if isempty(BatchOfFolders{countBatchFolder,2})%no binarized vessels
    OCTAVarname=whos('-file',BatchOfFolders{countBatchFolder,1});
        OCTAVarnameF=OCTAVarname.name;
            if isequal(LoadOrMatfile,'Matfile')
                OCTA=matfile(BatchOfFolders{countBatchFolder,1});
                stOCT=matfile(BatchOfFolders{countBatchFolder,3});
            elseif isequal(LoadOrMatfile,'Load')
                OCTA=load(BatchOfFolders{countBatchFolder,1});
                stOCT=load(BatchOfFolders{countBatchFolder,3});
            end
else
    OCTAVarname=whos('-file',BatchOfFolders{countBatchFolder,2});
        OCTAVarnameF=OCTAVarname.name;
            if isequal(LoadOrMatfile,'Matfile')
                OCTA=matfile(BatchOfFolders{countBatchFolder,2});
                stOCT=matfile(BatchOfFolders{countBatchFolder,3});
            elseif isequal(LoadOrMatfile,'Load')
                OCTA=load(BatchOfFolders{countBatchFolder,2});
                stOCT=load(BatchOfFolders{countBatchFolder,3});
            end
end
    stOCTVarname=whos('-file',BatchOfFolders{countBatchFolder,3});
        stOCTVarnameF=stOCTVarname.name;
    
    

Dims=size(stOCT.(stOCTVarnameF));
DimsVessels=size(OCTA.(OCTAVarnameF));
RatioScales=DimsVessels(3)/Dims(3);
% if glass_1_Tissue_2_contour==2
    zline_TissueTrace_TopSurf=cell(num_contoured_slices,1);
    zline_TissueTrace_BotSurf=zline_TissueTrace_TopSurf;
    slices=round(linspace(1,round(Dims(3)),num_contoured_slices))%Dims(3)
        n=0;%slice count
%         n_bot=0;%since sometimes skip
%         changeStruct=[];%Initialized since if later decide to set Oversaturation removal to 0 needs to remain for all later B-scans
%% Running contouring
if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==0 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2 
if AutoProcess==0
    while n<num_contoured_slices%for n=1:num_contoured_slices % For loop does not work if I am tyring to extend the limit-- test example:for x=1:y
n=n+1;
        SliceN=slices(n);

        %if isequal(LoadOrMatfile,'Matfile')
             tempst=removeOversaturation4(squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN)),OSremoval);
            tempsv=squeeze(OCTA.(OCTAVarnameF)(:,:,ceil(SliceN*RatioScales)));
            tempsvEnFace=imrotate(squeeze(sum(OCTA.(OCTAVarnameF),1)),-90);
        %elseif isequal(LoadOrMatfile,'Load')
%              tempst=removeOversaturation4(squeeze(stOCT(:,:,SliceN)),OSremoval);
%             tempsv=squeeze(OCTA.(OCTAVarnameF)(:,:,ceil(SliceN*RatioScales)));
%             tempsvEnFace=squeeze(sum(OCTA.(OCTAVarnameF),1));
%         end
        

        Goodtogo='n';
        attempt=0;
        while Goodtogo=='n'
            %% Visualization + B-scan to label
            figure('Units','characters','Position',[1 1 120 50]);
                t = tiledlayout(4,7);
                    nexttile(1,[2,3])%[2,3]
                        hImTop=imagesc(tempsvEnFace);
                            hold on
                            plot([0 Dims(2)], [ceil(SliceN*RatioScales) ceil(SliceN*RatioScales)],'Color','r','LineWidth',2)
                            hold off
                        title(sprintf('OCTA en-face view positioning'))    
                    nexttile(15,[2,3])%[2,3]
                            hSvRawvsSvBin=imshowpair(tempst,tempsv);
                        title(sprintf('stOCT vs OCTA slice = %d\n%s',SliceN,fileparts(fileparts(saveFolder))))
                    nexttile(4,[4,4])
                            hIm=imagesc(tempst)%imagesc(refIm);
                            colormap(gray)
                        title(sprintf('Contour top surface of Tissue on stOCT slice = %d.\n Simply enter as many points as needed and the edges will be extrapolated.\n If unhappy with view, press Esc for more options.',SliceN))
                        
                  title(t,MouseTimepoint)%fileparts(fileparts(saveFolder)))%fileparts(fileparts(SaveFilenameData500um))))
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
                   if attempt==0
                       if exist(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',SliceN)))     
                           load(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',SliceN)))
                           user_roi = drawpolyline('Position',[LastDrawn],'InteractionsAllowed','all');
                       elseif exist(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',slices(n-1))))%based on previous slice
                           load(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',slices(n-1))))
                           user_roi = drawpolyline('Position',[LastDrawn],'InteractionsAllowed','all');
                       else
                           user_roi = drawpolyline;
                       end
                   
                   else
                       
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
                       elseif isequal(UsePrev,'y') && exist(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',slices(n-1))))%based on previous slice
                           load(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',slices(n-1))))
                           user_roi = drawpolyline('Position',[LastDrawn],'InteractionsAllowed','all');
                       else
                           user_roi = drawpolyline;
                       end
                   end
               end
                Goodtogo={};   
                opts.WindowStyle='normal'
                       GoodtogoQ=inputdlg(sprintf('Good to go?\n n or type literally anything else or just press enter for yes\n'),'Tissue trace',[1,50],{''},opts);
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
                        if isequal(LoadOrMatfile,'Matfile')
                            tempst=removeOversaturation4(squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN)),OSremoval);
                        elseif isequal(LoadOrMatfile,'Load')
                            tempst=removeOversaturation4(squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN)),OSremoval);
                        end
                        changeStructCond='y';
                        break;
                    elseif (0<=changeStruct && changeStruct<1)
                        OSremoval=changeStruct;
                        if isequal(LoadOrMatfile,'Matfile')
                            tempst=removeOversaturation4(squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN)),OSremoval);
                        elseif isequal(LoadOrMatfile,'Load')
                            tempst=removeOversaturation4(squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN)),OSremoval);
                        end
                        changeStructCond='y';
                    elseif changeStruct>=1
                        if changeStruct>Dims(3) || changeStruct<slices(n)
                            changeStructCond='n';
                        else
                            SliceN=changeStruct;
                            slices(n)=changeStruct;
                                if isequal(LoadOrMatfile,'Matfile')
                                    tempst=removeOversaturation4(squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN)),OSremoval);
                                elseif isequal(LoadOrMatfile,'Load')
                                    tempst=removeOversaturation4(squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN)),OSremoval);
                                end
                            changeStructCond='y';
                        end
%                     elseif changeStruct==0
%                         if isequal(LoadOrMatfile,'Matfile')
%                             tempst=squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN));
%                         elseif isequal(LoadOrMatfile,'Load')
%                             tempst=squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN));
%                         end
%                         changeStructCond='y';
                    end
                    
                   end
                attempt=attempt+1;
                else
                    TraceBottomTissueAsWell{n}='';%[];
                    TraceBottomTissueAsWellQ=inputdlg(sprintf('Trace bottom Tissue interface as well?\n Type n or simply press enter for no otherwise type y for yes\n'),'Bottom Tissue as well?');
                    TraceBottomTissueAsWell{n}=TraceBottomTissueAsWellQ{1};
                    if isempty(TraceBottomTissueAsWell{n})
                        TraceBottomTissueAsWell{n}='n';
                    end
                 
                end       
        end
        %% Saving Drawn top contour and creating 2D Mask for current B-scan 
                                fprintf('Iteration %d of %d\n', n,num_contoured_slices);%gcf
                                saveas(hIm,char(fullfile(FolderConsideredSaveDraft,sprintf('ContouringTissueTopSurf%d.png',SliceN))),'png');
                                mask_1D = createMask(user_roi);%just the hand drawn line on 2D black overlay of image
                                    mask_2D=mask_1D;%zeros(size(temp));
                                        %%filling incomplete parts of line
                                        LastDrawn=user_roi.Position;
                                        save(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Top_slice%d.mat',SliceN)),'LastDrawn');
                                        %fprintf('Saving as default tumour mask for this mouse (which may be altered a bit timepoint to timepoint for consistency)\n');                                                
                                        %save(fullfile(OneTimePointFolder,sprintf('ROI_drawn_Top_slice%d.mat',SliceN)),'LastDrawn');
        %% Performing same steps in case requested by user (or just setting arbitrary contour of bottom based on translation of top contour
                    attempt=0;   
                        if isequal(TraceBottomTissueAsWell{n},'y')
                            Goodtogo2='n';
                            while isequal(Goodtogo2,'n')
                                %% Visualization + B-scan to label
                                    figure('Units','characters','Position',[1 1 120 50]);
                                        t = tiledlayout(4,7);
                                            nexttile(1,[2,3])%[2,3]
                                                hImTop=imagesc(tempsvEnFace);
                                                    hold on
                                                    plot([0 Dims(3)], [ceil(SliceN*RatioScales) ceil(SliceN*RatioScales)],'Color','r','LineWidth',2)
                                                    hold off
                                                title(sprintf('OCTA en-face view positioning'))    
                                            nexttile(15,[2,3])%[2,3]
                                                    hSvRawvsSvBin=imshowpair(tempst,tempsv);
                                                title(sprintf('stOCT vs OCTA slice = %d\n%s',SliceN,fileparts(fileparts(saveFolder))))
                                            nexttile(4,[4,4])
                                                    hIm=imagesc(tempst)%imagesc(refIm);
                                                    colormap(gray)
                                                title(sprintf('Contour bottom surface of Tissue on stOCT slice = %d.\n Simply enter as many points as needed and the edges will be extrapolated.\n If unhappy with view, press Esc for more options.',SliceN))

                                          title(t,MouseTimepoint)%fileparts(fileparts(saveFolder)))%fileparts(fileparts(SaveFilenameData500um))))
                                            set(gcf, 'Position', get(0,'Screensize'));
                                       if n==1 %%initial frame based on previously drawn timepoint
                                           if attempt==0
                                               if exist(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',SliceN)))     
                                                   load(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',SliceN)))
                                                   user_roi2 = drawpolyline('Position',[LastDrawn],'InteractionsAllowed','all');
                                               else
                                                   user_roi2 = drawpolyline;
                                               end
                                               %saving it regardlesss for the first attempt at
                                               %first slice to later fine tune
                                               mask_1D = createMask(user_roi2);%just the hand drawn line on 2D black overlay of image
                                                            mask_2D=mask_1D;%zeros(size(temp));
                                                                %%filling incomplete parts of line
                                                                LastDrawn=user_roi2.Position;
                                                                save(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',SliceN)),'LastDrawn');
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
                                                       if isequal(UsePrev,'y') && exist(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',SliceN)))     
                                                           load(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',SliceN)))
                                                           user_roi2 = drawpolyline('Position',[LastDrawn],'InteractionsAllowed','all');
                                                       elseif isequal(UsePrev,'y') && exist(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',slices(n-1))))%based on previous slice
                                                           load(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',slices(n-1))))
                                                           user_roi2 = drawpolyline('Position',[LastDrawn],'InteractionsAllowed','all'); 
                                                       else
                                                           user_roi2 = drawpolyline;
                                                       end
                                           end
                                       else %for following slices 
                                           if attempt==0
                                               if exist(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',SliceN)))     
                                                   load(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',SliceN)))
                                                   user_roi2 = drawpolyline('Position',[LastDrawn],'InteractionsAllowed','all');
                                               elseif exist(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',slices(n-1))))%based on previous slice
                                                    load(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',slices(n-1))))
                                                    user_roi2 = drawpolyline('Position',[LastDrawn],'InteractionsAllowed','all');
                                               else
                                                    user_roi2 = drawpolyline;
                                               end
                                           else
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
                                               if isequal(UsePrev,'y') && exist(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',SliceN)))     
                                                   load(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',SliceN)))
                                                   user_roi2 = drawpolyline('Position',[LastDrawn],'InteractionsAllowed','all');
                                               elseif isequal(UsePrev,'y') && exist(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',slices(n-1))))%based on previous slice
                                                   load(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',slices(n-1))))
                                                   user_roi2 = drawpolyline('Position',[LastDrawn],'InteractionsAllowed','all');
                                               else
                                                   user_roi2 = drawpolyline;
                                               end
                                           end
                                       end
                                        Goodtogo2={};   
                                        opts.WindowStyle='normal'
                                               Goodtogo2Q=inputdlg(sprintf('Good to go?\n n or type literally anything else or just press enter for yes\n'),'Tissue trace',[1,50],{''},opts);
                                        Goodtogo2=Goodtogo2Q{1};
                                        if isempty(Goodtogo2)
                                            Goodtogo2= 'Y';
                                        end

                                        if isequal(Goodtogo2,'n')||isequal(Goodtogo2,'N')
                                           changeStructCond='n';
                                           changeStruct={};%[];
                                           while isequal(changeStructCond,'n')%~(0<=changeStructCond && changeStructCond<=1) && (isempty(changeStructCond)~=1)
                                            changeStructQ=inputdlg(sprintf('Change settings?\n Simply press enter to leave as is,\n Enter 0 for no oversaturation removal,\n Enter the fraction of Bot intensity to remove,\n Or Enter a number >=1 to select a different frame to contour.'),'How to redo?')
                                            if ~isempty(changeStructQ{1})
                                                changeStruct=str2double(changeStructQ{1});
                                            end
                                            if isempty(changeStructQ{1})
                                                changeStruct=changeStruct;%Just here for reference %it will simply default to whatever it changed to last time
                                            end
                                            if isempty(changeStruct)
%                                                 if isequal(LoadOrMatfile,'Matfile')
                                                    tempst=removeOversaturation4(squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN)),OSremoval);
%                                                 elseif isequal(LoadOrMatfile,'Load')
%                                                     tempst=removeOversaturation4(squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN)),OSremoval);
%                                                 end
                                                changeStructCond='y';
                                                break;
                                            elseif (0<=changeStruct && changeStruct<1)
                                                OSremoval=changeStruct;
%                                                 if isequal(LoadOrMatfile,'Matfile')
                                                    tempst=removeOversaturation4(squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN)),OSremoval);
%                                                 elseif isequal(LoadOrMatfile,'Load')
%                                                     tempst=removeOversaturation4(squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN)),OSremoval);
%                                                 end
                                                changeStructCond='y';
                                            elseif changeStruct>=1
                                                if changeStruct>Dims(3) || changeStruct<slices(n)
                                                    changeStructCond='n';
                                                else
                                                    SliceN=changeStruct;
                                                    slices(n)=changeStruct;
%                                                         if isequal(LoadOrMatfile,'Matfile')
                                                            tempst=removeOversaturation4(squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN)),OSremoval);
%                                                         elseif isequal(LoadOrMatfile,'Load')
%                                                             tempst=removeOversaturation4(squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN)),OSremoval);
%                                                         end
                                                    changeStructCond='y';
                                                end
                        %                     elseif changeStruct==0
                        %                         if isequal(LoadOrMatfile,'Matfile')
                        %                             tempst=squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN));
                        %                         elseif isequal(LoadOrMatfile,'Load')
                        %                             tempst=squeeze(stOCT.(stOCTVarnameF)(:,:,SliceN));
                        %                         end
                        %                         changeStructCond='y';
                                            end

                                           end
                                           attempt=attempt+1;
                                        end
                                    
                            end
                                %% Saving Drawn Bot contour and creating 2D Mask for current B-scan 
                                fprintf('Iteration %d of %d\n', n,num_contoured_slices);%gcf
                                saveas(hIm,char(fullfile(FolderConsideredSaveDraft,sprintf('ContouringTissueBotSurf%d.png',SliceN))),'png');
                                mask_1D = createMask(user_roi2);%just the hand drawn line on 2D black overlay of image
                                    mask_2D=mask_1D;%zeros(size(temp));
                                        %%filling incomplete parts of line
                                        LastDrawn=user_roi2.Position;
                                        save(fullfile(FolderConsideredSaveDraft,sprintf('ROI_drawn_Bot_slice%d.mat',SliceN)),'LastDrawn');
                                        %fprintf('Saving as default tumour mask for this mouse (which may be altered a bit timepoint to timepoint for consistency)\n');                                                
                                        %save(fullfile(OneTimePointFolder,sprintf('ROI_drawn_Bot_slice%d.mat',SliceN)),'LastDrawn');
                       else
                           fid = fopen(fullfile(FolderConsideredSaveDraft,'BottomNotClear.txt'), 'wt');
                            fprintf(fid, 'The bottom of the tissue is not visible in stOCT (due to current processing or simply as a result of depth >2.2mm');%sprintf('',strrep(d(i).date,':','_'))%'Jake said: %f\n', sqrt(1:10));
                            fclose(fid);
                       end
%% Extrapolate Tissue interface (when cannot see full interface (low backscatter)
        %% top
         if ceil(user_roi.Position(end,1))<1
             user_roi.Position(1,1)=1;
         end
            zlineTop(1:ceil(user_roi.Position(1,1)))=user_roi.Position(1,2);
         if ceil(user_roi.Position(end,1))>size(tempst,2)
             user_roi.Position(end,1)=size(tempst,2)-1;
         end
         
         zlineTop((ceil(user_roi.Position(end,1))+1):size(tempst,2))=user_roi.Position(end,2);
        slopeTop=zeros(size(user_roi.Position,1)-1,1);
        InterceptTopTissue=zeros(size(user_roi.Position,1)-1,1);
        if size(user_roi.Position,1)>=4
            for indx=1:(size(user_roi.Position,1)-1)      
                slopeTop(indx)=(user_roi.Position(indx+1,2)-user_roi.Position(indx,2))/(user_roi.Position(indx+1,1)-user_roi.Position(indx,1));
                InterceptTopTissue(indx)=user_roi.Position(indx,2)-slopeTop(indx)*user_roi.Position(indx,1);

                %in between if 4 or more vertices
                    rangex=(ceil(user_roi.Position(indx,1))+1):ceil(user_roi.Position(indx+1,1));%floor(user_roi.Position(indx,1)):ceil(user_roi.Position(indx+1,1));

                zlineTop(rangex)=slopeTop(indx)*[rangex]+InterceptTopTissue(indx);
            end
        end 
        
    if isequal(TraceBottomTissueAsWell{n},'y')
        %% bottom if applicable
        if ceil(user_roi2.Position(end,1))<1
             user_roi2.Position(1,1)=1;
         end
            zlineBot(1:ceil(user_roi2.Position(1,1)))=user_roi2.Position(1,2);
         if ceil(user_roi2.Position(end,1))>size(tempst,2)
             user_roi2.Position(end,1)=size(tempst,2)-1;
         end
            zlineBot((ceil(user_roi2.Position(end,1))+1):size(tempst,2))=user_roi2.Position(end,2);
        slopeBot=zeros(size(user_roi2.Position,1)-1,1);
        InterceptBotTissue=zeros(size(user_roi2.Position,1)-1,1);
        if size(user_roi.Position,1)>=4
            for indx=1:(size(user_roi2.Position,1)-1)
                slopeBot(indx)=(user_roi2.Position(indx+1,2)-user_roi2.Position(indx,2))/(user_roi2.Position(indx+1,1)-user_roi2.Position(indx,1));
                InterceptBotTissue(indx)=user_roi2.Position(indx,2)-slopeBot(indx)*user_roi2.Position(indx,1);

                %in between if 4 or more vertices
                    rangex=(ceil(user_roi2.Position(indx,1))+1):ceil(user_roi2.Position(indx+1,1));%floor(user_roi2.Position(indx,1)):ceil(user_roi2.Position(indx+1,1));

                zlineBot(rangex)=slopeBot(indx)*[rangex]+InterceptBotTissue(indx);
            end
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

    %% Saving traces
        zline_TissueTrace_TopSurf{n}=zlineTop;
            save(SaveFilenameDataTissueTraceTop,'zline_TissueTrace_TopSurf','-v7.3');
            zlineTop=[];
        if sum([TraceBottomTissueAsWell{:}]=='y')>0%isequal(TraceBottomTissueAsWell,'y')
            zline_TissueTrace_BotSurf{n}=zlineBot;%average width of DSWC glass ~0.19mm and converted via umPerPix_For200PixDepth, also consistent with manual pixel count 
                save(SaveFilenameDataTissueTraceBot,'zline_TissueTrace_BotSurf','-v7.3');
                zlineBot=[];
        end
    end
end
mask_3D_TissueOnly=[];%Set as empty output in case no further mask 3D creation will be performed
end

if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1 || AutoProcess==1
    load(SaveFilenameDataTissueTraceTop)
    if exist(SaveFilenameDataTissueTraceBot,'file')
        load(SaveFilenameDataTissueTraceBot)
    end
end

if Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==1 || Mask2DandMetsOnly_0_OR_Mask3DOnlyAfter_1_OR_AllAtOnce_2==2
    %% Creating no glass mask interpolating across contours drawn in previous steps
    %% From Top surface of glass
    mask_3D_TissueAndAllBelow=ones([Dims]);
    %Interpolating just over the drawn top surface
    TissueMaskTopSurface=zeros(size(mask_3D_TissueAndAllBelow,2),size(mask_3D_TissueAndAllBelow,3));
        for n=1:num_contoured_slices-1
            slopeyz_perXSlice{n}=-diff([zline_TissueTrace_TopSurf{n+1};zline_TissueTrace_TopSurf{n}],1,1)/(slices(n+1)-slices(n));%positive slope means later y slices are lower
            Interceptyz_perXSlice{n}=zline_TissueTrace_TopSurf{n}-slopeyz_perXSlice{n}*slices(n);%Do not transpose by zline_GlassTrace_TopSurf{1}(:)
                    if n==1 && num_contoured_slices==2
                        rangey=1:size(mask_3D_TissueAndAllBelow,3);
                    elseif n==1 && num_contoured_slices>2
                        rangey=1:slices(n+1);%1:floor(user_roi.Position(indx+1,1));
                    elseif n==(num_contoured_slices-1)
                        rangey=slices(n):size(mask_3D_TissueAndAllBelow,3);%ceil(user_roi.Position(indx,1)):size(tempst,2);
                    else%in between if 4 or more vertices
                        rangey=(slices(n):slices(n+1));%floor(user_roi.Position(indx,1)):ceil(user_roi.Position(indx+1,1));
                    end
                        for x=1:size(mask_3D_TissueAndAllBelow,2)%taking step by step along x drawing top of yz slice
                            TissueMaskTopSurface(x,rangey)=slopeyz_perXSlice{n}(x)*[rangey]+Interceptyz_perXSlice{n}(x);%=slopeyz_perXSlice(x)*[1:size(mask_3D_GlassInc,3)]+Interceptyz_perXSlice(x);
                        end
                        %Since no longer going from first to last frame (sampling at 1 and 1/2frames (maybe later 1/3 and 2/3) as they might be the cleanest %GlassMaskTopSurface(x,(slices(n):slices(n+1)))=linspace(zline_GlassTrace_TopSurf{n}(x),zline_GlassTrace_TopSurf{n+1}(x),(slices(n+1)-slices(n)+1));
        end

        for y=1:size(mask_3D_TissueAndAllBelow,3)%along its y dimension just called z as it is the 3rd dimension being added
            for x=1:size(mask_3D_TissueAndAllBelow,2)
                    z= 1;%size(mask_3DTempTop,1);%Where it starts search(very top of B-scan)
                while z<TissueMaskTopSurface(x,y) %(everythinfg below line is 1)
                    mask_3D_TissueAndAllBelow(z,x,y)=0;%corrected%note that usually z,x,y here just labelled for consistence with 2D and then adding a dimension
                    z=z+1;
                end
            end
        end
        
        mask_3D_TissueAndAllBelow=imresize3(cast(mask_3D_TissueAndAllBelow,'uint16'),DimsVesselsRaw3D);
        save(SaveFilenameData3DMaskTissueAndAllBelow,'mask_3D_TissueAndAllBelow','-v7.3');
        
    %% From bottom surface Of Glass
if exist('zline_TissueTrace_BotSurf','var') && ~isempty([zline_TissueTrace_BotSurf{:}])
    mask_3D_TissueOnly=ones([Dims]);
    %Interpolating just over the drawn top surface glass shifted down
    TissueMaskBotSurface=zeros(size(mask_3D_TissueOnly,2),size(mask_3D_TissueOnly,3));
        %IncIndices=[];
        slices_bot=[];
        IncIndicesC=0;
        zline_TissueTrace_BotSurfSkip={};
        for n=1:num_contoured_slices-1
            if ~isempty(zline_TissueTrace_BotSurf{n})%checking what slices were skipped
                IncIndicesC=IncIndicesC+1;
                %IncIndices(IncIndicesC)=n;
                slices_bot(IncIndicesC)=slices(n);
                zline_TissueTrace_BotSurfSkip{IncIndicesC}=zline_TissueTrace_BotSurf{n};
            end
        end
        num_contoured_slices_bot=length(slices_bot);
        
        if num_contoured_slices_bot==1
            num_contoured_slices_bot=num_contoured_slices_bot+1;
            slices_bot(1)=1;
            slices_bot(2)=2;%Flat mask
            %if slices_bot==1%only the first one was traced
                zline_TissueTrace_BotSurfSkip{2}=zline_TissueTrace_BotSurfSkip{1};
        end
        
        if slices_bot(1)~=1
           slices_bot=[1,slices_bot];
           zline_TissueTrace_BotSurfSkip=[zline_TissueTrace_BotSurfSkip{1},zline_TissueTrace_BotSurfSkip];
        end
        if slices_bot(end)~=size(mask_3D_TissueOnly,3)
           slices_bot=[slices_bot,size(mask_3D_TissueOnly,3)];%
           zline_TissueTrace_BotSurfSkip=[zline_TissueTrace_BotSurfSkip,zline_TissueTrace_BotSurfSkip{end}];
        end
                
            
            num_contoured_slices_bot=length(slices_bot);
            
            for n=1:num_contoured_slices_bot-1
    %             if isempty(zline_TissueTrace_BotSurf{n})%checking what slices were skipped
    %                 SkipIndxorNot
                slopeyz_perXSlice{n}=-diff([zline_TissueTrace_BotSurfSkip{n+1};zline_TissueTrace_BotSurfSkip{n}],1,1)/(slices_bot(n+1)-slices_bot(n));%positive slope means later y slices are lower
                Interceptyz_perXSlice{n}=zline_TissueTrace_BotSurfSkip{n}-slopeyz_perXSlice{n}*slices_bot(n);%Do not transpose by zline_GlassTrace_BotSurf{1}(:)
                        if n==1 && num_contoured_slices_bot==2
                            rangey=1:size(mask_3D_TissueOnly,3);
                        elseif n==1 && num_contoured_slices_bot>2%even if first slice not slice 1
                            rangey=1:slices_bot(n+1);%1:floor(user_roi.Position(indx+1,1));
                        elseif n==(num_contoured_slices_bot-1)
                            rangey=slices_bot(n):size(mask_3D_TissueOnly,3);%ceil(user_roi.Position(indx,1)):size(tempst,2);
                        else%in between if 4 or more vertices (contoured slices)
                            rangey=(slices_bot(n):slices_bot(n+1));%floor(user_roi.Position(indx,1)):ceil(user_roi.Position(indx+1,1));
                        end
                            for x=1:size(mask_3D_TissueOnly,2)%taking step by step along x drawing top of yz slice
                                TissueMaskBotSurface(x,rangey)=slopeyz_perXSlice{n}(x)*[rangey]+Interceptyz_perXSlice{n}(x);%=slopeyz_perXSlice(x)*[1:size(mask_3D_GlassInc,3)]+Interceptyz_perXSlice(x);
                            end
                            %Since no longer going from first to last frame (sampling at 1 and 1/2frames (maybe later 1/3 and 2/3) as they might be the cleanest %GlassMaskBotSurface(x,(slices(n):slices(n+1)))=linspace(zline_GlassTrace_BotSurf{n}(x),zline_GlassTrace_BotSurf{n+1}(x),(slices(n+1)-slices(n)+1));
            end

        for y=1:size(mask_3D_TissueOnly,3)%along its y dimension just called z as it is the 3rd dimension being added
            for x=1:size(mask_3D_TissueOnly,2)
                    z= size(mask_3D_TissueOnly,1);%size(mask_3DTempTop,1);%Where it starts search(very top of B-scan)
                while z>TissueMaskBotSurface(x,y) %(everythinfg below line is 1)
                    mask_3D_TissueOnly(z,x,y)=0;%corrected%note that usually z,x,y here just labelled for consistence with 2D and then adding a dimension
                    z=z-1;
                end
            end
        end

     mask_3D_TissueOnly = imresize3(cast(mask_3D_TissueOnly,'uint16'),DimsVesselsRaw3D) & mask_3D_TissueAndAllBelow;
     save(SaveFilenameData3DMaskTissueOnly,'mask_3D_TissueOnly','-v7.3');
else
    mask_3D_TissueOnly=mask_3D_TissueAndAllBelow;
end
end
end