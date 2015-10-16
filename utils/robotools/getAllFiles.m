%>@file getAllFiles.m Get a list of all files in the given folder and subfolders
%>
%> @brief Get a list of all files in the given folder and subfolders
%>
%> @param dirName The root directory where to start searching from
%>
%> @return fileList A cell array with the full path of all the files
function fileList = getAllFiles(dirName)
    dirData = dir(dirName);      %# Get the data for the current directory
    dirIndex = [dirData.isdir];  %# Find the index for directories
    fileList = {dirData(~dirIndex).name}';  %'# Get a list of the files
    if ~isempty(fileList)
        fileList = cellfun(@(x) fullfile(dirName,x),...  %# Prepend path to files
                       fileList,'UniformOutput',false);
    end
    subDirs = {dirData(dirIndex).name};  %# Get a list of the subdirectories
    validIndex = ~ismember(subDirs,{'.','..'});  %# Find index of subdirectories
                                               %#   that are not '.' or '..'
    for iDir = find(validIndex)                  %# Loop over valid subdirectories
        nextDir = fullfile(dirName,subDirs{iDir});    %# Get the subdirectory path
        fileList = [fileList; getAllFiles(nextDir)];  %# Recursively call getAllFiles
    end
end