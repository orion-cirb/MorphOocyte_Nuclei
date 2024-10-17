/////////////////////////////////////////////////////////////////
//      Authors Thomas Caille & Héloïse Monnet @ ORION-CIRB    //
//       https://github.com/orion-cirb/MorphOocyte_Nuclei      //
/////////////////////////////////////////////////////////////////

// Hide images during macro execution
setBatchMode(true);

// Ask for the images directory
inputDir = getDirectory("Please select a directory containing images to analyze");

// Create results directory
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
resultDir = inputDir + "Results_" + year + "-" + (month+1) + "-" + dayOfMonth + "_" + hour + "-" + minute + "-" + second + File.separator();
if (!File.isDirectory(resultDir)) {
	File.makeDirectory(resultDir);
}

// Get all files in the input directory
inputFiles = getFileList(inputDir);

// Create a file named "results.csv" and write headers in it
fileResults = File.open(resultDir + "results.csv");
print(fileResults, "Image name, Slice, ROI name, Area (µm2), Perimeter (µm), Circularity, Feret max diameter (µm), Feret min diameter (µm)\n");

// Loop through all files with .TIF extension
for (i = 0; i < inputFiles.length; i++) {
    if (endsWith(inputFiles[i], ".tif")) {
    	
    	open(inputDir + inputFiles[i]);
    	raw_image= getImageID();
    	//rename("raw_image");
    	run("Properties...", "channels=1 slices=241 frames=1 pixel_width=0.1135074 pixel_height=0.1135074 voxel_depth=0.1135074 frame=[1 sec]");

    	selectImage(raw_image);

  
   		run("Duplicate...", "duplicate");
		// Remove background noise
		run("Subtract Background...", "rolling=5 sliding stack");
		
		// Median filter to smooth signal
		run("Median...", "radius=7 stack");
		
		// Automatic thresholding using Otsu method to segment object
		setAutoThreshold("Mean dark no-reset stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=Mean background=Dark black");
		// Fill holes to improve segmentation result
		run("Fill Holes", "stack");
		

		run("Analyze Particles...", "size=4000-Infinity pixel circularity=0.50-1.00 show=[Overlay Masks] clear overlay add stack");
		
		for (j=0 ; j < roiManager("count"); j++){	
			roiManager("Select", j);
			run("Add Selection...");
			run("Clear Outside", "slice");
		}
		roiManager("reset");
		for(k=1; k <= nSlices; k+=10) {
					slice = k;
					setSlice(slice);
					run("Create Selection");
					roiManager("Add");
					roiManager("select", roiManager("count")-1);
					roiName = Roi.getName;
					
					// Compute ROI parameters
					run("Set Measurements...", "area perimeter shape feret's limit redirect=None decimal=0");
					List.setMeasurements();
					area = List.getValue("Area");
					perim = List.getValue("Perim.");
					circ = List.getValue("Circ.");
					maxDiam = List.getValue("Feret");
					minDiam = List.getValue("MinFeret");
					List.clear();
					
					// Save ROI parameters into the "result.csv" file
					print(fileResults, inputFiles[i]+","+slice+","+roiName+","+area+","+perim+","+circ+","+maxDiam+","+minDiam+"\n");
				}
		roiManager("save", resultDir + replace(inputFiles[i], "tif", "zip"));
		roiManager("reset");
    }
    close("*");
}
setBatchMode(false);