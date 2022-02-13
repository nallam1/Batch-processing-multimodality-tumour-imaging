function [DimsDataPatchRaw_pix,DimsDataFull_pix,DimsDataFull_um,Patches,folder1,folder2, files1Cont,files2Cont, FolderToCreateCheck]=AnalyzeRawDataDims(BatchOfFolders,DataFolderInd)
%% by Nader A.
%% Load data into 4D complex spatio-temporal data stacks and extract dimensions
%for DataFolderInd=1:NumberFilesToProcess%(length(BatchOfFolders)-1)%skip last that has no data
    ProcessingCountofDataSet=0;%the idea is to only save structural data once--so counts number of times does the whole processing
    %for SVprocVersion=1:1%:2 
        %ProcessingCountofDataSet=ProcessingCountofDataSet+1;
        FilePathParts=strsplit(BatchOfFolders{DataFolderInd},'\');%split(FullFolderName,'\');
            %FilePathParts{1}
            mouse=FilePathParts{3};
            day_=FilePathParts{4};
            %[Folderpath,FolderToAnalyze]=fileparts(FullFolderName);
            FolderToAnalyze='data1';%find this folder to tell the time of creation
                AllFolders=dir(BatchOfFolders{DataFolderInd});
                fileFoldernames = {AllFolders(:).name};
                if ismember(FolderToAnalyze,fileFoldernames)
                    Folder=fullfile(BatchOfFolders{DataFolderInd},'data1');
                    FileToAnalyze='b0_ch1.dat';%'data1';%find this folder to tell the time of creation
                    AllFiles=dir(Folder);
                    filenames = {AllFiles(:).name};
                    [~,idx] = ismember(FileToAnalyze,filenames);
                    Time=strrep(AllFiles(idx).date,':',',');%replace(AllFolders(idx).date,":","'");%FilePathParts{4};
                end
%             Time=strrep(AllFolders(idx).date,':',',');%replace(AllFolders(idx).date,":","'");%FilePathParts{4};
        FolderToCreateCheck=fullfile(BatchOfFolders{DataFolderInd},[mouse '_' Time '_ProcVers_IDBISIM_1']);
    if ~exist(FolderToCreateCheck,'dir')
        mkdir(FolderToCreateCheck);
    end
    FileToCreateCheck=fullfile(FolderToCreateCheck,'IDBISIM_binarized_vessels.mat');%'st3D_uint16.mat');%Last file to create as part of batch processing
    if ~exist(FileToCreateCheck,'file')
        %% Determining matrix dimensions        
            depth_image=500;
                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'9x9mm')) && isempty(strfind(BatchOfFolders{DataFolderInd},'Quick')) && ~exist(FileToCreateCheck,'file')%strfind(%sum(ismember(BatchOfFolders{DataFolderInd},'9x9m'))>=4%contains(BatchOfFolders{DataFolderInd},'9x9mm')
        %             ProcessingCountofDataSet=ProcessingCountofDataSet+1;
                    Widthx=400;
                    BscansPerY=8;
                    Lengthy=2400;
                    DimsDataFull_um=[2170,9000,9000];
        %             nrc_svOCT_9x9_pure_sv_fast_500June2021ForBatchproc_os_removal(BatchOfFolders{DataFolderInd},mouse,day_,Time,SVprocVersion,ProcessingCountofDataSet,OSremoval)%the idea is to only save structural data once
                end

                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'6x6mm')) && isempty(strfind(BatchOfFolders{DataFolderInd},'Quick')) && ~exist(FileToCreateCheck,'file')%sum(ismember(BatchOfFolders{DataFolderInd},'6x6m'))>=4%contains(BatchOfFolders{DataFolderInd},'6x6m')
                    ProcessingCountofDataSet=ProcessingCountofDataSet+1;
                    Widthx=400;
                    Lengthy=1600;
                    BscansPerY=8;
                    DimsDataFull_um=[2170,6000,6000];
                        if ~isempty(strfind(BatchOfFolders{DataFolderInd},'4F'))
                                BscansPerY=4;
                            end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'8F'))
                                    BscansPerY=8;
                                end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'16F'))
                                    BscansPerY=16;
                                end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'24F'))
                                    BscansPerY=24;
                                end
        %             nrc_svOCT_6x6_pure_sv_fast_500June2021ForBatchproc_os_removal(BatchOfFolders{DataFolderInd},mouse,day_,Time,SVprocVersion,ProcessingCountofDataSet,BscansPerY,OSremoval) %the idea is to only save structural data once
                end

                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'3x3mm')) && isempty(strfind(BatchOfFolders{DataFolderInd},'Quick')) && ~exist(FileToCreateCheck,'file')%strfind(%sum(ismember(BatchOfFolders{DataFolderInd},'9x9m'))>=4%contains(BatchOfFolders{DataFolderInd},'9x9mm')
                    ProcessingCountofDataSet=ProcessingCountofDataSet+1;
                        Widthx=400;
                        Lengthy=800;
                        BscansPerY=8;
                        DimsDataFull_um=[2170,3000,3000];
                            if ~isempty(strfind(BatchOfFolders{DataFolderInd},'HalfX')) || ~isempty(strfind(BatchOfFolders{DataFolderInd},'200x'))
                                Widthx=200;
                            end
                            if ~isempty(strfind(BatchOfFolders{DataFolderInd},'HalfY')) || ~isempty(strfind(BatchOfFolders{DataFolderInd},'400y'))
                                Lengthy=400;
                            end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'QuarterY')) || ~isempty(strfind(BatchOfFolders{DataFolderInd},'200y'))
                                    Lengthy=200;
                                end
                            if ~isempty(strfind(BatchOfFolders{DataFolderInd},'4F'))
                                BscansPerY=4;
                            end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'8F'))
                                    BscansPerY=8;
                                end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'16F'))
                                    BscansPerY=16;
                                end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'24F'))
                                    BscansPerY=24;
                                end
        %             nrc_svOCT_3x3_pure_sv_fast_500June2021ForBatchproc_os_removal(BatchOfFolders{DataFolderInd},mouse,day_,Time,SVprocVersion,ProcessingCountofDataSet,Widthx,Lengthy,BscansPerY,OSremoval)%the idea is to only save structural data once
                end

            if ~isempty(strfind(BatchOfFolders{DataFolderInd},'3x6mm')) && isempty(strfind(BatchOfFolders{DataFolderInd},'Quick')) && ~exist(FileToCreateCheck,'file')%strfind(%sum(ismember(BatchOfFolders{DataFolderInd},'9x9m'))>=4%contains(BatchOfFolders{DataFolderInd},'9x9mm')
                    ProcessingCountofDataSet=ProcessingCountofDataSet+1;
                        Widthx=400;
                        Lengthy=1600;
                        BscansPerY=8;
                        DimsDataFull_um=[2170,3000,6000];
                            if ~isempty(strfind(BatchOfFolders{DataFolderInd},'HalfX')) || ~isempty(strfind(BatchOfFolders{DataFolderInd},'200x'))
                                Widthx=200;
                            end
                            if ~isempty(strfind(BatchOfFolders{DataFolderInd},'HalfY')) || ~isempty(strfind(BatchOfFolders{DataFolderInd},'400y'))
                                Lengthy=400;
                            end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'QuarterY')) || ~isempty(strfind(BatchOfFolders{DataFolderInd},'200y'))
                                    Lengthy=200;
                                end
                            if ~isempty(strfind(BatchOfFolders{DataFolderInd},'4F'))
                                BscansPerY=4;
                            end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'8F'))
                                    BscansPerY=8;
                                end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'16F'))
                                    BscansPerY=16;
                                end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'24F'))
                                    BscansPerY=24;
                                end
        %             nrc_svOCT_3x6_pure_sv_fast_500June2021ForBatchproc_os_removal(BatchOfFolders{DataFolderInd},mouse,day_,Time,SVprocVersion,ProcessingCountofDataSet,Widthx,Lengthy,BscansPerY,OSremoval)%the idea is to only save structural data once
                end    
            if ~isempty(strfind(BatchOfFolders{DataFolderInd},'4x4mm')) && isempty(strfind(BatchOfFolders{DataFolderInd},'Quick')) && ~exist(FileToCreateCheck,'file')%strfind(%sum(ismember(BatchOfFolders{DataFolderInd},'9x9m'))>=4%contains(BatchOfFolders{DataFolderInd},'9x9mm')
                    ProcessingCountofDataSet=ProcessingCountofDataSet+1;
                        Widthx=400;
                        Lengthy=800;
                        BscansPerY=8;
                        DimsDataFull_um=[2170,4000,4000];
                            if ~isempty(strfind(BatchOfFolders{DataFolderInd},'HalfX')) || ~isempty(strfind(BatchOfFolders{DataFolderInd},'200x'))
                                Widthx=200;
                            end
                            if ~isempty(strfind(BatchOfFolders{DataFolderInd},'HalfY')) || ~isempty(strfind(BatchOfFolders{DataFolderInd},'400y'))
                                Lengthy=400;
                            end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'QuarterY')) || ~isempty(strfind(BatchOfFolders{DataFolderInd},'200y'))
                                    Lengthy=200;
                                end
                            if ~isempty(strfind(BatchOfFolders{DataFolderInd},'4F'))
                                BscansPerY=4;
                            end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'8F'))
                                    BscansPerY=8;
                                end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'16F'))
                                    BscansPerY=16;
                                end
                                if ~isempty(strfind(BatchOfFolders{DataFolderInd},'24F'))
                                    BscansPerY=24;
                                end
        %             nrc_svOCT_4x4_pure_sv_fast_500June2021ForBatchproc_os_removal(BatchOfFolders{DataFolderInd},mouse,day_,Time,SVprocVersion,ProcessingCountofDataSet,Widthx,Lengthy,BscansPerY,OSremoval)%the idea is to only save structural data once
            end    
        %% Opening raw data files           
                folderr=BatchOfFolders{DataFolderInd};%[BatchOfFolders{DataFolderInd}, '\'];
                foldersave=folderr;%('D:\M60s\M61\Apr12\');
        folder1=(fullfile(folderr, 'data1' ));
        folder2=(fullfile(folderr, 'data2' ));
%         savefolder_f=FolderToCreateCheck;%([foldersave mouse '_' Time '_ProcVers' num2str(SVprocVersion) '_Improved\']);
%         mkdir(savefolder_f);


        cd (folderr);
        % Get all PDF files in the current folder
        files1 = dir(fullfile(folder1, '*_ch1.dat'));
        files2 = dir(fullfile(folder2, '*_ch2.dat'));
            files1Cont= {files1(:).name}; 
            files2Cont= {files2(:).name}; 

        % if isempty(Widthx)
        % Widthx=400;
        % end
        % if isempty(Lengthy)
        % Lengthy=800;
        % end
        depth_image=500;
%% Info full 3D matrix
        Stitches=length(files2)-2;%length(LinearData_Re)-1;
        Patches=length(files2)-1;
        WidthVolFull=Widthx*(Stitches+1)-12*Stitches-12*(Stitches);
        DimsDataFull_pix=[depth_image,WidthVolFull,BscansPerY,Lengthy];
        DimsDataPatchRaw_pix=[depth_image,Widthx,BscansPerY,Lengthy];
            tabulatedDims_pix=table(depth_image,WidthVolFull,BscansPerY,Lengthy);
            tabulatedDims_um=table(DimsDataFull_um(1),DimsDataFull_um(2),DimsDataFull_um(3),'VariableNames',{'Depth_um','Widthx_um','Lengthy_um'});
            save(fullfile(FolderToCreateCheck,'DimensionsOfVolData_pix.mat'),'tabulatedDims_pix','-v7.3');
            save(fullfile(FolderToCreateCheck,'DimensionsOfVolData_um.mat'),'tabulatedDims_um','-v7.3');
        
%         % if SVprocVersion==3
%         %     depth_image=400;
%         % end
% 
%         Im1=sqrt(-1);
%         % 
%         % % Sructural_3D_x_8_frames_volume=zeros(depth_image,rxx,length(files1)-1,'single');
%         % sv3D=zeros(depth_image,Widthx,Lengthy,'single');
%         % % st3D=zeros(depth_image,776,1600,'single');
%         %     finishedsearching=0; %Intialize search for FRG files
%         %     while finishedsearching==0 %this is to simply count the number of fringes to be processed to initialize speckle variance images
%         %         FRG_filename(FRG_FileCount+1)=sprintf('%s_00%d%s',FRG_name_format,FRG_FileCount,DataSetNum);
%         %         if exist(FRG_filename(FRG_FileCount+1),'file')~=0% checks if the folder exists in the directory
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         % Loading Real data of patch
%         for ind=1:length(files1)
%             if ~contains(files1Cont{ind},'bg') && contains(files1Cont{ind},int2str((PatchCount-1)*BscansPerY*Lengthy))
%                 Gfilename1=fullfile(folder1,files1Cont{ind});%([folder1 'b0_ch1.dat']); % 1st quadrature
% 
%                 fprintf('Loading Real data, file %d\n', ind)%disp(['Loading Real data, file ', ind]); 
%                 di1=[];di1=fopen(Gfilename1,'r');
% 
%                 LinearData_Re=fread(di1,'int16=>int16');
% 
%                 fclose(di1); %fclose(di2);
%             end
%         end
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         % Loading Imaginary data of patch
% 
%         for ind=1:length(files2)
%             if ~contains(files2Cont{ind},'bg') && contains(files2Cont{ind},int2str((PatchCount-1)*BscansPerY*Lengthy))
%                 Gfilename2=fullfile(folder2,files2Cont{ind});%([folder1 'b0_ch1.dat']); % 1st quadrature
% 
%                 fprintf('Loading Imaginary data, file %d\n', ind)%                 disp(['Loading Imaginary data, file ', ind]); 
%                 di2=[];di2=fopen(Gfilename2,'r');
% 
%                 LinearData_Im=fread(di2,'int16=>int16');
% 
%                 fclose(di2); %fclose(di2);
%             end
%         end
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %         % Loading Real data full
% %         for ind=1:length(files1)
% %             if ~contains(files1Cont{ind},'bg')
% %                 Gfilename1=fullfile(folder1,files1Cont{ind});%([folder1 'b0_ch1.dat']); % 1st quadrature
% % 
% %                 fprintf('Loading Real data, file %d\n', ind)%disp(['Loading Real data, file ', ind]); 
% %                 di1=[];di1=fopen(Gfilename1,'r');
% % 
% %                 LinearData_Re{ind}=fread(di1,'int16=>int16');
% % 
% %                 fclose(di1); %fclose(di2);
% %             end
% %         end
% %         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %         % Loading Imaginary data
% % 
% %         for ind=1:length(files2)
% %             if ~contains(files2Cont{ind},'bg')
% %                 Gfilename2=fullfile(folder2,files2Cont{ind});%([folder1 'b0_ch1.dat']); % 1st quadrature
% % 
% %                 fprintf('Loading Imaginary data, file %d\n', ind)%                 disp(['Loading Imaginary data, file ', ind]); 
% %                 di2=[];di2=fopen(Gfilename2,'r');
% % 
% %                 LinearData_Im{ind}=fread(di2,'int16=>int16');
% % 
% %                 fclose(di2); %fclose(di2);
% %             end
% %         end
%         %% Forming 3D matrix
%         Stitches=length(files2)-2;%length(LinearData_Re)-1;
%         WidthVolFull=Widthx*(Stitches+1)-12*Stitches-12*(Stitches);
%         DimsDataFull_pix=[depth_image,WidthVolFull,BscansPerY,Lengthy];
%         %% REAL 
%         %Reshaping REAL
%             %Stack1_Re=reshape(dil1_1, [], Widthx, BscansPerY, Lengthy);%reshape(dil1_1, 500, 400, 8, 1600);
%             %clearvars ('dil1_1');
%         % Merging together
%         Main_stack_Re=zeros(DimsDataFull_pix,'int16');%12 from right and 12 from left as explaned below
%         SubStack_Re={};
%         for ind=1:length(LinearData_Re)
%             SubStack_Re{ind}=reshape(LinearData_Re{ind},depth_image, Widthx, BscansPerY, Lengthy);
%             if ind==1 
%                 Main_stack_Re(1:depth_image,(1:(Widthx-12)),:,:)=SubStack_Re{ind}(1:depth_image,(1:(Widthx-12)),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             elseif ind==length(LinearData_Re)
%                 Main_stack_Re(1:depth_image,((ind-1)*(Widthx-12))+(1:(Widthx-12)),:,:)=SubStack_Re{ind}(1:depth_image,(13:Widthx),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             else
%                 Main_stack_Re(1:depth_image,((ind-1)*(Widthx-12))+(13:(Widthx-12)),:,:)=SubStack_Re{ind}(1:depth_image,(13:(Widthx-12)),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             end
%         end
% 
%         clearvars SubStack_Re
%         %% IMAGINARY
%         Main_stack_Im=zeros(DimsDataFull_pix,'int16');%12 from right and 12 from left as explaned below
%         SubStack_Im={};
%         for ind=1:length(LinearData_Im)
%             SubStack_Im{ind}=reshape(LinearData_Re{ind},depth_image, Widthx, BscansPerY, Lengthy);
%             if ind==1 
%                 Main_stack_Im(1:depth_image,(1:(Widthx-12)),:,:)=SubStack_Im{ind}(1:depth_image,(1:(Widthx-12)),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             elseif ind==length(LinearData_Re)
%                 Main_stack_Im(1:depth_image,((ind-1)*(Widthx-12))+(1:(Widthx-12)),:,:)=SubStack_Im{ind}(1:depth_image,(13:Widthx),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             else
%                 Main_stack_Im(1:depth_image,((ind-1)*(Widthx-12))+(13:(Widthx-12)),:,:)=SubStack_Im{ind}(1:depth_image,(13:(Widthx-12)),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
%             end
%         end
%         
%         clearvars SubStack_Im
%         
%         if PatchCount ==1
    end
end