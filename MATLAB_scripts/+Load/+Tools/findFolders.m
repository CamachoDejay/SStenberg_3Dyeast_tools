function list = findFolders (main_dir)
%FINDFOLDERS gets a list of all folders that start their name with
%'h5files'

   
    if run_conditional_name(main_dir)
        list = {main_dir};
        return
    end
    
    list = {};

    list = check_folders(main_dir, list);

end

function list = check_folders(dir2look, list)
    
    [ Folders ] = Load.Tools.subFolderList( dir2look );
    
    for i = 1:length(Folders)

        name = [Folders(i).folder, filesep, Folders(i).name];
        test = run_conditional_name(name);
        if test
            list = [list, name];
            
        else
            list = check_folders(name, list);
        end

    end

end

function test = run_conditional_name(name)
%     test = endsWith(name, '_out');
    test = false;
    if endsWith(name, '_out')
        label_tif = [name filesep 'lab.tif'];
        seg_tif = [name filesep 'Mito_Segmentation.tif'];
        
        if and(isfile(label_tif), isfile(seg_tif))
            test = true;
        end
        
    end
    
end