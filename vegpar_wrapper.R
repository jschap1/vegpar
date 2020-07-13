# vegpar package wrapper script

library(vegpar)
library(raster)
library(rgdal)

# Convert vegetation parameters from NetCDF to geotiff -----------------------------------------

# VICGlobal
vegpar_name <- "/home/jschap/Documents/Data/VICParametersGlobal/VICGlobal/Image/ucrb_params_vicglobal.nc"
class.list <- "/media/jschap/PC_PART/HydrologyData/BV2019/igbp_classnames.txt"
geotiff.dir <- "/home/jschap/Documents/Data/VICParametersGlobal/VICGlobal/Image/Vegetation"
clipped.gtiff.dir <- "/home/jschap/Documents/Data/VICParametersGlobal/VICGlobal/Image/Vegetation/clipped/"

# L2015
# vegpar_name <- "/home/jschap/Documents/Data/VICParametersCONUS/L2013_params.nc"
# class.list <- "/home/jschap/Documents/Data/VICParametersCONUS/umd-nldas_classnames.txt"
# geotiff.dir <- "/home/jschap/Documents/Data/VICParametersCONUS/vegetation"
# clipped.gtiff.dir <- "/home/jschap/Documents/Data/VICParametersCONUS/vegetation/clipped_to_ucrb"

# BV2019
# vegpar_name <- "/media/jschap/PC_PART/HydrologyData/BV2019/params.CONUS_MX.MOD_IGBP.mode.2000_2016.nc"
# class.list <- "/media/jschap/PC_PART/HydrologyData/BV2019/igbp_classnames.txt"
# geotiff.dir <- "/home/jschap/Documents/ESSD/data/ucrb_vegpars/bv2019"
# clipped.gtiff.dir <- "/home/jschap/Documents/ESSD/data/ucrb_vegpars/bv2019/clipped_to_ucrb/"

classname <- read.table(class.list, stringsAsFactors = FALSE)[[1]]
netcdf2raster(vegpar_name, "LAI", classname, geotiff.dir)
netcdf2raster(vegpar_name, "fcanopy", classname, geotiff.dir)
netcdf2raster(vegpar_name, "Cv", classname, geotiff.dir)

# Subset vegetation parameter to basin -----------------------------------------

ucrb_mask <- raster("/home/jschap/Documents/ESSD/data/colo_mask.tif")
system(paste0("mkdir ", clipped.gtiff.dir))
subset_vegpar(geotiff.dir, "LAI", classname, clipped.gtiff.dir, ucrb_mask)
subset_vegpar(geotiff.dir, "fcanopy", classname, clipped.gtiff.dir, ucrb_mask)
subset_vegpar(geotiff.dir, "Cv", classname, clipped.gtiff.dir, ucrb_mask, nt = 1)

# Calculate area-weighted vegetation parameter values --------------------------

LAI <- stack_by_time("LAI", clipped.gtiff.dir)
FCAN <- stack_by_time("fcanopy", clipped.gtiff.dir)
cvnames <- list.files(clipped.gtiff.dir, pattern = glob2rx("Cv*.tif"), full.names = TRUE)
CV <- stack(cvnames)
LAI_wt_avg <- vegpar_wt_avg(LAI, CV)
fcan_wt_avg <- vegpar_wt_avg(FCAN, CV)

# Compute seasonal and annual average maps -------------------------------------

LAI_seasonal_avg <- vegpar_seasonal_avg(LAI_wt_avg)
fcan_seasonal_avg <- vegpar_seasonal_avg(fcan_wt_avg)

# Compute average over basin and tabulate --------------------------------------

avg_LAI_tab <- get_basin_avg(LAI_wt_avg)
avg_fcan_tab <- get_basin_avg(fcan_wt_avg)
dat <- data.frame(t = 1:12, month = month.name[1:12], LAI = avg_LAI_tab, fcan = avg_fcan_tab)

# Save key results -------------------------------------------------------------

savedir <- "/home/jschap/Documents/ESSD/vegpar_comparison/BV2019"
write.table(dat, file = file.path(savedir, "tabulated_data.txt"),
            row.names = FALSE)
saveRDS(LAI_seasonal_avg, file = file.path(savedir, "LAI_seasonal_avg.rds"))
saveRDS(fcan_seasonal_avg, file = file.path(savedir, "fcan_seasonal_avg.rds"))
