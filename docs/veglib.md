# Vegetation library file

The vegetation library maps each land cover type to a set of vegetation parameters. I adapted the LDAS vegetation library from Cherkauer (1999) --- I can't find any online documentation for this file, but it is nearly the same as the vegetation library used by Livneh et al. (2013). I updated the old values of monthly LAI, fcanopy, and albedo with values estimated from recent MODIS data products. I set the architectural and minimum stomatal resistance parameters based on literature values. I left the rest of the parameters unmodified.

<!-- Good, but still need to add details of how the fcanopy, albedo, and LAI data were obtained from the MODIS/GLASS data.  -->

## Stomatal and architectural resistance

The minimum stomatal resistance (rmin) and the architectural resistance (r0) play a role in how much plant transpiration occurs. Higher resistance means less transpiration. Stomatal resistance is resistance to the release of water through the plant stomata, and architectural resistance is the aerodynamic resistance between the leaves and the canopy top (Ducoudre et al., 1993). Two sets of resistance parameters have been used in past VIC implementations. Nijssen et al. (2001) ran VIC over the entire globe using rmin values adapted from Dorman and Sellers (1989)'s global database of rmin values computed using the Simple Biosphere Model (SiB, Sellers et al., 1986). N2001's r0 values were taken from Ducoudre et al. (1993)'s SECHIBA land surface parameterization. The other set of rmin and r0 parameters are those used in the LDAS vegetation library and in studies such as Livneh et al. (2013). This set of rmin values comes from Mao et al. (2007) and Mao and Cherkaur (2009). I could not find any documentation regarding the r0 values. For VICGlobal, I used the rmin values from SiB (Dorman and Sellers, 1989) and the r0 values from SECHIBA (Ducoudre et al., 1993) as they appear to be the best documented values.

## Defining snow-free cells

I used the [MODIS MOD10CM][mod10cm] snow cover data product to calculate snow-free monthly average LAI, fractional canopy cover, and albedo for each IGBP land cover type for the year 2017. With the exception of the "perennial snow and ice" land cover, the vegetation parameters in the vegetation library are supposed to be for vegetation, not snow-covered vegetation. Therefore, before calculating albedo, fcanopy, and LAI for each land cover class, we need to exclude snow-covered pixels.

First, I used the MODIS HDF-EOS to Geotiff ConversionTool (HEG) to convert the 2017 MOD10CM snow cover data to Geotiff format, then I used the MODIS QA band to exclude low-quality data from consideration. The 0 values in the QA band are considered good quality, while values like 250 (cloud), 253 (no decision), 254 (water), and 255 (fill) are not good quality. I excluded grid cells with nonzero QA values.


```r
library(vegpar)
library(raster)

# Load snow cover data
snow.names <- list.files("/hdd/Data/MODIS_snow/geotiffs/", 
                         pattern = glob2rx("*5km.tif"), full.names = TRUE)

qa.names <- list.files("/hdd/Data/MODIS_snow/geotiffs/", 
                       pattern = glob2rx("*5km0.tif"), full.names = TRUE)

snowcover <- stack(snow.names) 
qa <- stack(qa.names)
names(snowcover) <- month.name[1:12]
names(qa) <- month.name[1:12]

# Remove the no-data values
snowcover <- reclassify(snowcover, cbind(100, Inf, NA))

# Remove poor quality data using the QA band
for (j in 1:12)
{
  bad.ind <- which(values(qa[[j]])!=0)
  snowcover[[j]][bad.ind] <- NA
  print(j) # display progress
}
```

`snowcover` is a list of rasters containing fractional snow cover in each month.

 <!-- ![fractional snow cover](/img/fsca.png). -->

Next, I loaded the [MODIS MCD12C1][mcd12c1] land cover data, and I resampled snow cover to match the resolution of the land cover data, which is already in the correct 1/16 degree coordinate system for VICGlobal.

```r
# Load land cover data
cv.names <- list.files("/hdd/Data/VICParametersGlobal/VICGlobal/Vegetation_Fractions/Resampled_1_16/", 
                       pattern = glob2rx("*.tif"),
                       full.names = TRUE)
cv <- stack(cv.names)
nclass <- nlayers(cv)
lcnames <- vector(length = nclass)
temp <- strsplit(names(cv), split = "_fraction")
for (ii in 1:nclass)
{
  lcnames[[ii]] <- temp[[ii]]  
}
names(cv) <- lcnames

# Project to match resolution (1/16) of the land cover data
snowcover.proj <- projectRaster(snowcover, cv[[1]], 
                                method = "bilinear",
                                progress = "text",
                                file = "/home/jschap/Documents/ESSD/data/monthly_snow_cover_2017.tif")
```

