/////////////////////////////////////////////////////////////////
//      Authors Thomas Caille & Héloïse Monnet @ ORION-CIRB    //
//	            https://github.com/orion-cirb/CLDN2            //
/////////////////////////////////////////////////////////////////


// Hide images during macro execution
setBatchMode(true);
// Ask for the image repertory
inputDir =getDirectory("Merci d'indiquer le dossier contenant vos images");


// Create result directory
resultDir = inputDir + "Results"+ File.separator();

if (!File.isDirectory(resultDir)) {
	File.makeDirectory(resultDir);
}
// Get all files in the input directory
imgtif= getFileList(inputDir);

// create a file named "results.csv" and write headers in it
fileResults = File.open(resultDir + "results.csv");
print(fileResults,"Image - noyau , Circ n-3 , Circ , Circ n+3 , Aire n-3 , Aire , Aire n+3 , Perim n-3 , Perim , Perim n+3 , Slice n-3 , Slice , Slice n+3 , Radius n-3 , Rayon , Radius n+3\n");

// Loop through all files with .TIF extension
for (i = 0; i < imgtif.length; i++) {
    if (endsWith(imgtif[i], ".tif")) {
    	img= File.getNameWithoutExtension(inputDir + imgtif[i]);
    	// Create result directory based on image name
    	resultDirImg = resultDir + img + File.separator();
    	if (!File.isDirectory(resultDirImg)) {
			File.makeDirectory(resultDirImg);
		}
		// open image
    	open(inputDir + imgtif[i]);
    	print("ouvre l'image : " + img);
    	rename("raw_image");
    	
    	// Compute image background noise as the median intensity of the stack sum projection 
		run("Z Project...", "projection=[Sum Slices]");
		run("Set Measurements...", "area mean standard median redirect=None decimal=0");
		List.setMeasurements;
		close("SUM_raw_image");
		stdDev=List.getValue("StdDev");
		mean=List.getValue("Mean");
		backNoise = (stdDev + mean) /nSlices;
		// Remove background noise from the stack average projection to normalize intensity measurements
		run("Subtract...", "value=" + backNoise +" stack");
		run("Clear Results");
		
		// Median filter to enhance signal of the image
		run("Median...", "radius=1 stack");
		
		// Automatic thresholding by Otsu method to segment object
		setAutoThreshold("Otsu dark no-reset stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=Otsu background=Dark black");
		// Fill holes to improve segmentation result
		run("Fill Holes", "stack");
		
		// Initialize the 3D Manager before doing some 3D watershed to separate the nucleus
		run("3D Manager Options", "volume centroid_(unit) centre_of_mass_(pix) centre_of_mass_(unit) distance_between_centers=10 distance_max_contact=1.80 drawing=Contour display");
		run("3D Watershed Split", "binary=raw_image seeds=Automatic radius=10");
		run("3D Manager");
		Ext.Manager3D_Reset();
		Ext.Manager3D_AddImage();
		// Measure 3D volume of nucleus allowing us to filter them
		Ext.Manager3D_Measure();
		
		Vol=newArray(nResults); Label= newArray(nResults); Centro = newArray(nResults); Centro2 = newArray(nResults);
		b=nResults;
		// Loop over each objects found
		for (j = 0; j <=b ; j++) {
			Vol[j]=getResult("Vol (unit)", j-1);
			Label[j]=getResult("Label", j-1);
			Centro[j]=getResult("CZ (unit)", j-1);
			
		}
			for (k = 1; k < j ; k++){
				
				volume= Vol[k];
				Centro2=Centro[k];
				label=abs(Label[k]);
				// Measure only the parameters of objects with a volume of at least 40,000 pixels
				if (volume > 40000){
					selectImage("Split");
					run("Duplicate...", "duplicate");
					
					// Do a manual thresholding based on object label 
					run("Manual Threshold...", "min="+label+" max="+label+"");
					run("Set Measurements...", "area perimeter shape feret's stack limit display add redirect=None decimal=0");
					run("Clear Results");
					
					// Create 3 ROI's according to the Centroid of the object (n-3 , n , n+3)
					// rename ROI's with "the nucleus (1 or 2)" - " the label given by 3D segmentation" - "the slice number"
					// Compute finals results from the ROI 
					setSlice(Centro2-3);
					run("Create Selection");
					roiManager("Add");
					
					if (roiManager("count") <= 3){
						roiManager("select", 0);
						roiManager("rename", "1 - "+ label +" - "+ getSliceNumber());
					} else {
						roiManager("select", 3);
						roiManager("rename", "2 - "+ label +" - "+ getSliceNumber());
					}
					run("Measure");
					
					setSlice(Centro2);
					run("Create Selection");
					roiManager("Add");
					
					if (roiManager("count") <= 3){
						roiManager("select", 1);
						roiManager("rename", "1 - "+ label +" - "+ getSliceNumber());
					} else {
						roiManager("select", 4);
						roiManager("rename", "2 - "+ label +" - "+ getSliceNumber());
					}
					run("Measure");
						
					setSlice(Centro2+3);
					run("Create Selection");
					roiManager("Add");
					
					if (roiManager("count") <= 3){
						roiManager("select", 2);
						roiManager("rename", "1 - "+ label +" - "+ getSliceNumber());
					} else {
						roiManager("select", 5);
						roiManager("rename", "2 - "+ label +" - "+ getSliceNumber());
					}
					run("Measure");
					
					// Get results into variables
					areaSliceNegative = getResult("Area", 0); area = getResult("Area", 1); areaSlicePositive = getResult("Area", 2);
					circSliceNegative = (getResult("Circ.", 0))*100; circ = (getResult("Circ.", 1))*100; circSlicePositive = (getResult("Circ.", 2))*100;
					perimSliceNegative = getResult("Perim.", 0); perim =getResult("Perim.", 1); perimSlicePositive = getResult("Perim.", 2);
					sliceNegative = getResult("Slice", 0); slice = getResult("Slice", 1); slicePositive = getResult("Slice", 2);
					rayonSliceNegative = (getResult("Feret", 0))/2; rayon = (getResult("Feret", 1))/2; rayonSlicePositive  = (getResult("Feret", 2))/2;
				
					// Write into the result.csv file
					print(fileResults,img +"-"+ label +","+circSliceNegative+","+ circ+","+ circSlicePositive+","+ areaSliceNegative +","+ area +","+ areaSlicePositive +","+ perimSliceNegative +","+ perim +","+ perimSlicePositive +","+ sliceNegative +","+ slice +","+ slicePositive+","+ rayonSliceNegative +","+ rayon +","+ rayonSlicePositive +"\n");
				}
				close("Results");	
		}
		// close and save windows
		Ext.Manager3D_Close();		
		roiManager("save", resultDirImg + img +".zip");
		roiManager("reset");
		saveAs("tif", resultDirImg + img);
		close("*");
    }
}

setBatchMode(false);
		
		


