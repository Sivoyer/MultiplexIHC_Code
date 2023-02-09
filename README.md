# MultiplexIHC_Code

Multiplex IHC allows for the simultaneous detection of multiple Ab targets in the same tissue section using published methods previously described (1,2).

REFERENCES

1. Tsujikawa, Takahiro, et al. "Quantitative multiplex immunohistochemistry reveals myeloid-inflamed tumor-immune complexity associated with poor prognosis."Cell reports19.1 (2017): 203-217
2. Banik, Grace, et al. "High-dimensional multiplexed immunohistochemical characterization of immune contexture in human cancers."Methods in enzymology635 (2020): 1-20.


This multiplex IHC image analysis pipeline provides a method to analyze cohorts of multiplexed IHC stains on FFPE tissue sections in batch. The basic steps include image registration, color deconvolution, nuclei segmentation, and single cell single marker intensity measurements. The output of the pipeline is a .CSV with single cells as rows and marker stain intensity, and any other exported measured features from Cell Profiler including X,Y location and shape features, as column variables.

Detailed steps can be found on the protocols.io link:

[protocols.io workflow](https://www.protocols.io/view/htan-multiplex-ihc-image-cytometry-v0-1-eq2lyp8qplx9/v1)
 

