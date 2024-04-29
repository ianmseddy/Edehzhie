
getOrUpdatePkg <- function(p, minVer, repo) {
  if (!isFALSE(try(packageVersion(p) < minVer, silent = TRUE) )) {
    if (missing(repo)) repo = c("predictiveecology.r-universe.dev", getOption("repos"))
    install.packages(p, repos = repo)
  }
}

getOrUpdatePkg("Require", "0.3.1.9067")
#TODO: fix this when reproducible works 
getOrUpdatePkg("SpaDES.project", "0.0.8.9047")
getOrUpdatePkg("SpaDES.core", "2.0.5")

.fast <- FALSE
################### setwd to location where project should be located
if (SpaDES.project::user("emcintir")) {
  setwd("~/GitHub")
  
  # This will set several options that make SpaDES.core run faster;
  # don't use yet unless you are aware of the things that are being set #duly noted
  .fast <- TRUE
}

out <- SpaDES.project::setupProject(
  runName = "Edehzhie",
  updateRprofile = TRUE,
  Restart = FALSE,
  paths = list(projectPath = runName,
               scratchPath = "~/scratch"),
  modules = c("PredictiveEcology/fireSense_dataPrepFit@lccFix", #for 2 lcc and flammableRTMs
              "PredictiveEcology/Biomass_borealDataPrep@lccFix", #for lcc mapped to dataYear
              "PredictiveEcology/Biomass_speciesData@development", #development okay
              "PredictiveEcology/fireSense_SpreadFit@lccFix", 
              # "PredictiveEcology/fireSense_ignitionFit@biomassFuel", #when necesssary
              #flammableRTM is not needed (and causes error) as RTM sufficient,
              "PredictiveEcology/canClimateData@newClimate" #temporary while climateData tested 
  ),
  options = list(spades.allowInitDuringSimInit = TRUE,
                 spades.allowSequentialCaching = FALSE, #changed this 
                 reproducible.showSimilar = FALSE,
                 reproducible.useCache = TRUE,
                 reproducible.useMemoise = FALSE,
                 reproducible.memoisePersist = FALSE,
                 LandR.assertions = FALSE,
                 reproducible.shapefileRead = "terra::vect", #required if gadm is down as terra:projct won't work on sf
                 reproducible.gdalwarp = TRUE, #this will be temporarily turned off by prepInputs_NTEMS_FAO (to avoid crash)
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
                 # parallelly.availableCores.custom = function(){return(32)} 
  ),
  times = list(start = 2011, end = 2012),
  params = list(
    fireSense_SpreadFit = list(
      cores = pemisc::makeIpsForNetworkCluster(
        ipStart = "10.20.0",
        ipEnd = c(97, 189, 220, 184, 106),
        availableCores = c(28, 28, 28, 14, 14),
        availableRAM = c(500, 500, 500, 250, 250),
        localHostEndIp = 97,
        proc = "cores",
        #nProcess is determined by the number of params - given below
        #logistic1", "logistic2", "logistic3",  "youngAge", "CMD_sm", "NFhigh", "NFlow", "Bl", "Ja", "PBTWT"
        nProcess = 10, 
        internalProcesses = 10,
        sizeGbEachProcess = 1),
      trace = 1, #cacheID_DE = "previous", Not a param?
      mode = "debug", SNLL_FS_thresh = 3050, 
      doObjFunAssertions = FALSE),
    Biomass_borealDataPrep = list("overrideAgeInFires" = FALSE, #has bugs
                                  "overrideBiomassInFires" = FALSE), #has bugs
    fireSense_IgnitionFit = list(.useCache = c("run"), 
                                 rescalers = c("CMD_sm" = 100)),
    fireSense_dataPrepFit = list("ignitionFuelClassCol" = "madeupFuel",  
                                 "spreadFuelClassCol" = "madeupFuel", 
                                 ".studyAreaName" = "Edehzhie", 
                                 "whichModulesToPrepare" = "fireSense_SpreadFit",
                                 "igAggFactor" = 32),
    .globals = list(.plots = NA,
                    .plotInitialTime = NA,
                    .studyAreaName = "Edehzhie",
                    dataYear = 2011,
                    sppEquivCol = 'simName')
  ),
  require = c("reproducible", "SpaDES.core", "PredictiveEcology/LandR@lccFix"), #lccFix merged in
  packages = c("googledrive", "RCurl", "XML"),
  useGit = "sub",
  #custom functions and objects
  functions = "ianmseddy/Edehzhie@main/R/setupFuns.R",
  studyArea = makeEdehzhieSAandRTM()$studyArea, 
  studyAreaLarge = makeEdehzhieSAandRTM()$studyArea, #TODO:unnecessary if Biomass_speciesData allows SA now..
  rasterToMatch = makeEdehzhieSAandRTM()$rasterToMatch,
  rasterToMatchLarge = makeEdehzhieSAandRTM()$rasterToMatch,#TODO:unnecessary if Biomass_speciesData allows RTM now..
  climateVariablesForFire = list("spread" = c("CMD_sm"), 
                                 "ignition" = c("CMD_sm")),
  sppEquiv = makeEdehzhieSppEquiv()
)

out$climateVariables <- list(
  historical_CMD_sm = list(
    vars = "historical_CMD_sm",
    fun = quote(calcAsIs),
    .dots = list(historical_years = 1991:2022)
  ),
  projected_CMD_sm = list(
    vars = "future_CMD_sm",
    fun = quote(calcAsIs),
    .dots = list(projected_years = 2011:2100)
  )
)
# pkgload::load_all("../LandR") 
#document the NTEMS functions and then push
inSim <- do.call(SpaDES.core::simInitAndSpades, out)

