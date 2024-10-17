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
print(fileResults, "Image name, Nucleus ID, Volume3D (µm3), Slice, ROI name, Area (µm2), Perimeter (µm), Circularity, Feret max diameter (µm), Feret min diameter (µm)\n");

// Loop through all files with .TIF extension
for (i = 0; i < inputFiles.length; i++) {
    if (endsWith(inputFiles[i], ".tif")) {
    	print("\n - Analyzing image " + inputFiles[i] + " -");
    	
		// Open image
    	open(inputDir + inputFiles[i]);
    	getVoxelSize(voxWidth, voxHeight, voxDepth, voxUnit);
    	rename("raw_image");

    	// Compute background noise as the intensity (mean + stdDev) of the stack
		run("Z Project...", "projection=[Sum Slices]");
		run("Set Measurements...", "mean standard redirect=None decimal=0");
		List.setMeasurements;
		close("SUM_raw_image");
		mean = List.getValue("Mean");
		stdDev = List.getValue("StdDev");
		bgNoise = (mean + stdDev) / nSlices;
		List.clear();
		// Remove background noise
		run("Subtract...", "value=" + bgNoise +" stack");
		
		// Median filter to smooth signal
		run("Median...", "radius=1 stack");
		// Automatic thresholding using Otsu method to segment object
		setAutoThreshold("Otsu dark no-reset stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=Otsu background=Dark black");
		// Fill holes to improve segmentation result
		run("Fill Holes", "stack");
		// 3D watershed to separate objects
		run("3D Watershed Split", "binary=raw_image seeds=Automatic radius=10");
		Stack.setXUnit(voxUnit);
		run("Properties...", "pixel_width="+voxWidth+" pixel_height="+voxHeight+" voxel_depth="+voxDepth);
		rename("watershed");
		
		// Initialize 3D Manager
		run("3D Manager");
		Ext.Manager3D_Reset();
		// Load segmentation result into 3D Manager
		Ext.Manager3D_AddImage();
		// Measure objects volume and centroid
		run("3D Manager Options", "volume centroid_(pix) distance_between_centers=10 distance_max_contact=1.80 drawing=Contour display");
		Ext.Manager3D_Measure();
		nbObjs = nResults; labels = newArray(nResults); vols = newArray(nResults); cZs = newArray(nResults);
		for (j = 0; j < nbObjs; j++) {
			labels[j] = getResult("Label", j);
			cZs[j] = Math.round(getResult("CZ (pix)", j));
			vols[j] = getResult("Vol (unit)", j);
		}
		close("MeasureTable");
		close("Results");
		
		// Loop over each object found with a volume of at least 1000 µm3
		nucleiCounter = 0;
		for (j = 0; j < nbObjs; j++) {
			if (vols[j] > 1000){
				nucleiCounter++;
				
				// Do a manual thresholding based on object label
				selectImage("watershed");
				run("Manual Threshold...", "min="+labels[j]+" max="+labels[j]);
				
				// Create 3 ROIs according to the z-centroid of the object (z-3, z, z+3)
				for(k=-3; k <= 3; k+=3) {
					slice = cZs[j] + k;
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
					print(fileResults, inputFiles[i]+","+nucleiCounter+","+ vols[j] +","+slice+","+roiName+","+area+","+perim+","+circ+","+maxDiam+","+minDiam+"\n");
				}
			}
		}
		
		// Save ROIs
		roiManager("save", resultDir + replace(inputFiles[i], "tif", "zip"));
		roiManager("reset");
		
		// Close all windows
		Ext.Manager3D_Close();
		close("*");
    }
}

print("\n - Analysis done! -");
setBatchMode(false);
