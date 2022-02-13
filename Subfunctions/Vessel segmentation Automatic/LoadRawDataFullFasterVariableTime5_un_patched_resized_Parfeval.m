function [F_SubStack_Re,F_SubStack_Im,DimsDataFull_pixUsed,DimsDataPatch_pixUsed]=LoadRawDataFullFasterVariableTime5_un_patched_resized_Parfeval(BatchOfFolders,DataFolderInd,folder1,folder2,files1Cont,files2Cont, DimsDataPatchRaw_pix,DimsDataFull_pix,TimeRepsToUse)%,Patching)
%%by Nader A.
% Patching 0 --Loads single large volume all at once
% Patching 1 --Loads split volume (patch) once per for loop
% round--depending on PatchToLoad (the number)
% Patching 2 --Loads split volume all at once (in patches)--Nevermind it
% will be Patching 1 but just when unrequested
%% Load data into 4D complex spatio-temporal data stacks and extract dimensions
%for DataFolderInd=1:NumberFilesToProcess%(length(BatchOfFolders)-1)%skip last that has no data
   
        %% Opening raw data files           
                folderr=BatchOfFolders{DataFolderInd};%[BatchOfFolders{DataFolderInd}, '\'];
        cd (folderr);
    
        depth_image=DimsDataPatchRaw_pix(1);
        Widthx=DimsDataPatchRaw_pix(2);
        BscansPerY=DimsDataPatchRaw_pix(3);
        Lengthy=DimsDataPatchRaw_pix(4);
        
        delete(gcp('nocreate'))
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Loading Real data full
        %          h = waitbar(0,'Working...');
        numStacks=length(files1Cont)-1;
        %SubStack_Re=cell(numStacks,1);
        p=parpool(numStacks);%3 workers if 3 stacks
        %Instantiating the future instances to be placed in parallel processing
        %queue
        F_SubStack_Re(1:numStacks)=parallel.FevalFuture;
        F_SubStack_Im(1:numStacks)=parallel.FevalFuture;
        %SubStack_Re{1:numStacks}=parallel.FevalFuture;
        %{zeros(depth_image, Widthx, BscansPerY, Lengthy)};
        memory
        for ind1=1:length(files1Cont) %join files1Cont with files2Cont and make single 'for' loop for speed?
            if ~contains(files1Cont{ind1},'bg')
                Gfilename1=fullfile(folder1,files1Cont{ind1});%([folder1 'b0_ch1.dat']); % 1st quadrature
                fprintf('Loading Real data, patch %d/%d \n', ind1,numStacks);%disp(['Loading Real data, file ', ind]);                 
                F_SubStack_Re(ind1)=parfeval(@LoadAndStitchInParallel,1,ind1,Gfilename1,depth_image, Widthx, BscansPerY, Lengthy,TimeRepsToUse,numStacks);
            end
            memory
            if ~contains(files2Cont{ind1},'bg')
                Gfilename2=fullfile(folder2,files2Cont{ind1});%([folder1 'b0_ch1.dat']); % 1st quadrature
                fprintf('Loading Imaginary data, patch %d/%d \n', ind1,numStacks)%                 disp(['Loading Imaginary data, file ', ind]); 
                F_SubStack_Im(ind1)=parfeval(@LoadAndStitchInParallel,1,ind1,Gfilename2,depth_image, Widthx, BscansPerY, Lengthy,TimeRepsToUse,numStacks);
            end%SubStack_Re{ind1}=
            memory
        end
        
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         % Loading Imaginary data
%         F_SubStack_Im(1:numStacks)=parallel.FevalFuture;
%         %SubStack_Im{1:numStacks}=parallel.FevalFuture;
%         %SubStack_Im=cell(numStacks,1);
%         for ind2=1:length(files2Cont)
%             if ~contains(files2Cont{ind2},'bg')
%                 Gfilename2=fullfile(folder2,files2Cont{ind2});%([folder1 'b0_ch1.dat']); % 1st quadrature
%                 fprintf('Loading Imaginary data, file %d\n', ind2)%                 disp(['Loading Imaginary data, file ', ind]); 
%                 F_SubStack_Im(ind2)=parfeval(@LoadAndStitchInParallel,1,ind2,Gfilename2,depth_image, Widthx, BscansPerY, Lengthy,TimeRepsToUse,numStacks);
%             end%SubStack_Im{ind2}=
%         end
%         
        %     updateWaitbar = @(~) waitbar(mean([{f.State},{g.State}] == "finished"),h);
        % updateWaitbarFutures = afterEach([f,g],updateWaitbar,0);
        %     afterAll(updateWaitbarFutures,@(~) delete(h),0);

%         if Patching==0 || Patching==2
%         
%                 Im1=sqrt(-1);
%             fprintf('Creating the %d patches of complex data matrices.\n',numStacks)    
%             %Full_stack_ReIm=cell(numStacks,1);
%             Patch_stack_Re=cell(numStacks,1);
%             Patch_stack_Im=cell(numStacks,1);
% 
%                 for ind3=1:numStacks
%                     [idxFetchedRe,RealP]=fetchNext(F_SubStack_Re);%{ind3});%SubStack_Re{numStacks-ind+1});
%                     [idxFetchedIm,ImaginaryP]=fetchNext(F_SubStack_Im);%{ind3});%idxFetchedIm first element
%                     Patch_stack_Re{idxFetchedRe}=imresize(single(RealP),DimsDataFull_pix(1),[DimsDataFull_pix(2),DimsDataFull_pix(1),DimsDataFull_pix(4)/2]);%not necessairly in right order
%                     Patch_stack_Im{idxFetchedIm}=imresize(single(ImaginaryP),[DimsDataFull_pix(2),DimsDataFull_pix(1),DimsDataFull_pix(4)/2]);
%                     fprintf('Completing patch %d/%d \n', ind3,numStacks)
%                 end
%                 if Patching==0
%                     fprintf('Stitching together complex data') 
%                         Full_stack_ReIm=[Patch_stack_Re{end:-1:1}]+Im1*[Patch_stack_Im{end:-1:1}];%[Full_stack_ReIm{end:-1:1}];%single(double(Patch_stack_Re(:,:,1:TimeRepsToUse,:))+sqrt(-1)*double(Patch_stack_Im(:,:,1:TimeRepsToUse,:)));
%                         DimsDataPatch_pixUsed=size(Full_stack_ReIm);
%                 elseif Patching==2
%                     fprintf('Keeping as separate complex data patches for memory efficiency.\n')
%                         Full_stack_ReIm_patched=cell(numStacks,1);
%                         for ind4=1:numStacks
%                             Full_stack_ReIm_patched{ind4}=Patch_stack_Re{ind4}+Im1*Patch_stack_Im{ind4};
%                         end
%                 end
%         elseif Patching==1
%             Full_stack_ReIm_patched=F_SubStack_Re;
%         end
%         Full_stack_ReIm_patched=[Patch_stack_Re{end:-1:1}]+Im1*[Patch_stack_Im{end:-1:1}];%[Full_stack_ReIm{end:-1:1}];%single(double(Patch_stack_Re(:,:,1:TimeRepsToUse,:))+sqrt(-1)*double(Patch_stack_Im(:,:,1:TimeRepsToUse,:)));
     DimsDataFull_pixUsed=[DimsDataFull_pix(1),DimsDataFull_pix(2),TimeRepsToUse,DimsDataFull_pix(4)];
    DimsDataPatch_pixUsed=repmat(DimsDataFull_pixUsed,numStacks,1);%To initialize%zeros(numStacks,4);  
      %WidthsPatchesForStitching=zeros(numStacks,1);  
        for ind=1:numStacks
            if ind==1
                DimsDataPatch_pixUsed(ind,2)=length((1:(Widthx-12))); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
            elseif ind==numStacks%length(LinearData_Re)
                DimsDataPatch_pixUsed(ind,2)=length((13:Widthx)); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
            else%middle
                DimsDataPatch_pixUsed(ind,2)=length((13:(Widthx-12))); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
            end
        end
