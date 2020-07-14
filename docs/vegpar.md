# Vegetation parameter file

The vegetation parameter file defines the fractional cover of each land cover type in each grid cell, as well as the depth of each root zone and the fraction of roots in each root zone. It can also optionally include time-varying leaf-area index (LAI), fractional canopy cover (fcanopy), and albedo, but it is simpler to describe these in the vegetation library file.

## Land cover types

I used MODIS land cover data from the [0.05° MODIS MCD12C1 Version 6 data product][mcd12c1] to assign a land cover type to each grid cell. MCD12C1 contains percent cover of each land cover class for three different land cover classification systems. I chose to use the IGBP LC classifications. 

While MCD12C1 observations are available from 2000-present, I chose to use observations from 2017 only because it was the most recent year with data in all of the MODIS-based datasets used for this study. I computed average values over all MODIS observations for the year. A future update to VICGlobal could incorporate multi-year vegetation climatology.

1. Download MODIS data in hdf format. The data are annual average percent cover of each of 17 different IGBP land covers. 
1. Use nearest neighbor interpolation to resample the land cover data to 1/16 degree resolution.
1. Write out Geotiff files with percent land cover data for each land cover class.

## Root zone depth and root fractions

I calculated root fraction as a function of land cover class following the method of [Zeng (2001)][zeng-paper], who used a formula to calculate the root distribution vs. depth as a function of empirical parameters defined for each IGBP land cover type. Maximum root depths for each land cover type were taken from literature.

[mcd12c1]:https://lpdaac.usgs.gov/products/mcd12c1v006/
[zeng-paper]:https://journals.ametsoc.org/jhm/article/2/5/525/4965/Global-Vegetation-Root-Distribution-for-Land