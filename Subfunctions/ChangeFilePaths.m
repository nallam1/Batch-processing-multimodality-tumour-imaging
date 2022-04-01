function AppropriateFilePath=ChangeFilePaths(DirectoryDataLetter, filepath)
    filepathTemp=strsplit(filepath,'\');
    AppropriateFilePath=fullfile([DirectoryDataLetter,':'],filepathTemp{2:end});
end