function [F_SubStack_Re,F_SubStack_Im,DimsDataFull_pixUsed,DimsDataPatch_pixUsed]=LoadRawDataFullFasterVariableTime6_un_patched_resized_Parfeval(BatchOfFolders,DataFolderInd,folder1,folder2,files1Cont,files2Cont, DimsDataPatchRaw_pix,DimsDataFull_pix,TimeRepsToUse,Patching,PatchCount)
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
        
%         delete(gcp('nocreate'))
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Loading Real data full
        %          h = waitbar(0,'Working...');
        numStacksPossible=length(files1Cont)-1;
if Patching==0
    delete(gcp('nocreate'))
        numStacksConsidered=numStacksPossible;%length(files1Cont)-1;
        %SubStack_Re=cell(numStacks,1);
        p=parpool(numStacksConsidered);%3 workers if 3 stacks
        %Instantiating the future instances to be placed in parallel processing
        %queue
        F_SubStack_Re(1:numStacksConsidered)=parallel.FevalFuture;
        F_SubStack_Im(1:numStacksConsidered)=parallel.FevalFuture;
        %SubStack_Re{1:numStacks}=parallel.FevalFuture;
        %{zeros(depth_image, Widthx, BscansPerY, Lengthy)};
        memory
        for ind1=1:length(files1Cont) %join files1Cont with files2Cont and make single 'for' loop for speed?
            if ~contains(files1Cont{ind1},'bg')
                Gfilename1=fullfile(folder1,files1Cont{ind1});%([folder1 'b0_ch1.dat']); % 1st quadrature
                fprintf('Loading Real data, patch %d/%d \n', ind1,numStacksConsidered);%disp(['Loading Real data, file ', ind]);                 
                F_SubStack_Re(ind1)=parfeval(@LoadAndStitchInParallel,1,ind1,Gfilename1,depth_image, Widthx, BscansPerY, Lengthy,TimeRepsToUse,numStacksConsidered);
            end
            memory
            if ~contains(files2Cont{ind1},'bg')
                Gfilename2=fullfile(folder2,files2Cont{ind1});%([folder1 'b0_ch1.dat']); % 1st quadrature
                fprintf('Loading Imaginary data, patch %d/%d \n', ind1,numStacksConsidered)%                 disp(['Loading Imaginary data, file ', ind]); 
                F_SubStack_Im(ind1)=parfeval(@LoadAndStitchInParallel,1,ind1,Gfilename2,depth_image, Widthx, BscansPerY, Lengthy,TimeRepsToUse,numStacksConsidered);
            end%SubStack_Re{ind1}=
            memory
        end
        
    DimsDataFull_pixUsed=[DimsDataFull_pix(1),DimsDataFull_pix(2),TimeRepsToUse,DimsDataFull_pix(4)];
    DimsDataPatch_pixUsed=repmat(DimsDataFull_pixUsed,numStacksConsidered,1);%To initialize%zeros(numStacks,4);  
      %WidthsPatchesForStitching=zeros(numStacks,1);  
        for ind=1:numStacksConsidered
            if ind==1
                DimsDataPatch_pixUsed(ind,2)=length((1:(Widthx-12))); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
            elseif ind==numStacksConsidered%length(LinearData_Re)
                DimsDataPatch_pixUsed(ind,2)=length((13:Widthx)); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
            else%middle
                DimsDataPatch_pixUsed(ind,2)=length((13:(Widthx-12))); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
            end
        end
elseif Patching==1 || Patching==2
     numStacksConsidered=1;%length(files1Cont)-1;
        %SubStack_Re=cell(numStacks,1);
        %p=parpool(numStacksConsidered);%3 workers if 3 stacks (technically 6 (real+imaginary)
        %Instantiating the future instances to be placed in parallel processing
        %queue
        F_SubStack_Re(1:numStacksConsidered)=parallel.FevalFuture;
        F_SubStack_Im(1:numStacksConsidered)=parallel.FevalFuture;
        %SubStack_Re{1:numStacks}=parallel.FevalFuture;
        %{zeros(depth_image, Widthx, BscansPerY, Lengthy)};
        memory
        for ind1=1:length(files1Cont) %join files1Cont with files2Cont and make single 'for' loop for speed?
            if ~contains(files1Cont{ind1},'bg') && ind1==PatchCount
                Gfilename1=fullfile(folder1,files1Cont{ind1});%([folder1 'b0_ch1.dat']); % 1st quadrature
                fprintf('Loading Real data, patch %d/%d \n', ind1,numStacksPossible);%disp(['Loading Real data, file ', ind]);                 
                F_SubStack_Re=parfeval(@LoadAndStitchInParallel,1,ind1,Gfilename1,depth_image, Widthx, BscansPerY, Lengthy,TimeRepsToUse,numStacksPossible);
            end
%             memory
            if ~contains(files2Cont{ind1},'bg') && ind1==PatchCount
                Gfilename2=fullfile(folder2,files2Cont{ind1});%([folder1 'b0_ch1.dat']); % 1st quadrature
                fprintf('Loading Imaginary data, patch %d/%d \n', ind1,numStacksPossible)%                 disp(['Loading Imaginary data, file ', ind]); 
                F_SubStack_Im=parfeval(@LoadAndStitchInParallel,1,ind1,Gfilename2,depth_image, Widthx, BscansPerY, Lengthy,TimeRepsToUse,numStacksPossible);
            end%SubStack_Re{ind1}=
%             memory
        end
        
    DimsDataFull_pixUsed=[DimsDataFull_pix(1),DimsDataFull_pix(2),TimeRepsToUse,DimsDataFull_pix(4)];
    DimsDataPatch_pixUsed=repmat(DimsDataFull_pixUsed,numStacksConsidered,1);%To initialize%zeros(numStacks,4);  
      %WidthsPatchesForStitching=zeros(numStacks,1);  
            if PatchCount==1
                DimsDataPatch_pixUsed(2)=length((1:(Widthx-12))); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
            elseif PatchCount==numStacksPossible%length(LinearData_Re)
                DimsDataPatch_pixUsed(2)=length((13:Widthx)); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
            else%middle
                DimsDataPatch_pixUsed(2)=length((13:(Widthx-12))); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
            end
end
        
end
    
