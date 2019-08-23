
 
function [idx, rois, pos, k, pixel_region, R, nm, smread, smcrop] = sort_regions(D, filename, xy, xml_files)
    rois = [xy, upper(xml_files.name(1:end-4))]; %save each xml ROI
    idx = length(rois);
    k = find(contains(filename, rois(idx))); %get index of image
    pos = cell(1, length(rois)-1);
    
    for r = 1:length(rois)-1 
        row = [rois{r}(6) rois{r}(6)+(rois{r}(8) - rois{r}(7))];
        col = [rois{r}(1) rois{r}(1)+(rois{r}(2) - rois{r}(1))];
        pos{r} = [row,col]; %[row start, row stop, col start, col stop]
    end
    % pos{1} = 1.0040    1.4995    2.6968    3.1923
    pixel_region = cell(1,length(pos));
    for i = 1:length(pos)
        pixel_region{i} = {pos{i}([1,2]),pos{i}([3,4])};
    end

    %all regions
    R = cell(1, length(pos));
    for y = 1:length(pos)
        R{y} = [pos{y}(3) pos{y}(1) (pos{y}(4) - pos{y}(3)) (pos{y}(2) - pos{y}(1))];    
    end

    regionnum = length(R);
    fprintf("%d regions found on this slide\n", regionnum);
    
    % set read and crop region variables
        %read and crop should be the same now
        %TO DO: reduce this loop to create 1 variable for storing the region coordinates in crop
        %and read formats
    smread = cell(1, length(R));
    smcrop = cell(1, length(R));

    for g = 1:length(Rlg)
        smread{g} = {[R{g}(2), (R{g}(2)+R{g}(4))], [R{g}(1), (R{g}(1)+R{g}(3))]};
        smcrop{g} = [R{g}(1), R{g}(2), R{g}(3), R{g}(4)];
    end
    
   %create region folder struture inside of Registered_Regions folder
    nm = cell(1, length(regionnum));
    for w=1:length(regionnum)
        if w <= 9
            nm{w} = sprintf('ROI0%d', w);
        else
            nm{w} = sprintf('ROI%d', w);
        end
        
        %later make an input var so this is flexible
        registered_dir = 'Registered_Regions';
        
        name = fullfile(D, registered_dir, nm{w});
        if exist(name, 'dir') ~= 1 || 7
            warning('off', 'MATLAB:MKDIR:DirectoryExists');
            mkdir(name);
        end
    end
end