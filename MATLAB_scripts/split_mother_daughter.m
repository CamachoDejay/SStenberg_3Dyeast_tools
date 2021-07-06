function [mother, daughter, Labels] = split_mother_daughter(B, voxel_size, scale, view_3d)
%SPLIT_MOTHER_DAUGHTER if we detect that a daughter cell is present then we
%try to slip the body in two via waterched. If you are new to programming
%notice that this is a recursive function, meainng that it calls itself
%under some conditions.

norm_vox = voxel_size./voxel_size(1);
norm_vox = norm_vox * scale;
new_pix = round(size(B) ./ [norm_vox(3), norm_vox(3), norm_vox(1)]);
iso_dow = imresize3(B,new_pix);
% SE = strel('sphere',3);
% C = imopen(C,SE);


dist_map = bwdist(~iso_dow);
dist_map = -dist_map;
dist_map(~iso_dow) = Inf;
Labels = watershed(dist_map);
Labels(~iso_dow) = 0;

Labels = imresize3(Labels,size(B),'nearest');
Labels(~B) = 0;

if max(Labels(:)) ~= 2
%     warning(['split failed, we get more than 2 objects out, smoothing the object more: ' num2str(scale*1.2)])
    if scale > 2
        warning('split failed, going out')
        mother = B;
        daughter = false(size(mother));
        Labels = bwlabeln(B);
        return
    else
        [mother, daughter, Labels] = split_mother_daughter(B, voxel_size, scale*1.2, view_3d);
        return
    end
end



stats = regionprops3(Labels,'Volume');

vol = stats.Volume;
[~,idx] = sort(vol);
daughter = Labels == idx(1);
mother   = Labels == idx(2);

L = bwlabeln(daughter);
if max(L(:)) > 1
    warning("more than one daughter, keeping largest")
    vol = regionprops3(daughter,'Volume');
    vol = vol.Volume;
    [~, idx] = max(vol);
    daughter = L == idx;
end

L = bwlabeln(mother);
if max(L(:)) > 1
    warning("more than one mother, keeping largest")
    vol = regionprops3(mother,'Volume');
    vol = vol.Volume;
    [~, idx] = max(vol);
    mother = L == idx;
end
        
if view_3d
    volumeViewer(B,Labels,'ScaleFactors',norm_vox)
end
end

