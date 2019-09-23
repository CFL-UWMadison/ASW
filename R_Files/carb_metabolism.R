#### required packages
library(tidyverse)
library(AquaEnv)
library(LakeMetabolizer)
library(lubridate)

#### functions

carb.bookkkeep <- function(datetime = datetime,ph = ph, t = t, lat = lat, salinity = salinity, alk = alk, zmix=zmix) {
    # Simple bookkeep estimation of metabolism from high frequency pH data
    # model accounts gas exchange assuming static wind and zmix
    # datetime: vector of date times (format = YYYY-MM-DD HH:MM:SS)
    # ph: vector of ph values equal to length of datetime vector
    # t: vector of temperature values (degrees C) equal to length of datetime vector
    # lat: latitude of sample location (used to calculate atmospheric pressure)
    # salinity: salinity of water
    # alk: alkalinity of water in ueq/L HCO3
    # zmix: estimate of zmix for sampling period

    nobs <- length(ph)
    #extract data with 30min time step from the original time series
    start.time <- floor_date(datetime[1],unit = "hour")
    end.time <- ceiling_date(datetime[nobs],unit= "hour")
    datetime.30min <- seq(from=start.time,to=end.time,by="30 min")
    samples <- datetime %in% datetime.30min
    datetime <- datetime[samples]
    ph <- ph[samples]
    t <- t[samples]
    nobs <- length(ph)
    
    #estimate carbon concentrations
    TA <- convert(alk/1000/1000,"conc","molar2molin",S=salinity,t=t) #convert to molin
    ae <- aquaenv(t = t,S = salinity,TA = TA,pH = ph,SumCO2 = NULL,lat = lat)
    dic <- as.numeric(convert(ae$SumCO2,"conc","molin2molar",S=salinity,t=t))*1e6 #umol/L
    co2 <- as.numeric(convert(ae$CO2,"conc","molin2molar",S=salinity,t=t))*1e6 #ummol/L
    co2_sat <- as.numeric(convert(ae$CO2_sat,"conc","molin2molar",S=salinity,t=t))*1e6 #umol/L
    
    #identify day and night time periods
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
    
    #remove the component of delta.dic that is due to gas flux
    delta.dic <- diff(dic) * (-1) #multiply by -1 so changes are same direction as O2 method
    delta.dic.metab <- delta.dic - gas.flux[1:(length(gas.flux)-1)]
    
    #calculate day and night nep values
    nep.day <- delta.dic.metab[dayI]
    nep.night <- delta.dic.metab[nightI]
    
    #estimate metabolism in mgC/L/hr for the entire deployment period
    R <- mean(nep.night,na.rm=TRUE) * nobs
    NEP <- mean(delta.dic.metab,na.rm=TRUE) * nobs
    GPP <- mean(nep.day, na.rm = TRUE) * sum(dayI) - mean(nep.night, na.rm = TRUE) * sum(dayI)
    metab <- data.frame("GPP_mg_l_hr" = GPP/nobs*2*12.0107/1000, 
                        "R_mg_l_hr" = R/nobs*2*12.0107/1000, 
                        "NEP_mg_l_hr" = NEP/nobs*2*12.0107/1000)
    return(metab)
}

# get data from sensor deployment
data <- read_csv("ME_ph.csv")

# organize data for metabolism estimates
datetime <- ymd_hms(paste(data$sampledate,data$sampletime,sep=" "))
ph <- data$ph
t <- data$do_wtemp
lat <- 44
salinity <- 0.1 
alk <- 4 #Trout Lake 742, Sparkling Lake 637, Trout Bog 4
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
