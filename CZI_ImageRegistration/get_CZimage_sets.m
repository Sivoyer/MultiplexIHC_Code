% Takes a 'parent' directory that has folders containing full image sets
% with an XML annotation file and *.svs images to be registered
    
function [D, xml_files, czifiles, fpath, filename, numfiles] = get_CZimage_sets(imageset, checkname)

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
        czifiles = dir(fullfile(D,'*.czi')); %only select svs files 
        xml_files = dir(fullfile(D, '*.cz')); %find XML file

        %get number of files for preallocation
        numfiles = length(czifiles);
        if isempty(numfiles)
            error('There are no czi files in this directory')
        else
            fprintf(" %d czi image files found in %s \n", numfiles, D); %this should match the number of markers you have for slide

            %preallocate 
            fpath = cell(1, numfiles);
            filename = cell(1, numfiles);

            %store full file paths (fname)
            for r=1:numfiles
                fpath{r} = fullfile(czifiles(r).folder, czifiles(r).name);
            end

            %store image file name (filename)
            for s=1:numfiles
                filename{s} = upper(czifiles(s).name(1:end-4));
            end
        end
    end
end
