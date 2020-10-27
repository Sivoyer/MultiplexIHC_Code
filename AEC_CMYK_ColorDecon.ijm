
macro "AEC CMYK Color Deconvolution" {
	
	input = getArgument(); 
	
	if(input =="");{
	input = getDirectory("Select the folder of image sets");
	}
	
	suffix =".tif" ;
	
	setBatchMode("true");
	pdir = getFileList(input); //Each image set
		for (m=1; m<pdir.length+1; m++) {
		if(!startsWith(pdir[m-1], "Registration_Check/")) {
			//silde folders only
			output = input+pdir[m-1]+"Processed";
			if(!File.exists(output)) {
				File.makeDirectory(output);
				}
		} 
		if(endsWith(pdir[m-1], "Registered_Regions/"));
			rr = input+pdir[m-1]+"Registered_Regions/"; //Each file in image set dir- look for Registered_Regions
			//for each R dir...
			rdir = getFileList(rr); //number of ROI
			roidirs = Array.sort(rdir);
			//Array.show("title", roidirs);
			for (n=1; n<rdir.length+1; n++) {
					Rsave = input+pdir[m-1]+"Processed"+File.separator+roidirs[n-1];
				if(!File.exists(Rsave));{
					File.makeDirectory(Rsave);
					}
				processRFolder(input+pdir[m-1]+"Registered_Regions/"+roidirs[n-1]);
					}
				}
	}

function processRFolder(in) {
	list = getFileList(in);
	for (i = 1; i < list.length+1; i++) {
		if(File.isDirectory(input + list[i-1]))
			processRFolder("" + input + list[i-1]);
			else {
					if(endsWith(list[i-1], suffix)||endsWith(list[i-1], ".tiff")) {
						if(!File.exists(Rsave+File.separator+"V_"+list[i-1])) {
						CD_cmyk(in, output, list[i-1]); //run CMYK and masking for each marker in ROI
						}
					}
			}
	}
}


function CD_cmyk(in, output, filename) {
  if(!startsWith(filename, "NUCLEI_")==1) {
			open(in+filename);
			markerID = getImageID();
			marker = getTitle();
	        run("RGB to CMYK");
	        CMYKID = getImageID();
			selectImage(CMYKID);
			run("Stack to Images");
			imageCalculator("Add create", "Y","M");
			mimg = getImageID();
			close("M");
			close("K");
			close("C");
			close("Y");
			selectImage(mimg);
	        run("Despeckle");
			run("Grays"); //this is dark bkgd
			run("8-bit");
			getRawStatistics(nPixels, mean, min, max);
			newmin = max*(0.05);
			newmax = max*(0.95);
			setMinAndMax(newmin, newmax);
			run("Apply LUT"); 
			saveAs("Tiff", Rsave+File.separator+"V_"+marker);
			print(filename+" saved");
			close();
			close(marker);
			//print("RGB to CMYK Finished");
  }
}
