census2 <- reproducible::prepInputs(url = paste0("https://www12.statcan.gc.ca/census-recensement/",
                                   "2021/geo/sip-pis/boundary-limites/files-fichiers/lcd_000b21a_e.zip"),
                      destinationPath = "inputs")
census2 <- census2[census2$DGUID == "2021A00036105",]
census2 <- terra::vect(census2)
census2 <- terra::project(census2, "epsg:25831")

terra::writeVector(census2, "inputs/Edehzhie.shp", overwrite =TRUE)
