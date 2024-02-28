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
> In construction!

## Single-cell measurement
Measure signal intensity in the nucleus and the cytoplasm of a cell.

Images are split by their channel, so the first task is to group them back, by opening the same image with multiple channels.

Code here

Then we need to segment our cells:
- The nucleus, using the DAPI channel
- The cytoplasm, using the mitotracker signal

Image here

Discuss about segmentation data cleaning, such as fill holes, erode, dilate, open and close
Discuss about the 3D version of such algo, better for Z stack

Introduce the analyze particle

Introduce the ROI manager

Measure the green fluorescence from the nuclear segmentation

Repeat on the cytoplasm and the cyan/yellow channel

## Multi-cell measurement
It is a similar exercise to the previous one, analyzing multiple cells in a vast field on one Z plane instead.

Quick showcase here

## Make your analysis!
