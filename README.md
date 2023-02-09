# MultiplexIHC_Code

Multiplex IHC allows for the simultaneous detection of multiple Ab targets in the same tissue section using published methods previously described1,2.This protocol contains detailed instructions on how to prepare files and run the image processing pipeline for mIHC SVS images in a GUI or command line, making it accessible to biologist and labs without computational specialty. 

REFERENCES

1. Tsujikawa, Takahiro, et al. "Quantitative multiplex immunohistochemistry reveals myeloid-inflamed tumor-immune complexity associated with poor prognosis."Cell reports19.1 (2017): 203-217
2. Banik, Grace, et al. "High-dimensional multiplexed immunohistochemical characterization of immune contexture in human cancers."Methods in enzymology635 (2020): 1-20.


This multiplex IHC image analysis pipeline provides a method to analyze cohorts of multiplexed IHC stains on FFPE tissue sections in batch. The basic steps include image registration, color deconvolution, nuclei segmentation, and single cell single marker intensity measurements. The output of the pipeline is a .CSV with single cells as rows and marker stain intensity, and any other exported measured features from Cell Profiler including X,Y location and shape features, as column variables.

Detailed steps can be found on the protocols.io link:

[protocols.io workflow](dx.doi.org/10.17504/protocols.io.bsqjndun)
 

