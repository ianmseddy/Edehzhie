library(fireSenseUtils)
library(data.table)
library(terra)
####exploratory###

studyArea <- terra::vect("inputs/Edehzhie.shp")
months <- c(paste0("0", 4:9))

MDC <- rast("cache/cacheOutputs/MDC_historical_NT_83e4a2f93881e577.tif")
fires <- fireSenseUtils::getFirePolygons(years = 1991:2022, studyArea = studyArea,
                                         destinationPath = "C:/Ian/data/LandR")

makeSeasonal <- function(variable, months, years, rtm) {
  
  monthsAndYears <- list.files("inputs/climate/historic/Northwest Territories & Nunavut/",
                               pattern = paste0(variable, "[0][",months,"]"), 
                               recursive = TRUE, full.names = TRUE)
  
  asYears <- lapply(paste0("Year_", years), function(x){
    annual <- monthsAndYears[grep(monthsAndYears, pattern = x)]
  })
  
  asRas <- lapply(asYears, FUN = function(x){
    rasStack <- lapply(x, terra::rast)
    out <- terra::rast(rasStack) |>
      terra::mean() |>
      terra::project(, y = rtm)
  })
  names(asRas) <- paste0(variable, years)
  return(asRas)
}


CMDsp <- makeSeasonal(variable = "CMD", months = "3-5", years = 1991:2022, rtm = MDC)
names(CMDsp) <- paste0("CMDsp", 1991:2022)
CMDsm <- makeSeasonal(variable = "CMD", months = "6-8", years = 1991:2022, rtm = MDC)
names(CMDsm) <- paste0("CMDsm", 1991:2022)


#first step - landscape value 
takeMean <- function(stack) {
  out <- sapply(stack, FUN = function(x){
    x <- as.vector(x)
    x <- mean(x, na.rm = TRUE)
  })
}
CMDspMean <- takeMean(CMDsp)
CMDsmMean <- takeMean(CMDsm)
MDCmean <- takeMean(MDC)

fireSize <- sapply(fires, FUN = function(x){sum(x$SI)})
nFires <- sapply(fires, function(x){length(x$SIZE_HA)})


climData <- data.table(CMDsp = CMDspMean, CMDsm = CMDsmMean, MDC = MDCmean, 
                       fire_size = fireSize, fire_count = nFires,
                       year = 1991:2022)
climData <- climData[years < 2021] #MDC was made without 2021:2022
cor(climData)# MDC and CMDsm are both highly correlated (0.82), slight edge to CMDsm with fire size

gg <- melt.data.table(data = climData, id.vars = "year", variable.name = "stat", value.name = "value")

