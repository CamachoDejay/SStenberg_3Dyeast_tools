function [body_i,mito_i] = extract_bodies(cell_BW, mito_BW)
%EXTRACT_BODY Summary of this function goes here
%   Detailed explanation goes here
stats = regionprops3(cell_BW,'BoundingBox');


col_1 = floor(stats.BoundingBox(1));
col_2 = col_1 + ceil(stats.BoundingBox(4));

if col_1 == 0
    col_1 =1;
end
if col_2 > size(cell_BW,2)
    col_2 = size(cell_BW,2);
end

row_1 = floor(stats.BoundingBox(2));
row_2 = row_1 + ceil(stats.BoundingBox(5));

if row_1 == 0
    row_1 =1;
end
if row_2 > size(cell_BW,1)
    row_2 = size(cell_BW,1);
end

z_1 = floor(stats.BoundingBox(3));
if z_1 == 0
    z_1 =1;
end
z_2 = z_1 + ceil(stats.BoundingBox(6));
if z_2 > size(cell_BW,3)
    z_2 = size(cell_BW,3);
end

body_i = cell_BW(row_1:row_2,col_1:col_2, z_1:z_2);
mito_i = mito_BW(row_1:row_2,col_1:col_2, z_1:z_2);
end

