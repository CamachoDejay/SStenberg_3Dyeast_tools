function [vol,  voxel_size] = load_volume(tif2load)
%LOAD_VOLUME Summary of this function goes here
    %   Detailed explanation goes here
    reader = bfGetReader(tif2load);
    % get the global meta data
    globalMeta = reader.getGlobalMetadata;
    pix_size = (globalMeta.get('XResolution')); % pixels per micron
    pix_size = 1/pix_size; % size of 1 pexel in microns
    z_spacing = (globalMeta.get('Spacing')); % in microns

    voxel_size = [pix_size, pix_size, z_spacing];
    im = bfopen(tif2load);
    nPlanes = size(im{1,1});


    vol = im{1,1}{1,1};
    for i = 2:nPlanes 
        tmp = im{1,1}{i,1};
        vol = cat(3,vol,tmp);
    end

end

