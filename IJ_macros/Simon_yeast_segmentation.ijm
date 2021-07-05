//  The purpose of this program is to segment the yeast cells from Simon,
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

blue = "Blue";
red = "Red";
//seeds = "seeds";
mask = "segmentation";

// create output folder
out_path = d_path + data + "_out" + File.separator; 
File.makeDirectory(out_path);


if ( channel_order == "RGB" && channels == 3) {
	print("Data has " + channels + " color channels");
	print("You chose a channel format of: " + channel_order);

	// extract blue
	selectWindow(data);
	run("Duplicate...", "title="+ blue +" duplicate channels=3");

	// extract red
	selectWindow(data);
	run("Duplicate...", "title="+ red +" duplicate channels=1");

	// find focus using blue channel
	f_idx = findFocus(blue, "intensity", false);

	// enhance contrast blue
	enhance_contrast(blue, f_idx, 0.35);

	// enhance contrast red
	enhance_contrast(red, f_idx, 0.35);

	red_mask = run_segmentation(red, 4);
	blue_mask = run_segmentation(blue, 4);

	imageCalculator("OR create stack", blue_mask, red_mask);
	rename("Combined_mask");

	close(red);
	close(blue);

	save_and_close("Red_grad", out_path, "Red_gradient.tif");
	save_and_close("Blue_grad", out_path, "Blue_gradient.tif");
	save_and_close(red_mask, out_path, "Red_mask.tif");
	save_and_close(blue_mask, out_path, "Blue_mask.tif");

	selectWindow("Combined_mask");
	rename(mask);


} else if ( channel_order == "RG" && channels == 2) {
	print("Data has " + channels + " color channels");
	print("You chose a channel format of: " + channel_order);

	// extract red
	selectWindow(data);
	run("Duplicate...", "title="+ red +" duplicate channels=1");

	// find focus using red channel
	f_idx = findFocus(red, "intensity", false);

	// enhance contrast red
	enhance_contrast(red, f_idx, 0.35);

	red_mask = run_segmentation(red, 4);

	close(red);
	
	save_and_close("Red_grad", out_path, "Red_gradient.tif");

	
	selectWindow(red_mask);
	run("Duplicate...", "title="+ mask +" duplicate");
	save_and_close(red_mask, out_path, "Red_mask.tif");

	
} else {
	print("We could detect " + channels + " color channels");
	print("You chose a channel format of: " + channel_order);
	exit("error message: " + channels + " channels is not compatible with " +  channel_order);
}


// save mask
selectWindow(mask);
saveAs("Tiff", out_path + "Segmentation.tif");
rename(mask);

// we get the seeds and save them in the output folder
seeds = get_and_save_seeds(mask, out_path);


// generate labels
lab = watershed_via_seeds(mask, seeds);
run("Select None");
saveAs("Tiff", out_path + "Labels.tif");

// we are done
print("All done");

exit


function run_segmentation(win_name, sigma_val) { 
// function description
	s1 = sigma_val;
	s2 = 1.414 * s1;
	
	f1 = freq_filter(win_name, s1, s2);
	selectWindow(f1);
	setSlice(f_idx);
	resetMinAndMax();
	run("Enhance Contrast", "saturated=0.35");
	f1 = "DoG_filt_"+s1;
	rename(f1);
	
	g1 = "gradient_1";
	run("Gradient (3D)", "use");
	rename(g1);
	setSlice(f_idx);
	resetMinAndMax();
	
	selectWindow(g1);
	mask1 = "mask_1";
	run("Duplicate...", "title="+mask1+" duplicate");
	selectWindow(mask1);
	resetMinAndMax();
	setAutoThreshold("Triangle dark stack");
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Triangle background=Dark black");
	run("3D Fill Holes");
	

	/*
	selectWindow(f1);
	mask2 = "mask_2";
	run("Duplicate...", "title="+mask2+" duplicate");
	selectWindow(mask2);
	resetMinAndMax();
	setAutoThreshold("Otsu dark stack");
	run("Convert to Mask", "method=Otsu background=Dark black");
	
	
	imageCalculator("OR create stack", "mask_1","mask_2");
	rename(win_name + "_mask");

	selectWindow(g1);
	rename(win_name + "_grad");

	close(mask1);
	close(mask2);
	*/

	selectWindow(mask1);
	out_name = win_name + "_mask";
	rename(out_name);

	selectWindow(g1);
	rename(win_name + "_grad");
	
	close(f1);

	return out_name;
}


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

function freq_filter_fix(window_title){
	selectWindow(window_title);
	run("Duplicate...", "title=g_small duplicate");
	run("Gaussian Blur 3D...", "x=2 y=2 z=1");
	resetMinAndMax();
	run("Enhance Contrast", "saturated=0.35");
	
	selectWindow(window_title);
	run("Duplicate...", "title=g_med duplicate");
	run("Gaussian Blur 3D...", "x=4 y=4 z=2");
	resetMinAndMax();
	run("Enhance Contrast", "saturated=0.35");
	
	selectWindow(window_title);
	run("Duplicate...", "title=g_large duplicate");
	run("Gaussian Blur 3D...", "x=8 y=8 z=4");
	resetMinAndMax();
	run("Enhance Contrast", "saturated=0.35");
	
	
	imageCalculator("Subtract create stack", "g_med","g_large");
	selectWindow("Result of g_med");
	rename("m_freq_" + window_title);
	
	imageCalculator("Subtract create stack", "g_small","g_med");
	selectWindow("Result of g_small");
	rename("h_freq_" + window_title);

	close("g_*");


	
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


function get_and_save_seeds(mask, folder2use) { 
	seeds_str = "seeds";
	// generate seeds
	selectWindow(mask);
	run("Morphological Filters (3D)", "operation=Erosion element=Ball x-radius=4 y-radius=4 z-radius=2");
	rename(seeds_str);

	run("Morphological Filters (3D)", "operation=Opening element=Ball x-radius=7 y-radius=7 z-radius=3");
	close(seeds_str);

	
	selectWindow(seeds_str + "-Opening");
	rename(seeds_str);
	
	// save seeds
	selectWindow(seeds_str);
	saveAs("Tiff", folder2use + "Seeds_auto.tif");
	saveAs("Tiff", folder2use + "Seeds.tif");
	rename(seeds_str);
	return seeds_str;

}

function watershed_via_seeds(mask, seeds) { 
	// generate labels
	selectWindow(mask);
	getVoxelSize(width, height, depth, unit);
	
	lab_str = "Labels";
	run("3D Watershed Split", "binary="+mask+" seeds="+seeds+" radius=2");
	selectWindow("EDT");
	close();
	selectWindow("Split");
	rename(lab_str);

	selectWindow(lab_str);
	run("Set Label Map", "colormap=[Golden angle] background=Black shuffle");
	setVoxelSize(width, height, depth, unit);
	return lab_str;
}