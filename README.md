# Batch-processing-multimodality-tumour-imaging
This code is designed to help simplify the batch processing (co-registration, 2D and 3D (semi-automatic) segmentation, and quantification) of longitudinally collected 2D and 3D multi-modality imaging data using Matlab. The code was originally intended for processing of tumour response kinetics following irradiation pre-clinically in a window chamber model, data acquired using optical imaging modalities (brightfield, epifluorescence, and optical coherence tomography angiography).
Provided for example 4D (BM mode acquired OCT data (with ideally ~5 repetitions of B-scans per y-step of the scanning-mirror galvonometer) and 2D en-face view microscopy images, the code aims to perform the following tasks:

1) 2D lateral mask creation and 2D co-registration of OCT to brightfield/fluorescence images; 
2) Quantification of brightfield and fluorescence images for automatic extraction of tumour viability and approximate volume;
3) 3D co-registration of OCT scans inter-timepoints;
4) 3D tumour mask creation;
5) 3D Vessel segmentation (manual or in the future automatically);
6) Quantification of vascular morphology from segmentation within defined VOI. 


*Disclaimer: My background is in biophysics and medical biophysics; the code may more than definitely be far from having optimal performance.
