# MorphOocyte_Nuclei

* **Developed by:** Thomas
* **Developed for:** Elvira
* **Team:** Verlhac
* **Date:** September/October 2024
* **Software:** Fiji


### Images description

3D images of oocyte.

1 channel: 

### Plugin description

Segment oocyte using stack sum projection + background noise subtraction + median filtering + Otsu thresholding
Estimate background noise as mean + standard deviation intensity of stack sum projection
Use the 3D Suite plug-in to watershed oocyte, labeling them and filter by volume
Compute 3 ROIs for each oocyte, one at the centroid (determined by 3D), one 3 slices up and one 3 slices down
For each obtained ROI, compute area + Perimeter + Circularity + Radius measured on the 3 slices

### Dependencies

3D Suite plug-in

### Version history

Version 1 released on October 03, 2024.
