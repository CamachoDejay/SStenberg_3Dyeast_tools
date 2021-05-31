function [ Folders ] = subFolderList( main_PathName )
%SUBFOLDERLIST Finds all folders in a directory
%   Detailed explanation goes here

% Find all folders in the directory
% Folders = dir([main_PathName '/*.*']);
Folders = dir([main_PathName]);
% Get a logical vector that tells which is a directory.
dirFlags = [Folders.isdir];
Folders = Folders(dirFlags);
% remove the '.' and '..' that are always there
Folders(strcmp({Folders.name},'.')) = [];
Folders(strcmp({Folders.name},'..')) = [];

% if isempty(Folders)
%     warning('No subfolders found')
% end
end