`snowcover.proj` is a raster brick of fractional snow cover data on the VICGlobal grid, with one layer for each month. I used this to create a mask of which pixels are majority snow-covered, as well as a mask of non-snow-covered pixels. I used 90% as the threshold for a pixel to be considered snow covered. I separated the snow masks by hemisphere.

```r
# Make polygons for the northern and southern hemispheres
e_nh<- c(-180, 180, 0, 90)
e_sh<- c(-180, 180, -90, 0)
nh <- make_spatial_polygon(e_nh)
sh <- make_spatial_polygon(e_sh)

# Make mask of where the pixels are majority snow-covered
thres <- 0.9
snow.maj <- reclassify(snowcover.proj, cbind(thres, Inf, 1), progress = "text")
snow.maj <- reclassify(snow.maj, cbind(-Inf, thres, 0), right = FALSE, progress = "text")
snow.maj.nh <- crop(snow.maj, nh)

# invert_raster doesn't work well for a raster stack, so using reclassify instead:
nosnow.maj.nh <- reclassify(snow.maj.nh, cbind(-0.5,0.5,2))
nosnow.maj.nh <- reclassify(nosnow.maj.nh, cbind(0.5,1.5,0))
nosnow.maj.nh <- reclassify(nosnow.maj.nh, cbind(1.5,2.5,1))
```

## Albedo

After creating raster masks of snow-free area, the next step is to use the albedo and land cover data products to calculate the average snow-free albedo for each land cover class, in each month. I used monthly 0.05 degree broadband albedo data from Dr. Shunlin Liang's research group at UMD. [Data available here][glass-download]

Load the monthly albedo data, crop it to the northern hemisphere, and apply the snow-free mask to keep only the albedo values for non-snow-covered pixels. 

```r
albedo <- brick("/home/jschap/Documents/ESSD/codes/Vegetation_Fractions/monthly_average_albedo_2017.grd")
albedo <- calc(albedo, fun = function(x) {x/10000}) # scaling factor
albedo.nh <- crop(albedo, nh)
albedo.nosnow.nh <- mask(albedo.nh, nosnow.maj.nh, maskvalue = 0, prog = "text")
```

Create a majority land cover raster than includes all pixels that are majority (at least 90%) a single land cover (not mixed).

```r
cv.nh <- crop(cv, nh, progress = "text")
CVmaj.nh <- majority_raster(cv.nh, 0.9)
```

For each land cover, make a mask of that land cover only, and calculate the average monthly albedo for that land cover type. I fixed albedo at 0.05 for water-covered area.

```r

lc.num <- 1 # repeat for each lc.num = 1, 2, ..., 17
lcnames[lc.num]

cv.lc <- CVmaj.nh
cv.lc[CVmaj.nh!=lc.num] <- NA
cv.lc[!is.na(cv.lc)] <- 1

# Make a map of albedo, but only over the land cover type
albedo.lc <- mask(albedo.nosnow.nh, cv.lc, prog="text")

# Calculate the mean over that land cover type
mean.albedo.lc.nh <- colMeans(values(albedo.lc), na.rm = TRUE)

# Write out the monthly albedo time series for the current land cover
write.table(mean.albedo.lc.nh, 
            file = "/home/jschap/Documents/ESSD/codes/vegpars/albedo.txt",
            quote = FALSE, col.names = FALSE, row.names = FALSE)

```

## Leaf-area index

The calculations for snow-free LAI and fcanopy are similar to the albedo calculation. I obtained LAI data from [GLASS][glass-download]. I used the snow-free mask and the majority land cover raster to calculate the average LAI for each land cover class in each month. Here is the code: 

```r
# Load LAI data and crop to northern hemisphere
lai <- brick("/home/jschap/Documents/ESSD/codes/Vegetation_Fractions/monthly_average_LAI_2017.grd")
lai <- reclassify(lai, cbind(100, Inf, NA), prog="text")
lai <- calc(lai, fun = function(x) {x/10}) # scaling factor
lai.nh <- crop(lai, nh, prog="text")

# Mask out the snow-covered pixels
lai.nosnow.nh <- mask(lai.nh, nosnow.maj.nh, maskvalue = 0, prog = "text")

# For each land cover, calculate monthly average LAI
lc.num <- 1
lcnames[lc.num]

cv.lc <- CVmaj.nh
cv.lc[CVmaj.nh!=lc.num] <- NA
cv.lc[!is.na(cv.lc)] <- 1

# Make a map of LAI, but only over the land cover type
lai.lc <- mask(lai.nosnow.nh, cv.lc, prog="text")

# Calculate the mean over that land cover type
mean.lai.lc.nh <- colMeans(values(lai.lc), na.rm = TRUE)
write.table(mean.lai.lc.nh, 
            file = "/home/jschap/Documents/ESSD/codes/vegpars/LAI.txt",
            quote = FALSE, col.names = FALSE, row.names = FALSE)


```

