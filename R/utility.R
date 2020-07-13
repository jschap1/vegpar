# Utility functions for vegpar package

# ------------------------------------------------------------------
#' Make Spatial Polygon
#'
#' Makes a rectangular spatial polygon from four points
#' @param e extent [xmin, xmax, ymin, ymax]
#' @example rect <- make_spatial_polygon(c(-180, 180, -90, 90))
#' @export
make_spatial_polygon <- function(e)
{
  x_coord <- c(e[1], e[1], e[2], e[2], e[1])
  y_coord <- c(e[3], e[4], e[4], e[3], e[3])
  xym <- cbind(x_coord, y_coord)
  p <- Polygon(xym)
  ps <- Polygons(list(p),1)
  sps <- SpatialPolygons(list(ps))
}

# ------------------------------------------------------------------
#' Clip raster
#'
#' Clips a raster with another raster by cropping, then multiplying their values
#' @param x raster to clip
#' @param y raster with clipping extent
#' @export
clip_raster <- function(x, y)
{
  x_crop <- crop(x, y)
  x_clip <- overlay(x_crop, y,
                    fun = function(x,y){x*y},
                    progress = "text"
  )
}

# ------------------------------------------------------------------
#' Line Plot 2
#'
#' Makes a line plot comparing two data series
#' @export
#' @param x x-coordinates
#' @param y1 y-coordinates for first data series
#' @param y1 y-coordinates for second data series
#' @param ... additional arguments for plot()
lineplot2 <- function(x, y1, y2, legtext,
                      lpos = "topleft",
                      sz = 1.5, lw = 1.5, ...
                      )
{
  plot(x, y1,
       type = "o", col = "blue",
       lwd = lw,
       cex.axis = sz, cex.main = sz, cex.lab = sz, ...)
  lines(x, y2,
        type = "o", col = "red", lwd = lw)
  legend(lpos, legend = legtext,
         col = c("blue", "red"),
         pch = c(1,1), lty = c(1,1),
         cex = 1.2)
}

# ------------------------------------------------------------------
#' Majority Raster
#'
#' Calculate which grid cells are mostly each kind of LC cover
#' @param thres threshold for determining whether a pixel is mostly that land cover
#' @param cv raster stack with land cover fraction data
#' @export
#' @examples CVmaj <- majority_raster(cv_clip, 0.9)
majority_raster <- function(cv, thres)
{
  CVmaj <- cv[[1]]
  CVmaj[!is.na(CVmaj)] <- 0
  nclass <- nlayers(cv)
  for (classnum in 1:nclass)
  {
    maj.ind <- which(values(cv[[classnum]]) > thres)
    CVmaj[maj.ind] <- classnum
  }
  names(CVmaj) <- "cv"
  return(CVmaj)
}

# ------------------------------------------------------------------
#' Invert raster
#'
#' Swaps the zero and one values in a mask
#' @param r input raster
#' @export
invert_raster <- function(r)
{
  # Swaps the 0 and 1 values
  r1 <- r
  r1[r==1] <- NA
  r1[r==0] <- 1
  r1[is.na(r1)] <- 0
  return(r1)
}
