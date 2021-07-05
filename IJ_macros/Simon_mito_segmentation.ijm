//  The purpose of this program is to segment the mitochondria in yeast cells from Simon,
// files are stored in an output folder
//
//	Author: Rafael Camacho
//  github: camachodejay
//  date:   2021 - 04 - 26
//  current address: Centre for cellular imaging - Göteborgs universitet
#@ File(label="Select file to analyze", style="open") im_dir
#@ String(label="Channels and order", choices={"RGB", "RG"}, style="radioButtonHorizontal") channel_order

// clean up first
// close all images
close("*");
// empty the ROI manager
roiManager("reset");
// empty the results table
run("Clear Results");
// configure that binary image are black in background, objects are white
setOption("BlackBackground", true);
print("\\Clear");


// open image
open(im_dir);
data = File.nameWithoutExtension;
d_path = File.directory;
getDimensions(width, height, channels, slices, frames)
rename(data);

green = "Green";
mask = "segmentation";

// create output folder
out_path = d_path + data + "_out" + File.separator; 
File.makeDirectory(out_path);


if ( channel_order == "RGB" && channels == 3) {
	print("Data has " + channels + " color channels");
	print("You chose a channel format of: " + channel_order);

} else if ( channel_order == "RG" && channels == 2) {
	print("Data has " + channels + " color channels");
	print("You chose a channel format of: " + channel_order);
	
} else {
	print("We could detect " + channels + " color channels");
	print("You chose a channel format of: " + channel_order);
	exit("error message: " + channels + " channels is not compatible with " +  channel_order);
}



// extract green
selectWindow(data);
run("Duplicate...", "title="+ green +" duplicate channels=2");

// find focus using gree channel
f_idx = findFocus(green, "intensity", false);

// enhance contrast green
enhance_contrast(green, f_idx, 0.35);

// run spatial filter
filter_2 = "filter_2";
sig1 = 2;
sig2 = 1.414 * sig1;
tmp = freq_filter(green, sig1, sig2);
selectWindow(tmp);
rename(filter_2);
enhance_contrast(filter_2, f_idx, 0.35);

// small median filter to clean a bit 
run("Median 3D...", "x=2 y=2 z=1");



/*
selectWindow(filter_2);
triangle = "triangle";
run("Duplicate...", "title="+ triangle +" duplicate");

// threshold
selectWindow(triangle);
resetThreshold();
setAutoThreshold("MaxEntropy dark stack");
run("Convert to Mask", "method=MaxEntropy background=Dark black");
*/

// threshold 
selectWindow(filter_2);
mask = "otsu";
run("Duplicate...", "title="+ mask +" duplicate");

selectWindow(mask);
resetThreshold();
setAutoThreshold("Otsu dark stack");
run("Convert to Mask", "method=Otsu background=Dark black");


// save mask
selectWindow(mask);
saveAs("Tiff", out_path + "Mito_Segmentation.tif");
rename(mask);


// we are done
print("All done");

exit


function freq_filter(window_title, sig1, sig2){
	selectWindow(window_title);
	xsig = sig1;
	ysig = sig1;
	zsig = sig1/2;
	
	run("Duplicate...", "title=g_small duplicate");
	run("Gaussian Blur 3D...", "x="+xsig+" y="+ysig+" z="+zsig);
	resetMinAndMax();
	run("Enhance Contrast", "saturated=0.35");

	xsig = sig2;
	ysig = sig2;
	zsig = sig2/2;
	
	selectWindow(window_title);
	run("Duplicate...", "title=g_large duplicate");
	run("Gaussian Blur 3D...", "x="+xsig+" y="+ysig+" z="+zsig);
	resetMinAndMax();
	run("Enhance Contrast", "saturated=0.35");
	
	
	imageCalculator("Subtract create stack", "g_small","g_large");
	out_name = "filtered_" + window_title;
	rename(out_name);

	close("g_*");
	return out_name;
	
}


function findFocus(window_title, focus_metric, do_plot) {
/*
 As of this moment this function can only handle the overal intensity approximation,
 depending on the image it might be better to use total gradient or something similar
 Input;
 window_title = title of the window containing a simple z-stack for a single color channel
 focus_metric = metric used to calculate focus, I place this to be able to grow this function
 				in the future.
 do_plot = 		if true then I do a plot for user of the focus metric over z-positon index
 */
	if (focus_metric == "intensity") {
		intVal = stackIntensity(window_title);
		maxLocs= Array.findMaxima(intVal, 500);
		focus_idx = maxLocs[0];

		if (do_plot) {
			Plot.create("Focus metric", "Z-position index", focus_metric, intVal);
			Plot.show();
		}


	}else {
		exit("In findFocus, I dont understand focus_metric option: " + focus_metric);
	}

	return focus_idx
}

function stackIntensity(window_title) {
/*
 Finds the total intensity of each slice in the z-stack given by window_title
 */
	// select stack to look at
	selectWindow(window_title);
	// number of frames
	nr_slices = nSlices;
	// I will look at total intensity
	run("Set Measurements...", "integrated redirect=None decimal=3");
	// init array
	intVal = newArray(nr_slices);
	for (i = 0; i < nr_slices; i++) {
		setSlice(i+1);
		run("Clear Results");
		run("Measure");
		tmp = getResult("RawIntDen", 0);
		//print("z-pos: " + i + "; Intensity: " + tmp);
		intVal[i] = tmp;
	}

	run("Clear Results");
	selectWindow("Results");
	run("Close");
	return intVal;

}

function enhance_contrast(window_title, focus_idx, saturation) { 
// function description
	selectWindow(window_title);
	setSlice(focus_idx);
	resetMinAndMax();
	run("Enhance Contrast", "saturated=" + saturation);

}


function save_and_close(window_title, folder2use, tif_title){

	selectWindow(window_title);
	saveAs("Tiff", folder2use + tif_title);
	close(tif_title);
}
