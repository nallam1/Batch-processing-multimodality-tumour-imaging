function [SegFolderTimepoint0,IndexMouse]=findSegmentationtimepoint0_Folderv3(MouseName,BatchOfFolders,countBatchFolder,ListofInitialTimepoints,InitialTimepointtxtFile,DirectoriesBareSkinMiceKeyword,ProcessedFilename,MaskCreationFolder,UnformatedDataSet)%VesselsBinarizedFilename
    for ii=1:length(ListofInitialTimepoints)
        if contains(ListofInitialTimepoints{ii},MouseName)
            IndexMouse=ii;
        end
    end
    %mousenameDate=fullfile(MouseName,DateName)
%     timeFid=fopen(fullfile(TumourMaskAndStepsDir,'Timepoint.txt'),'r');
% ImgTimepoint_temp=fscanf(timeFid,'%s', [1, inf]);
% ImgTimepoint_temp2=strsplit(sprintf('%s',ImgTimepoint_temp(1:11)),'-');
% ImgTimepoint=[ImgTimepoint_temp2{2},' ',ImgTimepoint_temp2{1},' ',ImgTimepoint_temp2{3}];%rearranged to be Apr 23 2021 for example
% 


    TempDir=strsplit(ProcessedFilename,'\');
    if UnformatedDataSet==1
        path1=fullfile(fileparts(InitialTimepointtxtFile),MaskCreationFolder);
        path2=fullfile(fileparts(BatchOfFolders{countBatchFolder,1}),MaskCreationFolder);
    else
        path1=fileparts(InitialTimepointtxtFile);
        path2=fileparts(BatchOfFolders{countBatchFolder,1});
    end
% if sum(contains(TempDir,'pre'))>0||sum(contains(TempDir,'post'))>0
%     path3=fullfile(TempDir{1:8});
% else
%     path3=fullfile(TempDir{1:7});
% end

    if ~exist(fullfile(path1,'timepoint0SegFolderpath.mat')) || ~exist(fullfile(path2,'timepoint0SegFolderpath.mat')) %|| (UnformatedDataSet==0  && ~exist(fullfile(path3,'timepoint0SegFolderpath.mat')))
        %if contains(ListofInitialTimepoints{IndexMouse},mousenameDate) %whether or not to even go through the process of searching for t0- folder or you already are in it
            if contains(MouseName,DirectoriesBareSkinMiceKeyword)%defining t0 folder directyory where to search for the file (which includes all the t0 files)           
                if UnformatedDataSet==1
                    TumourMaskAndStepsDirT0_Temp=fileparts(path1);%fullfile(ListofInitialTimepoints{IndexMouse},'Segmentation_TumourMaskCreation2D-3D');
                else
                    TumourMaskAndStepsDirT0_Temp=fullfile(ListofInitialTimepoints{IndexMouse},'Segmentation_TumourMaskCreation2D-3D');
                end    
            else%if contains(BatchOfFolders{countBatchFolder,1},'pre')
                if UnformatedDataSet==1
                    TumourMaskAndStepsDirT0_Temp=fileparts(path1);%fullfile(ListofInitialTimepoints{IndexMouse},'Segmentation_TumourMaskCreation2D-3D');
                else
                    TumourMaskAndStepsDirT0_Temp=fullfile(ListofInitialTimepoints{IndexMouse},'Segmentation_TumourMaskCreation2D-3D','pre');  
                end
            end
                SearchTrueT0_FolderAllDir=dir(fullfile(TumourMaskAndStepsDirT0_Temp,'**'));%dir(TumourMaskAndStepsDirT0_Temp,'**')
                    for iii=1:length(SearchTrueT0_FolderAllDir)
                        if contains(ProcessedFilename,SearchTrueT0_FolderAllDir(iii).name) && ~isequal(SearchTrueT0_FolderAllDir(iii).name,'.') && isequal(TempDir{end},SearchTrueT0_FolderAllDir(iii).name) 
                            if UnformatedDataSet==1 || (UnformatedDataSet==0 && contains(SearchTrueT0_FolderAllDir(iii).folder,MaskCreationFolder))%contains(SearchTrueT0_FolderAllDir(iii).name,ProcessedFilename)%,fullfile(MaskStyle,SavedFilename3DTumourMask))
                                if contains(ProcessedFilename,'intermediate steps')
                                    SegFolderTimepoint0=fileparts(SearchTrueT0_FolderAllDir(iii).folder);
                                else
                                    SegFolderTimepoint0=SearchTrueT0_FolderAllDir(iii).folder;
                                end
                            end
                            break;
                        end
                    end
%Different timepoint0 processing folders depending on what is needed                    
                                    
                                        if ~exist(path1,'dir')
                                            mkdir(path1)
                                        end
                                        if ~exist(path2,'dir')
                                            mkdir(path2)
                                        end
                                    save(fullfile(path1,'timepoint0SegFolderpath.mat'),'SegFolderTimepoint0','-v7.3');
                                    save(fullfile(path2,'timepoint0SegFolderpath.mat'),'SegFolderTimepoint0','-v7.3');
%                                     save(fullfile(path3,'timepoint0SegFolderpath.mat'),'RawFolderTimepoint0','-v7.3');
%         else
%             PotentialRawFolderTimepoint0Temp=fullfile(ListofInitialTimepoints{IndexMouse},'Segmentation_TumourMaskCreation2D-3D');
%             RawFolderTimepoint0Dir=dir(fullfile(PotentialRawFolderTimepoint0Temp,'**'));%fileparts(BatchOfFolders{countBatchFolder,1})
%                     for iii=1:length(RawFolderTimepoint0Dir)
%                         if contains(ProcessedFilename,RawFolderTimepoint0Dir(iii).name) && contains(RawFolderTimepoint0Dir(iii).folder,MaskCreationFolder)%contains(SearchTrueT0_FolderAllDir(iii).name,ProcessedFilename)%,fullfile(MaskStyle,SavedFilename3DTumourMask))
%                             RawFolderTimepoint0=RawFolderTimepoint0Dir(iii).folder
%                             break;
%                         end
%                     end
%             save(fullfile(fileparts(BatchOfFolders{countBatchFolder,1}),MaskCreationFolder,'timepoint0SegFolderpath.mat'),'RawFolderTimepoint0','-v7.3');
%         end
    else
        load(fullfile(path1,'timepoint0SegFolderpath.mat'))
        %load(fullfile(fileparts(BatchOfFolders{DataFolderInd,1}),'timepoint0SegFolderpath.mat'))
    end
end
%                             savePathToT0folder where all processing data is stored--> in the Timepoint0- folder
%                             savePathToT0folder where all processing data is stored--> in all timepoint folders