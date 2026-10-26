# StAR_MAT
A MATLAB tool for Statistical Analysis of Rocks

### Software development and maintenance

This repository contains the original MATLAB implementation of StAR. 
The maintained Python version, available at https://github.com/SimoneColucci/StAR, is recommended for new applications

StAR enables users to 
i)  statistically characterise particle (e.g., bubbles, crystals, clasts) size distributions using a robust and well-established fitting procedure; 
ii) determine the fractal index of the distribution
ii) convert 2D data to 3D applying stereological methods; 
iii) visualise particle shape and orientation distributions.

The statistical analysis is based on:
> Proussevitch A.A., Sahagian D.L., Tsentalovich E.P. (2007)
> *Statistical analysis of bubble and crystal size distributions*,
> JVGR, 164(3), 95-111.
> https://doi.org/10.1016/j.jvolgeores.2007.04.006

The stereology is based on:
> van der Jagt, T., Jongbloed, G., & Vittorietti, M. (2023)
> *Existence and Approximation of Densities of Chord Length- and Cross Section Area Distributions*,
> Image Analysis and Stereology, 42(3), 171-184.
> https://doi.org/10.5566/ias.2923.

> van der Jagt, T., Jongbloed, G., & Vittorietti, M. (2024)
> *Stereological determination of particle size distributions for similar convex bodies*
> Electronic Journal of Statistics, 18(1), 742-774.
> DOI: 10.1214/24-EJS2215

## Modules

StAR includes four modules:

    PreProcess  →  Analyze  →  Stereology  →  Properties

Each module can be used **independently** or **in succession** within a single
workflow. 

1. **PreProcess** – Spatial calibration of the input image file; cropping a region of the image; calculation of the intensity threshold for image binarisation.
   Results are saved in `<output>/preProcessingResults.csv` and the cropped images in `<output>/CropImages`. 
3. **Analyze** –  Threshold-based segmentation of the preprocessed images.
   This module generates `<output>/Measurements/measurementsTable_*.csv` and property
   histograms and orientation rose diagrams in `<output>/Measurements/Figures/`.
5. **Stereology** *(optional)* – Converts the two-dimensional distribution of equivalent diameters, obtained through the segmentation analysis,
   into a three-dimensional distribution, assuming spherical particles.
   Produces `measurementsStereoTable_*.csv` and comparison figures.
8. **Properties** – Statistically characterise particle size distributions.
   Define groups of image files here. Particle-size data from images belonging to the same group are pooled during the statistical analysis.
   This is useful for images from the same sample acquired at different magnifications.
   Saves best-fitting parameters in `<output>/Statistics/DensityBasedFitting_*.csv` and `<output>/Statistics/ExceedanceBasedFitting_*.csv`
   and calculated properties in `<output>/Statistics/Properties_*.csv`.    
   Optionally computes the fractal index and saves results in `<output>/Statistics/FractalIndex_*.csv`.
   Saves figures with the results of the fitting and the fractal analysis.

## Requirements

  - Tested on MATLAB R2025b
  - Python 3.10:
      The **Stereology** module requires the `pysizeunfolder` Python package
      from GitHub. The `pysizeunfolder` dependency is known to be incompatible with Python 3.14;
      Python 3.11–3.13 have not been tested. 

## Installation of `pysizeunfolder` 

## CASE 1: WINDOWS

Open the **Command Prompt** (`cmd`):

```
cd C:\StAR_MAT/src/Stereology
python -m pip install --upgrade pip
python -m pip install git+https://github.com/thomasvdj/pysizeunfolder
pip install -r requirements.txt
```

## CASE 2: LINUX / macOS (using a virtual environment - recommended)

# Navigate to the project directory
```bash
cd ~/StAR_MAT/src/Stereology
```

# Set Python 3.10 as the local version for this folder
```bash
pyenv local 3.10
```

# Create a virtual environment named 'venv'
```bash
python -m venv venv
```

# Activate the virtual environment
```bash
source venv/bin/activate
```

# Upgrade pip to ensure compatibility with modern wheels
```bash
pip install --upgrade pip
```

# Install pysizeunfolder directly from the GitHub repository
```bash
pip install git+https://github.com/thomasvdj/pysizeunfolder
```

# Install all other required libraries
```bash
pip install -r requirements.txt
```
### Usage

```Command Windows
cd run
PreProcess 
Analyze
Stereology
Properties
fractal
```

## 

## Author
Simone Colucci
