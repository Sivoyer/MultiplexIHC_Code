# ImageIO
**Reading and writing image data formats with MatLab.**

This library aims to implement a generic Matlab wrapper for several image format types. It uses existing libraries (such as Matlab's bindings for Bioformat), define Matlab wrappers for existing C libraries (such as TiffLib) or implements from scratch file format specifications (like CZI) to achieve the goal.

The library defines an abstract class called **ImageIO** which defines the image metadata as well as a few methods which every subclass is required to implement.

There are two ways to use this library to read the data:

1. via class construction: based on the input data, the user selects the appropriate class to create an object instance representing the data. A later call to othe **read** method allows the user to extract the desired data.
2. using the **imageIORead** function: a function which accepts as input a filename will check the filetype and will create the appropriate object to extract the required data and metadata. More info about it cluld be achieved by typing 
```matlab
doc imageIORead
```

In both cases the user can specify a subset of the data to extract. For more info on how to get a subset of the input data, refer to the *Examples* section below or check the Matlab help for the **imageIORead.m** function

## APIs

The library relies on other software. In particular we use these APIs:

1. BioFormats (version 5.1.10)
2. TiffLib (version 4.0.5)
3. OpenExr (version 2.2.0)
4. Andor Sif Reader (dll for windows, Linux requires [Andor SDK](https://github.com/RJ3/AndorSIF))
5. Imspector omex (reads .msr and .obf files on windows)

## Reading metadata

The **ImageIO** class defines a set of common information and metadata about the input file: 

```matlab
fileName;          % Image filename
fileFullPath;      % Full filename, together with absolute path
fileFolder;        % Folder containing the image
fileExt;           % File extension
height;            % Image height / number of rows
width;             % Image width / number of columns
channels;          % Number of image channels
stacks;            % Image stacks (Z axis)
series;            % number of series (assume it is usually one)
time;              % Image timeseries
tile;              % Image tiles per stack
numTilesRow;       % Image tiles in vertical direction
numTilesCol;       % Image tiles in horizontal direction
rowTilePos;        % vertical position of tile
colTilePos;        % horizontal position of tile
pixPerTileRow;     % number of rows of pixels in a tile
pixPerTileCol;     % number of cols of pixels in a tile
tileOverlap;       % overlap between 2 adjacent tiles
channelInfo;       % (if available) color info of each channel
datatype;          % Image datatype (uint8, int16, ...)
scaleSize;         % Pixel physical size (x,y,z)
scaleUnits;        % Unit of measurement of scaleSize
scaleTime;        
timePixel;         % Time it takes to acquire a single pixel, 
                   % especially relevant in point-scanning devices 
                   % in which each physical location of the sample 
                   % is measured at a different time (focused laser beam is scanned across the sample)
timeLine;          % Time it takes to acquire a single line of pixels, 
                   % again mainly for point scanning devices. The value
                   % usually differs from timePixel * numberOfPixels
                   % since only a portion of the scan period can be 
                   % used for data acquisition
timeFrame;         % Time it takes to acquire a single frame
timeStack;         % Time it takes to acquire a stack 
zoom;              % In a point scanning device the observed field
                   % can be changed by simply changing the range of 
                   % the scanning process (in contrast to a camera 
                   % based system, where the magnification is fixed). 
gain;              % Many light-detectors have the ability to "amplify"
                   % the signal. This is usually described by a single
                   % "gain" parameter, though the physical meaning of 
                   % this parameter depends on the type of detector. 
                   % For point scanning devices these are photo 
                   % multiplier tubes (PMT), the gain is then typically 
                   % the voltage used to accelerate the free electrons 
                   % towards the next cathode
wavelengthExc;
wavelengthEm;
refractionMedia;
refractionIndex;
NA;                % Numerical aperture
microscopeName;
microscopeType;
objectiveMagnification;
objectiveName;
originalMetadata;       % as presented originally in the file. Each
                        % file format has a specific type of metadata,
                        % so no assumption is made on the type of
                        % data (string, struct or cell are all
                        % valid formats)
```

## Example usage

For details regarding usage of specific classes, please check the Matlab documentation of each class in the **+imageIO** package.

### READING IMAGE DATA

Here's a description on how to use the **imageIORead** function:

**IMAGEIOREAD**: Main function for reading image data using imageIO library
   imageIORead provides a single interface for reading image data using
   any of the classes specified in the +imageIO package. The easiest way
   to use the function is to pass a filename as argument: the function
   will return the whole content of the image. Several arguments can be
   passed to restrict the amount of data returned by the function or, in
   case the user passed a folder as input, to specify the file pattern of
   the images to be read in the folder. When the user specifies a second
   output argument the function returns also the image reader object,
   which can be used later to read other data without requiring to parse
   again the file to extract all the metadata information
 
**INPUT**

   *file*: [mandatory] the input image to be read or a folder containing a collection of
      tiff images

**NAME-VALUE INPUT ARGUMENTS**

   *filePattern*: used only when 'file' is a directory.
     Specifies the pattern used to number the images. It uses the same
     formatting rules used by Matlab and C 'sprintf' function. For example, 
     if the folder contains files like *'img_001.tif'*, *'img_002.tif'* and so on, 
     the file pattern will be *'img_%03d.tif'*. A more complicated
     pattern could be *'img_UII%02dX%02d_%02d_xyz-Table_%04d.ome.tif'*,
     where there are four number representing the X/Y tile position,
     the channel and the Z value. If no pattern is specified, it is
     assumed that the images represent a Z stack whose order is
     determined by alphabetical sorting of the filenames
   
   *dimOrder*: used only when 'file' is a directory.
     Represents the order of the dimensions presented in the file
     pattern. Each dimension is represented by a single character, uppercase.
     Valid values could be *'Z'*, *'XYCZ'*, *'T'*. If not specified,
     the value depends on the number of format tags in the file
     pattern: if 0 or 1 format tags specified, it will be *'Z'*, if 2
     format tags specified, it will be *'XY'*, if 3 tags specified, it
     will be *'XYC'*, if four tags specified, it will be *'XYCZ'*. With
     five tags, it will be *'XYCZT'*
   
   *overlap*: used only when 'file' is a directory.
     Expected overlap (in percentage) between the tiles. If 'file' is not
     a directory, the value is inferred by the metadata contained in the
     file and, in that case, any user provided value would be overridden.
     If not specified, assumes 0
     
  *separateTile*: Used only for LSM or CZI files.
     boolean, option valid only for multitile datasets. If
     set to true, the function will not merge all the tiles in a single
     plane together, but rather will leave them separate. That means that
     one or 2 more dimensions are added to the data, containing the indices
     of the tile rows and columns. Default is false
   
   *closeFile*: Specify if the file should be closed after reading the data.
     The default is true, should be set to false if the user wants to
     perform multiple reads on the same imageIOPtr.
   
   The following name value parameters are used to extract only part of
   the data. The user can specify subset
   of the images by specifying the dimension and the interval of interest
   as a Name-Value pair. If no arguments are given, all the data is
   extracted. For the Cols and Rows argument, the interval is intented
   per-tile. For example, if the user wants to keep only the top left tile,
   he won't specify any subset for *'Rows'* and *'Cols'* (that is, take them all),
   but will specify the subset *'TileRow' = 1* and *'TileCol' = 1*. On the other
   hand, if the user wants to extract from a 800x600 image a version which
   is subsampled by a factor 2 he will specify *Rows = 1:2:600*
   and *Cols = 1:2:800*, and no subset for the tiles (i.e. use
   all tiles).
   
   *Cols*: Specify which columns to extract
   
   *Rows*: Specify which rows to extract
   
   *Channels*: Specify which channels to extract
   
   *Planes*: Specify which planes to extract
   
   *Time*: Specify which timeseries to extract
   
   *TileRows*: Specify which row tiles to read.
   
   *TileCols*: Specify which col tiles to read.

**OUTPUT**

   *data*: image data, up to 5 dimension (in this order: XYCZT). If only one
   	channel is extracted (or the input is single channel), the singleton
   	dimension relative to channel is squeezed.
   
   *metadata*: structure containing all of the 
   
   *originalMetadata*: When available, an object containing all the
   metadata extracted from the file
     
**EXAMPLES**

   Reading all the content from single files:
   
 ```matlab
 tiffData = imageIORead('myTiff.tif');
 cziData = imageIORead('aCZIFile.czi');
```
   
   Reading a Z stack from a folder
   
 ```matlab
tiffStack = imageIORead('folderWithImages'); % no need to specify pattern
tiffStack = imageIORead('folderWithImages', 'Planes', 100:150); % subset
```
   
   Reading complex datasets from a folder
   
```matlab
multiChTiffStack = imageIORead('folder', 'filePattern', 'filePattern_Ch_%d_Z_%04d.tif', 'dimOrder', 'CZ');
```
   
   Reading a subset from complex datasets from a folder
   
 ```matlab
multiChTiffStack = imageIORead('folder', 'filePattern', 'filePattern_Pos_%02dx%02d_Ch_%d_Z_%04d.tif', 'dimOrder', 'YXCZ', 'Channels', 2, 'TileRows', 1:2, 'TileCols', 1:3);
 ```
   
   Read from file of size 4000x3000, subset of a factor 4, only first and third channel
   
 ```matlab
bioReaderData = imageIORead('sample.lsm', 'Channels', [1 3], 'Cols', 1:4:4000, 'Rows', 1:4:3000);
 ```

### WRITING IMAGE DATA

Writing functionalities are currently limited. We write 3D + channels information image data as Tiff stacks, with an additional xml file containing the metadata, and 4D (and above) data as matlab mat file.

Here's a description on how to use the **imageIOWrite** function:

**imageIOWrite** Write to disk data extracted using imageIO toolbox
    imageIOWrite provides an interface to write on disk data which has been
    extracted using the imageIO toolbox. The function behaves differently
    depending on the size of the data input parameter. If the data has a
    number of dimensions which is less than or equals to four (and one of
    the dimensions, the one representing the channels, has size of at most
    three), then the data will be written as a Tiff file. An additional
    xml file will contain additional metadata information who couldn't be
    stored in any of the Tiff tags. If the number of dimensions is bigger
    than four, the file will be saved as a .mat object. This object will
    contain 2 fields, one for the actual data content and the other  for the 
    metadata extracted by the imageIO toolbox
 
**INPUT**
  
  *data*: mandatory, it contains the actual image data to be written
      on disk
  *metadata*: metadata obtained when using the imageIO Toolbox
  *filename*: Mandatory, it's the output filename. If the filename doesn't 
      end in *.tif, the extension will be added automatically.
  
**OUTPUT**
  
  *success*: boolean flag, true if writing was successful, false otherwise
 
**EXAMPLE**
  
  ```matlab
  [data, metadata] = imageIORead('/some/test/data/img.czi'); %get Data
  success = imageIOWrite(data, metadata, 'myData.tif');
  ``` 


## Folder containing test data
smb://storage.corp.brain.mpg.de/data/Projects/ImageIO

## Targeted image file formats
* TIFF --> open using Tiff library
* LSM --> open using our Matlab implementation
* CZI --> open using our Matlab implementation
* MSR --> open using omex read functionalities provided by Imspector
* OBR --> open using omex read functionalities provided by Imspector
* XML based single images
* LIF
* SIF --> open using Andor library and Matlab files from File Exchange
* Sutter TIFF files --> Using our extension to Tiff library
* Slide Book Container (not in bioformats?)
* HDF --> Natively supported by Matlab
* multiple TIFF files in a folder --> opened using our Matlab implementation

## Things that could be required in the future

* Read multiple stacks (datsets with different dimension from within the same file)
* Read Knossos (ie multiple files)
* Read Prairie (ie multiple files)
* Deal with line averages, frame averages, line steps, pixel steps 
* Read stacks or read images by default 
* Check or not for wildcards (slow)

## Current limitations of Bioformats
List of formats supported by bioformat:
https://www.openmicroscopy.org/site/support/bio-formats5.1/supported-formats.html#term-ratings-legend-and-definitions
BioFormat cannot cope with a bunch of datasets, both in LSM and CZI format

Possible disadvantages of open bioformat:

*	conversion to the OME format when opening an image (which guarantees interoperability, but also overhead)
*	Matlab interface is quite poor at the moment, and extracting specific metadata information is quite frustrating.
* Write is supported only for a fraction of the bioformat compatible formats.
* BioFormat does not support series

