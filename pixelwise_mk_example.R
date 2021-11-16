# example of implimenting a Mann-Kendall analysis on spatial data

# max mk test 
# nov 24 2020

library(raster)
library(rgdal)
library(parallel)
library(data.table)
library(gtools)
library(spatialEco)
library(EnvStats)
library(Kendall)
library(remotes)




# read in stack of annual metric (max, scf, etc.)
setwd("/Volumes/jt/projects/margulis/snow_metric_rasters/max_swe/rasters")
list <-list.files()
max_list <-lapply(list, function(x) raster(x))

# using raster not terra
max_stack <-stack(max_list) 

# test mk code by first running it on .5 degrees lat near tahoe
#tahoe_crop <-crop(scf_stack, extent(-123.3, -117.6, 39, 39.5))
#tahoe_crop
#plot(tahoe_crop[[9]])

###### mk test, trend.slope is full stats, 2 is just p-val and slope stats
trend.slope <- function(y, p.value.pass = TRUE, z.pass = TRUE, 
                        tau.pass = TRUE, confidence.pass = TRUE, intercept.pass = TRUE) {
  options(warn = -1)
  fit <- EnvStats::kendallTrendTest(y ~ 1)
  fit.results <- fit$estimate[2]
  if (tau.pass == TRUE) {
    fit.results <- c(fit.results, fit$estimate[1])
  }
  if (intercept.pass == TRUE) {
    fit.results <- c(fit.results, fit$estimate[3])
  }
  if (p.value.pass == TRUE) {
    fit.results <- c(fit.results, fit$p.value)
  }
  if (z.pass == TRUE) {
    fit.results <- c(fit.results, fit$statistic)
  }
  if (confidence.pass == TRUE) {
    ci <- unlist(fit$interval["limits"])
    if (length(ci) == 2) {
      fit.results <- c(fit.results, ci)
    }
    else {
      fit.results <- c(fit.results, c(NA, NA))
    }
  }
  options(warn = 0)
  return(fit.results)
}

trend.slope2 <- function(y, p.value.pass = TRUE, z.pass = FALSE, 
                         tau.pass = FALSE, confidence.pass = FALSE, intercept.pass = FALSE) {
  options(warn = -1)
  fit <- EnvStats::kendallTrendTest(y ~ 1)
  fit.results <- fit$estimate[2]
  if (tau.pass == TRUE) {
    fit.results <- c(fit.results, fit$estimate[1])
  }
  if (intercept.pass == TRUE) {
    fit.results <- c(fit.results, fit$estimate[3])
  }
  if (p.value.pass == TRUE) {
    fit.results <- c(fit.results, fit$p.value)
  }
  if (z.pass == TRUE) {
    fit.results <- c(fit.results, fit$statistic)
  }
  if (confidence.pass == TRUE) {
    ci <- unlist(fit$interval["limits"])
    if (length(ci) == 2) {
      fit.results <- c(fit.results, ci)
    }
    else {
      fit.results <- c(fit.results, c(NA, NA))
    }
  }
  options(warn = 0)
  return(fit.results)
}


# run it in parallel to see if stripping is gone 
beginCluster(n=7) # n = number of cores

system.time(max_trends_full <- clusterR(max_stack, overlay, args=list(fun=trend.slope2)))

endCluster()

# check
plot(max_trends_full[[1]])
plot(max_trends_full[[2]])

max_p_value_full <-max_trends_full[[2]] # define
max_slope_full <-max_trends_full[[1]]
writeRaster(max_p_value_full,"/Volumes/jt/projects/margulis/snow_metric_rasters/max_swe/mk_results/max_p_value_full.tif")
writeRaster(max_slope_full, "/Volumes/jt/projects/margulis/snow_metric_rasters/max_swe/mk_results/max_slope_full.tif")
