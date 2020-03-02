
 
function [imgczi,imagen, maxcol, maxrow, pixel_region_buff, cropregion, idxn, rois, k,nm] = sort_CZregions(D, filename, pos, xml_files, fpath)
    rois = [pos, upper(xml_files.name(1:end-3))]; %save each xml ROI
    idxn = length(rois);
    k = find(contains(filename, rois(idxn))); %get index of image
    imagen = fpath{k};

    imgczi = imageIO.CZIReader(imagen);

    maxcol = imgczi.width;
    maxrow = imgczi.height;
    
    %'position' formatting for CZI image from .cz file
    % pos = [X,Y,width,height]
    buff=1500;
    pixel_region_buff = cell(1,length(pos));
    cropregion = cell(1,length(pos));
    for i = 1:length(pos)
       rowstart = pos{i}(2)-buff;
       rowstop =pos{i}(2)+ pos{i}(4)+ buff; 
       colstart = pos{i}(1)-buff;
       colstop = pos{i}(1)+pos{i}(3)+buff;
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
     cropregion{i} = [buff, buff, (pos{i}(4)-pos{i}(3)), (pos{i}(2)-pos{i}(1))];
    end
    
    
    regionnum = length(pos);
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