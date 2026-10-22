library(dplyr)
library(ggplot2)
library(tidyr)
library(readxl)

# setwd("Unit05_RegressionEtc")

# initialization
# df <- read.csv("Smart_Farming_Crop_Yield_2024.csv")
df <- read.csv("Bures24_genome.csv")
bioclimatic <- read.csv("Bures24_bioclimate.csv")

# remove NA in log10_2C_genome.size
df <- df[!is.na(df$log10_2C_genome.size),]

# general idea of preprocessing
## ok so in TDWG_all, there are multiple values that separated by ";" since one species can be found in multiple places / country
# get sub data contains Working_Taxon_Name, Latitude and TDWG_all, but now make TDWG_all one row each
# then join with bioclimatic based on that code
# get the latitude and the diff between recorded latitude of that species and the bioclimatic latitude, then filter out the rows with diff <3

# pivot long
clean_df <- df %>%
  select(Working_Taxon_Name, Latitude, TDWG_all) %>%
  separate_rows(TDWG_all, sep = ";") 

# join and only keep ones that nearby recorded latitude value 
select_df <- clean_df %>%
  left_join(bioclimatic, by = c("TDWG_all" = "TDWG_level_3.code")) %>%
  mutate(diff_lat = abs(Latitude.x - Latitude.y)) %>%
  filter(diff_lat <= 3)

## join df with bioclimatic based on Distribution_firstupper and TDWG_level_3.code
var_to_join <- c("Latitude.x", "Longitude", "Mean.aridity.index", "Mean.BIO1", "Mean.BIO3", "Mean.BIO7",
"Mean.BIO12",  "Mean.BIO15","Mean.BIO19","Mean.GSL", "Mean.GST", "Mean.NGD5", "Mean.UVB1", "Mean.UVB3", "Mean.UVB5")

# group by Working_Taxon_Name and get the mean of each variable in var_to_join
# also only keep variables in var_to_join and Working_Taxon_Name
select_df <- select_df %>%
  select(Working_Taxon_Name, all_of(var_to_join)) %>%
  group_by(Working_Taxon_Name) %>%
  summarise(
    across(all_of(var_to_join), ~ mean(.x, na.rm = TRUE)),
    .groups = "drop")

# remove TDWG_all column from df and select_df
df <- df %>%
  select(-TDWG_all)

# join select_df with df based on Working_Taxon_Name
df <- df %>%
  left_join(select_df, by = "Working_Taxon_Name")



# actually we should remove species and taxa name etc as well
df <- df %>%
  select(-c(Order,Family,Working_Taxon_Name))

df <- df %>%
  mutate(across(-Growth_form, as.numeric))

# remove all rows that have NA 
df <- na.omit(df) 
dim(df)
# [1] 10008    22

write.csv(df,"Bures24_genome_cleaned.csv",row.names=FALSE)
