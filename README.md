# MorphOocyte_Nuclei

* **Developed by:** Thomas
* **Developed for:** Elvira
* **Team:** Verlhac
* **Date:** October 2024
* **Software:** Fiji


### Images description

3D images of oocytes nuclei.

1 channel: nuclear envelope

### Plugin description

* Estimate background noise as [(intensity mean + standard deviation)/slices number] of stack sum projection
* Segment oocytes nuclei using background noise subtraction + median filtering + Otsu thresholding + fill holes
* Use the 3D ImageJ Suite plugin to perform a 3D watershed to separate nuclei, label them and filter them by volume to retain only relevant ones
* Compute 3 ROIs for each oocyte nucleus: one at the nucleus centroid along z-slices, one 3 slices above and one 3 slices below
* For each obtained ROI, compute area + perimeter + circularity + Feret max and min diameters

### Dependencies

**3D ImageJ Suite** Fiji plugin

### Version history

Version 1 released on October 14, 2024.
