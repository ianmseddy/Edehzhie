library(terra)
library(reproducible)
# census2 <- reproducible::prepInputs(url = paste0("https://www12.statcan.gc.ca/census-recensement/",
#                                    "2021/geo/sip-pis/boundary-limites/files-fichiers/lcd_000b21a_e.zip"),
#                       destinationPath = "inputs")
# census2 <- census2[census2$DGUID == "2021A00036105",]
# census2 <- terra::vect(census2)
# census2 <- terra::project(census2, "epsg:25831")
# 



temp <- reproducible::prepInputs(url = "https://drive.google.com/file/d/1pfocYITTbvJXh8llQSGlvBvxzpERVeGM/view?usp=drive_link", 
                                 destinationPath = "inputs/",
                                 targetFile = "CMDsm_2001-2020.tif",
                                 fun = "terra::rast")
rtm <- temp[[1]]
writeRaster(rtm, "inputs/rasterToMatch.tif")
studyArea <-  postProcess(census2, projectTo = rtm)
terra::writeVector(studyArea, "inputs/Edehzhie.shp", overwrite = TRUE)


firePerimeters <- prepInputsFireYear(
  destinationPath =  "~/data/LandR",
  studyArea = studyArea,
  rasterToMatch = rtm,
  overwrite = TRUE,
  url = "https://cwfis.cfs.nrcan.gc.ca/downloads/nfdb/fire_poly/current_version/NFDB_poly.zip",
  fireField = "YEAR"
)

writeRaster(firePerimeters, "inputs/firePerimeters.tif")

firePolys <- fireSenseUtils::getFirePolygons(
  fun = "terra::vect",
  years = 1987:2021,
  cropTo = studyArea,
  maskTo = studyArea,
  projectTo = studyArea,
  destinationPath = "~/data/LandR")

