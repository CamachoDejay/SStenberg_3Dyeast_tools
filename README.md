[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

# Simon Stenberg 3D yeast tools

ImageJ macro tools for Simon Stenberg to assist him in his yeast segmentation and quantification

## IJ Macros

### Segmentation

* [Simon_yeast_segementation.ijm](./IJ_macros/Simon_yeast_segmentation.ijm): The purpose of this macro is to segment yeast cells from 3 or 2 color images. As further post-processing, the algorithm tries to suggest good seeds that can be used later on to separate touching objects via watershed.

* Simon_mito_segmentation.ijm: The purpose of this macro is to segment mitochondria from 3 or 2 color images. The user must select the mitochondria color channel and then segmentation takes place, taking advantage of 3D filtering.

### Seed based watershed

In the imaging conditions used in this study, separating single yeast cells from their neighbors can be challenging. Thus we used a seed-based watershed algorithm to separate touching objects after segmentation. The seeds are prepared in a semi-automated fashion. The initial segmentation suggests seeds and the user then uses other macros to improve this suggestion by either adding or removing seeds. 3 macros are used together:

* improve_seg.ijm: The purpose of this macro is to help with the seed generation done during the yeast segmentation. Once it runs on an output folder it will show the current status of the object separation via watershed. If in this step a mistake is found then you can use:

* Add_seed.ijm: to add seeds by clicking (point selection tool) on the cell body you want to separate. After clicking, you must run add seed. At this point, you can add another seed, then click run again. Once you added a few easy seeds, then you can save the new seeds and run again improve_seg.ijm to see the current state of the watershed output.

* Remove_seed.ijm: removes a particular seed by clicking (point selection) on the seed you want to remove. After removing one or several seeds you have to save the new seeds.

### Save labels after the watershed

Once you are happy with the seeds then you can save the output after the watershed, which is a label image/volume. This will be used later on for the calculation of mitochondria properties per yeast cell. To do so run the macro:

* save_labels.ijm
