# vegpar demo

This tutorial explains how I used vegpar to compare VIC vegetation parameters among different input datasets.

<!-- Revise this/look at the actual results from the analysis. -->

<!-- This tutorial describes how I created vegetation parameter files for the VIC model.  -->

## Converting vegetation parameters from NetCDF format to Geotiff

The latest version of the VIC model (VIC-5, image driver) uses NetCDF files as inputs. While these are easier to work with than the ASCII parameter files used in older version of the VIC model, users might still want to convert to Geotiff format for analysis, this being a very easy file type to work with in R thanks to the `raster` package.

```r 
library(vegpar)

# Define inputs and outputs

# Name of VIC parameter file
vegpar <- "/hdd/Data/VICParametersGlobal/VICGlobal/v1.5/Image/ucrb_params_vicglobal.nc"

# File containing list of land cover class names
class.list <- "/media/jschap/PC_PART/HydrologyData/BV2019/igbp_classnames.txt"

# Directory where geotiffs should be saved
geotiff.dir <- "/home/jschap/Documents/Data/VICParametersGlobal/VICGlobal/Image/Vegetation"

classname <- read.table(class.list, stringsAsFactors = FALSE)[[1]]
netcdf2raster(vegpar_name, "LAI", classname, geotiff.dir)
netcdf2raster(vegpar_name, "fcanopy", classname, geotiff.dir)
netcdf2raster(vegpar_name, "Cv", classname, geotiff.dir)
```

## Clipping the vegetation parameters to the basin mask

```r 
# Directory where clipped geotiffs should be saved
clipped.gtiff.dir <- "/home/jschap/Documents/Data/VICParametersGlobal/VICGlobal/Image/Vegetation/clipped/"

# Basin mask
ucrb_mask <- raster("/home/jschap/Documents/ESSD/data/colo_mask.tif")

system(paste0("mkdir ", clipped.gtiff.dir))
subset_vegpar(geotiff.dir, "LAI", classname, clipped.gtiff.dir, ucrb_mask)
subset_vegpar(geotiff.dir, "fcanopy", classname, clipped.gtiff.dir, ucrb_mask)
subset_vegpar(geotiff.dir, "Cv", classname, clipped.gtiff.dir, ucrb_mask, nt = 1)
```

## Calculating weighted-average vegetation parameters

```r
LAI <- stack_by_time("LAI", clipped.gtiff.dir)
FCAN <- stack_by_time("fcanopy", clipped.gtiff.dir)

cvnames <- list.files(clipped.gtiff.dir, pattern = glob2rx("Cv*.tif"), full.names = TRUE)
CV <- stack(cvnames)

LAI_wt_avg <- vegpar_wt_avg(LAI, CV)
fcan_wt_avg <- vegpar_wt_avg(FCAN, CV)
```

## Compute seasonal and annual average maps

```r
LAI_seasonal_avg <- vegpar_seasonal_avg(LAI_wt_avg)
fcan_seasonal_avg <- vegpar_seasonal_avg(fcan_wt_avg)
```

## Compute average over basin

```r
avg_LAI_tab <- get_basin_avg(LAI_wt_avg)
avg_fcan_tab <- get_basin_avg(fcan_wt_avg)
dat <- data.frame(t = 1:12, month = month.name[1:12], LAI = avg_LAI_tab, fcan = avg_fcan_tab)
```

## Save results

```r
savedir <- "/home/jschap/Documents/ESSD/vegpar_comparison/BV2019"
write.table(dat, file = file.path(savedir, "tabulated_data.txt"),
            row.names = FALSE)
saveRDS(LAI_seasonal_avg, file = file.path(savedir, "LAI_seasonal_avg.rds"))
saveRDS(fcan_seasonal_avg, file = file.path(savedir, "fcan_seasonal_avg.rds")
	)
```


[vegpar-github]:https://github.com/jschap1/vegpar