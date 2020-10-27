
macro "Nuclei Binary Mask" {
	
	input = getArgument(); 
	
	if(input =="");{
	input = getDirectory("Select the folder of image sets");
	}
	
	suffix =".tif" ;

	Dialog.create("Noise parameter");
	Dialog.addNumber("Noise Parameter:", 22);
	// the lower the number the more objects you get
	Dialog.show();
	noise = Dialog.getNumber();
	
	setBatchMode("true");
	pdir = getFileList(input); //Each image set
	for (m=1; m<pdir.length+1; m++) {
		//parent = File.getParent(input);
		output = input+pdir[m-1]+"Processed";
		if(!File.exists(output)) {
			File.makeDirectory(output);}
		if(endsWith(pdir[m-1], "Registered_Regions/"));
			rr = input+pdir[m-1]+"Registered_Regions/"; //Each file in image set dir- look for Registered_Regions
			//for each R dir...
			rdir = getFileList(rr); //number of ROI
			roidirs = Array.sort(rdir);
			Array.show("title", roidirs);
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
				for (i = 1; i < list.length+1;i++) {
					if(endsWith(list[i-1], suffix)||endsWith(list[i-1], ".tiff")) {
						Create_mask(in, output, list[i-1]); //run CMYK and masking for each marker in ROI
					}
				}
				close("*");
			}
	 }
}

function Create_mask(in, output, filename) {
  if(startsWith(filename, "NUCLEI_")==1) {
    	if(!File.exists(Rsave+File.separator+"MASK_"+filename)) {
			open(in+filename);
			Nuc = getTitle();
			print("Nuclei image for mask creation: ", Nuc);
			
    //color deconvolution 
			run("Colour Deconvolution", "vectors=[H&E] hide");
			close("*-(Colour_3)");
			close("*-(Colour_2)");
			selectWindow(Nuc+"-(Colour_1)");
			cdnuc = getImageID();
			run("Duplicate...", " ");
			masknuc = getImageID();
			run("8-bit");
			run("Smooth");
			run("Bandpass Filter...", "filter_large=30 filter_small=2 suppress=Horizontal tolerance=3 autoscale saturate");
			run("Smooth");
			run("Despeckle");
			run("Enhance Contrast...", "saturated=0.3");
			run("Smooth");
			run("Invert LUT");
			run("Invert");
			run("Subtract Background...", "rolling=150 light sliding");
			//run("Maximum...", "radius=1");
			setAutoThreshold("Otsu");
			run("Find Maxima...", "noise=&noise output=[Segmented Particles] above light");
			run("Erode");
			run("Remove Outliers...", "radius=3 threshold=50 which=Dark");
			run("Watershed");
			run("Despeckle");
			run("Dilate");
			run("Watershed");
			run("Despeckle");
			run("Watershed");
			run("Invert LUT");
			mask = getImageID();
			
	//save Nuclei mask

			selectImage(mask);
			saveAs("Tiff", Rsave+File.separator+"MASK_"+filename);
			print("mask image image saved" );
			close();
			close(mask);
			close(masknuc);
			
	//make V nuc
			selectImage(cdnuc);
			run("Smooth");
			run("Despeckle");
			run("Despeckle");
			run("Enhance Contrast...", "saturated=0.25");
			run("Grays");
			run("Subtract Background...", "rolling=150 light");
			run("8-bit");
			run("Sharpen");
			run("Invert");
			saveAs("Tiff", Rsave+File.separator+"V_"+Nuc); //V name
    		print("Nuclei image processed" );
    		close();
    		close(cdnuc);
    		close(Nuc);
    	}
  	}
}


			
