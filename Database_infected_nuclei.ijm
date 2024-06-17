//Define variables
save_path = File.directory + File.separator + "database";
if (!File.isDirectory(save_path)){File.makeDirectory(save_path);}
min_nuclei_size = 750;
infection_int = 100;
img_size = 100;
min_solidity = 0.8;
min_roundess = 0.7;

//first adjust the brightness/contrast
selectWindow("C2-Composite-4hpi.tif");
run("Enhance Contrast", "saturated=0.35");
selectWindow("C3-Composite-4hpi.tif");
run("Enhance Contrast", "saturated=0.35");
//dupli as security
run("Duplicate...", "title=nuclei");
//Threhsolding
setAutoThreshold("Triangle dark");
setOption("BlackBackground", true);
run("Convert to Mask");
run("Open"); //clean

//set and measure
run("Set Measurements...", "area centroid perimeter bounding shape redirect=None decimal=3");
run("Analyze Particles...", "size="+min_nuclei_size+"-Infinity display exclude clear add");

//Result manipulation
selectWindow("Results");
Table.rename("Results", "Results-nuclei");

// measure the signal in the infection channel
run("Set Measurements...", "mean standard modal min redirect=None decimal=3");
selectWindow("C2-Composite-4hpi.tif");
roiManager("multi-measure measure_all");
Table.rename("Results", "Results-infection");

//Set up the analysis loop
nRows_nuclei = Table.size;
row = 0;
while (row < nRows_nuclei){
	//Can check some parameters here to select only some nuclei
	selectWindow("Results-nuclei");
	Round = Table.get("Round", row);
	Solidity = Table.get("Solidity", row);
	//verify if the nuclei correspond to the desired parameters
	if ((Round > min_roundess) && (Solidity > min_solidity)){
		selectWindow("Results-infection");
		infection = Table.get("Mean", row);
		//check if the nuclei is infected
		if (infection > infection_int){
			selectWindow("Results-nuclei");
			//grab the nuclei coordinates
			bx = Table.get("BX", row);
			by = Table.get("BY", row);
			w = Table.get("Width", row);
			h = Table.get("Height", row);
			// and make a duplicate of the selection
			selectWindow("C3-Composite-4hpi.tif");
			makeRectangle(bx, by, w, h);
			run("Duplicate...", "title=nuclei_"+row+"_"+round(infection));
			//resize to have the same kind of image
			run("Size...", "width="+img_size+" height="+img_size+" depth=1 average interpolation=Bilinear");
			//adjust to 8 bits
			run("Enhance Contrast", "saturated=0.35");
			run("8-bit");
			//save and close the duplicate
			name = getTitle();
			saveAs("Tiff", save_path+File.separator+name);
			close();
			print(infection);
			}
		}
	row ++;// increment for the next row
	}
