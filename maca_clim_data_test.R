library(terra)
library(rgdal)

tmax_monthly <-rast("/Users/jacktarricone/nres_proj_data/maca_data/macav2livneh_tasmax_CCSM4_r6i1p1_historical_1990_2005_CONUS_monthly.nc")
tmax_monthly
plot(tmax_monthly)

# pull out first month
test <-tmax_monthly[[1]]
plot(test) 
test_crop <- crop(test, ext(-120, -117, 35, 39)) # crop to sierras
plot(test_crop)


full_crop <- crop(tmax_monthly, ext(-120, -117, 35, 39)) # crop to sierras

cuts=c(270,320) #set breaks
pal <- colorRampPalette(c("red", "white", "blue"))

plot(full_crop[[1:6]], breaks=s, col = pal(7)) #plot with defined breaks

rng <- range(270:320)
arg <- list(at=rng, labels=round(rng, 4))
plot(full_crop[[1:6]], col=gray(seq(0,1,length=50)), axis.args=arg)


     