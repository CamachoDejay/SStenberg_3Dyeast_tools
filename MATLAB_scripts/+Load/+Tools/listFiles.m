function [ file_list ] = listFiles( data_path, fileExt )
%LISTFILES Generates a list of images contained in the directory, only
%images of known extension are kept
%   Detailed explanation goes here

%Extract the part of the folder that is a tif file
Folder_Content = dir(data_path);
index2Images   = contains({Folder_Content.name},fileExt);
file_list = Folder_Content(index2Images);

if isempty(file_list)
    warning('No %s file found in the selected directory')
end

end

