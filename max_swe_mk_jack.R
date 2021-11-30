# snodas max swe mk test


# november 30th 2021
# jack tarricone

library(raster)
library(rgdal)
library(parallel)
library(spatialEco)
library(EnvStats)
library(Kendall)
library(snow)


# read in max_swe snodas rasster
setwd("/Users/jacktarricone/Desktop/max_swe")
list <-list.files()
max_list <-lapply(list, function(x) raster(x))
max_stack <-stack(max_list) 
plot(max_stack[[9]])
max_stack


###### mk test with just pval and slope estimate

# updated trend.slope function from the spatialEco::raster.kendall 
# updated Envstats:kendallTrendTest function to ci.slope = FALSE to hopefully suppress error

trend.slope2 <- function(y, tau.pass = FALSE, p.value.pass = TRUE,  
                        confidence.pass = FALSE, z.value.pass = FALSE,
                        intercept.pass = FALSE) {
  fit <- suppressWarnings( EnvStats::kendallTrendTest(y ~ 1, ci.slope = FALSE) ) # important, error before this
  fit.results <- fit$estimate[2]
  if(p.value.pass == TRUE) { fit.results <- c(fit.results, fit$p.value) } 
  if(z.value.pass == TRUE) { fit.results <- c(fit.results, fit$statistic) } 
  if(confidence.pass == TRUE) { 
    ci <- unlist(fit$interval["limits"])
    if( length(ci) == 2) { 
      fit.results <- c(fit.results, ci)
    } else {
      fit.results <- c(fit.results, c(NA,NA))
    }			  
  }
  if(intercept.pass == TRUE) { fit.results <- c(fit.results, fit$estimate[3]) }  
  if(tau.pass == TRUE) { fit.results <- c(fit.results, fit$estimate[1]) }  
  return( fit.results )
}


# run it in parallel using snow and parallel 

beginCluster(n=12) # number of cores you want, never use them all!

system.time(max_trends_full <- raster::clusterR(max_stack, overlay, args=list(fun=trend.slope2)))

endCluster()



###########################
##### raster creation #####
##########################


# pull out the data
p_value <-max_trends_full[[2]]
slope <-max_trends_full[[1]]

# test plot
plot(p_value) # p_val
plot(slope) # trend

# create raster for just significant p-values
sig_pval <-p_value
values(sig_pval)[values(sig_pval) > 0.05] = NA
plot(sig_pval)

# mask slope raster with sig p-values
sig_slope <-mask(slope, sig_pval)
plot(sig_slope)

# save
writeRaster(sig_pval, "/Volumes/JT/2021_1_fall_UNR/eco_r/mk_results/max_swe_sig_pval.tif")
writeRaster(p_value,"/Volumes/JT/2021_1_fall_UNR/eco_r/mk_results/max_swe_p_value.tif")
writeRaster(sig_slope, "/Volumes/JT/2021_1_fall_UNR/eco_r/mk_results/max_swe_sig_slope.tif")
writeRaster(slope, "/Volumes/JT/2021_1_fall_UNR/eco_r/mk_results/max_swe_slope.tif")
