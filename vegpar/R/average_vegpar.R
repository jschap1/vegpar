# Functions for calculating average vegetation parameter values
#
# Contains several functions for calculating raster averages

# --------------------------------------------------------------------------------
#' Stack by Time
#'
#' Rearranges the vegetation parameter files into a list of raster stacks for each time t
#' @param varname name of variable (e.g. LAI)
#' @param outdir directory to save outputs
#' @param nt number of time steps. Default is 12 (monthly)
#' @example stack_by_time("LAI", "~/Documents/")
#' @return par.bytime, a list of raster stacks.
#' @details Returns a list of raster stacks, where each entry is for a different time,
#' and each layer contains vegetation parameter data for a different land cover.
#' This code is set up for monthly average data.
#' @export
stack_by_time <- function(varname, outdir, nt = 12)
{
  par.bytime <- vector(length = nt, "list")
  for (t in 1:nt)
  {
    par_names <- list.files(outdir, pattern = glob2rx(paste0(varname, "*", month.name[t], "*")),
                            full.names = TRUE)
    par.bytime[[t]] <- raster::stack(par_names)
  }
  names(par.bytime) <- month.name[1:12]

  outname <- file.path(outdir, paste(varname, "_bytime.rds"))
  saveRDS(par.bytime, file = outname)
  print(paste("Saved", varname, "as", outname))
  return(par.bytime)
}

# --------------------------------------------------------------------------------
#' Vegpar Weighted Average
#'
#' Calculates the average value of the vegetation parameter in each month, taking into account land-cover based weighting.
#' @param vpar Input list of LAI raster stacks (LAI, fcanopy, albedo, etc.).
#' @param CV Input raster stack with cover fractions
#' @example LAI_wt_avg <- vegpar_wt_avg(LAI, CV)
#' @details Generate the input list vpar with stack_by_time()
#' @return raster stack containing weighted average vegetation parameter values
#' @export
vegpar_wt_avg <- function(vpar, CV)
{

  nclasses <- raster::nlayers(vpar[[1]])
  nt <- length(names(vpar))

  vpar_out <- CV[[1]]
  for (t in 1:nt)
  {
    vpar_t <- CV[[1]]
    values(vpar_t) <- 0
    names(vpar_t) <- names(LAI)[t]
    for (cc in 1:nclasses)
    {
      # Compute (vegetation parameter for a given month and time)*(cover fraction)
      vpar_t_cc <- overlay(vpar[[t]][[cc]], CV[[cc]],
                           fun = function(x,y){x*y}, na.rm = TRUE)
      # Calculate a running sum to get the area-weighted average
      if (!all(is.na(values(vpar_t_cc))))
      {
        vpar_t_cc[is.na(vpar_t_cc)] <- 0
        vpar_t <- overlay(vpar_t_cc, vpar_t, fun = sum, na.rm = TRUE)
      }
    }
    print(paste("Finished time step", t, "of", nt))
    vpar_t[values(vpar_t==0)] <- NA
    vpar_out <- addLayer(vpar_out, vpar_t)
  }
  vpar_out <- dropLayer(vpar_out, 1)
  names(vpar_out) <- names(vpar)
  return(vpar_out)
}

# --------------------------------------------------------------------------------
#' Vegpar Seasonal Average
#'
#' Calculates the seasonal value of the vegetation parameter, given monthly average maps
#' @param meanrasters Input raster stack of monthly average vegpar values
#' @examples LAI <- stack_by_time("LAI", clipped.gtiff.dir)
#' CV <- stack(cvnames)
#' LAI_wt_avg <- vegpar_wt_avg(LAI, CV)
#' LAI_seasonal_avg <- vegpar_seasonal_average(LAI)
#' @details Assumes the inputs are 1. Use output fromvegpar_wt_avg().
#' @return raster brick containing seasonal and annual average vegetation parameter values
#' @export
vegpar_seasonal_avg <- function(meanrasters)
{

  djf <- overlay(meanrasters[[12]], meanrasters[[1]], meanrasters[[2]], fun = sum, na.rm = TRUE)
  djf <- calc(djf, fun = function(x){x/3})

  mam <- overlay(meanrasters[[3]], meanrasters[[4]], meanrasters[[5]], fun = sum, na.rm = TRUE)
  mam <- calc(mam, fun = function(x){x/3})

  jja <- overlay(meanrasters[[6]], meanrasters[[7]], meanrasters[[8]], fun = sum, na.rm = TRUE)
  jja <- calc(jja, fun = function(x){x/3})

  son <- overlay(meanrasters[[9]], meanrasters[[10]], meanrasters[[11]], fun = sum, na.rm = TRUE)
  son <- calc(son, fun = function(x){x/3})

  ann_avg <- overlay(son, jja, mam, djf, fun = sum, na.rm = TRUE)
  ann_avg <- calc(ann_avg, fun = function(x){x/4})

  out1 <- brick(djf, mam, jja, son, ann_avg)
  names(out1) <- c("djf","mam","jja","son", "ann_avg")
  return(out1)
}

# --------------------------------------------------------------------------------
#' Get Basin Average
#'
#' Calculates the basin average values of a distributed parameter, given monthly maps
#' @param r Input raster stack of monthly average parameter values
#' @examples LAI_wt_avg <- vegpar_wt_avg(LAI, CV)
#' spatial_avg_LAI <- get_basin_avg(LAI_wt_avg)
#' @details This function is not limited to vegetation parameters. t's just a function for calculating the average value of a raster (stack).
#' @export
get_basin_avg <- function(r)
{
  nt <- length(names(r))
  avg_vals <- vector(length = nt)
  for (t in 1:nt)
  {
    avg_vals[t] <- mean(values(r[[t]]), na.rm = TRUE)
  }
  return(avg_vals)
}
