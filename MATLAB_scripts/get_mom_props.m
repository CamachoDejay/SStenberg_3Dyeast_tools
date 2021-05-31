function [T_out, M] = get_mom_props(mom, dau, mito, voxel_size)
%GET_MOM_PROPS Summary of this function goes here
%   Detailed explanation goes here

% only look at mito in mother cell
mito = and(mom,mito);

% remove very small objects
mito = bwareaopen(mito,26);

stats_mom = regionprops3(mom,'Solidity','Volume');
cell_vol = stats_mom.Volume;

stats_dau = regionprops3(dau,'Solidity','Volume');
if isempty(stats_dau)
    % no daugther cell
    dau_vol = 0;    
else
    dau_vol = stats_dau.Volume;
end
    
[single_mito_table, M] = mito_props(mito, voxel_size);

% total_mito_table = regionprops3(mito,'Volume','PrincipalAxisLength','ConvexVolume','Solidity');
% total_mito_var_names = {'Total_Mito_Volume',...
%                         'Total_Mito_PrincipalAxisLength',...
%                         'Total_Mito_ConvexVolume',...
%                         'Total_Mito_Solidity'};
% 
% total_mito_table.Properties.VariableNames = total_mito_var_names;

n = 1:height(single_mito_table);

if isempty(n)
    % no mito detected!!
    n=0;
    single_mito_table = table(0,0,0,0,0,'VariableNames',{'Mito_Volume',...
                                               'Mito_Solidity',...
                                               'Mito_Volume_micron',...
                                               'Mito_Diameter_micron',...
                                               'Mito_SkelPix_Micron'});
end
cell_vol = repmat(cell_vol,height(single_mito_table),1);
Cell_Volume_micron = cell_vol .* voxel_size(1) .* voxel_size(2) .* voxel_size(3);

dau_vol = repmat(dau_vol,height(single_mito_table),1);
Dau_Volume_micron = dau_vol .* voxel_size(1) .* voxel_size(2) .* voxel_size(3);


single_mito_table.Mito_Vol_Ratio = single_mito_table.Mito_Volume ./ cell_vol;


% total_mito_table = repmat(total_mito_table,height(single_mito_table),1);

T_out = table(cell_vol, Cell_Volume_micron, dau_vol, Dau_Volume_micron, n',...
                                    'VariableNames',{'Cell_Volume',...
                                                     'Cell_Volume_micron',...
                                                     'Daughter_Volume',...
                                                     'Daughter_Volume_micron',...
                                                     'Mito_Number'});

try
T_out = cat(2,T_out, single_mito_table);
catch
   disp("bla") ;
end
end

