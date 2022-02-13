%% Extract noiseFloor from acquisitions in air
%Instead of taking single A scan and cutoff at 500pix in depth
%part of the idea being good was the realization that SNR is depth
%dependent (actually increasing in depth) even in air
%In other words, old technique of relying only on bottom few pixels of 
%each frame to establish its respective noise floor would not work since 
%1) it assumes noise same at all depths and slightly less importantly 
%2) it asumes that we reached a depth where signal always attenuated to 
%same significant level (may not be the case depending on superficial 
%tissue. Old technique: use mean along A-scan of variance over time 
%of the 6 bottom pixels of each B-scan. Now use 3D measurement in air and
%take variance in time 8 B/M-scans of each frame in air (essentially speckle
%variance processing in air) and either use this 3D speckle variance volume
%to represent noise (as a function of depth) for each B-scan or more likely take mean
%of the variance B/M-scan of all y-step B-scans
addpath(genpath('\\Desktop-4kfu3pj\d\Processing code\OCT'))%'W:\Processing code\OCT'))
addpath(genpath('D:\Testing nrcOCT'))
Directories={'D:\Testing nrcOCT\Different depths in air'}%'D:\Testing nrcOCT\Measurements of noise floor (air) dim lighting conditions'};
Structsave=1
count=0;
for ind=1:length(Directories)
    x=dir(fullfile(Directories{ind},'**','data1'));
            for k=1:length(x)
                count=count+1;
                BatchOfFolders{count}=fileparts(x(k).folder);
            end
end
NumberFilesToProcess=length(BatchOfFolders);  
for DataFolderInd=1:NumberFilesToProcess%(length(BatchOfFolders)-1)%skip last that has no data
    ProcessingCountofDataSet=0;%the idea is to only save structural data once--so counts number of times does the whole processing
    for SVprocVersion=1:1%:2 
        %ProcessingCountofDataSet=ProcessingCountofDataSet+1;
%         FilePathParts=strsplit(BatchOfFolders{DataFolderInd},'\');%split(FullFolderName,'\');
%             %FilePathParts{1}
%             mouse=FilePathParts{3};
%             day_=FilePathParts{4};
            %[Folderpath,FolderToAnalyze]=fileparts(FullFolderName);
            FolderToAnalyze='data1';%find this folder to tell the time of creation
                AllFolders=dir(BatchOfFolders{DataFolderInd});
                fileFoldernames = {AllFolders(:).name};
                if ismember(FolderToAnalyze,fileFoldernames)
                    Folder=fullfile(BatchOfFolders{DataFolderInd},'data1');
                    FileToAnalyze='b0_ch1.dat'%'data1';%find this folder to tell the time of creation
                    AllFiles=dir(Folder);
                    filenames = {AllFiles(:).name};
                    [~,idx] = ismember(FileToAnalyze,filenames);
                    Time=strrep(AllFiles(idx).date,':',',');%replace(AllFolders(idx).date,":","'");%FilePathParts{4};
                end
%             Time=strrep(AllFolders(idx).date,':',',');%replace(AllFolders(idx).date,":","'");%FilePathParts{4};
        FileToCreateCheck=fullfile(BatchOfFolders{DataFolderInd},['NoiseInfoNormalizedIntensityOfNoise.mat']);%'st3D_uint16.mat');%Last file to create as part of batch processing
        FileToCreateCheck
        
        if ~isempty(strfind(BatchOfFolders{DataFolderInd},'3x3mm')) && isempty(strfind(BatchOfFolders{DataFolderInd},'Quick')) && ~exist(FileToCreateCheck,'file')%strfind(%sum(ismember(BatchOfFolders{DataFolderInd},'9x9m'))>=4%contains(BatchOfFolders{DataFolderInd},'9x9mm')
            ProcessingCountofDataSet=ProcessingCountofDataSet+1;
                WidthX=400;
                LengthY=800;
                BscansPerY=8;
                    if ~isempty(strfind(BatchOfFolders{DataFolderInd},'HalfX')) || ~isempty(strfind(BatchOfFolders{DataFolderInd},'200x'))
                        WidthX=200;
                    end
                    if ~isempty(strfind(BatchOfFolders{DataFolderInd},'HalfY')) || ~isempty(strfind(BatchOfFolders{DataFolderInd},'400y'))
                        LengthY=400;
                    end
                        if ~isempty(strfind(BatchOfFolders{DataFolderInd},'QuarterY')) || ~isempty(strfind(BatchOfFolders{DataFolderInd},'200y'))
                            LengthY=200;
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
            NoiseMeas_nrc_svOCT_3x3_pure_sv_fast(BatchOfFolders{DataFolderInd},Structsave,WidthX,LengthY,BscansPerY);%the idea is to only save structural data once
        
        elseif ~isempty(strfind(BatchOfFolders{DataFolderInd},'Quick')) && ~exist(FileToCreateCheck,'file')
            if ~isempty(strfind(BatchOfFolders{DataFolderInd},'1F'))
                        BscansPerY=1;
            end
            if ~isempty(strfind(BatchOfFolders{DataFolderInd},'8F'))
                BscansPerY=8;
            end
            if ~isempty(strfind(BatchOfFolders{DataFolderInd},'16F'))
                BscansPerY=16;
            end
            QuickVis_Noise(BatchOfFolders{DataFolderInd},BscansPerY)
        end
    end
end

% %% Noise floor visualization
% %Intensity
% x=randi(size(NoiseIntensity,2),1)
% y=randi(size(NoiseIntensity,3),1)
% plot(NoiseIntensity(:,x,y))
% %Real
% x=randi(size(Main_stack_Re,2),1)
% y=randi(size(Main_stack_Re,3),1)
% plot(Main_stack_Re(:,x,y))
% %Imaginary
% x=randi(size(Main_stack_Im,2),1)
% y=randi(size(Main_stack_Im,3),1)
% plot(Main_stack_Im(:,x,y))