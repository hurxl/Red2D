# Red2D
![Red2D_image](https://user-images.githubusercontent.com/52224108/60145474-1d91e280-9801-11e9-891f-739cd63bf8f3.png)


## Description

Red2D is a small data reduction package to convert 2D elastic scattering patterns to 1D I-q profile, working on a scientific data analysis software Igor Pro. This package targets for data from small/wide angle X-ray scattering (SAXS/WAXS), small angle neutron scattering (SANS) and static light scattering (SLS).

This package can
- Load 2D scattering patterns (32bit signed integer tiff)
- Display 2D images and 1D I-q profiles
- Get beam center and SDD by fitting standard sample (AgBh)
- Make and apply mask on images
- Perform circular average or sector average with proper mask
- Normalize 1D I-q profiles with exposure time, transmittance, sample thickness, absolute intensity correction, and also support cell and solvent subtraction.


## Other features

- Batch reduction of multiple images
- Support tilted detector using Euler angles
- Fit AgBh even when beam center is outside the image
- ROI mask and sector mask avilable
- Azimuthal profile
- Combining multiple images into one image


## Requirement

- Igor Pro by Wavemetrics
- This pacakge is only tested with Igor Pro 8 but it should work on Igor Pro 6 and 7.
- This package is only tested on MacOS but should work on Windows as well.


## Usage

- Please refer the manual for step by step introcution.


## Installation

1. Download Red2D_igor.zip and unzip the file.
2. Put the Red2D_igor folder in /Documents/WaveMetrics/Igor Pro User Files/Igor Procedures
3. Restart Igor Pro


## Author

[hurxl](https://www.shibayamalab.issp.u-tokyo.ac.jp/li-xiang)


## License

[MIT](http://b4b4r07.mit-license.org)
