# mari webb and jack tarricone
# download 1 WY of gridmet data (tmin)
# resample to 1km SNODAS resolution
# save as .h5

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
library(rhdf5)

# create list of years
years <-as.list(seq(2003,2019,1))
test_year <-years[[1]]

# define funtcion
gridmet_to_h5 <-function(year){

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

# create water year variable for endDate
wy <-year + 1

# var <- c("prcp", "tmin") # single variable for testing code
param <- 'tmin' 
start <- paste0(tyear,"-10-01") # shorter date period for testing code
end <- paste0(wy,"-09-30")

# read in 1 water year of tmin data
system.time(
  climate_data <-getGridMET(AOI, param = param, startDate = start, endDate = end)
)

# convert from list of raster to SpatRaster
system.time(climate_data <-rast(climate_data$gridmet_tmin)) # change this for each of the four variables
climate_data

###############################################################
## read in 1 day of SNODAS data to resample the climate data
###############################################################

snodas_for_resample <-rast("/Volumes/jack_t/nres_project/test_tiffs/snodas_for_resample.tif")

# resample climate variables which are at 4km down to 1km
system.time(climate_resamp <-resample(climate_data, snodas_for_resample, method = "bilinear"))

# convert to array for saving as .h5
system.time(climate_array <-array(climate_resamp, 
                      dim=c(nrow = nrow(climate_resamp), 
                      ncol = ncol(climate_resamp),
                      nlyr = nlyr(climate_resamp))))

rm(climate_resamp) # remove old iterations
rm(climate_data)

#####################################
# save resampled array as hdf5 file #
#####################################
# setwd , change for function
setwd(file.path("/Volumes","jack_t","nres_project","gridmet_data","tmin")) 

# create file name with year
hdf_file_name <-paste0("tmin_daily_wy_",wy,".h5")

h5createFile(hdf_file_name) # create empty .h5 file

# create data set with proper info, set "chunk"
# level is compression amount 0 - 9, 9 is most compressed but slowest to read in
h5createDataset(file = hdf_file_name, dataset = "tmin",
                dims = c(3351, 2488, dim(climate_array)[[3]]), 
                level = 1, 
                chunk = c(3351, 2488, dim(climate_array)[[3]]),
                storage.mode = "double")

# view the structure of the h5 created
h5ls(hdf_file_name)

# write data the the hdf5 file we made
system.time(h5write(climate_array, hdf_file_name,"tmin"))

rm(climate_array) # remove looping through multiple years
}






