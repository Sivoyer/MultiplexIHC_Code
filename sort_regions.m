
 
function [idx, rois, pos, k, pixel_region, R, Rlg, lgr, nm, smread, smcrop] = sort_regions(D, filename, xy, xml_files)
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
    lgr = cell(1,length(pos)/2);
    for y = 1:length(pos)
        R{y} = [pos{y}(3) pos{y}(1) (pos{y}(4) - pos{y}(3)) (pos{y}(2) - pos{y}(1))];    
    end
    p = length(pos)/2;
    Rlg = cell(1, length(pos)/2);
    for q = 1:length(pos)/2
        p = p + 1;
        if p > length(pos)/2
            lgr{q} = pixel_region{p}; %large bounding box format in pos
            Rlg{q} = R{p}; %large bounding box format in R
        end
    end

    regionnum = length(R)/2;
    fprintf("%d regions found on this slide\n", regionnum);
    
    nm = cell(1, length(R)/2);
    for w=1:length(R)/2
        if w <= 9
            nm{w} = sprintf('ROI0%d', w);
        else
            nm{w} = sprintf('ROI%d', w);
        end
        
        name = fullfile(D, 'Registered_Regions', nm{w});
        if exist(name, 'dir') ~= 1 || 7
            warning('off', 'MATLAB:MKDIR:DirectoryExists');
            mkdir(name);
        end
    end
    
    smread = cell(1, length(Rlg));
    smcrop = cell(1, length(Rlg));

    for g = 1:length(Rlg)
        smread{g} = {[R{g}(2)- Rlg{g}(2), (R{g}(2)- Rlg{g}(2)+R{g}(4))], [R{g}(1)-Rlg{g}(1), (R{g}(1)-Rlg{g}(1)+R{g}(3))]};
        smcrop{g} = [R{g}(1) - Rlg{g}(1), R{g}(2)-Rlg{g}(2), R{g}(3), R{g}(4)];
    end
end