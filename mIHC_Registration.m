%% Most current version 02/13/19 --**--
% sivagnan@ohsu.edu -- do not distribute

% Uses xml to read annotated ROI regions
% Make sure regions were selected in this order: from upper left corner
% Order of boxes: small1, small2, small3, large1, large2, large3 etc.

%Checks nuclei blue and red for matching keypoints

% Creates Redo folders for regions that cannot be registered and crops large
% region for manual registration
% For registered images, the ROI is cropped and they go into Registered_Regions/ROI*/ with the file
% name 'reg_' prepended.

%--**-- UPDATES--**--: 
% recognizes reg and NONREG files in Registered_Regions
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
for a = 3:length(imageset)
    if imageset(a).name == "Registration_Check"
        continue
    else
     [D, xml_files, svsfiles, fpath, filename, numfiles] = get_image_sets(imageset(a), checkname);
     [xy]= parse_xml(xml_files);
     [idx, rois, pos, k, pixel_region, R, Rlg, lgr, nm, smread, smcrop] = sort_regions(D, filename, xy, xml_files);
     register_SURF(Parent, xy, xml_files, fpath, nm, pos, D, filename, lgr, smcrop, pixel_region);

    end
end

%% Run Color Deconvolution 

