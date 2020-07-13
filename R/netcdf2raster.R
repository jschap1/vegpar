#' NetCDF to raster
#'
#' Converts a 3D or 4D NetCDF file to a raster. Saves output as geotiff. Specifically designed for vegetation parameters from the VIC-5 (Image Mode) parameter file.
#' @param ncdf_name netcdf filename
#' @param varname name of NetCDF variable (e.g. LAI or fcanopy)
#' @param classname list of vegetation class names
#' @param outdir directory to save outputs
#' @export
#' @return raster containing vegetation parameter data from NetCDF file
#' @examples
#' vegpar_name <- "params.CONUS_MX.MOD_IGBP.mode.2000_2016.nc"
#' class.list <- "igbp_classnames.txt"
#' classname <- read.table(class.list, stringsAsFactors = FALSE)[[1]]
#' geotiff.dir <- "/home/jschap/Documents/"
#' netcdf2raster(vegpar_name, "LAI", classname, geotiff.dir)
#' # class.list is a text file containing the names of each vegetation class. The order might be important.
#' #' @details Assumes NetCDF file is set up as [x, y, time, (class)]

netcdf2raster <- function(ncdf_name, varname, classname, outdir)
{

  vegpars <- ncdf4::nc_open(ncdf_name)
  ncdata <- ncdf4::ncvar_get(vegpars, varid = varname)
  r <- suppressWarnings(raster::raster(ncdf_name)) # template raster

  n <- dim(ncdata)
  if (length(n) == 3)
  {
    print("3D")
    nt <- 1
    nclasses <- n[3]
  } else
  {
    print("4D")
    nt <- n[3]
    nclasses <- n[4]
  }

  for (t in 1:nt)
  {
    for (cc in 1:nclasses)
    {

      if (length(n) == 3)
      {
        nc_out <- t(ncdata[,,cc])
        raster_out <- flip(raster::raster(nc_out, template = r), "y")
        outname <- file.path(outdir,
                             paste0(varname, "_", classname[cc], ".tif"))
      } else
      {
        nc_out <- t(ncdata[,,t,cc])
        raster_out <- flip(raster::raster(nc_out, template = r), "y")
        outname <- file.path(outdir,
                             paste0(varname, "_", month.name[t], "_", classname[cc], ".tif"))
      }

      raster::writeRaster(raster_out, outname, overwrite = TRUE)
    }
  }
  print(paste("Saved geotiff files to", outdir))

}
