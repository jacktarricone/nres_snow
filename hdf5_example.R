# example of working with hdf data

# oct 7th 2020
# start of pixel wise sens slop analysis 
# need to firgure out the  best way to cut full year vertical columns out for anlaysis and stich them back

library(BiocManager)
library(rhdf5)
library(tidyverse)
library(rgeos)
library(raster)
library(rgdal)
library(parallel)
library(data.table)
library(gtools)



# oct 12
# keeping data in a matrix instead of raster for processing
# this way we can avoid geolocation issues

tempdir <- function() { "/Volumes/jt/projects/margulis/temp" }
tempdir()

#set path and file name for hdf5 SWE file
hdf_path <- "/Volumes/jt/projects/margulis/swe/hdf/" #create path
path <-file.path( hdf_path , hdf_name ) 
h5closeAll()
h5readAttributes(hdf_file, name = "swe") #$units = mm


max_raster <- function( hdf_name ) {
  
  path <-file.path( hdf_path , hdf_name ) 
  
  c1 <-h5read(path, "/swe", index = list(,,)) #load in 
  c1[ c1[] == -32768 ] <- NA #remove NA
  max_c1 <-as.matrix(apply(c1, c(1,2), max)) #create matrix with max value on z axis
  
  #bind chunks together
  rast <-raster(full_max, xmn=-123.3, xmx=-117.6, ymn=35.4, ymx=42, CRS("+proj=leac +ellps=clrk66"))
  plot(rast)
  hist(rast)
  
  name <- gsub(".h5", "", hdf_name)
  good_name <- gsub("SN_SWE_", "max_swe_", name)
  
  setwd("/Volumes/jt/projects/margulis/max_rasters/")
  writeRaster(rast, paste0(good_name, ".tif"))
  return(rast)
}


#### apply to hdf list

setwd("/Volumes/jt/projects/margulis/swe/hdf")
files <- list.files(pattern = ".h5")
hdf_list <-mixedsort(sort(files)) #sort in correct order
print(hdf_list)

system.time(raster_list <-lapply(hdf_list, function(x) max_raster(x)))

