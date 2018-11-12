# Multitemporal 
(c) 2018 Applied Geosolutions, LLC

This library provides an efficient means of flexibly performing time series analysis on stacks of gridded data. There is a core python application that breaks the processing job into pieces and launches workers to perform the processing. Each worker has a configurable sequence of processing steps. All the inputs and each step are prescribed in a user-conigured JSON files.

Authors:

- Bobby H. Braswell (rbraswell at ags.io)
- Justin Fisk
- Ian Cooke

Supported in part by NASA Interdisciplinary Science Grant (NASA-IDS)
#NNX14AD31G -- **Drought-induced vegetation change and fire in Amazonian
forests: past, present, and future** to University of New Hampshire (Michael Palace, PI) 

## Current supported modules:

Also see [this directory](https://github.com/Applied-GeoSolutions/multitemporal/tree/master/multitemporal/bin)

```
correlate.pyx
diff_ts.pyx
gapfill.pyx
interpolate.pyx
multiply.pyx
passthrough.pyx
phenology.pyx
recomposite.pyx
screen.pyx
simpletrend.pyx
summation.pyx
validmask.pyx
```
