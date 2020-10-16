Joshua Burrows Project 2
================
16 October 2020

# Introduction

The purpose of this project is to analyze data about the Capital bike
sharing system. This data can be accessed through [the UCI Machine
Learning
Library](https://archive.ics.uci.edu/ml/datasets/Bike+Sharing+Dataset).

My analysis makes use of the following packages: *knitr*, *rmarkdown*,
*tidyverse*, *caret*, *corrplot*, *shiny*, and *rpart.plot*.

# Models

I built models to predict number of bikes rented. Predictor variables
include:

  - Year and month of the rental  
  - Hour of the day  
  - Weather, temperature, humidity, and wind speed  
  - Whether the day is a holiday

My analysis is divided up by day of the week. The analysis for each day
can be viewed here:

[Sunday](Sunday.md)  
[Monday](Monday.md)  
[Tuesday](Tuesday.md)  
[Wednesday](Wednesday.md)  
[Thursday](Thursday.md)  
[Friday](Friday.md)  
[Saturday](Saturday.md)

# Automation

I didn’t want to have to write seven different reports, so I automated a
few things to speed up the process. The code that does the automation is
here:

``` r
library(tidyverse)
library(rmarkdown)

bikes <- read_csv(file = "../Bike-Sharing-Dataset/hour.csv")

days <- c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday") 

output_file <- paste0(days, ".md") 

params = lapply(days, FUN = function(x){list(day = x)})

reports <- tibble(output_file, params)

apply(reports, 
      MARGIN = 1, 
      FUN = function(x){render(input = "./BurrowsProject2Analysis.Rmd", 
                               output_file = x[[1]], 
                               params = x[[2]])})
```
