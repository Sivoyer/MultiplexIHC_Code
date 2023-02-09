#@ DatasetIOService io
#@ CommandService command

""" This example runs stardist on all tif files in a folder
Full list of Parameters: 
res = command.run(StarDist2D, False,
			 "input", imp, "modelChoice", "Versatile (fluorescent nuclei)",
			 "modelFile","/path/to/TF_SavedModel.zip",
			 "normalizeInput",True, "percentileBottom",15, "percentileTop",99.8,
			 "probThresh",0.5, "nmsThresh", 0.3, "outputType","label",
			 "nTiles",1, "excludeBoundary",2, "verbose",1, "showCsbdeepProgress",1, "showProbAndDist",0).get();			
"""

from de.csbdresden.stardist import StarDist2D 
from glob import glob
import os
from ij import IJ, ImagePlus
from ij.gui import GenericDialog
from ij.plugin.frame import RoiManager
import fnmatch
import math


# Run stardist on all tiff files in <indir>
indir   = IJ.getDirectory("Input_directory")
print('Loaded directory ' + indir)

def find_files(directory, pattern):
    for root, dirs, files in os.walk(directory):
        for basename in files:
            if fnmatch.fnmatch(basename, pattern):
                f = os.path.join(root, basename)
                yield f

# Loop through slide folders
for slide_dir in sorted([sl for sl in glob(os.path.join(indir, '*/'))
				         if not 'Registration_Check' in sl]):	
	# Find Processed directory
	processed_dir = os.path.normpath(os.path.join(slide_dir, 'Processed'))

	# Loop through DSDNA V_ images in each region
	print('\nWorking on slide ' + os.path.split(os.path.split(processed_dir)[0])[1])
	for f in find_files(processed_dir, 'V_*DSDNA_*.tif'):
		# Get output directory name (same as directory of input file)
		output = os.path.dirname(f)

		# Create output filename
		finfile = os.path.join(output, "label_" + os.path.basename(f))

		# Skip if label_ file already exists
		if os.path.isfile(finfile) == False:
			# Open image
			print('-- Opening ' + f)
			imp = io.open(f)

			# Choose number of tiles needed, based on image area
			num_tiles = int(math.ceil((imp.height * imp.width) / 15000000.0))

			# Run StarDist
			print('-- Processing ' + finfile + ' with ' + str(num_tiles) + ' tile(s)')
			res = command.run(StarDist2D, False,
					"input", imp,
					"nTiles", num_tiles,
					"modelChoice", "Versatile (fluorescent nuclei)",
					).get()
			label = res.getOutput("label")
			io.save(label, os.path.join(output,"label_"+os.path.basename(f)))

			# Get ROI Manager
			rm = RoiManager.getRoiManager()

			# Count segments
			segment_count = rm.getCount()

			# Print error if too many segments
			if segment_count > 65535:
				print('-- ERROR: Found more than 65535 segments in ' + os.path.basename(f) + '. Split region and re-run segmentation.')

			# Clear ROI Manager
			if segment_count > 0:
				rm.runCommand('Delete')
		else:
			print('-- ' + finfile + ' already exists!')

	  
	