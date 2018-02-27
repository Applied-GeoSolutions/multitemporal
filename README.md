# README #


## Multitemporal analysis

This library provides an efficient means of flexibly performing time series analysis on stacks of gridded data. There is a core python application that breaks the processing job into pieces and launches workers to perform the processing. Each worker has a configurable sequence of processing steps. All the inputs and each step are prescribed in a user-conigured JSON files.

## Current supported modules:

Also see [this directory](https://bitbucket.org/appliedgeosolutions/multitemporal/src/3f754b97f6689a4377c680ab7b497d8b5071a89c/bin/?at=master)

```
annualstats.pyx
anomindex.pyx
aveminmax.pyx
calrojas.pyx
cfraction.pyx
crop_rotation_detection.pyx
crossings.pyx
daysofgreen.pyx
difference.pyx
disturbance.pyx
fft.pyx
fusion.pyx
gapfill.pyx
interannualslope.pyx
interannualtrend.pyx
multiply.pyx
optis_windows.pyx
overallmean.pyx
phenology.pyx
quicksort.pyx
reclassify.pyx
recomposite_count.pyx
recomposite.pyx
runningmean.pyx
shifttime.pyx
simpletrend.pyx
slice.pyx
startofgreen.pyx
summation.pyx
trend.pyx
valid_count.pyx
validmask.pyx
```

## Neat Features

+ `'output_type'` can be added to multitemporal output steps in numpy string style.  If missing, things remain `'float32'`.
   
