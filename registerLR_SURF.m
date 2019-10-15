

function registerLR_SURF(xy, xml_files, fpath, filename)
    %set max number of features
    rois = [xy, upper(xml_files.name(1:end-4))]; %save each xml ROI
    n_smpl = 100000; % depend (maximum number of features)
    idx = length(rois);
    k = find(contains(filename, rois(idx))); %get index of image
    image = fpath{k}; %nuclei image pathname
        
%read in whole slide nuclei image low res
    nuclevel4 = imread(image,4);
    nucB_l4 = nuclevel4(:,:,3);
    %nucR_l4 = nuclevel4(:,:,2);

    %Find SURF features in Nuclei Ref and select strongest
    ptsRef1 = detectSURFFeatures(nucB_l4); 
    ptsRef1 = ptsRef1.selectStrongest(min(n_smpl, length(ptsRef1)));
    [featuresRef1, validPtsRef1] = extractFeatures(nucB_l4, ptsRef1);
    %outputView1 = imref2d( [size(nucB_l4,1) size(nucB_l4,2)]);
   
    %get the transformation for the whole slide to apply later
     for z = 1:length(filename)
        %read in whole slide marker low res
        wObj = imread(fpath{z},4);
        channel = { wObj(:,:,1),  wObj(:,:,2),  wObj(:,:,3)}; %split channels on HR
        Obj1=channel{3};

        fprintf("Processing %s ...\n", filename{z});

        %get SURF features from determined object channel
        ptsObj = detectSURFFeatures(Obj1);

        %keep strongest features
        ptsObj = ptsObj.selectStrongest(min(n_smpl, length(ptsObj)));
        [featuresObj, validPtsObj] = extractFeatures(Obj1, ptsObj);

        indxPairs = matchFeatures(featuresRef1, featuresObj, 'MaxRatio', 0.8, 'Unique', true);
        matchedRef = validPtsRef1(indxPairs(:,1));
        matchedObj = validPtsObj(indxPairs(:,2));

        ip = length(indxPairs);

        [tform, inlierDistorted] = estimateGeometricTransform(...
                     matchedObj, matchedRef,  'similarity', 'MaxNumTrials',100000, 'Confidence',96, 'MaxDistance', 1.8);

        kp = length(inlierDistorted);
        fprintf("%d matching keypoints found out of %d in Ch1 ref\n", kp, ip);

        marker_tform = cell(1, length(filename));
        marker_tform{z} = tform;

     end
end      
    