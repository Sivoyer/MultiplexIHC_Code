
% Takes a 'parent' directory that has folders containing full image sets
% with an XML annotation file and *.svs images to be registered
    
function [D, xml_files, svsfiles, fpath, filename, numfiles] = get_image_sets(imageset, checkname)

    clear rois
    clear Regions 
    clear xml_files
    clear xDoc
    clear pos
    clear R
    clear xy
    clear verticies
    clear arear
    clear areafilen
    clear amm2

    if exist(checkname, 'dir')
        D = fullfile(imageset.folder, imageset.name);

        %D = uigetdir(pwd,'Select Directory');
        svsfiles = dir(fullfile(D,'*.svs')); %only select svs files 
        xml_files = dir(fullfile(D, '*.xml')); %find XML file

        %get number of files for preallocation
        numfiles = length(svsfiles);
        if isempty(numfiles)
            error('There are no svs files in this directory')
        else
            fprintf(" %d svs image files found in %s \n", numfiles, D); %this should match the number of markers you have for slide

            %preallocate 
            fpath = cell(1, numfiles);
            filename = cell(1, numfiles);

            %store full file paths (fname)
            for r=1:numfiles
                fpath{r} = fullfile(svsfiles(r).folder, svsfiles(r).name);
            end

            %store image file name (filename)
            for s=1:numfiles
                filename{s} = upper(svsfiles(s).name(1:end-4));
            end
        end
    end
end
