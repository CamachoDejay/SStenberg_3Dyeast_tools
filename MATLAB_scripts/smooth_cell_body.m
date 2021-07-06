function [B] = smooth_cell_body(B)
%SMOOTH_CELL_BODY soft smooth of the cell body, we can not do it much in
%here as a daughter cell might be present.

assert(islogical(B),'input should be binary image');
size_test = size(B) > [14, 14 ,8];
assert(all(size_test), 'volume is too small');

B = imfill(B,'holes');
SE = strel('sphere',4);
B = imclose(B,SE);
SE = strel('disk',7);
B = imclose(B,SE);
SE = strel('disk',5);
B = imopen(B,SE);

L = bwlabeln(B);

if max(L(:)) > 1
    warning("Smoothing split a bit the body, keeping largest")
    vol = regionprops3(B,'Volume');
    vol = vol.Volume;
    [~, idx] = max(vol);
    B = L == idx;
end

