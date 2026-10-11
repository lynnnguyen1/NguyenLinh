# analyzing climatic data (mostly temperature adn precipitation) - check its trend over years 1950 - 2008
## initialization
library(ggplot2)
library(dplyr)
library(maps)

#MODULARITY EXAMPLE 2 - Get the general idea of the data structure and 
# brainstorm the assignment and what to do to solve issue before actually start coding 

## read in data
# setwd("Unit04_modularity")  # in case need it
precipitation <- readRDS("USAAnnualPcpn1950_2008.rds")
temp <- readRDS("USAAnnualTemp1950_2008.rds")

head(precipitation,2)
head(temp,2)

# clean up cuz there are NAs in data column
precipitation <- precipitation[!is.na(precipitation$data), ]
temp <- temp[!is.na(temp$data), ]

# check the number of observations in dataset
print(paste("number of obs in precipitation:", nrow(precipitation)))
print(paste("number of obs in temperature:", nrow(temp)))

# > print(paste("number of obs in precipitation:", nrow(precipitation)))
# [1] "number of obs in precipitation: 26239"
# > print(paste("number of obs in temperature:", nrow(temp)))
# [1] "number of obs in temperature: 317530"

# Linh's obs: We have different number of observations between two datasets 


### create functions for our tasks
## Main task is, we have two climate variables
## for each variable and each location, separetely
## if they have least 40 measurements, regress the climate variable against year 
## and take the slope to quantify degree of change over time 

#MODULARITY EXAMPLE 1 - get the function of "data" as a parameter instead of hard-code input
#MODULARITY EXAMPLE 8 - get the clear description of each function and code chunk

# linear regression between climatic variable (temperature and precipitation as of now) over year
# then take their slope (beta)
slope_trend <- function (data){
    model <- lm(data ~ year, data = data) 
    # use linear regression - can change to other regression if needed 
    return(coef(model)[2])
}

# our main function 
# loop thru slope_trend with control on data to examine
# check quantify the slope of climatic changes over years

#MODULARITY 4 - get the different parameters and how it explains the function
#MODULARITY 6 - I had some scratch / draft code before putting them together in functions 

# take in data as a dataset variable
# and min_obs is for the quality control - minimum number of observations at each location 
# in assignment we have 40, but make it variable, just in case wanna change
# returns the dataframe of slopes of environment variables at different locations 

main_func <- function(data, min_obs) {
    # unique of location (based on the 'name' column)
    # we examine different locations, each by each 
    locations <- unique(data$name)

    # make a dataset to store slopes at that location
    slopes_df <- data.frame(location = character(), slope = numeric(), lat = numeric(), lon = numeric())
    
    # check how climatic values have changed in each location
    for (loc in locations) {
        # subset the data for each location
        data2 <- data[data$name == loc, ]

        # count observations
        n_data <- nrow(data2)
        # check if there are enough observations (40 obs or more)
        if (n_data < min_obs) {
            # cat("Not enough observations for location:", loc, "\n") # used this before to print messages
            next
        }

        ## check trend of precipitation
        slopes <- slope_trend(data2)

        # store the slope in the dataframe
        slopes_df <- rbind(slopes_df, data.frame(location = loc, slope = slopes, lat = data2$lat[1], lon = data2$lon[1]))
    }
    return(slopes_df) # return df
}

# examine trends 
# see how extreme climatic variable has changed and on which direction
# by counting values of slopes that exceed the threshold
examine_slopes <- function(slopes, threshold){
  check <- data.frame(
    positive = sum(slopes > threshold), 
    negative = sum(slopes < -threshold)
  )
  return(check)
}


#MODULARITY EXAMPLE 7 - I used the similar lines to plot figures multple times, 
# so I decided to create functions to make the script easy to read 

#MODULARITY EXAMPLE 3 - It might or might not show here (but will be in the previous commit)
# I revised the code from hard-code lines for drawing viz to get functions to do so 
# which is helpful in case we make some slight changes and then still ensure plots look consistent

## function to draw histogram
# inputs are the slope (dataframe of slope from main_func, the title of the plot and labels)
# output is the plot 
#MODULARITY EXAMPLE 1 - not hard-code labels and titles 
hist_draw_func <- function(slopes, title, xlab, ylab) {
  png(paste(title, ".png", sep = ""), width = 10, height = 6, units = "in", res = 300)
  hist(slopes, main = title, xlab = xlab, ylab = ylab)
  dev.off()
}

## then we have map
# precipitation
print("maps of slopes of precipitation")
us <- map_data("state") # just us map 

## function to draw map
# inputs are the slope (dataframe of slope from main_func, title and labels)
# output is the plot of US map with points are slopes at different locations  
map_draw_func <- function(data, title, xlab, ylab, threshold) {
  data$alpha_val <- ifelse(abs(data$slope) > threshold, 1, 0.3) # get different opacity for extreme values

  # initiate the plot
  plt <- ggplot(us) +
    geom_polygon(aes(x = long, y = lat, group = group),fill = "white", colour = "black") +
    geom_point(data = data,aes(x = lon, y = lat, color = slope,alpha = alpha_val))+
    scale_alpha_identity() + # trying to highlight extreme values 
    scale_color_gradient2(low = "blue2", mid="#e0f9ec",midpoint=0, high = "red") + # different colors
    coord_quickmap()+ # quick mapping 
    theme_bw()
  ggsave(plt, filename = paste(title, ".png", sep = ""), width = 10, height = 6, dpi=300)
}

## let's use our functions to examine temperature and precipitation variables 

# get slopes
precipitation_slopes <- main_func(precipitation,40)
temp_slopes <- main_func(temp,40)

# then examine the slopes
precipitation_check <- examine_slopes(precipitation_slopes$slope, 0.1) # threshold of 0.1 as of this test
temp_check <- examine_slopes(temp_slopes$slope, 0.1)

print(precipitation_check)
print(temp_check)

# histogram for precipitation
hist_draw_func(precipitation_slopes$slope, "precipitation_slopes", "Slope", "Frequency")

# histogram for temperature
hist_draw_func(temp_slopes$slope, "temperature_slopes", "Slope", "Frequency")

# map for precipitation
map_draw_func(precipitation_slopes, "map_precipitation", "Longitude", "Latitude", 0.1) # threshold of 0.1

# map for temperature
map_draw_func(temp_slopes, "map_temperature", "Longitude", "Latitude", 0.1) # threshold of 0.1 as well
