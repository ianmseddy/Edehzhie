makeEdehzhieSAandRTM <- function(){
  census2 <- Cache(reproducible::prepInputs, 
                   url = paste0("https://www12.statcan.gc.ca/census-recensement/",
                                "2021/geo/sip-pis/boundary-limites/files-fichiers/lcd_000b21a_e.zip"),
                   destinationPath = checkPath("inputs", create = TRUE), 
                                      fun = "terra::vect")
  census2 <- census2[census2$DGUID == "2021A00036105",]
  census2 <- terra::project(census2, "epsg:25831")
  rasterToMatch <- Cache(LandR::prepInputsLCC, 
                         year = 2005, 
                         destinationPath = checkPath("inputs", create = TRUE), 
                         filename2 = NULL,
                         studyArea = census2, 
                         userTags = c("prepInputsLCC", "rasterToMatch"))
  census2 <- terra::project(census2, rasterToMatch)
  

  return(list(
    studyArea = census2, 
    rasterToMatch = rasterToMatch
  ))
}


makeEdehzhieSppEquiv <- function(){
speciesOfConcern <- c("Pice_mar", "Pice_gla", "Pinu_ban", "Lari_lar", "Popu_tre", "Popu_bal", "Betu_pap")
sppEquiv <- LandR::sppEquivalencies_CA[LandR %in% speciesOfConcern]
sppEquiv$simName <- c("birch", "tamarack", "white spruce", "black spruce", "jack pine",
                      "poplar", "poplar", "poplar", "poplar", "poplar")

sppEquiv$madeupFuel <- c("PBWT", "PBWT", "PBWT", "Bl", "Ja",
                         "PBWT", "PBWT", "PBWT", "PBWT", "PBWT")
return(sppEquiv)
}


#TODO: confirm no longer necesssary with bugFix to BBDP and changes to canClimateData
# firePerimeters <- LandR::prepInputsFireYear(
#   destinationPath =  "~/data/LandR",
#   studyArea = studyArea,
#   rasterToMatch = rtm,
#   overwrite = TRUE,
#   url = "https://cwfis.cfs.nrcan.gc.ca/downloads/nfdb/fire_poly/current_version/NFDB_poly.zip",
#   fireField = "YEAR"
# )
# 
# terra::writeRaster(firePerimeters, "inputs/firePerimeters.tif")


# CMDsm <- reproducible::prepInputs(url = "https://drive.google.com/file/d/1pfocYITTbvJXh8llQSGlvBvxzpERVeGM/view?usp=drive_link",
#                                  destinationPath = "inputs/",
#                                  targetFile = "CMDsm_2001-2020.tif",
#                                  fun = "terra::rast")
