getOrUpdatePkg <- function(p, minVer, repo) {
  if (!isFALSE(try(packageVersion(p) < minVer, silent = TRUE) )) {
    if (missing(repo)) repo = c("predictiveecology.r-universe.dev", getOption("repos"))
    install.packages(p, repos = repo)
  }
}

getOrUpdatePkg("Require", "0.3.1.9015")
#TODO: fix this when reproducible works 
getOrUpdatePkg("SpaDES.project", "0.0.8.9028")
getOrUpdatePkg("SpaDES.core", "2.0.3.9007")

.fast <- FALSE
################### setwd to location where project should be located
if (SpaDES.project::user("emcintir")) {
  setwd("~/GitHub")
  
  # This will set several options that make SpaDES.core run faster;
  # don't use yet unless you are aware of the things that are being set
  .fast <- TRUE
}
################ SPADES CALL
speciesOfConcern <- c("Pice_mar", "Pice_gla", "Pinu_ban", "Lari_lar", "Popu_tre", "Popu_bal", "Betu_pap")
sppEquiv <- LandR::sppEquivalencies_CA[LandR %in% speciesOfConcern]
sppEquiv$simName <- c("birch", "tamarack", "white spruce", "black spruce", "jack pine", 
                      "poplar", "poplar", "poplar", "poplar", "poplar")

sppEquiv$madeupFuel <- c("PBWT", "PBWT", "PBWT", "Bl", "Ja", 
                         "PBWT", "PBWT", "PBWT", "PBWT", "PBWT")

library(SpaDES.project)
out <- SpaDES.project::setupProject(
  runName = "Edehzhie",
  updateRprofile = TRUE,
  Restart = FALSE,
  paths = list(projectPath = runName,
               scratchPath = "~/scratch"),
  modules = c("PredictiveEcology/fireSense_dataPrepFit@biomassFuel",
              "PredictiveEcology/fireSense_IgnitionFit@biomassFuel",
              # "PredictiveEcology/fireSense_dataPrepPredict@pendingClimateData",
    file.path("PredictiveEcology",
               # c("canClimateData@usePrepInputs"),
              paste0(# development
                c("Biomass_borealDataPrep",
                  # "Biomass_core",
                  "Biomass_speciesData",
                  # "Biomass_speciesFactorial",
                  # "Biomass_speciesParameters",
                  "fireSense_EscapeFit"),
                  # "fireSense_SpreadFit"),
                  # "fireSense_dataPrepFit"),
                  # "fireSense_dataPrepPredict",
                  # "fireSense_IgnitionPredict",
                  # "fireSense_EscapePredict"),
                # "fireSense_SpreadPredict"),
                "@development")
              )),
  options = list(spades.allowInitDuringSimInit = TRUE,
                 spades.allowSequentialCaching = FALSE,
                 reproducible.showSimilar = FALSE,
                 reproducible.useCache = TRUE,
                 reproducible.useMemoise = FALSE,
                 reproducible.memoisePersist = FALSE,
                 reproducible.inputPaths = if (user("ieddy")) "../../data/LandR" else "~/data",
                 LandR.assertions = FALSE,
                 reproducible.shapefileRead = "terra::vect", #required if gadm is down as terra:projct won't work on sf
                 reproducible.gdalwarp = TRUE,
                 reproducible.showSimilarDepth = 7,
                 gargle_oauth_cache = if (machine("W-VIC-A127585")) "~/.secret" else NULL,
                 gargle_oauth_email =
                   if (user("emcintir")) {
                     "eliotmcintire@gmail.com" 
                   } else if (user("tmichele")) {
                     "tati.micheletti@gmail.com"
                   } else if (user("ieddy")) {
                     "ianmseddy@gmail.com"
                   } else NULL,
                 SpaDES.project.fast = isTRUE(.fast),
                 spades.recoveryMode = 1
                 # reproducible.useGdown = TRUE
  ),
  times = list(start = 2011, end = 2025),
  params = list(
    fireSense_SpreadFit = list(cores = NA, cacheID_DE = "previous", trace = 1,
                               mode = "fit", SNLL_FS_thresh = 9000),
    fireSense_IgnitionFit = list(.useCache = c("run"), 
                                 rescalers = c("MDC" = 100)),
    fireSense_dataPrepFit = list("ignitionFuelClassCol" = "madeupFuel",  
                                 "spreadFuelClassCol" = "madeupFuel", 
                                 ".studyAreaName" = "Edehzhie", 
                                 "igAggFactor" = 32),
    .globals = list(.plots = NA,
                    .plotInitialTime = NA,
                    .studyAreaName = "Edehzhie",
                    sppEquivCol = 'simName',
                    cores = 12)
    ),
  objects = list(studyArea = terra::vect("inputs/Edehzhie.shp"), 
                 studyAreaLarge = terra::vect("inputs/Edehzhie.shp"),
                 historicalClimateRasters = list("CMDsm" = terra::rast("inputs/CMDsm_2001-2020.tif")),
                 rasterToMatch = terra::rast("inputs/rasterToMatch.tif"),
                 rasterToMatchLarge = terra::rast("inputs/rasterToMatch.tif"),
                 sppEquiv = sppEquiv, 
                 climateVariablesForFire = list("spread" = c("CMDsm"), 
                                                "ignition" = c("CMDsm"))
                 ),
  require = c("reproducible", "SpaDES.core", "PredictiveEcology/LandR@development (>= 1.1.0.9073"),
  packages = c("googledrive", 'RCurl', 'XML',
               "PredictiveEcology/fireSenseUtils@biomassFuel",
               "PredictiveEcology/SpaDES.core@sequentialCaching (HEAD)",
               "PredictiveEcology/reproducible@modsForLargeArchives (HEAD)"),
  useGit = "sub"
)

outSim <- do.call(SpaDES.core::simInitAndSpades, out)
