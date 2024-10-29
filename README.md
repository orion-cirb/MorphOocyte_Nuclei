# MorphOocyte_Nuclei

* **Developed by:** Thomas & Héloïse
* **Developed for:** Elvira
* **Team:** Verlhac
* **Date:** October 2024
* **Software:** Fiji


### Images description

**MorphOocyte_Nuclei_ZStack.ijm:** 3D images of oocytes nuclei
**MorphOocyte_Nuclei_Timelapse.ijm:** Timelapse images of an oocyte nucleus

1 channel: nuclear envelope

### Macros description

**MorphOocyte_Nuclei_ZStack.ijm:**

* Estimate background noise as [(intensity mean + standard deviation)/slices number] of stack sum projection
* Segment oocytes nuclei using background noise subtraction + median filtering + Otsu thresholding + fill holes
* Use the 3D ImageJ Suite plugin to perform a 3D watershed to separate nuclei, label them and filter them by volume to retain only relevant ones
* Compute 3 ROIs for each oocyte nucleus: one at the nucleus centroid along z-slices, one 3 slices above and one 3 slices below
* For each obtained ROI, compute area + perimeter + circularity + Feret max and min diameters

**MorphOocyte_Nuclei_Timelapse.ijm:**

* Segment oocyte nucleus using Laplacian of Gaussian filtering + Triangle thresholding + fill holes
* Analyze every 10th frame of the timelapse, saving ROI and associated parameters: area + perimeter + circularity + Feret max and min diameters

!! Attention !!  This macro will not work if multiple nuclei are present in the image.

### Dependencies

**MorphOocyte_Nuclei_ZStack.ijm:** *3D ImageJ Suite* Fiji plugin
**MorphOocyte_Nuclei_Timelapse.ijm:** *GDSC* Fiji plugin

### Version history

Version 1 released on October 29, 2024.
