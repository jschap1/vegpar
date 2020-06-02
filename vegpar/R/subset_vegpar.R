#' Subset vegpar
#'
#' Subsets a vegetation parameter to a basin mask
#' @param indir directory containing geotiff files with vegetation parameter data
#' @param varname name of vegetation parameter (e.g. LAI or fcanopy)
#' @param classname list of vegetation class names
#' @param outdir directory to save outputs
#' @param basin_mask basin mask
#' @param nt number of time steps (generally going be to 12 (months))
#' @export
#' @return the most recent clipped raster
#' @examples ucrb_mask <- raster("colo_mask.tif")
#' class.list <- "igbp_classnames.txt"
#' classname <- read.table(class.list, stringsAsFactors = FALSE)[[1]]
#' geotiff.dir <- "~/Documents"
#' clipped.gtiff.dir <- "~/Documents/clipped_to_ucrb"
#' subset_vegpar(geotiff.dir, "LAI", classname, clipped.gtiff.dir, ucrb_mask)
#' @details Works specifically with the UMD-NLDAS land cover classes or the IGBP land cover classes.
#' To do: Make this more general by calling this code for a particular filename, instead of for a group of files at once.

subset_vegpar <- function(indir, varname, classname, outdir, basin_mask, nt = 12)
{

  nclasses <- length(classname)
  if (nclasses == 17)
  {
    lc_system = "IGBP"
    print("Input uses IGBP land cover classifications.")
  } else if (nclasses == 11)
  {
    lc_system = "UMD-NLDAS"
    print("Input uses UMD-NLDAS land cover classifications.")
  }

  for (t in 1:nt)
  {
    for (cc in 1:nclasses)
    {

      if (lc_system == "IGBP")
      {
        if (nt > 1)
        {
          name2load <- file.path(indir,
                                 paste0(varname, "_", month.name[t], "_", classname[cc], ".tif"))
        } else
        {
          name2load <- file.path(indir,
                                 paste0(varname, "_", classname[cc], ".tif"))
        }
        r <- raster::raster(name2load)

      } else if (lc_system == "UMD-NLDAS")
      {
        if (nt > 1)
        {
          name2load <- file.path(indir, paste0(classname[cc], "_", varname, t, ".tif"))
        } else
        {
          name2load <- file.path(indir, paste0(varname, "_", classname[cc], ".tif"))
        }

        # print(name2load)
        r <- raster::raster(name2load)

      }

      r.pr <- raster::projectRaster(r, basin_mask)
      r.clip <- raster::overlay(r.pr, basin_mask, fun= function(x,y){x*y})

      if (nt > 1)
      {
        name2save <- file.path(outdir,
                               paste0(varname, "_", month.name[t], "_", classname[cc], "_clipped.tif"))
      } else
      {
        name2save <- file.path(outdir,
                               paste0(varname, "_", classname[cc], "_clipped.tif"))
      }

      raster::writeRaster(r.clip, filename = name2save, overwrite = TRUE)
    }
    print(paste("Finished subsetting for time:", t))
  }
  print(paste("Saved clipped vegetation parameters to", outdir))
  return(r.clip)
}
