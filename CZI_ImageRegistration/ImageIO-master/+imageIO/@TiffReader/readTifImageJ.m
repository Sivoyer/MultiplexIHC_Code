function [ data ] = readTifImageJ( obj, cols, rows, channels, stacks )
%READTIFIMAGEJ Read data from Tiff files in non-standard imageJ format
%
% Georgi Tushev
% November 2017
% sciclist@brain.mpg.de
%


    % check compression
    if ~strcmp(obj.compression, 'Uncompressed')
        error('TiffReader::readTifImageJ:: compressed images are not supported!');
    end

    % allocate image
    iC = numel(channels);
    iZ = numel(stacks);
    imageSize = [obj.height, obj.width, iZ, iC];
    img = zeros(prod(imageSize), 1, obj.datatype);
    
    % define reading
    readSize = obj.height * obj.width;
    precision = [ obj.datatype '=>'  obj.datatype ];
    indexStrips = (1: obj.stacks * obj.channels);
    offsets = obj.offsetToImg + obj.stripByteCounts .* (indexStrips - 1);
    index = 0;
    
    % progress bar
    progBar = TextProgressBar('TiffReader --> Extracting data: ', 30);
    progSteps = iC * iZ;
    progIndex = 1;
    
    for c = 1 : iC
        for z = 1 : iZ
            
            % update progress bar
            progBar.update(100 * progIndex/progSteps);
            progIndex = progIndex + 1;
            
            % set file id position
            iS = sub2ind([obj.stacks, obj.channels], stacks(z), channels(c));
            readOffset = offsets(iS);
            fidOffset = ftell(obj.filePtr);
            if readOffset ~= fidOffset
                fseek(obj.filePtr, offsets(iS), 'bof');
            end
            
            % read pixels
            pixels = fread(obj.filePtr, readSize, precision, obj.endianness);
            
            % collector
            img((index+1):(index+readSize)) = pixels;
            index = index + readSize;
            
        end
    end
    
    % rearrange to Matlab image
    img = reshape(img, imageSize);
    img = permute(img, [2, 1, 3, 4]);
    
    % restrict height x width
    data = img(cols, rows, :, :);
    

%{
data = zeros(length(rows), length(cols), length(channels), length(stacks), obj.datatype);

fseek(obj.filePtr, obj.offsetToImg, 'bof');
imageSize = obj.height * obj.width * obj.channels;
precision = [ obj.datatype '=>'  obj.datatype ];

idx = 1;
progBar = TextProgressBar('TiffReader --> Extracting data: ', 30);

for k = stacks
  progBar.update(idx/(length(stacks)) * 100);
  image = fread(obj.filePtr, imageSize, precision, obj.endianness);
  image = reshape(image, [obj.width, obj.height, obj.channels]);
  image = image';
  data(:, :, :, idx) = image(rows, cols, channels);
  idx = idx + 1;
end
%}



end

