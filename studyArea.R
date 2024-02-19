library(terra)
library(reproducible)
# census2 <- reproducible::prepInputs(url = paste0("https://www12.statcan.gc.ca/census-recensement/",
#                                    "2021/geo/sip-pis/boundary-limites/files-fichiers/lcd_000b21a_e.zip"),
#                       destinationPath = "inputs")
# census2 <- census2[census2$DGUID == "2021A00036105",]
# census2 <- terra::vect(census2)
# census2 <- terra::project(census2, "epsg:25831")
# 
# terra::writeVector(census2, "inputs/Edehzhie.shp", overwrite =TRUE)

temp <- reproducible::prepInputs(url = "https://drive.google.com/file/d/1pfocYITTbvJXh8llQSGlvBvxzpERVeGM/view?usp=drive_link", 
                                 destinationPath = "inputs/",
                                 targetFile = "CMDsm_2001-2020.tif",
                                 fun = "terra::rast")
rtm <- temp[[1]]
writeRaster(rtm, "inputs/rasterToMatch.tif")
