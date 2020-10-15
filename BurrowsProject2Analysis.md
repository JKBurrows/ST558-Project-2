Joshua Burrows Project 2
================
16 October 2020

  - [Bike Rentals on Mondays:
    Introduction](#bike-rentals-on-mondays-introduction)
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
          - [Windspeed](#windspeed)
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
              - [Create the Model](#create-the-model)
          - [Model Information](#model-information)
      - [Boosted Tree](#boosted-tree)
          - [Training](#training-1)
              - [Boosted Tree Models](#boosted-tree-models)
              - [Tuning Paremeters](#tuning-paremeters)
              - [Create the Model](#create-the-model-1)
          - [Model Information](#model-information-1)
  - [Test Models](#test-models)
  - [Best Model](#best-model)

# Bike Rentals on Mondays: Introduction

This document walks though the process of creating a model to predict
hourly bike rentals on mondays. I compared two models - a *non-ensemble
tree* and a *boosted tree* - and picked the one that does better.

The data comes from the Capital bike sharing system, and it is available
[here](https://archive.ics.uci.edu/ml/datasets/Bike+Sharing+Dataset).
This data includes an hourly count of bike rentals for 2011 and 2012 as
well as information about the weather and the time of year.

My models use the following predictor variables:

  - yr: year (2011 or 2012)  
  - mnth: month  
  - hr: hour of the day  
  - holiday: whether the day is a holiday  
  - weathersit: weather condition
      - pleasant: clear, few clouds, partly cloudy  
      - less pleasant: mist, mist + cloudy, mist + broken clouds, mist +
        few clouds  
      - even less pleasant: light snow, light Rain + scattered clouds,
        light rain + thunderstorm + scattered clouds  
      - downright unpleasant: snow + fog, heavy rain + ice pallets +
        thunderstorm + mist  
  - temp: normalized temperature in celsius  
  - hum: normalized humidity  
  - windspeed: normalized windspeed

You can return to the homepage for this project by clicking
[here](README.md).

# Read in Data

## Get Bikes Data

Read in data.

``` r
bikes <- read_csv(file = "../Bike-Sharing-Dataset/hour.csv")

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

Grab the data for monday.

``` r
dayData <- bikes %>% filter(weekday == params$day)

dayData %>% head() %>% kable()
```

| instant | dteday     | season | yr   | mnth | hr | holiday | weekday | workingday | weathersit | temp |  atemp |  hum | windspeed | casual | registered | cnt |
| ------: | :--------- | :----- | :--- | :--- | -: | :------ | :------ | :--------- | :--------- | ---: | -----: | ---: | --------: | -----: | ---------: | --: |
|      48 | 2011-01-03 | winter | 2011 | jan  |  0 | no      | Monday  | yes        | pleasant   | 0.22 | 0.1970 | 0.44 |    0.3582 |      0 |          5 |   5 |
|      49 | 2011-01-03 | winter | 2011 | jan  |  1 | no      | Monday  | yes        | pleasant   | 0.20 | 0.1667 | 0.44 |    0.4179 |      0 |          2 |   2 |
|      50 | 2011-01-03 | winter | 2011 | jan  |  4 | no      | Monday  | yes        | pleasant   | 0.16 | 0.1364 | 0.47 |    0.3881 |      0 |          1 |   1 |
|      51 | 2011-01-03 | winter | 2011 | jan  |  5 | no      | Monday  | yes        | pleasant   | 0.16 | 0.1364 | 0.47 |    0.2836 |      0 |          3 |   3 |
|      52 | 2011-01-03 | winter | 2011 | jan  |  6 | no      | Monday  | yes        | pleasant   | 0.14 | 0.1061 | 0.50 |    0.3881 |      0 |         30 |  30 |
|      53 | 2011-01-03 | winter | 2011 | jan  |  7 | no      | Monday  | yes        | pleasant   | 0.14 | 0.1364 | 0.50 |    0.1940 |      1 |         63 |  64 |

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

![](BurrowsProject2Analysis_files/figure-gfm/Correlation-1.png)<!-- -->

### Hour

Create a scatter plot to investigate the relationship between time of
day and rentals on mondays. Fit a line through the points to get a basic
idea of their relationship.

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

![](BurrowsProject2Analysis_files/figure-gfm/Hour-1.png)<!-- -->

The correlation between hour and average rentals is 0.5174182.

Be careful, correlation measures straight line relationships, so if the
plot above shows a curved relationship, correlation may not be a useful
measure.

### Temperature

Create a scatter plot to investigate the relationship between
temperature and number of rentals on mondays. Fit a line through the
points to get a basic idea of their relationship.

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

![](BurrowsProject2Analysis_files/figure-gfm/Temp-1.png)<!-- -->

The correlation between temperature and average rentals is 0.8297901.

Be careful, correlation measures straight line relationships, so if the
plot above shows a curved relationship, correlation may not be a useful
measure.

### Felt Temperature

Create a scatter plot to investigate the relationship between felt
temperature and number of rentals on mondays. Fit a line through the
points to get a basic idea of their relationship.

The size of the dots represents the number of observations at each felt
temperatrure.

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

![](BurrowsProject2Analysis_files/figure-gfm/aTemp-1.png)<!-- -->

The correlation between felt temperature and average rentals is
0.8723605.

Be careful, correlation measures straight line relationships, so if the
plot above shows a curved relationship, correlation may not be a useful
measure.

### Humidity

Create a scatter plot to investigate the relationship between humidity
and number of rentals on mondays. Fit a line through the points to get a
basic idea of their relationship.

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

![](BurrowsProject2Analysis_files/figure-gfm/Hum-1.png)<!-- -->

The correlation between humidity and average rentals is -0.5675301.

Be careful, correlation measures straight line relationships, so if the
plot above shows a curved relationship, correlation may not be a useful
measure.

### Windspeed

Create a scatter plot to investigate the relationship between windspeed
and number of rentals on mondays. Fit a line through the points to get a
basic idea of their relationship.

The size of the dots represents the number of observations at each
windspeed.

``` r
windAvg <- dayData %>% 
  group_by(windspeed) %>% 
  summarize(avgRentals = mean(cnt), n = n())

corrWind <- cor(windAvg$windspeed, windAvg$avgRentals)

ggplot(windAvg, aes(x = windspeed, y = avgRentals)) + 
  geom_point(aes(size = n)) + 
  geom_smooth() + 
  labs(title = paste0("Average Rentals on ", paste0(params$day, "s"), " by Windspeed"), 
       x = "Normalized Windspeed", 
       y = "Average Rentals") + 
  scale_size_continuous(name = "Number of Obs")
```

![](BurrowsProject2Analysis_files/figure-gfm/Wind-1.png)<!-- -->

The correlation between windspeed and average rentals is 0.552632.

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

Explore how bike rentals on mondays change with the seasons using a
basic numeric summary and a boxplot. The boxplot can be used to identify
outliers.

It does not make much sense to keep both *season* and *mnth* in the
model, so I decided to eliminate *season*.

``` r
getSum(varName = "season", colName = "Season")
```

| Season | Minimum | 1st Quartile | Median |     Mean | 3rd Quartile | Maximum | Number of Observations |
| :----- | ------: | -----------: | -----: | -------: | -----------: | ------: | ---------------------: |
| winter |       1 |        19.75 |   71.5 | 104.2010 |       147.25 |     801 |                    612 |
| spring |       1 |        46.00 |  157.5 | 191.3898 |       274.00 |     834 |                    644 |
| summer |       1 |        56.50 |  189.0 | 234.8427 |       341.00 |     968 |                    623 |
| fall   |       2 |        47.75 |  166.0 | 203.6167 |       302.00 |     922 |                    600 |

``` r
ggplot(dayData, aes(x = season, y = cnt)) + 
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Season"), 
       x = "Season", 
       y = "Number of Rentals") 
```

![](BurrowsProject2Analysis_files/figure-gfm/Season-1.png)<!-- -->

### Year

Looking at total rentals each year gives us some idea of the long term
trend in bike rentals on mondays. It would be helpful to have data from
more years, though.

``` r
yearSum <- dayData %>% 
  group_by(yr) %>% 
  summarize(totalRentals = sum(cnt))

yearSum %>% kable(col.names = c("Year", "Total Rentals"))
```

| Year | Total Rentals |
| :--- | ------------: |
| 2011 |        180221 |
| 2012 |        275282 |

### Month

Explore how bike rentals on mondays change depending on the month using
a basic numeric summary and a boxplot. The boxplot can be used to
identify outliers.

As already noted, it is probably not worth including *mnth* and *season*
in the model, so *season* has been eliminated.

``` r
getSum(varName = "mnth", colName = "Month")
```

| Month | Minimum | 1st Quartile | Median |      Mean | 3rd Quartile | Maximum | Number of Observations |
| :---- | ------: | -----------: | -----: | --------: | -----------: | ------: | ---------------------: |
| jan   |       1 |        17.75 |   61.0 |  81.64407 |       116.25 |     493 |                    236 |
| feb   |       1 |        25.00 |   80.0 | 110.82447 |       154.25 |     529 |                    188 |
| mar   |       1 |        30.75 |   99.5 | 150.87766 |       223.00 |     801 |                    188 |
| apr   |       1 |        46.50 |  157.0 | 189.91589 |       279.50 |     729 |                    214 |
| may   |       2 |        59.00 |  170.5 | 188.01389 |       270.50 |     769 |                    216 |
| jun   |       1 |        45.25 |  182.5 | 228.26042 |       316.00 |     834 |                    192 |
| jul   |       2 |        61.75 |  201.5 | 241.31481 |       367.00 |     872 |                    216 |
| aug   |       1 |        59.75 |  192.5 | 229.93056 |       293.00 |     893 |                    216 |
| sep   |       2 |        54.50 |  187.0 | 236.10995 |       342.50 |     968 |                    191 |
| oct   |       2 |        51.00 |  174.0 | 213.47465 |       322.00 |     922 |                    217 |
| nov   |       2 |        47.00 |  152.0 | 195.11518 |       277.50 |     663 |                    191 |
| dec   |       1 |        23.25 |  113.0 | 147.09813 |       213.25 |     731 |                    214 |

``` r
ggplot(dayData, aes(x = mnth, y = cnt)) + 
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Month"), 
       x = "Month", 
       y = "Number of Rentals")
```

![](BurrowsProject2Analysis_files/figure-gfm/Month-1.png)<!-- -->

### Holiday

Explore how bike rentals change depending on whether the monday in
question is a holiday using a basic numeric summary and a boxplot. The
boxplot can be used to identify outliers.

Note: There are no holidays on Saturday or Sunday because the holiday
data has been extracted from the [Washington D.C. HR department’s
holiday schedule](https://dchr.dc.gov/page/holiday-schedules), which
only lists holidays that fall during the work week.

``` r
getSum(varName = "holiday", colName = "Holiday")
```

| Holiday | Minimum | 1st Quartile | Median |     Mean | 3rd Quartile | Maximum | Number of Observations |
| :------ | ------: | -----------: | -----: | -------: | -----------: | ------: | ---------------------: |
| no      |       1 |           37 |  142.5 | 186.5683 |       266.75 |     968 |                   2122 |
| yes     |       1 |           31 |  100.0 | 166.9608 |       281.00 |     712 |                    357 |

``` r
ggplot(dayData, aes(x = holiday, y = cnt)) + 
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Holiday"), 
       x = "Is it a Holiday?", 
       y = "Number of Rentals")
```

![](BurrowsProject2Analysis_files/figure-gfm/Holiday-1.png)<!-- -->

### Working Day

Explore how bike rentals change depending on whether the day in question
is a working day using a basic numeric summary and a boxplot. The
boxplot can be used to identify outliers.

Working days are neither weekends nor holidays. I decided not to keep
this variable in the model because it wouldn’t make much sense in the
reports for Saturday and Sunday.

``` r
getSum(varName = "workingday", colName = "Working Day")
```

| Working Day | Minimum | 1st Quartile | Median |     Mean | 3rd Quartile | Maximum | Number of Observations |
| :---------- | ------: | -----------: | -----: | -------: | -----------: | ------: | ---------------------: |
| no          |       1 |           31 |  100.0 | 166.9608 |       281.00 |     712 |                    357 |
| yes         |       1 |           37 |  142.5 | 186.5683 |       266.75 |     968 |                   2122 |

``` r
ggplot(dayData, aes(x = workingday, y = cnt)) +
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Working Day"), 
       x = "Is it a Working Day?", 
       y = "Number of Rentals")
```

![](BurrowsProject2Analysis_files/figure-gfm/Workingday-1.png)<!-- -->

### Weather Condition

Explore how bike rentals on mondays change depending on the weather
using a basic numeric summary and a boxplot. The boxplot can be used to
identify outliers.

``` r
getSum(varName = "weathersit", colName = "Weather Condition")
```

| Weather Condition    | Minimum | 1st Quartile | Median |     Mean | 3rd Quartile | Maximum | Number of Observations |
| :------------------- | ------: | -----------: | -----: | -------: | -----------: | ------: | ---------------------: |
| pleasant             |       1 |           32 |    145 | 191.8439 |       281.75 |     968 |                   1582 |
| less pleasant        |       1 |           57 |    139 | 181.6570 |       254.50 |     842 |                    726 |
| even less pleasant   |       1 |           20 |     70 | 117.4059 |       171.75 |     856 |                    170 |
| downright unpleasant |     164 |          164 |    164 | 164.0000 |       164.00 |     164 |                      1 |

``` r
ggplot(dayData, aes(x = weathersit, y = cnt)) +
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Weather Condition"), 
       x = "What is the Weather Like?", 
       y = "Number of Rentals")
```

![](BurrowsProject2Analysis_files/figure-gfm/Weather-1.png)<!-- -->

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

#### Create the Model

``` r
set.seed(123)
tree <- train(cnt ~ yr + mnth + hr + holiday + weathersit + temp + hum + windspeed, 
              data = train, 
              method = "rpart", 
              trControl = trainControl(method = "LOOCV"), 
              tuneLength = 10)
```

### Model Information

My final non-ensemble tree model uses a *cp* of 0.0090975. Its root mean
square error on the training set is 92.1064636.

More information about this model is below.

``` r
tree
```

    ## CART 
    ## 
    ## 1737 samples
    ##    8 predictor
    ## 
    ## No pre-processing
    ## Resampling: Leave-One-Out Cross-Validation 
    ## Summary of sample sizes: 1736, 1736, 1736, 1736, 1736, 1736, ... 
    ## Resampling results across tuning parameters:
    ## 
    ##   cp           RMSE       Rsquared     MAE      
    ##   0.009097489   92.10646  0.741114351   63.39225
    ##   0.009201394   92.40338  0.739339338   63.90371
    ##   0.014605347  101.97007  0.683146088   72.30808
    ##   0.015984558  100.40490  0.692212872   69.79485
    ##   0.016840713  105.03346  0.663572296   75.78070
    ##   0.028104739  116.70417  0.585312711   81.97684
    ##   0.028394545  115.48244  0.593375831   80.33306
    ##   0.039063065  120.29923  0.559516925   83.15185
    ##   0.093708081  165.06099  0.209623759  119.95018
    ##   0.307902102  185.46134  0.001849726  159.71931
    ## 
    ## RMSE was used to select the optimal model using the smallest value.
    ## The final value used for the model was cp = 0.009097489.

``` r
plot(tree$finalModel)
text(tree$finalModel)
```

![](BurrowsProject2Analysis_files/figure-gfm/Train%20Tree%20Info-1.png)<!-- -->

``` r
rpart.plot(tree$finalModel)
```

![](BurrowsProject2Analysis_files/figure-gfm/Train%20Tree%20Info-2.png)<!-- -->

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

``` r
tuneGr <- expand.grid(n.trees = seq(from = 50, to = 150, by = 50), 
                     interaction.depth = 1:3, 
                     shrinkage = seq(from = .05, to = .15, by = .05), 
                     n.minobsinnode = 9:11)

set.seed(123)
boostTree <- train(cnt ~ yr + mnth + hr + holiday + weathersit + temp + hum + windspeed, 
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

Its root mean square error on the training set is 58.0090856.

More information about this model is below.

``` r
boostTree
```

    ## Stochastic Gradient Boosting 
    ## 
    ## 1737 samples
    ##    8 predictor
    ## 
    ## No pre-processing
    ## Resampling: Cross-Validated (10 fold) 
    ## Summary of sample sizes: 1563, 1564, 1563, 1564, 1564, 1564, ... 
    ## Resampling results across tuning parameters:
    ## 
    ##   shrinkage  interaction.depth  n.minobsinnode  n.trees  RMSE       Rsquared 
    ##   0.05       1                   9               50      139.10699  0.4917589
    ##   0.05       1                   9              100      124.14296  0.5948604
    ##   0.05       1                   9              150      115.44256  0.6348989
    ##   0.05       1                  10               50      139.17850  0.4920665
    ##   0.05       1                  10              100      124.13518  0.5947841
    ##   0.05       1                  10              150      115.46802  0.6346048
    ##   0.05       1                  11               50      139.04073  0.4988459
    ##   0.05       1                  11              100      123.99270  0.5945396
    ##   0.05       1                  11              150      115.36211  0.6358622
    ##   0.05       2                   9               50      113.26356  0.6744069
    ##   0.05       2                   9              100       95.75593  0.7437194
    ##   0.05       2                   9              150       85.27838  0.7923848
    ##   0.05       2                  10               50      113.46989  0.6758476
    ##   0.05       2                  10              100       95.25869  0.7471785
    ##   0.05       2                  10              150       85.32323  0.7926921
    ##   0.05       2                  11               50      113.01675  0.6797561
    ##   0.05       2                  11              100       95.92753  0.7433892
    ##   0.05       2                  11              150       85.29720  0.7927797
    ##   0.05       3                   9               50       99.87898  0.7476982
    ##   0.05       3                   9              100       80.48751  0.8202186
    ##   0.05       3                   9              150       71.53177  0.8530196
    ##   0.05       3                  10               50       99.37903  0.7496427
    ##   0.05       3                  10              100       80.86046  0.8177818
    ##   0.05       3                  10              150       71.47324  0.8527619
    ##   0.05       3                  11               50       99.25140  0.7526865
    ##   0.05       3                  11              100       80.93101  0.8174557
    ##   0.05       3                  11              150       71.51527  0.8528877
    ##   0.10       1                   9               50      123.97624  0.5935182
    ##   0.10       1                   9              100      109.89606  0.6584907
    ##   0.10       1                   9              150      103.05656  0.6956395
    ##   0.10       1                  10               50      123.67853  0.5978181
    ##   0.10       1                  10              100      109.78544  0.6604753
    ##   0.10       1                  10              150      103.03410  0.6958958
    ##   0.10       1                  11               50      123.89323  0.5950989
    ##   0.10       1                  11              100      110.02529  0.6587149
    ##   0.10       1                  11              150      103.03399  0.6963856
    ##   0.10       2                   9               50       94.76740  0.7492786
    ##   0.10       2                   9              100       80.03984  0.8125464
    ##   0.10       2                   9              150       75.09228  0.8309288
    ##   0.10       2                  10               50       95.37636  0.7465566
    ##   0.10       2                  10              100       80.20246  0.8108710
    ##   0.10       2                  10              150       75.63760  0.8280072
    ##   0.10       2                  11               50       94.94776  0.7469012
    ##   0.10       2                  11              100       80.39293  0.8110463
    ##   0.10       2                  11              150       75.75371  0.8278348
    ##   0.10       3                   9               50       80.74620  0.8176043
    ##   0.10       3                   9              100       67.06186  0.8667430
    ##   0.10       3                   9              150       62.13539  0.8841140
    ##   0.10       3                  10               50       80.59360  0.8169992
    ##   0.10       3                  10              100       67.54049  0.8650108
    ##   0.10       3                  10              150       61.93553  0.8848741
    ##   0.10       3                  11               50       80.55644  0.8183353
    ##   0.10       3                  11              100       66.87907  0.8678704
    ##   0.10       3                  11              150       61.65631  0.8854535
    ##   0.15       1                   9               50      114.96371  0.6354696
    ##   0.15       1                   9              100      102.58442  0.6984019
    ##   0.15       1                   9              150       96.08466  0.7308919
    ##   0.15       1                  10               50      115.05071  0.6354221
    ##   0.15       1                  10              100      102.84892  0.6979313
    ##   0.15       1                  10              150       96.44169  0.7286301
    ##   0.15       1                  11               50      114.97007  0.6344673
    ##   0.15       1                  11              100      102.75450  0.6967385
    ##   0.15       1                  11              150       96.39704  0.7295601
    ##   0.15       2                   9               50       84.43799  0.7958779
    ##   0.15       2                   9              100       75.34297  0.8297827
    ##   0.15       2                   9              150       71.86133  0.8435770
    ##   0.15       2                  10               50       84.34552  0.7942972
    ##   0.15       2                  10              100       74.92577  0.8313117
    ##   0.15       2                  10              150       72.19121  0.8425347
    ##   0.15       2                  11               50       84.14866  0.7963517
    ##   0.15       2                  11              100       75.59430  0.8284746
    ##   0.15       2                  11              150       72.51875  0.8406917
    ##   0.15       3                   9               50       71.70147  0.8513863
    ##   0.15       3                   9              100       62.51294  0.8825897
    ##   0.15       3                   9              150       58.00909  0.8980189
    ##   0.15       3                  10               50       71.89154  0.8505190
    ##   0.15       3                  10              100       62.23050  0.8837465
    ##   0.15       3                  10              150       58.36406  0.8968884
    ##   0.15       3                  11               50       72.60173  0.8461003
    ##   0.15       3                  11              100       62.86697  0.8809712
    ##   0.15       3                  11              150       58.73145  0.8954142
    ##   MAE     
    ##   99.16546
    ##   86.46193
    ##   80.34819
    ##   99.17143
    ##   86.29446
    ##   80.28660
    ##   99.14135
    ##   86.10643
    ##   80.20841
    ##   78.54172
    ##   64.34446
    ##   58.01926
    ##   78.74227
    ##   64.14967
    ##   58.04420
    ##   78.39206
    ##   64.51274
    ##   57.97247
    ##   69.15679
    ##   54.45384
    ##   48.49838
    ##   68.84031
    ##   54.68518
    ##   48.46698
    ##   69.13581
    ##   54.65120
    ##   48.43574
    ##   86.29763
    ##   76.78557
    ##   72.14936
    ##   86.03787
    ##   76.54889
    ##   72.10293
    ##   86.11530
    ##   76.80454
    ##   72.10194
    ##   63.71971
    ##   54.96521
    ##   51.86737
    ##   64.29788
    ##   55.15567
    ##   52.23379
    ##   63.94186
    ##   55.19537
    ##   52.14205
    ##   54.38676
    ##   45.43656
    ##   42.00612
    ##   54.38813
    ##   45.63445
    ##   41.90538
    ##   54.15392
    ##   45.53707
    ##   41.82156
    ##   80.27786
    ##   72.24020
    ##   67.83141
    ##   80.02811
    ##   71.97095
    ##   67.92684
    ##   80.05610
    ##   71.92872
    ##   67.62822
    ##   57.75745
    ##   52.12573
    ##   49.59563
    ##   57.55832
    ##   51.69256
    ##   49.66194
    ##   57.92338
    ##   52.06919
    ##   49.85969
    ##   48.58967
    ##   42.38139
    ##   39.38276
    ##   49.00315
    ##   42.26579
    ##   39.44377
    ##   49.12370
    ##   42.43801
    ##   39.53783
    ## 
    ## RMSE was used to select the optimal model using the smallest value.
    ## The final values used for the model were n.trees = 150, interaction.depth =
    ##  3, shrinkage = 0.15 and n.minobsinnode = 9.

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

modelPerformance <- data.frame(model = c("Non-Ensemble Tree", "Boosted Tree"), 
                               trainRMSE = c(min(tree$results$RMSE), min(boostTree$results$RMSE)), 
                               testRMSE = c(treeRMSE, boostRMSE))

modelPerformance %>% kable(col.names = c("Model", "Train RMSE", "Test RMSE"))
```

| Model             | Train RMSE | Test RMSE |
| :---------------- | ---------: | --------: |
| Non-Ensemble Tree |   92.10646 |  93.87214 |
| Boosted Tree      |   58.00909 |  55.71787 |

# Best Model

``` r
best <- modelPerformance %>% filter(testRMSE == min(testRMSE))
worst <- modelPerformance %>% filter(testRMSE == max(testRMSE))
```

The boosted tree performs better than the non-ensemble tree as judged by
RMSE on the test set.

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
    ## There were 20 predictors of which 19 had non-zero influence.
