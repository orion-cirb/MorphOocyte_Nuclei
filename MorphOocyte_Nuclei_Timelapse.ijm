/////////////////////////////////////////////////////////////////
//      Authors Thomas Caille & Héloïse Monnet @ ORION-CIRB    //
//       https://github.com/orion-cirb/MorphOocyte_Nuclei      //
/////////////////////////////////////////////////////////////////

// Hide on-screen updates for faster macro execution
setBatchMode(true);

// Prompt user to select directory containing input images
inputDir = getDirectory("Please select a directory containing images to analyze");

// Generate results directory with timestamp
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
resultDir = inputDir + "Results_" + year + "-" + (month+1) + "-" + dayOfMonth + "_" + hour + "-" + minute + "-" + second + File.separator();
if (!File.isDirectory(resultDir)) {
	File.makeDirectory(resultDir);
}

// Retrieve list of all files in input directory
inputFiles = getFileList(inputDir);

// Create CSV file to store analysis results and add column headers
fileResults = File.open(resultDir + "results.csv");
print(fileResults, "Image name,Frame,ROI name,Area (µm2),Perimeter (µm),Circularity,Feret max diameter (µm),Feret min diameter (µm)\n");

// Process each .TIF file in the input directory
for (i = 0; i < inputFiles.length; i++) {
    if (endsWith(inputFiles[i], ".tif")) {
    	print("Analyzing image " + inputFiles[i] + "...");
    	
    	// Open the current image
    	open(inputDir + inputFiles[i]);
		
		// Apply Laplacian of Gaussian filter for nucleus edge enhancement
   		run("Laplacian of Gaussian", "sigma=6 scale_normalised negate enhance stack");
		
		// Use Triangle automatic thresholding to create binary mask of objects
		setAutoThreshold("Triangle dark no-reset stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=Triangle background=Dark black");
		
		// Fill holes within segmented objects for cleaner boundaries
		run("Fill Holes", "stack");
		
		// Identify ROIs with area ≥ 300 µm² and circularity ≥ 0.5, add to ROI Manager
		run("Analyze Particles...", "size=300-Infinity circularity=0.50-1.00 clear add stack");
		
		// Retain only selected objects, clearing the rest of objects in the image
		for (roi=0 ; roi < roiManager("count"); roi++){	
			roiManager("Select", roi);
			run("Add Selection...");
			run("Clear Outside", "slice");
		}

		// Clear ROI Manager
		roiManager("reset");
		
        // Analyze every 10th frame
		for(slice=1; slice <= nSlices; slice+=1) {
		    // Add current ROI to ROI Manager
			setSlice(slice);
			run("Create Selection");
			roiManager("Add");
			roiManager("select", roiManager("count")-1);
			roiName = Roi.getName;
			
			// Compute measurements for current ROI
			run("Set Measurements...", "area perimeter shape feret's redirect=None decimal=0");
			List.setMeasurements();
			area = List.getValue("Area");
			perim = List.getValue("Perim.");
			circ = List.getValue("Circ.");
			maxDiam = List.getValue("Feret");
			minDiam = List.getValue("MinFeret");
			List.clear();
			
			// Append ROI parameters to "results.csv" file
			print(fileResults, inputFiles[i]+","+slice+","+roiName+","+area+","+perim+","+circ+","+maxDiam+","+minDiam+"\n");
		}
		
		// Save ROIs in ROI Manager in a ZIP file for each analyzed image
		roiManager("save", resultDir + replace(inputFiles[i], "tif", "zip"));
		roiManager("reset");
		
		// Close all open windows
		close("*");
    }
}

// Print completion message and restore batch mode to default
print("Analysis done!");
setBatchMode(false);