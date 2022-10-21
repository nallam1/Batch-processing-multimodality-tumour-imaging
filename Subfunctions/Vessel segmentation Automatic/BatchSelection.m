function [NumberFilesToProcess,BatchOfFolders]=BatchSelection(Directory,Directories,Mice,Timepoints,ManualSel_0_OR_ListFiles_1_OR_SemiAut_2_OR_FullAutomatic_3,MatlabVer)  
%% by Nader A.
%% Search directory/directories of all files to be processed 
%% Defining directories for automatic and semi-automatic file search
if ManualSel_0_OR_ListFiles_1_OR_SemiAut_2_OR_FullAutomatic_3==2
%     Directories={'Y:\DLF data\20Gy'}%'Y:\DLF data\10 Gy'};%;'F:\DLF data\20Gy'};
    %countFiles=0;
        all=[];
        for idx=1:length(Directories)

            all=[all ; dir(fullfile(Directories{idx},'**'))]; %list all files in directory to do file search (since all sv files named differently, just have key words
            %all=[all;allTemp];
        end
        
elseif ManualSel_0_OR_ListFiles_1_OR_SemiAut_2_OR_FullAutomatic_3==3
    all=dir(fullfile(Directory,'**')); %list all files in directory to do file search (since all sv files named differently, just have key words
end

d=dir;
AllfilesAndFolders=d.name;
%NumTimepoints=11;
BatchOfFolders={};

if ManualSel_0_OR_ListFiles_1_OR_SemiAut_2_OR_FullAutomatic_3==0
     ind=1;
     BatchOfFolders{ind}={};
     FileSelectDirectory=Directory;
%     while ind<=NumFiles_max && BatchOfFolders{ind}~=0%MiceFolderInd=1:NumMice
    while isempty(BatchOfFolders{ind})
       % for DateFolderInd=1:%[FileSelectDirectory,BatchOfFolders{ind}]
        BatchOfFolders{ind}=uigetdir(FileSelectDirectory,'Please select folders of datasets to be CDV processed');
        if BatchOfFolders{ind}==0
            %BatchOfFolders{ind}={'All loaded'}
            break;
        else
            FileSelectDirectory=fileparts(BatchOfFolders{ind});
        ind=ind+1
        BatchOfFolders{ind}={};    
        end
    end
    %BatchOfFolders{ind}={};
    %NumberFilesToProcess=length(BatchOfFolders)-1;
elseif ManualSel_0_OR_ListFiles_1_OR_SemiAut_2_OR_FullAutomatic_3==1
    FileNum=0;
    NumMice=length(Mice);
    NumTime=length(Timepoints);
    for MiceFolderInd=1:NumMice
        for DateFolderInd=1:NumTime
            [MiceFolderInd,DateFolderInd]%FileNum=FileNum+1;
            PotentialFolderTemp=fullfile(Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd},'OCT\');%sprintf('%s\%s\%s\OCT\',Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd});
%BatchOfFolders{FileNum}=sprintf('%s\%s\%s\OCT',Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd});
                FileToLoadCheck=[PotentialFolderTemp 'High resolution scan_setting4_6x6mm'];
%BatchOfFolders{FileNum} '\data1'];
                FileExists=exist(FileToLoadCheck,'file');
            
            if FileExists==0%~ismember(BatchOfFolders(FileNum),d) %if the file does not exit try seeing if it is one of the timepoints with pre/post imaging           
                FileToLoadCheck=[PotentialFolderTemp 'High resolution scan_setting5_9x9mm'];
%BatchOfFolders{FileNum} '\data1'];
                FileExists=exist(FileToLoadCheck,'file')
                    if FileExists~=0
                        FileNum=FileNum+1;
                              BatchOfFolders{FileNum}=FileToLoadCheck;
                    end
                FileToLoadCheck=[PotentialFolderTemp 'High resolution scan_setting2_3x3mm'];
