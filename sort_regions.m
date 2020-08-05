
 
function [image, maxcol, maxrow, pixel_region_buff, cropregion, idx, rois, pos, k,nm] = sort_regions(D, buff, filename, xy, xml_files, fpath)
    rois = [xy, upper(xml_files.name(1:end-4))]; %save each xml ROI
    idx = length(rois);
    k = find(contains(filename, rois(idx))); %get index of image
    pos = cell(1, length(rois)-1);
    image = fpath{k};
    
    imgsizeinfo = imfinfo(image);
    maxcol = imgsizeinfo(1).Width;
    maxrow = imgsizeinfo(1).Height;
    
     %'position' formatting
    cpos = cell(1,length(pos));
    for r = 1:length(rois)-1 
        croi = sortrows(rois{r});
        crow = [croi(5) croi(6)];
        ccol = [croi(1) croi(3)];
        cpos{r} = [crow,ccol]; %[row start, row stop, col start, col stop]
    end
    
    %pixel region formatting for reading with buffer
    pixel_region_buff = cell(1,length(cpos));
    cropregion = cell(1,length(cpos));
    for i = 1:length(cpos)
       rowstart = cpos{i}([1])-buff;
       rowstop =cpos{i}([2])+buff; 
       colstart = cpos{i}([3])-buff;
       colstop = cpos{i}([4])+buff;
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
     cropregion{i} = [buff, buff, (cpos{i}([4])-cpos{i}([3])), (cpos{i}([2])-cpos{i}([1]))];
    end
    
    regionnum = length(pixel_region_buff);
    fprintf("%d regions found on this slide\n", regionnum);
%     

   %create region folder struture inside of Registered_Regions folder
    nm = cell(1, regionnum);
    for w=1:regionnum
        nm{w} = sprintf('ROI%02d', w);
        registered_dir = 'Registered_Regions';
        
        name = fullfile(D, registered_dir, nm{w});
        if exist(name, 'dir') ~= 1 || 7
            warning('off', 'MATLAB:MKDIR:DirectoryExists');
            mkdir(name);
        end
    end
end