

function register_SURF(Parent,fpath, nm, D, filename,cropregion, pixel_region_buff, image, k)
    n_smpl = 50000; % depend (maximum number of features)
    skip = {'NUCLEI', 'HEM', 'HEMATOXYLIN', 'FIRSTHEMA', 'FIRSTH', 'FIRSTHEM1', 'SECONDHEM'};    
        
    for t=1:length(nm) %for each region
       
        %find which marker images are already registered
        rrdone = dir(fullfile(D, 'Registered_Regions',nm{t}));
        rrname = cell(1,length(rrdone));
        for y=1:length(rrdone)
            rrname{y} = rrdone(y).name(1:end-4);
        end
        
        %read in nuc file and get image info
        nuc_ref = imread(image,1,'PixelRegion', pixel_region_buff{t});
        RefB =  nuc_ref(:,:,3); %blue channel
        RefR = nuc_ref(:,:,2); %red channel
        
        tags.ImageLength = size(nuc_ref,1);
        tags.ImageWidth = size(nuc_ref,2);
        tags.SamplesPerPixel = size(nuc_ref,3);
        tags.Photometric = Tiff.Photometric.RGB;
        tags.BitsPerSample = 8;
        tags.TileWidth = 240;
        tags.TileLength = 240;
        tags.Compression = Tiff.Compression.JPEG;
        tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
        tags.Software = 'MATLAB';
        
        %Find SURF features in Nuclei Ref and select strongest
        ptsRef1 = detectSURFFeatures(RefB); 
        ptsRef1 = ptsRef1.selectStrongest(min(n_smpl, length(ptsRef1)));
        [featuresRef1, validPtsRef1] = extractFeatures(RefB, ptsRef1);
        outputView1 = imref2d( [size(RefB,1) size(RefB,2)]);
   
        for z = 1:length(filename) %for each marker file
              %if file exists already OR if nuclei file go to next indx
            donefilename = (sprintf("reg_%s_%s", filename{z}, nm{t}));
            manregdone = (sprintf("reg_NONREG_%s_%s", filename{z}, nm{t}));
            next = regexp(filename{z},skip,'match');
            cont = regexp(rrname,donefilename,'match');
            cont2 = regexp(rrname,manregdone,'match');

            %new_img = sprintf('%s/Registered_Regions/%s/reg_%s_%s.tif', D, nm{t}, filename{z}, nm{t});
            %fprintf("%s", fullfilename{z});
            if isempty(find(~cellfun(@isempty,cont),1))==0 || isempty(find(~cellfun(@isempty,next), 1)) == 0 || isempty(find(~cellfun(@isempty,cont2),1))==0
               continue
            end

            wObj = imread(fpath{z},'PixelRegion', pixel_region_buff{t});
            channel = { wObj(:,:,1),  wObj(:,:,2),  wObj(:,:,3)}; %split channels on HR
            Obj1=channel{3};

            fprintf("Processing %s ...\n", filename{z});

            %get SURF features from determined object channel
            ptsObj = detectSURFFeatures(Obj1);
            
            %if NO points found (rare)
            if ptsObj.Count == 0    
                redo = sprintf('%s/Redo_%s', D, nm{t});
                non_reg = sprintf('%s/nonreg_%s_%s.tif', redo, filename{z}, nm{t});
                warning('off', 'MATLAB:MKDIR:DirectoryExists'); 
                if exist(redo, 'dir') ~= 1 || 7
                    mkdir(redo);
                end
                imnamed = Tiff(non_reg); 
                setTag(imnamed, tags);
                write(imnamed, wObj, 'tif');
                fprintf("Bummer, %s was not automatically registered, please try manually. Sorry!\n", filename{z});
                %save og nuclei also
                new_nuc = sprintf('%s/NUCLEI_%s_%s.tif', redo, filename{k}, nm{t});
                if exist(new_nuc, 'file') ~= 2
                    rrnuc = Tiff(sprintf('%s/NUCLEI_%s_%s.tif', redo, filename{k}, nm{t}));
                    setTag(rrnuc, tags); %set Bigtiff tags
                    write(rrnuc, nuc_ref); %writes the bigtiff image
                    close(rrnuc); %close the image
                end
                continue
            else
            ptsObj = ptsObj.selectStrongest(min(n_smpl, length(ptsObj)));
            [featuresObj, validPtsObj] = extractFeatures(Obj1, ptsObj);

            indxPairs = matchFeatures(featuresRef1, featuresObj, 'MaxRatio', 0.8, 'Unique', true);
            matchedRef = validPtsRef1(indxPairs(:,1));
            matchedObj = validPtsObj(indxPairs(:,2));

            ip = length(indxPairs);

            [tform, inlierDistorted, ~, status] = estimateGeometricTransform(...
                         matchedObj, matchedRef,  'similarity', 'MaxNumTrials',100000, 'Confidence',96, 'MaxDistance', 5);

            %disp(length(inlierDistorted))
            kp = length(inlierDistorted);
            fprintf("%d matching keypoints found out of %d in Ch1 ref\n", kp, ip);
            end
            
            %check other Nuclei channel for better matches if there aren't
            %enough kp
            if kp <= 5 
               warning('Hm, may not have enough matching keypoints to register %s under this channel- trying another channel...', filename{z});   
             
                %Find SURF features in Nuclei Ref and select strongest
                ptsRef2 = detectSURFFeatures(RefR); 
                ptsRef2 = ptsRef2.selectStrongest(min(n_smpl, length(ptsRef2)));
                [featuresRef2, validPtsRef2] = extractFeatures(RefR, ptsRef2);

                indxPairs2 = matchFeatures(featuresRef2, featuresObj, 'MaxRatio', 0.8, 'Unique', true);
                matchedRef2 = validPtsRef2(indxPairs2(:,1));
                matchedObj2 = validPtsObj(indxPairs2(:,2));

                ip2 = length(indxPairs2);

                [tform2, inlierDistorted2, ~, ~] = estimateGeometricTransform(...
                             matchedObj2, matchedRef2,  'similarity', 'MaxNumTrials',50000, 'Confidence',96, 'MaxDistance', 5);
                kp2 = length(inlierDistorted2);
                fprintf("%d matching keypoints found out of %d in Ch2 ref\n", kp2, ip2);
            
                %select which transformation to use (nuclei red or blue) based
                %on better keypoints
                if kp < kp2
                    tform = tform2;
                    fprintf("Ch1: %d kp, Ch2: %d kp - selecting channel with more kp", kp, kp2);
                end
                clear kp2
                clear kp
            end
            
            lastwarn('');
            warped = cell(1, length(channel));
            if status == 0
                for u=1:length(channel)
                       warped{u} = imwarp(channel{u}, tform, 'OutputView', outputView1);
                end
            end
            [~, msgid] = lastwarn;
            
            %if it does not register, catch the warning
            if contains(msgid, 'MATLAB:nearlySingularMatrix') == 1
                redo = sprintf('%s/Redo_%s', D, nm{t});
                non_reg = sprintf('%s/nonreg_%s_%s.tif', redo, filename{z}, nm{t});
                warning('off', 'MATLAB:MKDIR:DirectoryExists'); 
                if exist(redo, 'dir') ~= 1 || 7
                    mkdir(redo);
                end
                imnamed = Tiff(non_reg); 
                setTag(imnamed, tags);
                write(imnamed, wObj, 'tif');
                fprintf("Bummer, %s was not automatically registered, please try manually. Sorry!\n", filename{z});
                %save og nuclei also
                new_nuc = sprintf('%s/NUCLEI_%s_%s.tif', redo, filename{k}, nm{t});
                if exist(new_nuc, 'file') ~= 2
                    rrnuc = Tiff(sprintf('%s/NUCLEI_%s_%s.tif', redo, filename{k}, nm{t}));
                    setTag(rrnuc, tags); %set Bigtiff tags
                    write(rrnuc, nuc_ref); %writes the bigtiff image
                    close(rrnuc); %close the image
                end
                continue
            end
            
            Registered = cat(3, warped{1}, warped{2}, warped{3}); %combine all RGB warps for final image
            new_temp = sprintf('%s/Registered_Regions/%s/reg_%s_%s.tif', D, nm{t}, filename{z}, nm{t});
            if exist(new_temp, 'file') ~=2  %if file doesn't exist (check again)
                new_img = sprintf('%s/Registered_Regions/%s/reg_%s_%s.tif', D, nm{t}, filename{z}, nm{t});
                reg_check_img = sprintf('%s/Registration_Check/regck_%s_%s.tif', Parent, filename{z}, nm{t});
                reg_crop = imcrop(Registered, cropregion{t});
                imwrite(reg_crop, new_img);
                fprintf("%s %s image registered! \n", nm{t}, filename{z});
                reg_crop_LR = imresize(reg_crop, 0.0625);
                imwrite(reg_crop_LR, reg_check_img);

                if exist(new_img, 'file') ==2 
                    clear Registered
                    clear warp
                    clear channel
                    clear new_temp
                    clear trform
                    clear tform
                end
            end
        end
        %write image for registration check folder
        nuc_crop_name = sprintf('%s/Registered_Regions/%s/NUCLEI_%s_%s.tif', D, nm{t}, filename{k}, nm{t});
        nuc_check_img = sprintf('%s/Registration_Check/NUCLEIck_%s_%s.tif', Parent, filename{k}, nm{t});
        nuc_crop = imcrop(nuc_ref, cropregion{t});
        nuc_crop_LR = imresize(nuc_crop, 0.0625);
        imwrite(nuc_crop, nuc_crop_name);
        imwrite(nuc_crop_LR, nuc_check_img);
        fprintf("%s Registration complete!\n", nm{t});
    end    
end
