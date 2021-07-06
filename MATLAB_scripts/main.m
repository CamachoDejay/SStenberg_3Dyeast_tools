%	Author: Rafael Camacho
%   github: camachodejay
%   date:   2019 - 07 - 03
%   current address: Centre for cellular imaging - G�teborgs universitet
% 
%   This is the main function to run. It first finds all subfolder of a
%   directory that contain the expected information and then iterates of
%   each one of them. For an explanation of the output file and pipeline
%   have a look at: https://github.com/CamachoDejay/SStenberg_3Dyeast_tools

function main()

%     data_folder = 'C:\Users\xcamra\Documents\MATLAB\Simon\data\Sample_adapted\Replicate_1';
    
    data_folder = uigetdir('','Select main data foler');
    
    list_of_folders = Load.Tools.findFolders(data_folder);
    
    for i = 1:length(list_of_folders)
        
        disp(['Now we run the following folder: ' list_of_folders{i}] )
        try
            run_out_folder(list_of_folders{i});
        catch
            disp(['Problems here: ', list_of_folders{i}])
        end
        
        
    end
    

end

function run_out_folder(data_folder)

    k = strfind(data_folder, filesep);
    k = k(end);
    data_name = data_folder(k+1:end-4);
    %%

    tif2load = [data_folder, filesep, 'lab.tif'];
    % cell_bodies
    [cell_bodies,  voxel_size] = Load.load_volume(tif2load);
    nLabels = max(cell_bodies(:));

    tif2load = [data_folder, filesep, 'Mito_Segmentation.tif'];
    % mito
    [mito,  voxel_size_2] = Load.load_volume(tif2load);
    mito = mito > 1;


    assert(all((voxel_size - voxel_size_2)< 1e-6), 'data does not match');
    %%

    % create out folder
    cell_tif_folder = [data_folder, filesep, 'cell_tifs'];
    mkdir(cell_tif_folder);
    
    do_3d = false;

    Out_table = [];

    for idx = 1:nLabels

        cell_BW = cell_bodies == idx;
        mito_BW = and(cell_BW, mito);
        
        if sum(cell_BW(:)) < 10
            disp('this is to small to be a cell')
            continue
        end
        

        [cell_i, mito_i] = extract_bodies(cell_BW, mito_BW);


        try
           [B] = smooth_cell_body(cell_i);
        catch exception
           warning('cell seems to be very small, can not be smoothed')
           B = cell_i;
        end

        stats_before = regionprops3(B,'Solidity','Volume');

        if stats_before.Volume < 500
            disp('this is to small to be a cell')
            continue
        end

        figure(1)
        subplot(1,2,1)
        imshow(max(B,[],3))
        subplot(1,2,2)
        imshow(max(mito_i,[],3))

        %
        % has a daughter cell?

        disp('----------');
        fprintf('In Solidity: %0.3f In Volume: %0.1f \n', stats_before.Solidity, stats_before.Volume)

        if stats_before.Solidity < 0.72
            disp('This one had a daughter!!')
            % if so then:
            [mom, dau, L] = split_mother_daughter(B, voxel_size, 0.7, do_3d);


%             figure(2)
%             subplot(1,2,1)
%             imagesc(max(B,[],3))
%             subplot(1,2,2)
%             imagesc(max(L,[],3))

            stats_mom = regionprops3(mom,'Solidity','Volume');
            fprintf('Mom Solidity: %0.3f Mom Volume: %0.1f \n', stats_mom.Solidity, stats_mom.Volume)

            stats_dau = regionprops3(dau,'Solidity','Volume');
            fprintf('Daug Solidity: %0.3f Daug Volume: %0.1f \n', stats_dau.Solidity, stats_dau.Volume)
            
            if stats_mom.Solidity * 1.01 < stats_before.Solidity
                warning('split does not seem to work properly');
                mom = B;
                dau = false(size(B));
            end

        else
            disp('This cell has no daughter')
            mom = B;
            dau = false(size(B));
        end
        
        [mom] = extra_smooth(mom, voxel_size);
        [Cell_table, M] = get_mom_props(mom, dau, mito_i, voxel_size);
        
        % Store the image of the bodies used
        out_vol = mom + M + dau.*3;
        out_vol = uint8(out_vol.*85);
        out_vol_name = [cell_tif_folder, filesep, 'Cell_', num2str(idx), '.tif'];
        dataStorage.nBTiff(out_vol_name,out_vol,8);
        
        % prepare table
        tmp_idx = repmat(idx,height(Cell_table),1);
        tmp_name = cell(height(Cell_table),1);
        tmp_name(:) = {data_name};

        tmp_table = table(tmp_name,tmp_idx,...
                                            'VariableNames',{'data_name',...
                                                             'Cell_idx'});
        Cell_table = cat(2,tmp_table,Cell_table);
        
%         if size(Cell_table,2) ~= size(Out_table,2)
%            disp("here"); 
%         end
        Out_table = cat(1,Out_table,Cell_table);
    end

    table_name = [data_folder filesep data_name '.xlsx'];
    writetable(Out_table,table_name);

end


