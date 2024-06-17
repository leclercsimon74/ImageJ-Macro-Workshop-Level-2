# ImageJ Macro Workshop Level 2

Continuation of the workshop [level 1](https://github.com/leclercsimon74/ImageJ-Macro-Workshop-Level-1)

## Objective of the workshop
The objective is to reliably extract data from images using FiJi measure tool or analyze particles, and export these results as CSV, which can be further analyzed using your favorite software.

## Condition to come to the workshop
- Have followed level 1, how to make a macro
- Have some example images to make your macro and measurement
- Bring your laptop

> [!NOTE]
> We will jump immediately to macro recording and measurement!


## Single-cell measurement
Measure signal intensity in the nucleus and the cytoplasm of a cell.

Images are split by their channel, so the first task is to group them back, by opening the same image with multiple channels.

``` Java
dir = getDirectory("Choose directory to process");
list = getFileList(dir);

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
	
}
```

Then we need to segment our cells:
- The nucleus, using the DAPI channel
    - We want to get the most out of the nucleus's outer edge continuously. Default, Li, IJ_Isodata... 
- The cytoplasm, using the mitotracker signal
    - Default thresholding is good for grabbing the cytoplasm

![Thresholding example image](https://github.com/leclercsimon74/ImageJ-Macro-Workshop-Level-2/blob/main/img/tutorial_img/Thresholding.png)

Segmented data are in binary form. In ImageJ, the pixel is either 0 or 255 for false and true, respectively. However, most of the time, we will have imperfect segmentation. Some pixels will be noise. It is possible to reduce their number before or after the segmentation.
Before segmentation, smoothing the image can be a solution (Process -> Smooth, or with more control, Process->Filters). This can degrade the image quality though, and as such, most of the time, cleaning **after** the segmentation is more usual. In Process->Binary are multiple tools to clean the segmentation of noises and fill holes. If these tools are quick and powerful, they are not processing the data in 3D, but as a series of 2D images. In our case, the data is 3D, and we need to use a plugin instead: Plugins->Process. There, we found the dilate and erode functions that we can use to clean the data.

In the case of a weak group of pixels such as the one we have here (no solid white), making a dilation, followed by a couple of erosions, then finishing with a dilation, will group the nuclei pixel while removing the noisy pixel. Finishing with a 2D stack fill hole will give a full nuclei segmentation.

The most important point of this Macro - and the Workshop! -  is the Analyze->Analyze Particles window. It opens an unremarkable window that asks you only a few things, such as the size range, the circularity, and other options... The option 'add to manager' is the one that we are the most interested in. Remember, ImageJ will process the z-stack as a series of individual images. The parameters calculated by ImageJ can be changed in Analyze->Set Measurements...

![Particle analysis Image](https://github.com/leclercsimon74/ImageJ-Macro-Workshop-Level-2/blob/main/img/tutorial_img/Analyze%20particles.png)

Clicking on OK will open 3 windows, the Results window, lists the statistics such as those set by the user for **EVERY** particle. If single-pixel or small particles are not excluded at the previous window, you can end up with thousands or more ROI. The second window is the summary (if ticked), which summarizes the global stats of the particles by slice. And finally, the ROI manager. The ROI manager stores the ROI of each particle, and if the 'Show all' and 'Labels' are ticks, will show the **ALL** the ROI on the segmented image. This tool, if a little complicated to understand, is very powerful for measuring the fluorescence intensity of an ROI on another image. For example, if you select the channel 4 image ("C4-"), then on the ROI manager click on any ROI there (like the "009-..."), it will automatically put you on the correct slice and show the ROI. From there, it is possible to measure (Analyze->Measure), adding a line in the Results, or directly in the ROI manager with the 'Measure'.

![Roi manager example image](https://github.com/leclercsimon74/ImageJ-Macro-Workshop-Level-2/blob/main/img/tutorial_img/Roi%20manager.png)

Of course, what we want to do here is not only measure one ROI, but **ALL** of them. In the More>>, there is a MultiMeasure, as well as a lot of options to manipulate the ROI. Unticking all options is needed to measure only the correct ROI at the correct slice. For security, "Deselect" will reset the selection and allow the multi-measure to run correctly. Saving the results as csv for Excel analysis is required.

``` Java
selectWindow("C4-"+name);
roiManager("Deselect"); //security
roiManager("multi-measure");
selectWindow("Results");
saveAs("Results", name+"_YFP.csv");
```

The same steps can be repeated with the cytoplasm segmentation and the yellow channel (C2). In this case, we may also want to remove the nucleus from the cytoplasm. It is easily done by subtracting the segmentation of the nucleus from the segmentation of the cytoplasm using Process->Image Calculator.

We can of course discuss the facts to analyze 3D images. Most of the time, using the central plane or a z-projection (MAX or AVG) is enough for this kind of analysis. This is also to showcase the limit of FiJi: 3D analysis. It becomes quickly limited, even if some plugins are trying to compensate for this.

> [!NOTE]
> Macro 5-3D_multi_measure.ijm contains all the answers for this exercise!

> [!CAUTION]
> Macro 5-3D_multi_measure.ijm is not perfect and does not include safe-fail!
> If the segmentation fails (too big or too small), the macro will continue and analyze. A good practice is to set some limits and skip the processing. This can also be done at the data analysis stage.

## Multi-cell measurement
It is a similar exercise to the previous one, analyzing multiple cells in a vast field on one Z plane instead. The goal is to detect nuclei (C3) and find if they are infected (C2). We then want to extract the image of the infected nuclei (only C3) to generate a database, as well as save the infection stage on a CSV document.

In this case, the image results from tiles (4x4) done on a Nikon microscope. Some of these images are slightly out of focus, and we do NOT want to include such nuclei in the database.

> [!NOTE]
> This exercise focuses on Table management in ImageJ!

> [!NOTE]
> You can find the full macro: Database_infected_nuclei.ijm

We start by defining some variables, the first being the save directory, called database here. The second parameter is the minimum nuclei size that we want to take into account, the minimum average intensity of infection, the resulting image size and two parameters about the nuclei shape, the solidity, and the roundness.

``` Java
save_path = File.directory + File.separator + "database";
if (!File.isDirectory(save_path)){File.makeDirectory(save_path);}
min_nuclei_size = 750;
infection_int = 100;
img_size = 100;
min_solidity = 0.8;
min_roundess = 0.7;
```

Then we want a simple image treatment and segmentation on the nuclei side. In this case, we want to take as much of the nuclei as possible, so we will use a `Triangle` threshold and a simple `Open` to clean isolated pixels.
``` Java
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
```

We follow up by setting up the measurement that we want to do on the nuclei. Two parameters are important here, the bounding box as `bounding` and the shape descriptor, as `shape`. The `Analyze particles` is then run, with the minimum size set here as well as excluding the edges, since we want full nuclei.
This generates a `Results` table. However, if we leave it like that, other results will be appended to this table. To avoid this, we just need to rename it as `Results-nuclei`. Then we can set the measurement that we want to do on the infection channel, which is about intensity, then run the `multi-measure` from the `RoiManager`. In a similar fashion, we rename the Table as `Result-infection`.

``` Java
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
```

For this exercise, we will use a `while` loop, even if a `for` loop will have been more adapted (this `while` loop assumes we have at least one nuclei in the image). The first line sets the length of the Table, and the second a counter. The loop will continue to run until the condition is `False`. Then we select the correct table, grab the value of roundness and solidity at the correct row, and check if they are bigger than the one we setup earlier. If this is the case, we then check the average intensity of infection of this nuclei. If this cell is infected, we proceed on the image manipulation to extract only the nuclei of interest. We finish this code by incrementing the row to look at the next row when the loop restart.


``` Java
//Set up the analysis loop
nRows = Table.size;
row = 0;
while (row < nRows){
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
			...
			}
		}
	row ++;// increment for the next row
	}
```

Grab the bounding box, make a rectangle selection using the values, and duplicate the image. Then we resize it, adjust the contrast, and set up the image depth to 8 bits before saving it in the database folder. The image saved contains a generic name `nuclei` followed by its row number and the infection value.

``` Java
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
```

You can try different values for the initial variables. This kind of database can then be used to train an algorithm like machine learning to indicate if a cell is infected (easy) or what is the cell infection level (harder) based on the nuclei label.

![example image for exercise 2](https://github.com/leclercsimon74/ImageJ-Macro-Workshop-Level-2/blob/main/img/tutorial_img/Exercice2%20overview.png)


## Make your analysis!

We can discuss what sort of exercise and analysis you want to do here!
