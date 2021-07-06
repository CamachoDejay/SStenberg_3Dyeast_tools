function [stats_mito, M] = mito_props(M, voxel_size)
%MITO_PROPS get shape descriptor of each mithocondria (snake-like) in
%the binary image
    
%     sM = smooth_mito(M, voxel_size);
%     
%     if sum(sM(:)) == 0
%         warning("we lost all mito during smooth, going back to original data"); 
%     else
%         M = sM;
%     end
    
    
    
    %now I want to get the properties of the objects
    mito_L = bwlabeln(M);
    stats_mito = regionprops3(mito_L,'Solidity','Volume');
    nMito = height(stats_mito); 
    
    stats_mito.Properties.VariableNames =  {'Mito_Volume' 'Mito_Solidity'};
    
    % here is a quick approximation of length and width
    stats_mito.Mito_Volume_micron = stats_mito.Mito_Volume .* voxel_size(1) .* voxel_size(2) .* voxel_size(3);
    
    original_size = size(M);
    norm_vox = voxel_size./voxel_size(1);
    for idx =1:nMito
        m_1 = mito_L == idx;
        m_1 = imresize3(m_1,original_size .* norm_vox,'nearest');
        dist_map = bwdist(~m_1);
        d = dist_map(dist_map>0);
        d = median(d);

        stats_mito.Mito_Diameter_micron(idx) = d.*voxel_size(1);

        s_1 = bwskel(m_1,'MinBranchLength',uint16(inf));
        % here are some ideas for the future to make it better
        % n_diagonals = max(unique(bwlabeln(s_1, 6)));
        % n_diagonals = max(unique(bwlabeln(s_1, 18)));
        % n_diagonals = max(unique(bwlabeln(s_1, 26)));
        n_skel_pix = sum(s_1(:));
        stats_mito.Mito_SkelPix_Micron(idx) = n_skel_pix.*voxel_size(1);

    end
end

function M = smooth_mito(M, voxel_size)
    
    original_size = size(M);
    norm_vox = voxel_size./voxel_size(1);
    
    % smooth a bit the mito we know the z is quite under sampled in comp to
    % x-y so I have to scale to be able to smooth
    M = imresize3(M,original_size .* norm_vox,'nearest');

    M = imfill(M,'holes');
    SE = strel('disk',7);
    M = imclose(M,SE);
    SE = strel('sphere',1);
    M = imopen(M,SE);

    M = imresize3(M,original_size,'nearest');

end

