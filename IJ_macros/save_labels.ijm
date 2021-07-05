//  The purpose of this program is to help Simon clean his segmentation in 3D 
//  so each yeast is an indepent object. This is very important for the final 
//  quantification
//
//	Author: Rafael Camacho
//  github: camachodejay
//  date:   2021 - 04 - 26
//  current address: Centre for cellular imaging - Göteborgs universitet

// clean up first
// close all images
close("*");
// empty the ROI manager
roiManager("reset");
// empty the results table
run("Clear Results");
// configure that binary image are black in background, objects are white
setOption("BlackBackground", true);





macro "save_labels" {
	// ask user for directory that contains the data
	data_dir = getDirectory("Choose a Data Directory");
	print("Data directory: " + data_dir);
	run_out_folder(data_dir);
	print("All done");
	
}



function run_out_folder(dir2use) {

	if (!contains_Seeds_tif(dir2use)) {
	 	list_folder = listFolder(dir2use);
		// loops to navigate into each directory from the main one
		for (i=0; i<list_folder.length; i++)
		{
			// extends directory path
			dir=dir2use+list_folder[i];
			run_out_folder(dir);
		}
	}
	
	else {
		// create output directory, used later on for saving results
		print(dir2use);
		save_lab(dir2use);
		// close all images
		close("*");

		
		
	}
}



function contains_Seeds_tif(dir) {
// check if any file in the dir ends with ".tif"
    list = getFileList(dir);
     
    for (i=0; i<list.length; i++) {
    	list_element = list[i];
    	// look for tif files
        if (endsWith(list[i], "Seeds.tif")){
        	return true;
        }
           
     }

	 return false;
	
	
}



function listTif(dir) {
// list of all files in a directory that end with ".tif"
     list = getFileList(dir);
     tif_list = newArray(0);
     for (i=0; i<list.length; i++) {
     	list_element = list[i];
     	// look for tif files
        if (endsWith(list[i], ".tif")){
        	//tif_list = append(tif_list,list_element); 
        	tif_list = Array.concat(tif_list,list_element);
        }
           
     }

	 return tif_list;
 }



 function listFolder(dir) {
	//List folders inside a main one and transforming a charater to be able to extend the directoy path thereafter
     list = getFileList(dir);
     
     for (i=0; i<list.length; i++)
     {
     	list[i] = replace(list[i], "/", "\\");
     }
	 return list;
 }




function save_lab(directory) { 
// main function that does the saving
	seg = "Segmentation";
	seeds = "Seeds";
	lab = "Labels";

	do_overlay = false;
	
	open(directory + "Segmentation.tif");
	rename(seg);
	run("Select None");
	
	open(directory + "Seeds.tif");
	rename(seeds);
	run("Select None");
	
	f_idx = findFocus(seg, "intensity", false);
	
	selectWindow(seg);
	setSlice(f_idx);
	resetMinAndMax();
	getVoxelSize(width, height, depth, unit);
	
	selectWindow(seeds);
	setSlice(f_idx);
	resetMinAndMax();
	
	run("3D Watershed Split", "binary=Segmentation seeds=Seeds radius=2");
	selectWindow("EDT");
	close();
	selectWindow("Split");
	rename(lab);
	
	
	
	
	selectWindow(lab);
	run("Set Label Map", "colormap=[Golden angle] background=Black shuffle");
	//run("Sync Windows");
	setVoxelSize(width, height, depth, unit);
	run("Select None");
	
	//run("Duplicate...", "title=RGB duplicate");
	//run("RGB Color");
	selectWindow(lab);
	run("Duplicate...", "title=lab duplicate");
	
	selectWindow(seeds);
	run("Duplicate...", "title=sed duplicate");
	run("16-bit");
	
	
	selectWindow("Labels");
	
	if (do_overlay) {
		run("RGB Color");
		setBatchMode(true);
		nS = nSlices;
		for (i = 1; i <= nS; i++) {
			selectWindow("Seeds");
			setSlice(i);
			run("Select None");
			run("Create Selection");
		
			if (selectionType() > -1) {
				selectWindow("Labels");
				setSlice(i);
				run("Restore Selection");
				run("Fill", "slice");
				run("Select None");
			}
		}
		setTool("point");
	}
	
	close("sed");
	setBatchMode(false);
	selectWindow("Labels");
	
	
	
	save_and_leave("lab", directory, "lab.tif");

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

function save_and_leave(window_title, folder2use, tif_title){

	selectWindow(window_title);
	saveAs("Tiff", folder2use + tif_title);
	selectWindow(tif_title);
	rename(window_title);
	
}