I set LAI to 0 for water-covered area and snow and ice.

## Fractional canopy cover

Similar to albedo and LAI. I estimated fcanopy based on [MODIS MCD13C2][modis-ndvi] NDVI using the same technique as Bohn and Vivoni (2019). 

```r
# Load fcanopy data and crop to northern hemisphere
fcan <- brick("/home/jschap/Documents/ESSD/codes/Vegetation_Fractions/monthly_average_fcan.grd")
fcan.nh <- crop(fcan, nh)

fcan.nosnow.nh <- mask(fcan.nh, nosnow.maj.nh, maskvalue = 0, prog = "text")

# Repeat for each land cover class = 1..17
lc.num <- 1
lcnames[lc.num]

cv.lc <- CVmaj.nh
cv.lc[CVmaj.nh!=lc.num] <- NA
cv.lc[!is.na(cv.lc)] <- 1
plot(cv.lc, main = "LC mask")

# Make a map of fcan, but only over the land cover type
fcan.lc <- mask(fcan.nosnow.nh, cv.lc, prog="text")
plot(fcan.lc[[1]], main = lcnames[lc.num])

# Calculate the mean over that land cover type
mean.fcan.lc.nh <- colMeans(values(fcan.lc), na.rm = TRUE)
write.table(mean.fcan.lc.nh, 
            file = "/home/jschap/Documents/ESSD/codes/vegpars/fcan.txt",
            quote = FALSE, col.names = FALSE, row.names = FALSE)

```

I set fcanopy to 0.001 for water-covered area and snow and ice.

## References

* Bohn, T. J., & Vivoni, E. R. (2019). MOD-LSP, MODIS-based parameters for hydrologic modeling of North American land cover change. Scientific Data, 6(1), 144. https://doi.org/10.1038/s41597-019-0150-2

* Dorman,  J.,  &  Sellers,  P.  J.  (1989).  A  global  climatology  of  albedo,  rough-ness length and stomatal resistance for atmospheric general circulationmodels as represented by the Simple Biosphere Model (SiB).J.  Appl.Meteor.

* Ducoudre, N. I., Laval, K., & Perrier, A. (1993). SECHIBA, a New Set of Param-eterizations of the Hydrologic Exchanges at the Land-Atmosphere Inter-face within the LMD Atmospheric General Circulation Model.Journalof  Climate,6(2), 248–273. https://doi.org/10.1175/1520- 0442(1993)006〈0248:sansop〉2.0.co;2

* Livneh, B., Rosenberg, E. A., Lin, C., Nijssen, B., Mishra, V., Andreadis, K. M.,Maurer,  E.  P.,  &  Lettenmaier,  D.  P.  (2013).  A  long-term  hydrologi-cally based dataset of land surface fluxes and states for the contermi-nous United States: Update and extensions.Journal of Climate,26(23),9384–9392. https://doi.org/10.1175/JCLI-D-12-00508.1

* Mao, D., & Cherkauer, K. A. (2009). Impacts of land-use change on hydrologicresponses  in  the  Great  Lakes  region.Journal  of  Hydrology,374(1-2),71–82. https://doi.org/10.1016/j.jhydrol.2009.06.016

* Mao, D., Cherkauer, K. A., & Bowling, L. C. (2007). Improved vegetation properties for the estimation of evapotranspiration in the Midwestern UnitedStates., InAsabe annual international meeting

* Nijssen, B., Schnur, R., & Lettenmaier, D. P. (2001). Global retrospective es-timation  of  soil  moisture  using  the  variable  infiltration  capacity  landsurface  modl,  1980-93.Journal  of  Climate,14(8),  1790–1808.  https ://doi.org/10.1175/1520-0442(2001)014〈1790:GREOSM〉2.0.CO;2

* Sellers, P. J., Mintz, Y., Sud, Y. C., & Dalcher, A. (1986). A Simple BiosphereModel (SIB) for Use within General Circulation Models.Journal of theAtmospheric  Sciences,43(6), 505–531. https://doi.org/10.1175/1520-0469(1986)043〈0505:ASBMFU〉2.0.CO;2

[glass-download]:http://glass.umd.edu/Download.html
[mod10cm]:https://nsidc.org/data/MOD10CM
[mcd12c1]:https://lpdaac.usgs.gov/products/mcd12c1v006/
[modis-ndvi]:https://earthdata.nasa.gov/