%BatchOfFolders{FileNum} '\data1'];
                FileExists=exist(FileToLoadCheck,'file')
                    if FileExists~=0
                        FileNum=FileNum+1;
                              BatchOfFolders{FileNum}=FileToLoadCheck;
                    end    
                    %BatchOfFolders{FileNum}=sprintf('%s\%s\%s\OCT\pre',Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd});
                    PotentialFolderTemp1=fullfile(Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd},'OCT','pre\');%sprintf('%s\%s\%s\OCT\pre\',Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd});
                        FileToLoadCheck1=[PotentialFolderTemp1 'High resolution scan_setting4_6x6mm'];%[BatchOfFolders{FileNum} '\data1'];
                        PreFileExists=exist(FileToLoadCheck1,'file');
                            if PreFileExists~=0
                              FileNum=FileNum+1;
                              BatchOfFolders{FileNum}=FileToLoadCheck1;      
                            end
                    PotentialFolderTemp1=fullfile(Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd},'OCT','pre\');%sprintf('%s\%s\%s\OCT\pre\',Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd});
                        FileToLoadCheck1=[PotentialFolderTemp1 'High resolution scan_setting5_9x9mm'];%[BatchOfFolders{FileNum} '\data1'];
                        PreFileExists=exist(FileToLoadCheck1,'file');
                            if PreFileExists~=0
                              FileNum=FileNum+1;
                              BatchOfFolders{FileNum}=FileToLoadCheck1;
                            end
                    PotentialFolderTemp1=fullfile(Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd},'OCT','pre\');%sprintf('%s\%s\%s\OCT\pre\',Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd});
                        FileToLoadCheck1=[PotentialFolderTemp1 'High resolution scan_setting2_3x3mm'];%[BatchOfFolders{FileNum} '\data1'];
                        PreFileExists=exist(FileToLoadCheck1,'file');
                            if PreFileExists~=0
                              FileNum=FileNum+1;
                              BatchOfFolders{FileNum}=FileToLoadCheck1;
                            end
                    PotentialFolderTemp1=fullfile(Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd},'OCT','pre\');%sprintf('%s\%s\%s\OCT\pre\',Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd});
                        FileToLoadCheck1=[PotentialFolderTemp1 'High resolution 4x4mm'];%[BatchOfFolders{FileNum} '\data1'];
                        PreFileExists=exist(FileToLoadCheck1,'file');
                            if PreFileExists~=0
                              FileNum=FileNum+1;
                              BatchOfFolders{FileNum}=FileToLoadCheck1;
                            end     
                    PotentialFolderTemp2=fullfile(Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd},'OCT','post\');%sprintf('%s\%s\%s\OCT\post\',Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd});
                        FileToLoadCheck2=[PotentialFolderTemp2 'High resolution scan_setting4_6x6mm'];%[BatchOfFolders{FileNum} '\data1'];
                        PostFileExists=exist(FileToLoadCheck2,'file');
                            if PostFileExists~=0
                              FileNum=FileNum+1;
                              BatchOfFolders{FileNum}=FileToLoadCheck2;
                            end
                    PotentialFolderTemp2=fullfile(Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd},'OCT','post\');%sprintf('%s\%s\%s\OCT\post\',Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd});
                        FileToLoadCheck2=[PotentialFolderTemp2 'High resolution scan_setting5_9x9mm'];%[BatchOfFolders{FileNum} '\data1'];
                        PostFileExists=exist(FileToLoadCheck2,'file');
                            if PostFileExists~=0
                              FileNum=FileNum+1;
                              BatchOfFolders{FileNum}=FileToLoadCheck2;
                            end
                    PotentialFolderTemp2=fullfile(Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd},'OCT','post\');%sprintf('%s\%s\%s\OCT\post\',Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd});
                        FileToLoadCheck2=[PotentialFolderTemp2 'High resolution scan_setting2_3x3mm'];%[BatchOfFolders{FileNum} '\data1'];
                        PostFileExists=exist(FileToLoadCheck2,'file');
                            if PostFileExists~=0
                              FileNum=FileNum+1;
                              BatchOfFolders{FileNum}=FileToLoadCheck2;
                            end
                    PotentialFolderTemp2=fullfile(Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd},'OCT','post\');%sprintf('%s\%s\%s\OCT\post\',Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd});
                        FileToLoadCheck2=[PotentialFolderTemp2 'High resolution 4x4mm'];%[BatchOfFolders{FileNum} '\data1'];
                        PostFileExists=exist(FileToLoadCheck2,'file');
                            if PostFileExists~=0
                              FileNum=FileNum+1;
                              BatchOfFolders{FileNum}=FileToLoadCheck2;
                            end
            else
                    FileNum=FileNum+1;
                              BatchOfFolders{FileNum}=FileToLoadCheck;
            end
                            
%                     BatchOfFolders{FileNum}=sprintf('%s\%s\%s\OCT\post',Directory,Mice{MiceFolderInd},Timepoints{DateFolderInd});
%                         FileToLoadCheck1=[BatchOfFolders{FileNum} '\data1']
        end
    end
    
elseif ManualSel_0_OR_ListFiles_1_OR_SemiAut_2_OR_FullAutomatic_3==2
    count=0;
    for ind=1:length(Directories)        
        if MatlabVer<=2016.5
            dirinfo = dir(Directories{ind});%current directory

            dirinfo(~[dirinfo.isdir]) = [];  %remove non-directories
             subdirinfo = {};%cell(length(dirinfo));
            
             while ~isempty(dirinfo)
               count=count+1;
                for K = 1 : length(dirinfo)
                  thisdir = dirinfo(K).name;
                  subdirinfo{K} = dir(fullfile(thisdir, '*.dat'));
                end
                %%TO COMPLETE!!!! Search through all subfolders (at all depths) of all
                %%folders before proceeding to next folder in directory
             end
        else
            x=dir(fullfile(Directories{ind},'**','data1'));
            for k=1:length(x)
                count=count+1;
                BatchOfFolders{count}=fileparts(x(k).folder);
            end
        end
    end
                    
elseif ManualSel_0_OR_ListFiles_1_OR_SemiAut_2_OR_FullAutomatic_3==3
        if MatlabVer<=2016.5%'2016a' before 2016b
            dirinfo = dir();%current directory

            dirinfo(~[dirinfo.isdir]) = [];  %remove non-directories
             subdirinfo = {};%cell(length(dirinfo));
            count=0;
             while ~isempty(dirinfo)
               count=count+1;
                for K = 1 : length(dirinfo)
                  thisdir = dirinfo(K).name;
                  subdirinfo{K} = dir(fullfile(thisdir, '*.dat'));
                end
                %%TO COMPLETE!!!! Search through all subfolders (at all depths) of all
                %%folders before proceeding to next folder in directory
             end
        else
            x=dir(fullfile(Directory,'**','data1'));
            for k=1:length(x)
                BatchOfFolders{k}=fileparts(x(k).folder);
            end
        end
end
    NumberFilesToProcess=length(BatchOfFolders);  
    if ManualSel_0_OR_ListFiles_1_OR_SemiAut_2_OR_FullAutomatic_3==0
        NumberFilesToProcess=length(BatchOfFolders)-1; %since pressing cancel makes the last created filename '0'
    end
end

