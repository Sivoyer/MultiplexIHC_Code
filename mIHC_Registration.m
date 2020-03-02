%% Most current version 10/14/19 --**--
% sivagnan@ohsu.edu -- do not distribute

% Uses xml to read annotated ROI regions from ImageScope (Aperio Leica) SVS
% image annotation file.
% Make sure regions were drawn as rectangles starting from the upper left corner
% Each box is one ROI (larger registration region is automatically
% generated)

%Checks nuclei blue and red for matching keypoints

% Creates Redo folders for regions that cannot be registered and crops large
% region for manual registration
% For registered images, the ROI is cropped and they go into Registered_Regions/ROI*/ with the file
% name 'reg_' prepended.

%--**-- UPDATES--**--: 
% No need for large region boxes. If they are on the XML, you will get an
% ROI for EACH box, large and small. --remove in 30d
% Creates a directory called Registration_Check in the Parent dir and
% writes low res image of each region for quick eval of registered images

%% Run this script >>>

Parent = uigetdir(pwd,'Select Directory with ALL image sets');

checkname = fullfile(Parent, 'Registration_Check');
if exist(checkname, 'dir') ~= 1 || 7
    warning('off', 'MATLAB:MKDIR:DirectoryExists');
    mkdir(checkname);
end

imageset = dir(fullfile(Parent));
for a = 5:length(imageset)
    if imageset(a).name == "Registration_Check"
        continue
    else
     [D, xml_files, svsfiles, fpath, filename, numfiles] = get_image_sets(imageset(a), checkname);
     [xy]= parse_xml(xml_files);
     [image, maxcol, maxrow, pixel_region_buff, cropregion, idx, rois, pos, k,nm] = sort_regions(D, filename, xy, xml_files, fpath);
     register_SURF(Parent,fpath, nm, D, filename,cropregion, pixel_region_buff, image, k);
    end
end

%% Run Color Deconvolution 