%         DimsDataPatch_pixUsed=size(Full_stack_ReIm_patched);
%         %% REAL 
%         %Reshaping REAL
%             %Stack1_Re=reshape(dil1_1, [], Widthx, BscansPerY, Lengthy);%reshape(dil1_1, 500, 400, 8, 1600);
%             %clearvars ('dil1_1');
%         % Merging together
%         Main_stack_Re=zeros(DimsDataFull_pix,'single');%,'int16');%12 from right and 12 from left as explaned below
%         for ind=1:length(LinearData_Re)%ind=length(LinearData_Re):-1:1
%             SubStack_Re{ind}=reshape(LinearData_Re{length(LinearData_Re)-ind+1},depth_image, Widthx, BscansPerY, Lengthy);
%                             fprintf('Stitching real patch %d/%d \n', ind,length(LinearData_Re))
%             if ind==1
%                 Main_stack_Re(1:depth_image,(1:(Widthx-12)),:,:)=SubStack_Re{ind}(1:depth_image,(1:(Widthx-12)),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             elseif ind==length(LinearData_Re)
%                 Main_stack_Re(1:depth_image,(((ind-1)*(Widthx-12)+(ind-2)*(-12))+(1:(Widthx-12))),:,:)=SubStack_Re{ind}(1:depth_image,(13:Widthx),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             else%middle
%                 Main_stack_Re(1:depth_image,(((ind-1)*(Widthx-12))+(1:(Widthx-2*12))),:,:)=SubStack_Re{ind}(1:depth_image,(13:(Widthx-12)),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             end
%         end
% 
%         clearvars SubStack_Re
%         %% IMAGINARY
%         Main_stack_Im=zeros(DimsDataFull_pix,'single');%'int16');%12 from right and 12 from left as explaned below
%         SubStack_Im={zeros(depth_image, Widthx, BscansPerY, Lengthy)};
%         for ind=1:length(LinearData_Im)%length(LinearData_Im):-1:1
%             SubStack_Im{ind}=reshape(LinearData_Im{length(LinearData_Im)-ind+1},depth_image, Widthx, BscansPerY, Lengthy);
%             fprintf('Stitching imaginary patch %d/%d \n', ind,length(LinearData_Im))
%             if ind==1 
%                 Main_stack_Im(1:depth_image,(1:(Widthx-12)),:,:)=SubStack_Im{ind}(1:depth_image,(1:(Widthx-12)),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             elseif ind==length(LinearData_Im)
%                 Main_stack_Im(1:depth_image,(((ind-1)*(Widthx-12)+(ind-2)*(-12))+(1:(Widthx-12))),:,:)=SubStack_Im{ind}(1:depth_image,(13:Widthx),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             else
%                 Main_stack_Im(1:depth_image,((ind-1)*(Widthx-12))+(1:(Widthx-2*12)),:,:)=SubStack_Im{ind}(1:depth_image,(13:(Widthx-12)),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             end
%         end
%         
%         clearvars SubStack_Im
        %% REAL 
%             SubStack_Re=reshape(LinearData_Re,depth_image, Widthx, BscansPerY, Lengthy);
%             if PatchCount==1 
%                 Patch_stack_Re=SubStack_Re(1:depth_image,(1:(Widthx-12)),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             elseif PatchCount==Patches
%                 Patch_stack_Re=SubStack_Re(1:depth_image,(13:Widthx),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             else
%                 Patch_stack_Re=SubStack_Re(1:depth_image,(13:(Widthx-12)),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             end
        

%         clearvars SubStack_Re
        %% IMAGINARY
%             SubStack_Im=reshape(LinearData_Im,depth_image, Widthx, BscansPerY, Lengthy);
%             if PatchCount==1 
%                 Patch_stack_Im=SubStack_Im(1:depth_image,(1:(Widthx-12)),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             elseif PatchCount==Patches
%                 Patch_stack_Im=SubStack_Im(1:depth_image,(13:Widthx),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             else
%                 Patch_stack_Im=SubStack_Im(1:depth_image,(13:(Widthx-12)),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             end
%         
%         Patch_stack_ReIm=single(double(Patch_stack_Re)+sqrt(-1)*double(Patch_stack_Im));
%         clearvars SubStack_Im
%         DimsDataPatch_pix=size(Patch_stack_Re);
%         
%         if PatchCount ==1
%             tabulatedDims_pix=table(depth_image,WidthVolFull,BscansPerY,Lengthy);
%             tabulatedDims_um=table(DimsDataFull_um(1),DimsDataFull_um(2),DimsDataFull_um(3),'VariableNames',{'Depth_um','Widthx_um','Lengthy_um'});
%             save(fullfile(FolderToCreateCheck,'DimensionsOfVolData_pix.mat'),'tabulatedDims_pix','-v7.3');
%             save(fullfile(FolderToCreateCheck,'DimensionsOfVolData_um.mat'),'tabulatedDims_um','-v7.3');
%         end
%         StructFile=dir(fullfile(BatchOfFolders{DataFolderInd},'**','st3D_uint16.mat'))
%         if ~isempty(StructFile) && (contains(StructFile.folder,'Improved')||contains(StructFile.folder,'IDBISIM'))
%             load(fullfile(StructFile.folder,StructFile.name))
%         else
%             Structure=zeros(depth_image,WidthVol,Lengthy,'single');%zeros(400,800,1600,'single');
%             Im1=sqrt(-1);
%                 parfor frame=1:size(Main_stack_Im,4)%all 8 b-scans
%                     Frame_data=mean(abs(double(Main_stack_Re(:,:,:,frame))+Im1*(double(Main_stack_Im(:,:,:,frame)))),3);
%                     temp=imresize(Frame_data,[depth_image WidthVol]);
%                     [temp_sat, normalizationFactor(frame),~,~,~]=removeOversaturation2(temp,OSremoval);%Normalization and remove oversaturated pixels 
%                     Structure(:,:,frame)=temp_sat(:,:);
%                 end
%                 save([savefolder_f 'st3D_uint16.mat'],'Structure','-v7.3');
%                 save([savefolder_f 'normalizationFactorPerFrame.mat'],'normalizationFactor','-v7.3');
%         end
        % % Reshaping IMAGINARY
        % Stack1_Im=reshape(dil1_2, [], Widthx, BscansPerY, Lengthy);%reshape(dil1_2, 500, 400, 8, 1600);
        % 
        % clearvars ('dil1_2');
        % % Merging together
        % Main_stack_Im=zeros(depth_image,size(Stack1_Im,2),size(Stack1_Im,3),size(Stack1_Im,4),'int16');
        % Main_stack_Im(1:depth_image,:,:,:)=Stack1_Im(1:depth_image,:,:,:);
        % clearvars Stack1_Im
    end
