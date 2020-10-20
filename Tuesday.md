Joshua Burrows Project 2
================
16 October 2020

  - [Bike Rentals on Tuesdays:
    Introduction](#bike-rentals-on-tuesdays-introduction)
  - [Read in Data](#read-in-data)
      - [Get Bikes Data](#get-bikes-data)
      - [Factors](#factors)
      - [Filter by Day](#filter-by-day)
  - [Exploratory Data Analysis](#exploratory-data-analysis)
      - [Quantitative Predictors](#quantitative-predictors)
          - [Correlations](#correlations)
          - [Hour](#hour)
          - [Temperature](#temperature)
          - [Felt Temperature](#felt-temperature)
          - [Humidity](#humidity)
          - [Wind Speed](#wind-speed)
      - [Categorical Predictors](#categorical-predictors)
          - [Helper Function](#helper-function)
          - [Season](#season)
          - [Year](#year)
          - [Month](#month)
          - [Holiday](#holiday)
          - [Working Day](#working-day)
          - [Weather Condition](#weather-condition)
  - [Train Models](#train-models)
      - [Split Data](#split-data)
      - [Non-Ensemble Tree](#non-ensemble-tree)
          - [Training](#training)
              - [Tree Models](#tree-models)
              - [Tuning Parameter](#tuning-parameter)
              - [Formula](#formula)
              - [Create the Model](#create-the-model)
          - [Model Information](#model-information)
      - [Boosted Tree](#boosted-tree)
          - [Training](#training-1)
              - [Boosted Tree Models](#boosted-tree-models)
              - [Tuning Paremeters](#tuning-paremeters)
              - [Create the Model](#create-the-model-1)
          - [Model Information](#model-information-1)
      - [Multiple Linear Regression](#multiple-linear-regression)
          - [Training](#training-2)
              - [Create the Model](#create-the-model-2)
  - [Test Models](#test-models)
  - [Best Model](#best-model)

# Bike Rentals on Tuesdays: Introduction

This document walks though the process of creating a model to predict
hourly bike rentals on Tuesdays. I compared two models - a *non-ensemble
tree* and a *boosted tree* - and picked the one that does better.

The data comes from the Capital bike sharing system, and it is available
[here](https://archive.ics.uci.edu/ml/datasets/Bike+Sharing+Dataset).
This data includes an hourly count of bike rentals for 2011 and 2012 as
well as information about the weather and the time of year.

My models use the following predictor variables:

  - *yr*: year (2011 or 2012)  
  - *mnth*: month  
  - *hr*: hour of the day  
  - *holiday*: whether the day is a holiday  
  - *weathersit*: weather condition
      - pleasant: clear, few clouds, partly cloudy  
      - less pleasant: mist, mist + cloudy, mist + broken clouds, mist +
        few clouds  
      - even less pleasant: light snow, light rain + scattered clouds,
        light rain + thunderstorm + scattered clouds  
      - downright unpleasant: snow + fog, heavy rain + ice pallets +
        thunderstorm + mist  
  - *temp*: normalized temperature in celsius  
  - *hum*: normalized humidity  
  - *windspeed*: normalized wind speed

You can return to the homepage for this project by clicking
[here](https://jkburrows.github.io/ST558-Project-2/). The github repo
for this project is
[here](https://github.com/JKBurrows/ST558-Project-2).

# Read in Data

## Get Bikes Data

Read in data.

``` r
bikes <- read_csv(file = "hour.csv")

bikes %>% head() %>% kable()
```

| instant | dteday     | season | yr | mnth | hr | holiday | weekday | workingday | weathersit | temp |  atemp |  hum | windspeed | casual | registered | cnt |
| ------: | :--------- | -----: | -: | ---: | -: | ------: | ------: | ---------: | ---------: | ---: | -----: | ---: | --------: | -----: | ---------: | --: |
|       1 | 2011-01-01 |      1 |  0 |    1 |  0 |       0 |       6 |          0 |          1 | 0.24 | 0.2879 | 0.81 |    0.0000 |      3 |         13 |  16 |
|       2 | 2011-01-01 |      1 |  0 |    1 |  1 |       0 |       6 |          0 |          1 | 0.22 | 0.2727 | 0.80 |    0.0000 |      8 |         32 |  40 |
|       3 | 2011-01-01 |      1 |  0 |    1 |  2 |       0 |       6 |          0 |          1 | 0.22 | 0.2727 | 0.80 |    0.0000 |      5 |         27 |  32 |
|       4 | 2011-01-01 |      1 |  0 |    1 |  3 |       0 |       6 |          0 |          1 | 0.24 | 0.2879 | 0.75 |    0.0000 |      3 |         10 |  13 |
|       5 | 2011-01-01 |      1 |  0 |    1 |  4 |       0 |       6 |          0 |          1 | 0.24 | 0.2879 | 0.75 |    0.0000 |      0 |          1 |   1 |
|       6 | 2011-01-01 |      1 |  0 |    1 |  5 |       0 |       6 |          0 |          2 | 0.24 | 0.2576 | 0.75 |    0.0896 |      0 |          1 |   1 |

## Factors

Convert categorical variables to factors.

``` r
bikes$weekday <- as.factor(bikes$weekday)
levels(bikes$weekday) <- c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday") 

bikes$season <- as.factor(bikes$season)
levels(bikes$season) <- c("winter", "spring", "summer", "fall")

bikes$yr <- as.factor(bikes$yr)
levels(bikes$yr) <- c("2011", "2012")

bikes$mnth <- as.factor(bikes$mnth)
levels(bikes$mnth) <- c("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec")

bikes$weathersit <- as.factor(bikes$weathersit)
levels(bikes$weathersit) <- c("pleasant", "less pleasant", "even less pleasant", "downright unpleasant")

bikes$holiday <- as.factor(bikes$holiday)
levels(bikes$holiday) <- c("no", "yes")

bikes$workingday <- as.factor(bikes$workingday)
levels(bikes$workingday) <- c("no", "yes")

bikes %>% head() %>% kable()
```

| instant | dteday     | season | yr   | mnth | hr | holiday | weekday  | workingday | weathersit    | temp |  atemp |  hum | windspeed | casual | registered | cnt |
| ------: | :--------- | :----- | :--- | :--- | -: | :------ | :------- | :--------- | :------------ | ---: | -----: | ---: | --------: | -----: | ---------: | --: |
|       1 | 2011-01-01 | winter | 2011 | jan  |  0 | no      | Saturday | no         | pleasant      | 0.24 | 0.2879 | 0.81 |    0.0000 |      3 |         13 |  16 |
|       2 | 2011-01-01 | winter | 2011 | jan  |  1 | no      | Saturday | no         | pleasant      | 0.22 | 0.2727 | 0.80 |    0.0000 |      8 |         32 |  40 |
|       3 | 2011-01-01 | winter | 2011 | jan  |  2 | no      | Saturday | no         | pleasant      | 0.22 | 0.2727 | 0.80 |    0.0000 |      5 |         27 |  32 |
|       4 | 2011-01-01 | winter | 2011 | jan  |  3 | no      | Saturday | no         | pleasant      | 0.24 | 0.2879 | 0.75 |    0.0000 |      3 |         10 |  13 |
|       5 | 2011-01-01 | winter | 2011 | jan  |  4 | no      | Saturday | no         | pleasant      | 0.24 | 0.2879 | 0.75 |    0.0000 |      0 |          1 |   1 |
|       6 | 2011-01-01 | winter | 2011 | jan  |  5 | no      | Saturday | no         | less pleasant | 0.24 | 0.2576 | 0.75 |    0.0896 |      0 |          1 |   1 |

## Filter by Day

Grab the data for Tuesday.

``` r
dayData <- bikes %>% filter(weekday == params$day)

dayData %>% head() %>% kable()
```

| instant | dteday     | season | yr   | mnth | hr | holiday | weekday | workingday | weathersit | temp |  atemp |  hum | windspeed | casual | registered | cnt |
| ------: | :--------- | :----- | :--- | :--- | -: | :------ | :------ | :--------- | :--------- | ---: | -----: | ---: | --------: | -----: | ---------: | --: |
|      70 | 2011-01-04 | winter | 2011 | jan  |  0 | no      | Tuesday | yes        | pleasant   | 0.16 | 0.1818 | 0.55 |    0.1045 |      0 |          5 |   5 |
|      71 | 2011-01-04 | winter | 2011 | jan  |  1 | no      | Tuesday | yes        | pleasant   | 0.16 | 0.1818 | 0.59 |    0.1045 |      0 |          2 |   2 |
|      72 | 2011-01-04 | winter | 2011 | jan  |  2 | no      | Tuesday | yes        | pleasant   | 0.14 | 0.1515 | 0.63 |    0.1343 |      0 |          1 |   1 |
|      73 | 2011-01-04 | winter | 2011 | jan  |  4 | no      | Tuesday | yes        | pleasant   | 0.14 | 0.1818 | 0.63 |    0.0896 |      0 |          2 |   2 |
|      74 | 2011-01-04 | winter | 2011 | jan  |  5 | no      | Tuesday | yes        | pleasant   | 0.12 | 0.1515 | 0.68 |    0.1045 |      0 |          4 |   4 |
|      75 | 2011-01-04 | winter | 2011 | jan  |  6 | no      | Tuesday | yes        | pleasant   | 0.12 | 0.1515 | 0.74 |    0.1045 |      0 |         36 |  36 |

# Exploratory Data Analysis

I started with a little bit of exploratory data analysis. The goal is to
look at the relationships between the predictors and number of bike
rentals.

## Quantitative Predictors

### Correlations

Visualize the strength of the relationships between the quantitative
predictors.

Unsurprisingly, *atemp* and *temp* are strongly correlated. *atemp*
represents the heat index, which is typically calculated using
temperature and humidity. So it makes sense to either eliminate *atemp*
from the model or keep *atemp* but eliminate *temp* and *hum*. I decided
to eliminate *atemp*.

``` r
corr <- dayData %>% 
  select(temp, atemp, windspeed, hum) %>% 
  cor()

corrplot(corr)
```

![](Tuesday_files/figure-gfm/Correlation-1.png)<!-- -->

### Hour

Create a scatter plot to investigate the relationship between time of
day and rentals on Tuesdays. Fit a line through the points to get a
basic idea of how number or rentals changes with the time of day.

``` r
avgRentals <- dayData %>% 
  group_by(hr) %>% 
  summarize(meanRentals = mean(cnt))

corrHour <- cor(avgRentals$hr, avgRentals$meanRentals)

ggplot(avgRentals, aes(x = hr, y = meanRentals)) +
  geom_point() + 
  labs(title = paste0("Total Rentals on ", paste0(params$day, "s"), " by Hour"), 
       x = "Hour of the Day", 
       y = "Total Rentals") + 
  geom_smooth()
```

![](Tuesday_files/figure-gfm/Hour-1.png)<!-- -->

The correlation between hour and average rentals is 0.491732.

Be careful, correlation measures straight line relationships, so if the
plot above shows a curved relationship, correlation may not be a useful
measure.

### Temperature

Create a scatter plot to investigate the relationship between
temperature and average rentals on Tuesdays. Fit a line through the
points to get a basic idea of average rentals changes with temperature.

The size of the dots represents the number of observations at each
temperature.

``` r
tempAvg <- dayData %>% 
  group_by(temp) %>% 
  summarize(avgRentals = mean(cnt), n = n())

corrTemp <- cor(tempAvg$temp, tempAvg$avgRentals)

ggplot(tempAvg, aes(x = temp, y = avgRentals)) + 
  geom_point(aes(size = n)) + 
  geom_smooth() + 
  labs(title = paste0("Average Rentals on ", paste0(params$day, "s"), " by Temperature"), 
       x = "Normalized Temperature", 
       y = "Average Rentals") + 
  scale_size_continuous(name = "Number of Obs")
```

![](Tuesday_files/figure-gfm/Temp-1.png)<!-- -->

The correlation between temperature and average rentals is 0.9036214.

Be careful, correlation measures straight line relationships, so if the
plot above shows a curved relationship, correlation may not be a useful
measure.

### Felt Temperature

Create a scatter plot to investigate the relationship between felt
temperature and average rentals on Tuesdays. Fit a line through the
points to get a basic idea of how average rentals changes with felt
temperature.

The size of the dots represents the number of observations at each felt
temperature.

As already noted, it does not make much sense to keep *atemp* if *temp*
and *hum* will be in the model, so I eliminated *atemp* from the model.

``` r
atempAvg <- dayData %>% 
  group_by(atemp) %>% 
  summarize(avgRentals = mean(cnt), n = n())

corrATemp <- cor(atempAvg$atemp, atempAvg$avgRentals)

ggplot(atempAvg, aes(x = atemp, y = avgRentals)) +
  geom_point(aes(size = n)) + 
  geom_smooth() + 
  labs(title = paste0("Average Rentals on ", paste0(params$day, "s"), " by Felt Temperature"), 
       x = "Normalized Feeling Temperature", 
       y = "Average Rentals") + 
  scale_size_continuous(name = "Number of Obs")
```

![](Tuesday_files/figure-gfm/aTemp-1.png)<!-- -->

The correlation between felt temperature and average rentals is
0.861061.

Be careful, correlation measures straight line relationships, so if the
plot above shows a curved relationship, correlation may not be a useful
measure.

### Humidity

Create a scatter plot to investigate the relationship between humidity
and average rentals on Tuesdays. Fit a line through the points to get a
basic idea of how average rentals changes with humidity.

The size of the dots represents the number of observations at each
humidity level.

``` r
humAvg <- dayData %>% 
  group_by(hum) %>% 
  summarize(avgRentals = mean(cnt), n = n())

corrHum <- cor(humAvg$hum, humAvg$avgRentals)

ggplot(humAvg, aes(x = hum, y = avgRentals)) + 
  geom_point(aes(size = n)) + 
  geom_smooth() + 
  labs(title = paste0("Average Rentals on ", paste0(params$day, "s"), " by Humidity"), 
       x = "Normalized Humidity", 
       y = "Average Rentals") + 
  scale_size_continuous(name = "Number of Obs")
```

![](Tuesday_files/figure-gfm/Hum-1.png)<!-- -->

The correlation between humidity and average rentals is -0.55744.

Be careful, correlation measures straight line relationships, so if the
plot above shows a curved relationship, correlation may not be a useful
measure.

### Wind Speed

Create a scatter plot to investigate the relationship between wind speed
and average rentals on Tuesdays. Fit a line through the points to get a
basic idea of how average rentals changes with wind speed.

The size of the dots represents the number of observations at each wind
speed.

``` r
windAvg <- dayData %>% 
  group_by(windspeed) %>% 
  summarize(avgRentals = mean(cnt), n = n())

corrWind <- cor(windAvg$windspeed, windAvg$avgRentals)

ggplot(windAvg, aes(x = windspeed, y = avgRentals)) + 
  geom_point(aes(size = n)) + 
  geom_smooth() + 
  labs(title = paste0("Average Rentals on ", paste0(params$day, "s"), " by Wind Speed"), 
       x = "Normalized Wind Speed", 
       y = "Average Rentals") + 
  scale_size_continuous(name = "Number of Obs")
```

![](Tuesday_files/figure-gfm/Wind-1.png)<!-- -->

The correlation between wind speed and average rentals is -0.4214456.

Be careful, correlation measures straight line relationships, so if the
plot above shows a curved relationship, correlation may not be a useful
measure.

## Categorical Predictors

### Helper Function

Create a helper function to display basic numeric summaries for a given
grouping variable.

``` r
getSum <- function(varName, colName){ 
  
  sum <- dayData %>% 
    group_by(dayData[[varName]]) %>% 
    summarize(min = min(cnt), 
              Q1 = quantile(cnt, probs = c(.25), names = FALSE), 
              median = median(cnt), 
              mean = mean(cnt), 
              Q3 = quantile(cnt, probs = c(.75), names = FALSE), 
              max = max(cnt), 
              obs = n())
  
  output <- sum %>% 
    kable(col.names = c(colName, 
                        "Minimum", 
                        "1st Quartile", 
                        "Median", 
                        "Mean", 
                        "3rd Quartile", 
                        "Maximum", 
                        "Number of Observations"))
  
  return(output)
  
} 
```

### Season

Explore how bike rentals on Tuesdays change with the seasons using a
basic numeric summary and a boxplot. The numeric summary gives you an
idea of center and spread. So does the boxplot, but it is better for
identifying outliers.

It does not make much sense to keep both *season* and *mnth* in the
model, so I decided to eliminate *season*.

``` r
getSum(varName = "season", colName = "Season")
```

| Season | Minimum | 1st Quartile | Median |     Mean | 3rd Quartile | Maximum | Number of Observations |
| :----- | ------: | -----------: | -----: | -------: | -----------: | ------: | ---------------------: |
| winter |       1 |         23.5 |   85.0 | 122.2644 |       170.00 |     801 |                    571 |
| spring |       1 |         35.0 |  159.5 | 201.0401 |       285.25 |     850 |                    624 |
| summer |       1 |         57.0 |  192.0 | 236.0355 |       328.00 |     970 |                    647 |
| fall   |       1 |         40.0 |  157.0 | 198.2520 |       289.00 |     967 |                    611 |

``` r
ggplot(dayData, aes(x = season, y = cnt)) + 
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Season"), 
       x = "Season", 
       y = "Number of Rentals") 
```

![](Tuesday_files/figure-gfm/Season-1.png)<!-- -->

### Year

Looking at total rentals each year gives us some idea of the long term
trend in bike rentals on Tuesdays. It would be helpful to have data from
more years, though.

``` r
yearSum <- dayData %>% 
  group_by(yr) %>% 
  summarize(totalRentals = sum(cnt))

yearSum %>% kable(col.names = c("Year", "Total Rentals"))
```

| Year | Total Rentals |
| :--- | ------------: |
| 2011 |        180338 |
| 2012 |        288771 |

### Month

Explore how bike rentals on Tuesdays change depending on the month using
a basic numeric summary and a boxplot. The numeric summary gives you an
idea of center and spread. So does the boxplot, but it is better for
identifying outliers.

As already noted, it is probably not worth including *mnth* and *season*
in the model, so *season* has been eliminated.

``` r
getSum(varName = "mnth", colName = "Month")
```

| Month | Minimum | 1st Quartile | Median |     Mean | 3rd Quartile | Maximum | Number of Observations |
| :---- | ------: | -----------: | -----: | -------: | -----------: | ------: | ---------------------: |
| jan   |       1 |        27.25 |   83.0 | 116.7172 |       168.75 |     559 |                    198 |
| feb   |       1 |        29.50 |   86.0 | 123.4536 |       172.00 |     559 |                    183 |
| mar   |       1 |        25.50 |  104.0 | 149.6093 |       220.50 |     801 |                    215 |
| apr   |       1 |        29.50 |  132.0 | 189.8281 |       277.50 |     800 |                    192 |
| may   |       2 |        37.50 |  175.0 | 209.3750 |       286.25 |     785 |                    240 |
| jun   |       2 |        54.00 |  189.5 | 236.7031 |       328.50 |     900 |                    192 |
| jul   |       2 |        72.00 |  200.0 | 243.5093 |       334.00 |     877 |                    216 |
| aug   |       3 |        63.00 |  208.5 | 247.1019 |       343.25 |     878 |                    216 |
| sep   |       1 |        45.50 |  172.0 | 217.1518 |       304.00 |     970 |                    191 |
| oct   |       1 |        60.50 |  180.0 | 224.5369 |       317.50 |     943 |                    203 |
| nov   |       1 |        27.50 |  136.5 | 168.3426 |       242.00 |     665 |                    216 |
| dec   |       1 |        24.50 |  107.0 | 155.5288 |       242.00 |     743 |                    191 |

``` r
ggplot(dayData, aes(x = mnth, y = cnt)) + 
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Month"), 
       x = "Month", 
       y = "Number of Rentals")
```

![](Tuesday_files/figure-gfm/Month-1.png)<!-- -->

### Holiday

Explore how bike rentals change depending on whether the Tuesday in
question is a holiday using a basic numeric summary and a boxplot. The
numeric summary gives you an idea of center and spread. So does the
boxplot, but it is better for identifying outliers.

Note: There are no holidays on Saturday or Sunday because the holiday
data has been extracted from the [Washington D.C. HR department’s
holiday schedule](https://dchr.dc.gov/page/holiday-schedules), which
only lists holidays that fall during the work week. Accordingly, I have
left the *holiday* variable out of the models for Saturday and Sunday.

``` r
getSum(varName = "holiday", colName = "Holiday")
```

| Holiday | Minimum | 1st Quartile | Median |      Mean | 3rd Quartile | Maximum | Number of Observations |
| :------ | ------: | -----------: | -----: | --------: | -----------: | ------: | ---------------------: |
| no      |       1 |           36 |    149 | 192.63210 |          277 |     970 |                   2430 |
| yes     |       1 |           12 |     32 |  44.04348 |           68 |     126 |                     23 |

``` r
ggplot(dayData, aes(x = holiday, y = cnt)) + 
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Holiday"), 
       x = "Is it a Holiday?", 
       y = "Number of Rentals")
```

![](Tuesday_files/figure-gfm/Holiday-1.png)<!-- -->

### Working Day

Explore how bike rentals change depending on whether the day in question
is a working day using a basic numeric summary and a boxplot. The
numeric summary gives you an idea of center and spread. So does the
boxplot, but it is better for identifying outliers.

Working days are neither weekends nor holidays. I decided not to keep
this variable in the model because it wouldn’t make much sense in the
reports for Saturday and Sunday.

``` r
getSum(varName = "workingday", colName = "Working Day")
```

| Working Day | Minimum | 1st Quartile | Median |      Mean | 3rd Quartile | Maximum | Number of Observations |
| :---------- | ------: | -----------: | -----: | --------: | -----------: | ------: | ---------------------: |
| no          |       1 |           12 |     32 |  44.04348 |           68 |     126 |                     23 |
| yes         |       1 |           36 |    149 | 192.63210 |          277 |     970 |                   2430 |

``` r
ggplot(dayData, aes(x = workingday, y = cnt)) +
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Working Day"), 
       x = "Is it a Working Day?", 
       y = "Number of Rentals")
```

![](Tuesday_files/figure-gfm/Workingday-1.png)<!-- -->

### Weather Condition

Explore how bike rentals on Tuesdays change depending on the weather
using a basic numeric summary and a boxplot. The numeric summary gives
you an idea of center and spread. So does the boxplot, but it is better
for identifying outliers.

``` r
getSum(varName = "weathersit", colName = "Weather Condition")
```

| Weather Condition  | Minimum | 1st Quartile | Median |     Mean | 3rd Quartile | Maximum | Number of Observations |
| :----------------- | ------: | -----------: | -----: | -------: | -----------: | ------: | ---------------------: |
| pleasant           |       1 |        52.25 |  174.5 | 214.8364 |       303.75 |     970 |                   1522 |
| less pleasant      |       1 |        28.00 |  123.5 | 164.7133 |       238.75 |     868 |                    694 |
| even less pleasant |       1 |        20.00 |   66.0 | 117.3713 |       147.00 |     819 |                    237 |

``` r
ggplot(dayData, aes(x = weathersit, y = cnt)) +
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Weather Condition"), 
       x = "What is the Weather Like?", 
       y = "Number of Rentals")
```

![](Tuesday_files/figure-gfm/Weather-1.png)<!-- -->

# Train Models

After exploring the data, I created two models, a non-ensemble tree and
a boosted tree.

## Split Data

Split the data into a training set and a test set. The training set is
used to build the models, and the test set is used to evaluate them.

``` r
set.seed(123)
trainIndex <- createDataPartition(dayData$cnt, p = .7, list = FALSE)

train <- dayData[trainIndex,]
test <- dayData[-trainIndex,]
```

## Non-Ensemble Tree

### Training

Fit a non-ensemble tree model.

#### Tree Models

Tree models split each predictor space into regions and make a different
prediction for each region. For example, suppose we are interested in
predicting life expectancy based on exercise habits. We might split the
predictor space into **exercises less than one hour a week** and
**exercises at least one hour a week** and then predict that people in
the second group live longer.

How do we decide whether to split at one hour, one and a half hours, two
hours, etc? This decision is made using a method called “Recursive
Binary Splitting”, which we don’t have to worry about too much because
the *caret* package does it for us.

Ensemble tree models fit lots of trees and then average their results.
Here I have created a basic non-ensemble tree to model bicycle rentals.

#### Tuning Parameter

This model has one “tuning parameter” called *cp*. *cp* stands for
“Complexity Parameter”, and it controls the number of “nodes” that the
tree has.

The life expectancy example above has two terminal nodes: **less than
one hour** and **at least one hour**. We could complicate the example by
adding additional nodes. For instance, we could divide the group **less
than one hour** into two subgroups: **less than half an hour** and
**greater than half an hour but less than one hour**. And we could
divide **at least one hour a week** into **less than two hours but at
least one hour** and **greater than two hours**.

Sometimes increasing the number of nodes makes your model better, but
sometimes it makes it worse. There are lots of different methods for
picking the best number of nodes. For the bicycle rental model, I used a
method called “Leave One Out Cross Validation”.

*LOOCV* works by removing an observation from the data set, using the
rest of the data to create a model, and then seeing how well that model
does at predicting the observation that was left out. This process is
repeated for every observation, and the results are combined.

If we want to compare two different values of *cp*, we will go through
the *LOOCV* process twice and compare the results. In this way, we can
test different values of *cp* to see which one performs best.

I used the *caret* package to test 10 different values of *cp*.

#### Formula

The formula that is used to build the models is below. As previously
mentioned, *holiday* will be dropped from the models for Saturday and
Sunday, but kept in the models for weekdays.

``` r
if(params$day == "Saturday" | params$day == "Sunday"){
  form <- formula(cnt ~ yr + mnth + hr + temp + hum + windspeed, showEnv = FALSE)
} else if(params$day %in% c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")){
  form <- formula(cnt ~ yr + mnth + hr + holiday + temp + hum + windspeed, showEnv = FALSE)
} else{
  stop("error")
}

form
```

    ## cnt ~ yr + mnth + hr + holiday + temp + hum + windspeed
    ## <environment: 0x7f9e06e374a8>

#### Create the Model

Train the non-ensemble tree model using the above formula.

``` r
set.seed(123)
tree <- train(form, 
              data = train, 
              method = "rpart", 
              trControl = trainControl(method = "LOOCV"), 
              tuneLength = 10)
```

### Model Information

My final non-ensemble tree model uses a *cp* of 0.0117696. Its root mean
square error on the training set is 95.5422367.

More information about this model is below.

``` r
tree
```

    ## CART 
    ## 
    ## 1719 samples
    ##    7 predictor
    ## 
    ## No pre-processing
    ## Resampling: Leave-One-Out Cross-Validation 
    ## Summary of sample sizes: 1718, 1718, 1718, 1718, 1718, 1718, ... 
    ## Resampling results across tuning parameters:
    ## 
    ##   cp          RMSE       Rsquared     MAE      
    ##   0.01176962   95.54224  0.735780760   66.12993
    ##   0.01280478   97.17754  0.726516805   68.77486
    ##   0.01716169  102.48056  0.696130737   73.90667
    ##   0.02307597  106.45261  0.672225709   74.37923
    ##   0.02434265  111.38036  0.642278565   77.43030
    ##   0.02900421  117.88931  0.599765135   80.33408
    ##   0.03029094  119.63766  0.585999875   83.31669
    ##   0.05575980  126.51914  0.536961905   89.19741
    ##   0.08353242  165.25591  0.230081400  118.32685
    ##   0.31082120  190.87334  0.001488831  164.33395
    ## 
    ## RMSE was used to select the optimal model using the smallest value.
    ## The final value used for the model was cp = 0.01176962.

``` r
rpart.plot(tree$finalModel)
```

![](Tuesday_files/figure-gfm/Train%20Tree%20Info-1.png)<!-- -->

## Boosted Tree

### Training

#### Boosted Tree Models

Boosted trees are another type of tree model. “Boosting” works by
fitting a series of trees, each of which is a modified version of the
previous tree. The idea is to hone in on the best model.

#### Tuning Paremeters

Four tuning parameters are involved:  
\- *n.trees*: number of boosting iterations  
\- *interaction.depth*: maximum tree depth  
\- *shrinkage*: how strongly each subsequent tree is influenced by the
previous tree  
\- *n.minobsinnode*: minimum terminal node size

Values for the tuning parameters are found using Cross Validation. Cross
Validation works by splitting the data into groups called “folds”. One
fold is left out, the rest are used to create a model, and then that
model is tested on the fold that was left out. This process is repeated
for each fold, and the results are combined. It should be clear that
*LOOCV* is just *CV* with the number of folds equal to the number of
observations.

I used the *caret* package to test 81 different combinations of tuning
parameters.

#### Create the Model

Train the boosted tree model using the same formula as above.

``` r
tuneGr <- expand.grid(n.trees = seq(from = 50, to = 150, by = 50), 
                     interaction.depth = 1:3, 
                     shrinkage = seq(from = .05, to = .15, by = .05), 
                     n.minobsinnode = 9:11)

set.seed(123)
boostTree <- train(form, 
                   data = train, 
                   method = "gbm", 
                   trControl = trainControl(method = "cv", number = 10),
                   tuneGrid = tuneGr, 
                   verbose = FALSE)
```

### Model Information

My final boosted tree model uses the following tuning parameters:

  - *n.trees*: 150  
  - *interaction.depth*: 3  
  - *shrinkage*: 0.15  
  - *n.minobsinnode*: 9

Its root mean square error on the training set is 52.8398785.

More information about this model is below.

``` r
boostTree
```

    ## Stochastic Gradient Boosting 
    ## 
    ## 1719 samples
    ##    7 predictor
    ## 
    ## No pre-processing
    ## Resampling: Cross-Validated (10 fold) 
    ## Summary of sample sizes: 1547, 1546, 1547, 1547, 1547, 1548, ... 
    ## Resampling results across tuning parameters:
    ## 
    ##   shrinkage  interaction.depth  n.minobsinnode  n.trees  RMSE       Rsquared   MAE      
    ##   0.05       1                   9               50      142.93881  0.4913126  100.71648
    ##   0.05       1                   9              100      127.94934  0.5888566   87.20425
    ##   0.05       1                   9              150      119.28811  0.6326994   81.11627
    ##   0.05       1                  10               50      142.95117  0.4847950  100.85188
    ##   0.05       1                  10              100      128.01989  0.5865467   87.26382
    ##   0.05       1                  10              150      119.27567  0.6315924   81.24478
    ##   0.05       1                  11               50      142.87915  0.4884751  100.90553
    ##   0.05       1                  11              100      127.90947  0.5890752   87.24642
    ##   0.05       1                  11              150      119.19266  0.6319919   81.10529
    ##   0.05       2                   9               50      114.47490  0.6909219   77.96806
    ##   0.05       2                   9              100       91.35397  0.7925848   59.21020
    ##   0.05       2                   9              150       76.98180  0.8460377   50.60744
    ##   0.05       2                  10               50      114.38832  0.6937829   77.70959
    ##   0.05       2                  10              100       90.75250  0.7960519   58.85432
    ##   0.05       2                  10              150       76.87425  0.8468176   50.56211
    ##   0.05       2                  11               50      114.12153  0.6943391   77.62049
    ##   0.05       2                  11              100       91.27227  0.7926161   59.22069
    ##   0.05       2                  11              150       77.43347  0.8441463   51.02006
    ##   0.05       3                   9               50       99.04092  0.7865988   67.84991
    ##   0.05       3                   9              100       74.11126  0.8645129   48.58318
    ##   0.05       3                   9              150       64.33321  0.8903515   42.10756
    ##   0.05       3                  10               50       98.51078  0.7883948   67.64627
    ##   0.05       3                  10              100       73.47301  0.8667276   48.36395
    ##   0.05       3                  10              150       63.77102  0.8921194   41.94582
    ##   0.05       3                  11               50       98.85528  0.7897226   68.07596
    ##   0.05       3                  11              100       73.72870  0.8663982   48.65838
    ##   0.05       3                  11              150       63.80910  0.8917031   41.87413
    ##   0.10       1                   9               50      127.67027  0.5893921   87.04559
    ##   0.10       1                   9              100      112.61650  0.6715698   76.49997
    ##   0.10       1                   9              150      103.28471  0.7243086   70.15460
    ##   0.10       1                  10               50      127.70063  0.5893213   87.20270
    ##   0.10       1                  10              100      112.69520  0.6724600   76.50707
    ##   0.10       1                  10              150      103.25491  0.7261421   69.97405
    ##   0.10       1                  11               50      127.48567  0.5890098   86.94354
    ##   0.10       1                  11              100      112.65032  0.6738293   76.54943
    ##   0.10       1                  11              150      103.13088  0.7253008   70.12174
    ##   0.10       2                   9               50       90.08958  0.7981628   58.39801
    ##   0.10       2                   9              100       71.31929  0.8611319   47.10690
    ##   0.10       2                   9              150       66.59252  0.8753937   44.35286
    ##   0.10       2                  10               50       90.40151  0.7951881   58.50213
    ##   0.10       2                  10              100       71.05520  0.8623474   47.02891
    ##   0.10       2                  10              150       66.43458  0.8752852   44.20708
    ##   0.10       2                  11               50       90.23767  0.7985369   58.59299
    ##   0.10       2                  11              100       71.16717  0.8616433   47.36249
    ##   0.10       2                  11              150       66.86798  0.8738931   44.57685
    ##   0.10       3                   9               50       74.20756  0.8625207   49.19939
    ##   0.10       3                   9              100       59.53798  0.9019740   39.38927
    ##   0.10       3                   9              150       55.10738  0.9134808   36.08242
    ##   0.10       3                  10               50       73.78623  0.8648763   49.11135
    ##   0.10       3                  10              100       59.61969  0.9021615   39.11655
    ##   0.10       3                  10              150       55.77154  0.9114147   36.52824
    ##   0.10       3                  11               50       72.51357  0.8684337   48.05074
    ##   0.10       3                  11              100       59.71608  0.9009488   39.25599
    ##   0.10       3                  11              150       55.53833  0.9115161   36.20884
    ##   0.15       1                   9               50      118.63895  0.6324577   80.90468
    ##   0.15       1                   9              100      103.02574  0.7248683   69.98570
    ##   0.15       1                   9              150       93.48735  0.7677019   63.79414
    ##   0.15       1                  10               50      118.92449  0.6300194   80.68261
    ##   0.15       1                  10              100      102.97532  0.7268770   70.09364
    ##   0.15       1                  10              150       93.44820  0.7697115   63.95015
    ##   0.15       1                  11               50      118.54913  0.6364731   80.88680
    ##   0.15       1                  11              100      102.84764  0.7268072   70.27497
    ##   0.15       1                  11              150       93.16724  0.7714027   63.81493
    ##   0.15       2                   9               50       75.95039  0.8491982   50.20722
    ##   0.15       2                   9              100       66.52441  0.8745510   44.59841
    ##   0.15       2                   9              150       63.91532  0.8828278   43.08437
    ##   0.15       2                  10               50       76.63716  0.8466978   50.79613
    ##   0.15       2                  10              100       66.86175  0.8734983   44.73317
    ##   0.15       2                  10              150       64.45695  0.8805812   43.21193
    ##   0.15       2                  11               50       76.91237  0.8436220   50.54742
    ##   0.15       2                  11              100       67.11200  0.8727023   44.92140
    ##   0.15       2                  11              150       64.36505  0.8810851   43.50284
    ##   0.15       3                   9               50       63.66779  0.8902798   41.86205
    ##   0.15       3                   9              100       55.18217  0.9127564   36.06401
    ##   0.15       3                   9              150       52.83988  0.9196179   34.26809
    ##   0.15       3                  10               50       63.20707  0.8922060   41.93266
    ##   0.15       3                  10              100       55.22837  0.9125157   36.27501
    ##   0.15       3                  10              150       53.06553  0.9184500   34.56696
    ##   0.15       3                  11               50       63.35543  0.8914442   42.03256
    ##   0.15       3                  11              100       55.93081  0.9101148   36.86201
    ##   0.15       3                  11              150       54.10201  0.9151441   35.27858
    ## 
    ## RMSE was used to select the optimal model using the smallest value.
    ## The final values used for the model were n.trees = 150, interaction.depth = 3, shrinkage = 0.15 and n.minobsinnode
    ##  = 9.

## Multiple Linear Regression

### Training

#### Create the Model

``` r
mlr <- lm(form, data = train)
```

# Test Models

I tested the models on the test set and selected the model that
performed best.

Performance was measured using Root Mean Square Error, which is a
measure of how close the model gets to correctly predicting the test
data. The RMSE for each model is displayed below.

``` r
treePreds <- predict(tree, test)
treeRMSE <- postResample(treePreds, test$cnt)[1]

boostPreds <- predict(boostTree, test)
boostRMSE <- postResample(boostPreds, test$cnt)[1]

mlrPreds <- predict(mlr, test)
mlrRMSE <- postResample(mlrPreds, test$cnt)[1]

modelPerformance <- data.frame(model = c("Non-Ensemble Tree", "Boosted Tree", "MLR"), 
                               trainRMSE = c(min(tree$results$RMSE), min(boostTree$results$RMSE),
                                             summary(mlr)$sigma), 
                               testRMSE = c(treeRMSE, boostRMSE, mlrRMSE))

modelPerformance %>% kable(col.names = c("Model", "Train RMSE", "Test RMSE"))
```

| Model             | Train RMSE | Test RMSE |
| :---------------- | ---------: | --------: |
| Non-Ensemble Tree |   95.54224 |  98.39942 |
| Boosted Tree      |   52.83988 |  54.12700 |
| MLR               |  150.38621 | 157.30329 |

# Best Model

``` r
best <- modelPerformance %>% filter(testRMSE == min(testRMSE))
worst <- modelPerformance %>% filter(testRMSE == max(testRMSE))
```

The boosted tree performs better than the mlr as judged by RMSE on the
test set.

The boosted tree model is saved to the `final` object below.

``` r
if(best$model == "Non-Ensemble Tree"){
  final <- tree
} else if(best$model == "Boosted Tree"){
  final <- boostTree
} else{
  stop("Error")
}

final$finalModel
```

    ## A gradient boosted model with gaussian loss function.
    ## 150 iterations were performed.
    ## There were 17 predictors of which 16 had non-zero influence.
