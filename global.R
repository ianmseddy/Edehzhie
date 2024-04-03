
getOrUpdatePkg <- function(p, minVer, repo) {
  if (!isFALSE(try(packageVersion(p) < minVer, silent = TRUE) )) {
    if (missing(repo)) repo = c("predictiveecology.r-universe.dev", getOption("repos"))
    install.packages(p, repos = repo)
  }
}

getOrUpdatePkg("Require", "0.3.1.9042")
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
# speciesOfConcern <- c("Pice_mar", "Pice_gla", "Pinu_ban", "Lari_lar", "Popu_tre", "Popu_bal", "Betu_pap")
# sppEquiv <- LandR::sppEquivalencies_CA[LandR %in% speciesOfConcern]
# sppEquiv$simName <- c("birch", "tamarack", "white spruce", "black spruce", "jack pine", 
#                       "poplar", "poplar", "poplar", "poplar", "poplar")
# 
# sppEquiv$madeupFuel <- c("PBWT", "PBWT", "PBWT", "Bl", "Ja", 
#                          "PBWT", "PBWT", "PBWT", "PBWT", "PBWT")
# fwrite(sppEquiv, "inputs/sppEquiv.csv")

nParams <- length(c("logistic1", "logistic2", "logistic3", 
                    "youngAge", "CMDsm", "NFhigh", "NFlow", "Bl", "Ja", "PBTWT"))
cores <-  if (peutils::user("ieddy")) {
  localHostEndIp <- 97
  pemisc::makeIpsForNetworkCluster(ipStart = "10.20.0",
                                   ipEnd = c(97, 189, 220, 184, 106),
                                   availableCores = c(28, 28, 28, 14, 14),
                                   availableRAM = c(500, 500, 500, 250, 250),
                                   localHostEndIp = localHostEndIp,
                                   proc = "cores",
                                   nProcess = nParams,
                                   internalProcesses = 10,
                                   sizeGbEachProcess = 1)
}

library(SpaDES.project)
out <- SpaDES.project::setupProject(
  runName = "Edehzhie",
  updateRprofile = TRUE,
  Restart = FALSE,
  paths = list(projectPath = runName,
               scratchPath = "~/scratch"),
  modules = c("PredictiveEcology/fireSense_dataPrepFit@lccFix",
              "PredictiveEcology/Biomass_borealDataPrep@lccFix",
              "PredictiveEcology/Biomass_speciesData@development",
              "PredictiveEcology/fireSense_SpreadFit@lccFix"
              ),
  options = list(spades.allowInitDuringSimInit = TRUE,
                 spades.allowSequentialCaching = FALSE, #changed this 
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
    fireSense_SpreadFit = list(cores = cores, cacheID_DE = "previous", trace = 1,
                               mode = "fit", SNLL_FS_thresh = 3050),
    fireSense_IgnitionFit = list(.useCache = c("run"), 
                                 rescalers = c("CMDsm" = 100)),
    fireSense_dataPrepFit = list("ignitionFuelClassCol" = "madeupFuel",  
                                 "spreadFuelClassCol" = "madeupFuel", 
                                 ".studyAreaName" = "Edehzhie", 
                                 "whichModulesToPrepare" = "fireSense_SpreadFit",
                                 "igAggFactor" = 32),
    Biomass_borealDataPrep = list(overrideAgeInFires = FALSE,
                                  overrideBiomassInFires = FALSE),
    .globals = list(.plots = NA,
                    .plotInitialTime = NA,
                    .studyAreaName = "Edehzhie",
                    dataYear = 2011,
                    sppEquivCol = 'simName')
  ),
  objects = list(studyArea = terra::vect("inputs/Edehzhie.shp"), 
                 studyAreaLarge = terra::vect("inputs/Edehzhie.shp"),
                 historicalClimateRasters = list("CMDsm" = terra::rast("inputs/CMDsm_2001-2020.tif")),
                 rasterToMatch = terra::rast("inputs/rasterToMatch.tif"),
                 rasterToMatchLarge = terra::rast("inputs/rasterToMatch.tif"),
                 firePerimeters = terra::rast("inputs/firePerimeters.tif"),
                 sppEquiv = data.table::fread("inputs/sppEquiv.csv"), 
                 climateVariablesForFire = list("spread" = c("CMDsm"), 
                                                "ignition" = c("CMDsm"))
                 ),
  require = c("reproducible", "SpaDES.core"),
  packages = c("googledrive", "RCurl", "XML"),
  useGit = "sub"
)

#document the NTEMS functions and then push
#because of browser()
options("reproducible.useCache" = TRUE)
inSim <- SpaDES.core::simInitAndSpades(objects = out$objects, params = out$params, 
                                       modules = out$modules, times = out$times, 
                                       paths = out$paths, debug = TRUE)



####
# fsInit <- simInit(objects = out$objects, params = out$params, modules = out$modules, 
#                 times = out$times, paths = out$paths)
# fsOut <- spades(fsInit)
