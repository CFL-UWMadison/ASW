#### required packages
library(tidyverse)
library(AquaEnv)
library(LakeMetabolizer)
library(lubridate)
library(data.table)
library(gridExtra)
library(cowplot)

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
    samples <- get_30min_obs(datetime,nobs)
    datetime <- samples$datetime
    ph <- ph[samples$obs]
    t <- t[samples$obs]
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
    wnd <- wind.scale.base(wnd = 6,wnd.z = 2)
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

get_30min_obs <- function(datetime = datetime, nobs = nobs) {
    temp <- data.table(datetime=datetime,obs = seq(1,length(datetime)))
    start.time <- ceiling_date(datetime[1],unit = "hour")
    end.time <- ceiling_date(datetime[nobs],unit= "hour")
    datetime.30min <- seq(from=start.time,to=end.time,by="30 min")
    temp30 <- data.table(datetime=datetime.30min,obs30 = seq(1:length(datetime.30min)))
    setkey(temp, datetime)
    setkey(temp30, datetime)
    out <- temp[temp30, roll='nearest']
    return(out)
}

# get data from sensor deployment
data <- read.delim("sensor_data/testdata.txt",header=FALSE,sep=",",stringsAsFactors = FALSE)

#plot data time series
colnames(data) <- c("datetime","lux","ph","temp","therm")
data <- data %>% 
    mutate(datetime = ymd_hms(datetime)) %>% 
    mutate(datetime = round_date(datetime,"min")) %>% 
    filter(datetime > ymd_hms("2019-09-25 14:00:00")) %>% 
    filter(datetime < ymd_hms("2019-09-26 12:00:00"))
data_long <- data %>% gather(value = "value",key= "parameter",-datetime)

p1 <- ggplot(data = data_long %>% filter(parameter == "temp" | parameter == "therm"),
             aes(x=datetime,y=value,color=parameter)) + geom_line() + geom_point() +
    labs(x="",y="Temperature",color="Probe")
p2 <- ggplot(data = data_long %>% filter(parameter == "ph"),
             aes(x=datetime,y=value)) + geom_point() + geom_line() +
    labs(x="",y="pH")
p3 <- ggplot(data = data_long %>% filter(parameter == "lux"),
             aes(x = datetime,y=value)) + geom_point() + geom_line() +
    labs(x = "Date Time",y= "Lux")

plots <- plot_grid(p1,p2,p3,nrow=3,align="v",axis="rl")
plots
    
# organize data for metabolism estimates
datetime <- data$datetime
ph <- data$ph
t <- data$temp # digital temperature
lat <- 46.044
salinity <- 0.3 
alk <- 742 #Trout Lake 742, Sparkling Lake 637, Trout Bog 4
zmix = 11 #Trout Bog 2m, Sparkling 8m, Trout 11m

 




#run the model
out <- carb.bookkkeep(datetime = datetime,
                      ph = ph,
                      t = t,
                      lat = lat,
                      salinity = salinity,
                      alk = alk,
                      zmix=zmix)
out
