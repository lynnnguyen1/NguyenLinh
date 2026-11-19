library(ggplot2)
library(dplyr)

df_all <- read.csv("/Users/l233n428/Desktop/classes/Fall_26/NguyenLinh/finproj/data/appendicitis_all.csv")

# directory to save results
res_dir <- "/Users/l233n428/Desktop/classes/Fall_26/NguyenLinh/finproj/results"

dim(df_all)
# [1] 780 57

# checking missign data 
colSums(is.na(df_all))

# drop rows with NA in column US_number
df_all <- df_all[!is.na(US_Number), ]

# drop row with blank value in every columns
# df_all <- df_all[rowSums(df_all == " ", na.rm = TRUE) != ncol(df_all), ]
df_all <- df_all[df_all$Sex != "", ]
df_all <- df_all[df_all$Diagnosis != "", ]

# then remove all NA
df_all <- df_all[, colSums(is.na(df_all)) == 0, drop = FALSE]

# # drop columns with more than 600 missing values
# df_all <- df_all[, colSums(is.na(df_all)) <= 600]
# # then drop rows with more than 10 missing features
# df_all <- df_all[rowSums(is.na(df_all)) <= 10, ]

dim(df_all)
# [1] 780  40

# initial visualization 
# ages 
age_dist <- ggplot(df_all, aes(x = Age)) +
  geom_histogram(binwidth = 1, fill = "steelblue", color = "black") +
  labs(title = "Age of patients", x = "Age", y = "Count") +
  theme_minimal()
ggsave(file.path(res_dir, "age_distribution.png"), plot = age_dist, width = 8, height = 6,dpi = 300)

# stacked barplot for Sex and diagnosis
gender_diagnosis <- ggplot(df_all, aes(x = Sex, fill = Diagnosis)) +
  geom_bar(position = "fill") +
  labs(title = "Gender and Diagnosis", x = "Gender", y = "Proportion") +
  scale_fill_manual(values = c("orange", "purple")) +
  theme_minimal()
ggsave(file.path(res_dir, "gender_diagnosis.png"), plot = gender_diagnosis, width = 5, height = 5,dpi = 300)

