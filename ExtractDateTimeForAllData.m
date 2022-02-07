function ExtractDateTimeForAllData(DirectoryVesselsData) 
%% creates text file with info: Mouse name, as well as day and time of scan into what will become the 3D VOI/tumour segmentation folder
%% Folder organization:
% All individual mouse-tumour folders and folder containing extracted
% metrics for all considered mice.
    % All timepoints per mouse-tumour folder and the respective initial
    % timepoint folder on its own (with text file about the FOV size and
    % the raw OCTA file).
        %All acquired modalities (Brightfield-Fluorescence, MRI, OCT) per timepoint per mouse-tumour folder and
        %the segmentation (and intermediates) folder
        %(Segmentation_TumourMaskCreation2D-3D)
            % In the OCT folder, there is the acquisition type (e.g., High
            % resolution scan_setting4_6x6mm) and within, the folders of raw data
            % in both real and imaginary domains, and the folders of OCTA
            % processing, structural OCT extraction and vascular segmentation (e.g., BS3_23-Apr-2021 19,31,34_ProcVers1_Improved).
%% Listing all folders          
addpath(genpath(DirectoryVesselsData))
    d=dir(fullfile(DirectoryVesselsData,'**','b0_ch1.dat'));
    for i=1:length(d)
        FullFolderConsidered=d(i).folder;
        if ~contains(FullFolderConsidered,'Old') && ~contains(FullFolderConsidered,'old') && ~contains(FullFolderConsidered,'Quick') && ~contains(FullFolderConsidered,'quick') && ~contains(FullFolderConsidered,'TumourDepth') && ~contains(FullFolderConsidered,'Backside')%'Raw_OCT_Volume') % ~isempty(strfind(all(ind).name,'Raw_OCT_Volume'))
        FullFolderConsideredParts=strsplit(d(i).folder,'\');
            %Finding segmentation folder if it exist
            if contains(FullFolderConsidered,'pre')
                TumourMaskAndStepsDir=fullfile(FullFolderConsideredParts{1:4},'Segmentation_TumourMaskCreation2D-3D','pre',FullFolderConsideredParts{7});
            elseif contains(FullFolderConsidered,'post')
                TumourMaskAndStepsDir=fullfile(FullFolderConsideredParts{1:4},'Segmentation_TumourMaskCreation2D-3D','post',FullFolderConsideredParts{7});
            else
                TumourMaskAndStepsDir=fullfile(FullFolderConsideredParts{1:4},'Segmentation_TumourMaskCreation2D-3D',FullFolderConsideredParts{6});
            end
                    if ~exist(TumourMaskAndStepsDir,'dir')
                        mkdir(TumourMaskAndStepsDir);
                    end
%% In each segmentation folder creating text file with timepoint of acquisition 
            if ~exist(fullfile(TumourMaskAndStepsDir,'Timepoint.txt'),'file')
                fid = fopen(fullfile(TumourMaskAndStepsDir,'Timepoint.txt'), 'wt');
                fprintf(fid, d(i).date);%sprintf('',strrep(d(i).date,':','_'))%'Jake said: %f\n', sqrt(1:10));
                fclose(fid);
            else
                fprintf('Timepoint already recorded\n')
            end             
        else
            fprintf('Skippable folder\n')
        end 
    end
end
