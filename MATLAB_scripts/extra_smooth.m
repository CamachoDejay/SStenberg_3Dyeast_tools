function [BW] = extra_smooth(BW, voxel_size)
%EXTRA_SMOOTH smooths a 3D volume which we know should be elliptical in
%nature
    
    original_size = size(BW);
    norm_vox = voxel_size./voxel_size(1);
    norm_vox = norm_vox .* 0.2;
    
    % smooth a bit the mito we know the z is quite under sampled in comp to
    % x-y so I have to scale to be able to smooth
    BW = imresize3(BW,original_size .* norm_vox,'nearest');

    BW = imfill(BW,'holes');
    SE = strel('sphere',10);
    BW = imclose(BW,SE);

    BW = imresize3(BW,original_size,'nearest');

end

