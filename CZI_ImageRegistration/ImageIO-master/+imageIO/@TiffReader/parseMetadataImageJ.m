function obj = parseMetadataImageJ(obj, imageDescription)
% parse custom multi-stack images

    % parse number of stacks
    stacks = str2double(regexp(imageDescription, 'images=(\d+)', 'tokens', 'once'));
    if ~isnan(stacks)
        obj.stacks = stacks;
    end
    
    % read strip byte counts
    try 
        
        stripByteCounts = obj.tiffPtr.getTag('StripByteCounts');
        obj.stripByteCounts = double(stripByteCounts);
        
    catch
        
        error('TiffReader::parseMetadataImageJ:: Tiff.Tag.StripByteCounts is missing!');
        
    end
    
    % read strip offset
    try
        
        stripOffset = obj.tiffPtr.getTag('StripOffsets');
        obj.offsetToImg = double(stripOffset(1));
        
    catch
        
        error('TiffReader::parseMetadataImageJ:: Tiff.Tag.StripOffsets is missing!');
        
    end
    
end

