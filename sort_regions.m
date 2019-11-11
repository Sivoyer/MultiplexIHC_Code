
 
function [image, maxcol, maxrow, pixel_region_buff, cropregion, idx, rois, pos, k,nm] = sort_regions(D, filename, xy, xml_files, fpath)
    rois = [xy, upper(xml_files.name(1:end-4))]; %save each xml ROI
    idx = length(rois);
    k = find(contains(filename, rois(idx))); %get index of image
    pos = cell(1, length(rois)-1);
    image = fpath{k};
    
    imgsizeinfo = imfinfo(image);
    maxcol = imgsizeinfo(1).Width;
    maxrow = imgsizeinfo(1).Height;
    
    %'position' formatting
    for r = 1:length(rois)-1 
        row = [rois{r}(6) rois{r}(6)+(rois{r}(8) - rois{r}(7))];
        col = [rois{r}(1) rois{r}(1)+(rois{r}(2) - rois{r}(1))];
        pos{r} = [row,col]; %[row start, row stop, col start, col stop]
    end
    % pos{1} = 0.4541    0.7053    1.7944    2.4700
    
    %pixel region formatting for reading with buffer
    buff=1500;
    pixel_region_buff = cell(1,length(pos));
    cropregion = cell(1,length(pos));
    for i = 1:length(pos)
       rowstart = pos{i}([1])-buff;
       rowstop =pos{i}([2])+buff; 
       colstart = pos{i}([3])-buff;
       colstop = pos{i}([4])+buff;
       if colstart <= 0
           colstart = 1;
       end
       if rowstart <=0
           rowstart = 1;
       end
       if colstop > maxcol
           colstop = maxcol;
       end
       if rowstop > maxrow
           rowstop = maxrow;
       end
     pixel_region_buff{i} = {[rowstart, rowstop],[colstart, colstop]};
     cropregion{i} = [buff, buff, (pos{i}([4])-pos{i}([3])), (pos{i}([2])-pos{i}([1]))];
    end
    
    regionnum = length(pixel_region_buff);
    fprintf("%d regions found on this slide\n", regionnum);
%     
    
   %create region folder struture inside of Registered_Regions folder
    nm = cell(1, regionnum);
    for w=1:regionnum
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