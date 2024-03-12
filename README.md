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

> [!WARNING]
> 50% done!

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
saveAs("Results", "//fileservices.ad.jyu.fi/homes/sleclerc/Desktop/Project/ImageJ Macro Workshop lvl2/Single cell Img/"+name+"_YFP.csv");
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

In this case, the image is a result of tiles (4x4) done on the Nikon microscope. Some of these images are slightly out of focus, and we do NOT want to include such nuclei in the database.


Quick showcase here

## Make your analysis!
