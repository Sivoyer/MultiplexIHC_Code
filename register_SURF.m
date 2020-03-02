

function register_SURF(Parent,fpath, nm, D, filename,cropregion, pixel_region_buff, image, k)
    n_smpl = 100000; % depend (maximum number of features)
    skip = {'NUCLEI', 'HEM', 'HEMATOXYLIN', 'FIRSTHEMA', 'FIRSTH', 'FIRSTHEM1', 'SECONDHEM'};    
        
    for t=1:length(nm) %for each region
       
        %find which marker images are already registered
        roidir = fullfile(D, 'Registered_Regions',nm{t});
        rrdone = dir(roidir);
        rrname = cell(1,length(rrdone));
        for y=1:length(rrdone)
            rrname{y} = rrdone(y).name(1:end-4);
        end
        
        %read in nuc file and get image info
        nuc_ref = imread(image,1,'PixelRegion', pixel_region_buff{t});
        RefB =  nuc_ref(:,:,3); %blue channel
        RefR = nuc_ref(:,:,2); %red channel

        %Find SURF features in Nuclei Ref and select strongest
        ptsRef1 = detectSURFFeatures(RefB); 
        ptsRef1 = ptsRef1.selectStrongest(min(n_smpl, length(ptsRef1)));
        [featuresRef1, validPtsRef1] = extractFeatures(RefB, ptsRef1);
        outputView1 = imref2d( [size(RefB,1) size(RefB,2)]);

        %cd45_reg_crop to be used for ref image

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
         
                imwrite(wObj, non_reg, 'tif');
                fprintf("Bummer, %s was not automatically registered, please try manually. Sorry!\n", filename{z});
                %save og nuclei also
                new_nuc = sprintf('%s/NUCLEI_%s_%s.tif', redo, filename{k}, nm{t});
                if exist(new_nuc, 'file') ~= 2
                    imwrite(nuc_ref, new_nuc, 'tif'); %writes the bigtiff image
                end
                continue
            end
            
            n_pts = 20000;
            ptsObj = ptsObj.selectStrongest(min(n_pts, length(ptsObj)));
            [featuresObj, validPtsObj] = extractFeatures(Obj1, ptsObj);

            indxPairs = matchFeatures(featuresRef1, featuresObj, 'MaxRatio', 0.8, 'Unique', true);
            matchedRef = validPtsRef1(indxPairs(:,1));
            matchedObj = validPtsObj(indxPairs(:,2));

            ip = length(indxPairs);

            [tform, inlierDistorted, ~, status] = estimateGeometricTransform(...
                         matchedObj, matchedRef,  'similarity', 'MaxNumTrials',100000, 'Confidence',96, 'MaxDistance', 1.8);

            
           % imshowpair(wObj, RefB,'Scaling', 'Joint', 'ColorChannels', 'magenta-green');
           % imshowpair(wObj, RefB,'falsecolor');

            %disp(length(inlierDistorted))
            kp = length(inlierDistorted);
            fprintf("%d matching keypoints found out of %d in Ch1 ref\n", kp, ip);

            % Try CD45       
            if kp <= 5 %if not enough kp
                warning('Hm, may not have enough matching keypoints to register %s under this channel- trying CD45 reference...', filename{z});   

               % Try using CD45 ref
               cd45_svs = dir(fullfile(D, '*CD45*'));
               cd45_fname = upper(cd45_svs(1).name(1:end-4));
               cd45_reg = (sprintf("reg_%s_%s", cd45_fname, nm{t}));
               cd45_fullfn = sprintf("%s/%s.tif", roidir, cd45_reg);
               
               %if the registered image doesn't exist, register svs cd45
               if exist(cd45_fullfn, 'file')~=2

                   fprintf("Trying CD45 registration\n");
                   cd45im = fullfile(cd45_svs(1).folder, cd45_svs(1).name);
                   ref_cd45 = imread(cd45im,1,'PixelRegion', pixel_region_buff{t});

                    wCref = ref_cd45;
                    channelRef = { wCref(:,:,1),  wCref(:,:,2),  wCref(:,:,3)}; %split channels on HR
                    cRef1=channelRef{1};

                    fprintf("Processing registered CD45 image\n");

                    %Get KP for CD45 to register to Nuc first
                    cd45ptsObj = detectSURFFeatures(cRef1);

                    n_pts = 20000;
                    cd45ptsObj = cd45ptsObj.selectStrongest(min(n_pts, length(cd45ptsObj)));
                    [cd45featuresObj, cd45validPtsObj] = extractFeatures(cRef1, cd45ptsObj);

                    indxCPairs = matchFeatures(featuresRef1,cd45featuresObj, 'MaxRatio', 0.8, 'Unique', true);
                    matchedCRef = validPtsRef1(indxCPairs(:,1));
                    matchedCObj = cd45validPtsObj(indxCPairs(:,2));

                    ipc = length(indxCPairs);

                    [tCform, inlierCDistorted, ~, status] = estimateGeometricTransform(...
                             matchedCObj, matchedCRef,  'similarity', 'MaxNumTrials',100000, 'Confidence',96, 'MaxDistance', 1.8);

                    kpc = length(inlierCDistorted);
                    fprintf("%d matching keypoints found out of %d in CD45 ref\n", kpc, ipc);

                    %Try to register CD45 to HEM

                    lastwarn('');
                    Cwarped = cell(1, length(channelRef));
                    if status == 0
                        for u=1:length(channelRef)
                               Cwarped{u} = imwarp(channelRef{u}, tCform, 'OutputView', outputView1);
                        end
                    end

                    %if it does not register, catch the warning
                    if contains(msgid, 'MATLAB:nearlySingularMatrix') == 1
                        redo = sprintf('%s/Redo_%s', D, nm{t});
                        non_reg = sprintf('%s/nonreg_%s_%s.tif', redo, filename{z}, nm{t});
                        warning('off', 'MATLAB:MKDIR:DirectoryExists'); 
                        if exist(redo, 'dir') ~= 1 || 7
                            mkdir(redo);
                        end

                        imwrite(wObj, non_reg, 'tif');
                        fprintf("Bummer, %s was not automatically registered, please try manually. Sorry!\n", filename{z});
                        %save og nuclei also
                        new_nuc = sprintf('%s/NUCLEI_%s_%s.tif', redo, filename{k}, nm{t});
                        if exist(new_nuc, 'file') ~= 2
                            imwrite(nuc_ref, new_nuc, 'tif'); %writes the bigtiff image
                        end
                        continue
                    end

                    CD45Registered = cat(3, Cwarped{1}, Cwarped{2}, Cwarped{3}); %combine all RGB warps for final image
                    newcd45_ref = sprintf('%s/Registered_Regions/%s/reg_%s_%s.tif', D, nm{t}, filename{z}, nm{t});

                    % Write CD45 registered image if it doesn't exist
                    if exist(newcd45_ref, 'file') ~=2  %if file doesn't exist (check again)
                        new_img = sprintf('%s/Registered_Regions/%s/reg_%s_%s.tif', D, nm{t}, filename{z}, nm{t});
                        reg_check_img = sprintf('%s/Registration_Check/regck_%s_%s.tif', Parent, filename{z}, nm{t});
                        reg_crop = imcrop(CD45Registered, cropregion{t});
                        imwrite(reg_crop, new_img);
                        fprintf("%s %s image registered! \n", nm{t}, filename{z});
                        reg_crop_LR = imresize(reg_crop, 0.0625);
                        imwrite(reg_crop_LR, reg_check_img);
                    end


                   %now the registered CD45 image can be used to register the
                   %failed reg image

                    indxC2Pairs = matchFeatures(cd45featuresObj, featuresObj, 'MaxRatio', 0.8, 'Unique', true);
                    matchedC2Ref = cd45validPtsObj(indxC2Pairs(:,1));
                    matchedC2Obj = validPtsObj(indxC2Pairs(:,2));

                    ipc2 = length(indxC2Pairs);

                    [tC2form, inlierC2Distorted, ~, status] = estimateGeometricTransform(...
                             matchedC2Obj, matchedC2Ref,  'similarity', 'MaxNumTrials',100000, 'Confidence',96, 'MaxDistance', 1.8);

                    kpc2 = length(inlierC2Distorted);
                    fprintf("%d matching keypoints found out of %d in CD45 ref\n", kpc2, ipc2);

                    lastwarn('');
                    C2warped = cell(1, length(channel));
                    if status == 0
                        for u=1:length(channel)
                               C2warped{u} = imwarp(channel{u}, tC2form, 'OutputView', outputView1);
                        end
                    end

                    %if it does not register, catch the warning
                    if contains(msgid, 'MATLAB:nearlySingularMatrix') == 1
                        redo = sprintf('%s/Redo_%s', D, nm{t});
                        non_reg = sprintf('%s/nonreg_%s_%s.tif', redo, filename{z}, nm{t});
                        warning('off', 'MATLAB:MKDIR:DirectoryExists'); 
                        if exist(redo, 'dir') ~= 1 || 7
                            mkdir(redo);
                        end

                        imwrite(wObj, non_reg, 'tif');
                        fprintf("Bummer, %s was not automatically registered, please try manually. Sorry!\n", filename{z});
                        %save og nuclei also
                        new_nuc = sprintf('%s/NUCLEI_%s_%s.tif', redo, filename{k}, nm{t});
                        if exist(new_nuc, 'file') ~= 2
                            imwrite(nuc_ref, new_nuc, 'tif'); %writes the bigtiff image
                        end
                        continue
                    end
                    
                    %Register the previously failed image from cd45 points
                    Registered = cat(3, C2warped{1}, C2warped{2}, C2warped{3}); %combine all RGB warps for final image
                    new_temp = sprintf('%s/Registered_Regions/%s/reg_%s_%s.tif', D, nm{t}, filename{z}, nm{t});
                    reg_check_img = sprintf('%s/Registration_Check/regck_%s_%s.tif', Parent, filename{z}, nm{t});
                    imwrite(Registered, new_temp);
                    fprintf("%s %s image registered! \n", nm{t}, filename{z});
                    reg_crop_LR = imresize(Registered, 0.0625);
                    imwrite(reg_crop_LR, reg_check_img);
               
               %Otherwise, read in the previously registered cd45
               else
                    ref_cd45 = imread(cd45_fullfn);
                    
                    wCref = ref_cd45;
                    channelRef = { wCref(:,:,1),  wCref(:,:,2),  wCref(:,:,3)}; %split channels on HR
                    cRef1=channelRef{1};
                    outputViewC1 = imref2d( [size(cRef1,1) size(cRef1,2)]);


                    fprintf("Trying registered CD45 image\n");

                    %Get KP for CD45 to register to Nuc first
                    cd45ptsObj = detectSURFFeatures(cRef1);

                    n_pts = 20000;
                    cd45ptsObj = cd45ptsObj.selectStrongest(min(n_pts, length(cd45ptsObj)));
                    [cd45featuresObj, cd45validPtsObj] = extractFeatures(cRef1, cd45ptsObj);
                   
                    indxC2Pairs = matchFeatures(cd45featuresObj, featuresObj, 'MaxRatio', 0.8, 'Unique', true);
                    matchedC2Ref = cd45validPtsObj(indxC2Pairs(:,1));
                    matchedC2Obj = validPtsObj(indxC2Pairs(:,2));

                    ipc2 = length(indxC2Pairs);

                    [tC2form, inlierC2Distorted, ~, status] = estimateGeometricTransform(...
                             matchedC2Obj, matchedC2Ref,  'similarity', 'MaxNumTrials',100000, 'Confidence',96, 'MaxDistance', 1.8);

                    kpc2 = length(inlierC2Distorted);
                    fprintf("%d matching keypoints found out of %d in CD45 ref\n", kpc2, ipc2);

                    lastwarn('');
                    C2warped = cell(1, length(channel));
                    if status == 0
                        for u=1:length(channel)
                               C2warped{u} = imwarp(channel{u}, tC2form, 'OutputView', outputViewC1);
                        end
                    end

                    %if it does not register, catch the warning
                    if contains(msgid, 'MATLAB:nearlySingularMatrix') == 1
                        redo = sprintf('%s/Redo_%s', D, nm{t});
                        non_reg = sprintf('%s/nonreg_%s_%s.tif', redo, filename{z}, nm{t});
                        warning('off', 'MATLAB:MKDIR:DirectoryExists'); 
                        if exist(redo, 'dir') ~= 1 || 7
                            mkdir(redo);
                        end

                        imwrite(wObj, non_reg, 'tif');
                        fprintf("Bummer, %s was not automatically registered, please try manually. Sorry!\n", filename{z});
                        %save og nuclei also
                        new_nuc = sprintf('%s/NUCLEI_%s_%s.tif', redo, filename{k}, nm{t});
                        if exist(new_nuc, 'file') ~= 2
                            imwrite(nuc_ref, new_nuc, 'tif'); %writes the bigtiff image
                        end
                        continue
                    end

                    Registered = cat(3, C2warped{1}, C2warped{2}, C2warped{3}); %combine all RGB warps for final image
                    new_temp = sprintf('%s/Registered_Regions/%s/reg_%s_%s.tif', D, nm{t}, filename{z}, nm{t});
                    reg_check_img = sprintf('%s/Registration_Check/regck_%s_%s.tif', Parent, filename{z}, nm{t});
                    imwrite(Registered, new_temp);
                    fprintf("%s %s image registered! \n", nm{t}, filename{z});
                    reg_crop_LR = imresize(Registered, 0.0625);
                    imwrite(reg_crop_LR, reg_check_img);
               end
            end
  
            lastwarn('');
            warped = cell(1, length(channel));
            if status == 0
                for u=1:length(channel)
                       warped{u} = imwarp(channel{u}, tform, 'OutputView', outputView1);
                end
            end
                
            %if it does not register, catch the warning
            if contains(msgid, 'MATLAB:nearlySingularMatrix') == 1
                redo = sprintf('%s/Redo_%s', D, nm{t});
                non_reg = sprintf('%s/nonreg_%s_%s.tif', redo, filename{z}, nm{t});
                warning('off', 'MATLAB:MKDIR:DirectoryExists'); 
                if exist(redo, 'dir') ~= 1 || 7
                    mkdir(redo);
                end

                imwrite(wObj, non_reg, 'tif');
                fprintf("Bummer, %s was not automatically registered, please try manually. Sorry!\n", filename{z});
                %save og nuclei also
                new_nuc = sprintf('%s/NUCLEI_%s_%s.tif', redo, filename{k}, nm{t});
                if exist(new_nuc, 'file') ~= 2
                    imwrite(nuc_ref, new_nuc, 'tif'); %writes the bigtiff image
                end
            end

            Registered = cat(3, Cwarped{1}, Cwarped{2}, Cwarped{3}); %combine all RGB warps for final image
            new_temp = sprintf('%s/Registered_Regions/%s/reg_%s_%s.tif', D, nm{t}, filename{z}, nm{t});
                
            if exist(new_temp, 'file') ~=2  %if file doesn't exist (check again)
                new_img = sprintf('%s/Registered_Regions/%s/reg_%s_%s.tif', D, nm{t}, filename{z}, nm{t});
                reg_check_img = sprintf('%s/Registration_Check/regck_%s_%s.tif', Parent, filename{z}, nm{t});
                reg_crop = imcrop(Registered, cropregion{t});
                imwrite(reg_crop, new_img);
                fprintf("%s %s image registered! \n", nm{t}, filename{z});
                reg_crop_LR = imresize(reg_crop, 0.0625);
                imwrite(reg_crop_LR, reg_check_img);
            end
        end
        
        nuc_crop_name = sprintf('%s/Registered_Regions/%s/NUCLEI_%s_%s.tif', D, nm{t}, filename{k}, nm{t});
        nuc_check_img = sprintf('%s/Registration_Check/NUCLEIck_%s_%s.tif', Parent, filename{k}, nm{t});
        nuc_crop = imcrop(nuc_ref, cropregion{t});
        nuc_crop_LR = imresize(nuc_crop, 0.0625);
        imwrite(nuc_crop, nuc_crop_name);
        imwrite(nuc_crop_LR, nuc_check_img);
        fprintf("CD45 Registration complete!\n");
    end
end
