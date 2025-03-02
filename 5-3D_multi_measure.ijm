dir = getDirectory("Choose directory to process");
list = getFileList(dir);
run("Close All"); //security

for (i=0; i<list.length; i++) {
	if ((endsWith(list[i], ".tif")) && (startsWith(list[i], "C1-"))){ //only tif file
		processImage(dir+list[i]);
	}
}

function processImage(path){
	open(path);
	dapi_c = getTitle;
	name = dapi_c.replace("C1-", "");
	//open all the different c of the same name
	channel_number = 5;
	for (i=2; i<=channel_number; i++){
		open(path.replace("C1-", "C"+i+"-"));
	}
	//threshold the nucleus
	selectWindow(dapi_c);
	run("Duplicate...", "title=nucleus duplicate");
	run("Convert to Mask", "method=Li background=Dark black");
	run("Dilate (3D)", "iso=255");
	run("Erode (3D)", "iso=255");
	run("Erode (3D)", "iso=255");
	run("Dilate (3D)", "iso=255");
	run("Fill Holes", "stack");
	//threshold the cytoplasm
	cyto_c = dapi_c.replace("C1-", "C5-");
	selectWindow(cyto_c);
	run("Duplicate...", "title=cyto duplicate");
	run("Convert to Mask", "method=Default background=Dark black");
	run("Dilate (3D)", "iso=255");
	run("Erode (3D)", "iso=255");
	run("Erode (3D)", "iso=255");
	run("Dilate (3D)", "iso=255");
	run("Fill Holes", "stack");
	// detect the nucleus
	selectWindow("nucleus");
	run("Analyze Particles...", "size=50-Infinity display clear summarize add stack");
	// Select and measure YFP signal
	run("Clear Results");
	selectWindow("C4-"+name);
	roiManager("Deselect"); //security
	roiManager("multi-measure");
	selectWindow("Results");
	saveAs("Results", "//fileservices.ad.jyu.fi/homes/sleclerc/Desktop/Project/ImageJ Macro Workshop lvl2/Single cell Img/"+name+"_YFP.csv");
	// Select and measure IF signal only in cytoplasm
	// get the cytoplasm from subtracting the nucleus
	imageCalculator("Subtract create stack", "cyto","nucleus");
	selectWindow("Result of cyto");
	//analyze the particle
	run("Analyze Particles...", "size=50-Infinity display clear summarize add stack");
	run("Clear Results");
	//measure on the IF label
	selectWindow("C2-"+name);
	roiManager("Deselect"); //security
	roiManager("multi-measure");
	selectWindow("Results");
	saveAs("Results", "//fileservices.ad.jyu.fi/homes/sleclerc/Desktop/Project/ImageJ Macro Workshop lvl2/Single cell Img/"+name+"_IF.csv");
	//break; //for testing purpose
	run("Close All");
}