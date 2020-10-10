library(tidyverse)
library(rmarkdown)

bikes <- read_csv(file = "../Bike-Sharing-Dataset/hour.csv")

days <- c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday") 

output_file <- paste0(days, ".md") 

params = lapply(days, FUN = function(x){list(day = x)})

reports <- tibble(output_file, params)

apply(reports, MARGIN = 1, FUN = function(x){render(input = "./BurrowsProject2.Rmd", output_file = x[[1]], params = x[[2]])})







