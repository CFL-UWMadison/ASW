#### required packages
library(tidyverse)
library(AquaEnv)
library(LakeMetabolizer)
library(lubridate)

#### functions
carb.bookkkeep <- function(datetime = datetime,ph = ph, t = t, lat = lat, salinity = salinity, alk = alk) {
    # Simple bookkeep estimation of metabolism from high frequency pH data
    # model does not account for atmospheric exchange
    nobs <- length(ph)
    start.time <- floor_date(datetime[1],unit = "hour")
    end.time <- ceiling_date(datetime[nobs],unit= "hour")
    datetime.30min <- seq(from=start.time,to=end.time,by="30 min")
    samples <- datetime %in% datetime.30min
    datetime <- datetime[samples]
    ph <- ph[samples]
    t <- t[samples]
    nobs <- length(ph)
    TA <- convert(alk/1000/1000,"conc","molar2molin",S=salinity,t=t) #convert to molin
    ae <- aquaenv(t = t,S = salinity,TA = TA,pH = ph,SumCO2 = NULL,lat = lat)
    dic <- as.numeric(convert(ae$SumCO2,"conc","molin2molar",S=salinity,t=t))*1e6
    irr <- as.integer(is.day(datetime, lat = lat))
    dayI <- irr == 1L
    nightI <- irr == 0L
    delta.dic <- diff(dic) * (-1)
    
    nep.day <- delta.dic[dayI]
    nep.night <- delta.dic[nightI]
    
    R <- mean(nep.night,na.rm=TRUE) * nobs
    NEP <- mean(delta.dic,na.rm=TRUE) * nobs
    GPP <- mean(nep.day, na.rm = TRUE) * sum(dayI) - mean(nep.night, na.rm = TRUE) * sum(dayI)
    metab <- data.frame("GPP_mg_l_hr" = GPP/nobs*2*12.0107, 
                        "R_mg_l_hr" = R/nobs*2*12.0107, 
                        "NEP_mg_l_hr" = NEP/nobs*2*12.0107)
    return(metab)
}

# get data from sensor deployment
data <- read_csv("ME_ph.csv")

# organize data for metabolism estimates
datetime <- ymd_hms(paste(data$sampledate,data$sampletime,sep=" "))
ph <- data$ph
t <- data$do_wtemp
lat <- 44
salinity <- 0.3 
alk <- 3761

#run the model
out <- carb.bookkkeep(datetime = datetime,ph = ph,t = t,lat = lat,salinity = salinity,alk = alk)
out
