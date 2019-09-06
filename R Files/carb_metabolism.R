#### required packages
library(tidyverse)
library(AquaEnv)
library(LakeMetabolizer)
library(lubridate)

#### functions
carb.bookkkeep <- function(datetime = datetime,ph = ph, t = t, lat = lat, salinity = salinity, alk = alk, zmix=zmix) {
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
    co2 <- as.numeric(convert(ae$CO2,"conc","molin2molar",S=salinity,t=t))*1e6
    co2_sat <- as.numeric(convert(ae$CO2_sat,"conc","molin2molar",S=salinity,t=t))*1e6
    irr <- as.integer(is.day(datetime, lat = lat))
    dayI <- irr == 1L
    nightI <- irr == 0L
    
    #Gas fluxes
    wnd <- wind.scale.base(wnd = 4,wnd.z = 2)
    k600 <- k.cole.base(wnd)
    k.gas = k600.2.kGAS.base(k600 = k600,temperature = t,gas =  'CO2')
    #gas flux out is negative
    #normalized to z.mix, del_concentration/timestep (e.g., mg/L/10min)
    gas.flux <- (co2_sat - co2) * (k.gas/48) / zmix 
    
    #remove the component of delta.do that is due to gas flux
    delta.dic <- diff(dic)
    delta.dic.metab <- delta.dic - gas.flux[1:(length(gas.flux)-1)]
    delta.dic.metab <- delta.dic.metab * (-1)
    
    nep.day <- delta.dic.metab[dayI]
    nep.night <- delta.dic.metab[nightI]
    
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
zmix = 7

#run the model
out <- carb.bookkkeep(datetime = datetime,
                      ph = ph,
                      t = t,
                      lat = lat,
                      salinity = salinity,
                      alk = alk,
                      zmix=zmix)
out
