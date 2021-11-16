## GRIDMET Download
## Mariana Webb
## NRES 746
## Fall 2021


# Load Libraries ----------------------------------------------------------

# remotes::install_github("mikejohnson51/AOI") # suggested!
# remotes::install_github("mikejohnson51/climateR")

library(terra)
library(AOI)
library(climateR)
library(sf)
library(sp)

# Download Clim Data -------------------------------------------------------

# Selecting Western states as our area of interest
states <- c("Arizona", "California", "Colorado", "Idaho", "Montana", "Nevada",
            "New Mexico", "Oregon", "Utah", "Washington", "Wyoming")
AOI <- aoi_get(state = states)
plot(AOI$geometry)

# Select climate variables of interest. 
#        Options: 'prcp', 'rhmax', 'rhmin', 'shum', 'srad', 'wind_dir',
#        'tmin', 'tmax', 'wind_vel', 'burn_index', 'fmoist_100', 'fmoist_1000',
#        'energy_release', 'palmer', 'pet_alfalfa', 'pet_grass', 'vpd'

# var <- c("prcp", "tmin") #single variable for testing code
param <- c('prcp', 'tmin', 'tmax', 'palmer')
start <- "2018-10-01" #shorter date period for testing code
# start <- "2003-10-01"
end <- "2019-09-30"

test <-getGridMET(AOI, param = 'prcp', startDate = "2018-12-01", endDate = "2018-12-10")
test

system.time(
  var <-getGridMET(AOI, param = 'prcp', startDate = start, endDate = end)
)

var <-as.array(var$gridmet_prcp)
image(var[,,1])
var

# setwd , change for function
setwd(file.path("/Volumes","jack_t","nres_project","gridmet_data","precip")) 

# create file name with year
hdf_file_name <-paste0("swe_daily_",year,".h5")

h5createFile(hdf_file_name) # create empty .h5 file

# create data set with proper info, set "chunk"
# level is compression amount 0 - 9, 9 is most compressed but slowest to read in
h5createDataset(file = hdf_file_name, dataset = "swe",
                dims = c(nlines, nsamps, length(dat_files)), level = 5, chunk = c(nlines, nsamps, length(dat_files)),
                storage.mode = "double")

# view the structure of the h5 created
h5ls(hdf_file_name)

# write data the the hdf5 file we made
h5write(swe_array, hdf_file_name,"swe")
rm(swe_array)




system.time(array <-array(as.numeric(unlist(precip$gridmet_prcp)), dim=c(nlines, nsamps, length(mat_list))))
rm(mat_list)

plot(r[[40]])
plot(AOI, alpha = .01, add = TRUE)

# ?plot
# 
# rasterVis::levelplot(r, par.settings = BuRdTheme, names.attr = names(p)) +
#   layer(sp.lines(as_Spatial(AOI), col="gray30", lwd=3))
# 
# ?layer

# Plot --------------------------------------------------------------------

#Test plot of a single day of min temp.
rasterVis::levelplot(gridmetData$gridmet_tmin$X2019.10.02)


# Save as Raster File -----------------------------------------------------

vars <- names(gridmetData)

# Set custom save location
saveLocation <- 'Documents/Nevada/Fall2021/NRES746/' ##UPDATE THIS

for(v in vars) {
  filepath <- paste0(saveLocation, v, '.grd')
  writeRaster(gridmetData[[v]], filename=filepath, overwrite=TRUE, progress = 'window')
}

# readIn <- stack('Documents/Nevada/Fall 2021/NRES746/gridmet_prcp.grd') #checking to make sure saved netCDF can be read back in, has data
# rasterVis::levelplot(readIn$X2019.10.02) 
