# Facing Distortion

Data and MATLAB code for:

> Cui, B., & Bex, P. (2025). Facing distortion: Impact of spatial distortions on upright and inverted face identification. *PLOS ONE*, 20(9), e0308675. https://doi.org/10.1371/journal.pone.0308675

Eight observers matched a target face to one of four distorted faces. The distortions were applied at six frequencies (1–32 cycles/image), and the distortion amplitude followed an adaptive staircase. Each observer did the task with upright and with inverted faces.

## Contents

| Folder | What's inside |
|---|---|
| `IdDistort/` | `distortFaceSpatialNAFC2ET.m`, the experiment script |
| `IdDistort/Upright_Data/`, `IdDistort/Invert_Data/` | One `.mat` file per observer (P1–P8) per orientation |
| `Threshold_Analysis/` | Analysis scripts (thresholds, ANOVA, figures) |

Each `.mat` file contains `trialRecord`, with one entry per distortion frequency. It holds the trial-by-trial amplitudes, responses and response times, and the fitted threshold (`fitObj.thresh`).

## Reproducing the analysis

You need MATLAB with the Statistics and Curve Fitting toolboxes. Run any script in `Threshold_Analysis/`. The scripts load the data automatically and use the thresholds saved in the data files.

## Running the experiment

You need MATLAB and [Psychtoolbox-3](http://psychtoolbox.org/). The face images come from the [IASLab Face Set](https://affective-science.org/face-set.shtml), which is available to academic researchers on request and is not included here. Set `pathToImageFolders` in the script to your copy. The script also uses a few helper functions from the Bex lab's toolbox (`makeFilter`, `Gaussian2D`, `fitPFuncnAFC_BC`), which are not included.

## License

Apache 2.0. Supported by the National Eye Institute (R01EY032162).
