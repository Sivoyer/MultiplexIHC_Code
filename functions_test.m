


Parent = uigetdir(pwd,'Select Directory with ALL image sets');

imageset = dir(fullfile(Parent));
for a = 3:length(imageset)
     [D, xml_files, svsfiles, fpath, filename, numfiles] = get_image_sets(imageset(a));
     [xy, arear, amm2]= parse_xml(xml_files);
     [rois, pos, k, pixel_region, R, Rlg, lgr, nm, smread, smcrop] = sort_regions(D, filename, xy, xml_files);
     register_SURF(xy, xml_files, fpath, nm, pos, D, filename, lgr, smcrop, pixel_region, amm2);
end
