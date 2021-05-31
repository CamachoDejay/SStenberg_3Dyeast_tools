//  Helper function to "improve_seg.ijm" it removes a selected seed
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

selectWindow("lab");
setSlice(cSlice);
roiManager("Select", 0);
run("Set Measurements...", "modal redirect=None decimal=3");
roiManager("Measure");
idx = getResult("Mode", nResults-1);
run("Clear Results");

run("Duplicate...", "title=tmp_lab duplicate");
setAutoThreshold("Otsu dark stack");
//run("Threshold...");
setThreshold(idx, idx);
setOption("BlackBackground", true);
run("Convert to Mask", "method=Otsu background=Dark black");
run("Invert", "stack");

imageCalculator("AND stack", "Seeds","tmp_lab");
close("tmp_lab");

selectWindow("Seeds");
setSlice(cSlice);
print(idx);