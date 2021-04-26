//  Helper function to "improve_seg.ijm" it adds a seed at the selected posisiton
//
//	Author: Rafael Camacho
//  github: camachodejay
//  date:   2021 - 04 - 26
//  current address: Centre for cellular imaging - Göteborgs universitet

// empty the ROI manager
roiManager("reset");

selectWindow("Labels");
roiManager("Add");
cSlice = getSliceNumber();

selectWindow("Seeds");
run("Duplicate...", "title=new_seed duplicate");
run("Select All");
run("Clear", "stack");

setForegroundColor(255, 255, 255);
selectWindow("new_seed");
roiManager("Select", 0);
run("Draw", "slice");
run("Morphological Filters (3D)", "operation=Dilation element=Ball x-radius=4 y-radius=4 z-radius=3");
setAutoThreshold("Otsu dark stack");
run("Convert to Mask", "method=Otsu background=Dark black");
imageCalculator("XOR create stack", "Seeds","new_seed-Dilation");
selectWindow("Result of Seeds");
rename("Seeds_2");
run("3D Fill Holes");

close("new_seed-Dilation");
close("new_seed");
close("Seeds");

selectWindow("Seeds_2");
rename("Seeds");

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

	
	
    // do something here;
}

setBatchMode(false);
selectWindow("Seeds");
setSlice(cSlice);


selectWindow("Labels");
setSlice(cSlice);


