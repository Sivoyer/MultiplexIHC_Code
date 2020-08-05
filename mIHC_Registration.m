%% Most current version 07/14/20 --**--
% sivagnan@ohsu.edu -- do not distribute

% Uses xml to read annotated ROI regions from ImageScope (Aperio Leica) SVS
% image annotation file.
% Each box is one ROI (larger registration region is automatically
% generated)
%Checks nuclei blue and red for matching keypoints
% Creates Redo folders for regions that cannot be registered and crops large
% region for manual registration
% For registered images, the ROI is cropped and they go into Registered_Regions/ROI*/ with the file
% name 'reg_' prepended.

%--**-- UPDATES--**--: 
% 7/14/20
% Boxes can be drawn in any direction - no need for upper left starting pt.
% 10/14/19
% No need for large region boxes. If they are on the XML, you will get an
% ROI for EACH box, large and/or small. --remove in 30d
% Creates a directory called Registration_Check in the Parent dir and
% writes low res image of each region for quick eval of registered images

%% Run this script >>>

Parent = uigetdir(pwd,'Select Directory with ALL image sets');

checkname = fullfile(Parent, 'Registration_Check');
if exist(checkname, 'dir') ~= 1 || 7
    warning('off', 'MATLAB:MKDIR:DirectoryExists');
    mkdir(checkname);
end

buff = 2000;
imageset = dir(fullfile(Parent));
for a = 3:length(imageset)
    if imageset(a).name == "Registration_Check" || imageset(a).name == ".DS_Store"
        continue
    else
     fprintf("Slide: %s\n", imageset(a).name);
     [D, xml_files, svsfiles, fpath, filename, numfiles] = get_image_sets(imageset(a), checkname);
     [xy]= parse_xml(xml_files);
     [image, maxcol, maxrow, pixel_region_buff, cropregion, idx, rois, pos, k, nm] = sort_regions(D, buff, filename, xy, xml_files, fpath);
     register_SURF(Parent,fpath, nm, D, filename,cropregion, pixel_region_buff, image, k);
    end
end

%% Run Color Deconvolution 

