# Red2D
![GitHub release](https://img.shields.io/github/release/hurxl/Red2D.svg)
![GitHub platform](https://img.shields.io/badge/platform-Igor%20Pro-brightgreen.svg)
[![Github All Releases](https://img.shields.io/github/downloads/hurxl/Red2D/total.svg)]()
![Red2D_image](https://user-images.githubusercontent.com/52224108/60145474-1d91e280-9801-11e9-891f-739cd63bf8f3.png)


## Installation

1. Download [Red2D.zip](https://github.com/hurxl/Red2D/releases/latest) and unzip the file.
2. Put the Red2D folder in /Documents/WaveMetrics/Igor Pro User Files/Igor Procedures.
3. Restart Igor Pro.


## Description

Red2D is a small data reduction package to convert 2D elastic scattering patterns to 1D I-q profile, working on a scientific data analysis software [Igor Pro](https://www.wavemetrics.com/). This package handles data reduction for small/wide angle X-ray scattering (SAXS/WAXS), small angle neutron scattering (SANS) and static light scattering (SLS). This package is easy to install (See [Installation](#Installation)) and contains basic reduction features, suitable for light users. For more comprehensive data reduction and analysis, I recommend to use [Irena/Nika/Indra](https://github.com/jilavsky/SAXS_IgorCode) developded by Dr. Jan Ilavsky.

This package can
- Load 2D scattering patterns (32bit signed integer tiff)
- Display 2D images and 1D I-q or I-2θ profiles
- Get beam center and SDD by fitting standard samples (AgBh, Si, CeO2)
- Make and apply masks on images
- Perform circular average or sector average with solid angle correction.
- Normalize 1D I-q profiles with exposure time, transmittance, sample thickness, absolute intensity correction, and also support cell and solvent subtraction.


## Other features

- Batch reduction of multiple images
- Support tilted detector
- Fit standard samples even when beam center is outside the image
- ROI mask and sector mask avilable
- Azimuthal angle vs q profiles
- Combining multiple images into one image


## Requirement

- Igor Pro 8.0 or later by Wavemetrics
- This package has been tested on MacOS and Windows.
- This package does not support Igor 7 or older.


## Usage

- Please refer to the manual, included in the Red2D.zip, for step by step introcution.


## Author

[hurxl](https://www.shibayamalab.issp.u-tokyo.ac.jp/li-xiang)

## Acknowledgement

Thank you Dr. S. Nakagawa to help me add the tilted detector correction and check the validity of reduced 1D profiles.

## License

[MIT](https://github.com/hurxl/Red2D/blob/master/LICENSE)
