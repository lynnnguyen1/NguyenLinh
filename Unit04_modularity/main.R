# analyzing climatic data (mostly temperature adn precipitation) - check its trend over years 1950 - 2008
## initialization
library(ggplot2)
library(dplyr)
library(maps)

## read in data
# setwd("Unit04_modularity")  # in case need it
precipitation <- readRDS("USAAnnualPcpn1950_2008.rds")
temp <- readRDS("USAAnnualTemp1950_2008.rds")

head(precipitation,2)
head(temp,2)

# clean up cuz there are NAs in data column
precipitation <- precipitation[!is.na(precipitation$data), ]
temp <- temp[!is.na(temp$data), ]

nrow(precipitation)
nrow(temp)

### bunch of functions for our tasks

# Seperately for each of the two climate variables, and for each location, separetely, for which there are at
# least 40 measurements, regress the climate variable against year and take the slope. 
slope_trend <- function (data){
    model <- lm(data ~ year, data = data)
    return(coef(model)[2])
}

# our main
main_func <- function(data) {
    # unique of location (based on the name column)
    locations <- unique(data$name)

    # make a dataset to store slopes 
    slopes_df <- data.frame(location = character(), slope = numeric(), lat = numeric(), lon = numeric())
    # loop thru locations
    for (loc in locations) {
        # subset the data for each location
        data2 <- data[data$name == loc, ]

        # count variables
        n_data <- nrow(data2)

        # check if there are enough measurements 
        # if yes, proceed, if no, print a message
        if (n_data < 40) {
            cat("Not enough measurements for location:", loc, "\n")
            next
        }
        ## check trend of precipitation
        slopes <- slope_trend(data2)
        # store the slope in the dataframe
        slopes_df <- rbind(slopes_df, data.frame(location = loc, slope = slopes, lat = data2$lat[1], lon = data2$lon[1]))
    }
    return(slopes_df)
}

## histogram of slopes
# for precipitation
print("Slopes for Precipitation:")
precipitation_slopes <- main_func(precipitation)
png("precipitation_slopes.png", width = 10, height = 6, units = "in", res = 300)
hist(precipitation_slopes$slope, main = "Slopes for Precipitation", xlab = "Slope", ylab = "Frequency")
dev.off()

# for temperature
print("Slopes for Temperature:")
temp_slopes <- main_func(temp)
png("temperature_slopes.png", width = 10, height = 6, units = "in", res = 300)
hist(temp_slopes$slope, main = "Slopes for Temperature", xlab = "Slope", ylab = "Frequency")
dev.off()


## then we have map
# precipitation
print("maps of slopes of precipitation")
us <- map_data("state")

map_precipitation <- ggplot(us) +
  geom_polygon(aes(x = long, y = lat, group = group),
            fill = "white", colour = "black") +
  geom_point(data = precipitation_slopes,aes(x = lon, y = lat, color = slope)) +
  scale_color_gradient(low = "grey", high = "blue") +
  coord_quickmap()

ggsave("map_precipitation.png",map_precipitation, width = 10, height = 6, dpi = 300)

# kinda just around ohio, alabama and tennessee? 

# map temperature
map_temperature <- ggplot(us) +
  geom_polygon(aes(x = long, y = lat, group = group),
            fill = "white", colour = "black") +
  geom_point(data = temp_slopes,aes(x = lon, y = lat, color = slope)) +
  scale_color_gradient(low = "grey", high = "red") +
  coord_quickmap()

ggsave("map_temperature.png",map_temperature, width = 10, height = 6, dpi = 300)
# all over places???
