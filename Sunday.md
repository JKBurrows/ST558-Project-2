Joshua Burrows Project 2
================
16 October 2020

  - [Bike Rentals on Sundays:
    Introduction](#bike-rentals-on-sundays-introduction)
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

# Bike Rentals on Sundays: Introduction

This document walks though the process of creating a model to predict
hourly bike rentals on sundays. I compared two models - a *non-ensemble
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

Grab the data for sunday.

``` r
dayData <- bikes %>% filter(weekday == params$day)

dayData %>% head() %>% kable()
```

| instant | dteday     | season | yr   | mnth | hr | holiday | weekday | workingday | weathersit         | temp |  atemp |  hum | windspeed | casual | registered | cnt |
| ------: | :--------- | :----- | :--- | :--- | -: | :------ | :------ | :--------- | :----------------- | ---: | -----: | ---: | --------: | -----: | ---------: | --: |
|      25 | 2011-01-02 | winter | 2011 | jan  |  0 | no      | Sunday  | no         | less pleasant      | 0.46 | 0.4545 | 0.88 |    0.2985 |      4 |         13 |  17 |
|      26 | 2011-01-02 | winter | 2011 | jan  |  1 | no      | Sunday  | no         | less pleasant      | 0.44 | 0.4394 | 0.94 |    0.2537 |      1 |         16 |  17 |
|      27 | 2011-01-02 | winter | 2011 | jan  |  2 | no      | Sunday  | no         | less pleasant      | 0.42 | 0.4242 | 1.00 |    0.2836 |      1 |          8 |   9 |
|      28 | 2011-01-02 | winter | 2011 | jan  |  3 | no      | Sunday  | no         | less pleasant      | 0.46 | 0.4545 | 0.94 |    0.1940 |      2 |          4 |   6 |
|      29 | 2011-01-02 | winter | 2011 | jan  |  4 | no      | Sunday  | no         | less pleasant      | 0.46 | 0.4545 | 0.94 |    0.1940 |      2 |          1 |   3 |
|      30 | 2011-01-02 | winter | 2011 | jan  |  6 | no      | Sunday  | no         | even less pleasant | 0.42 | 0.4242 | 0.77 |    0.2985 |      0 |          2 |   2 |

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

![](Sunday_files/figure-gfm/Correlation-1.png)<!-- -->

### Hour

Create a scatter plot to investigate the relationship between time of
day and rentals on sundays. Fit a line through the points to get a basic
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

![](Sunday_files/figure-gfm/Hour-1.png)<!-- -->

The correlation between hour and average rentals is 0.4426479.

Be careful, correlation measures straight line relationships, so if the
plot above shows a curved relationship, correlation may not be a useful
measure.

### Temperature

Create a scatter plot to investigate the relationship between
temperature and number of rentals on sundays. Fit a line through the
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

![](Sunday_files/figure-gfm/Temp-1.png)<!-- -->

The correlation between temperature and average rentals is 0.9710369.

Be careful, correlation measures straight line relationships, so if the
plot above shows a curved relationship, correlation may not be a useful
measure.

### Felt Temperature

Create a scatter plot to investigate the relationship between felt
temperature and number of rentals on sundays. Fit a line through the
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

![](Sunday_files/figure-gfm/aTemp-1.png)<!-- -->

The correlation between felt temperature and average rentals is
0.9046467.

Be careful, correlation measures straight line relationships, so if the
plot above shows a curved relationship, correlation may not be a useful
measure.

### Humidity

Create a scatter plot to investigate the relationship between humidity
and number of rentals on sundays. Fit a line through the points to get a
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

![](Sunday_files/figure-gfm/Hum-1.png)<!-- -->

The correlation between humidity and average rentals is -0.8857646.

Be careful, correlation measures straight line relationships, so if the
plot above shows a curved relationship, correlation may not be a useful
measure.

### Windspeed

Create a scatter plot to investigate the relationship between windspeed
and number of rentals on sundays. Fit a line through the points to get a
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

![](Sunday_files/figure-gfm/Wind-1.png)<!-- -->

The correlation between windspeed and average rentals is -0.2271752.

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

Explore how bike rentals on sundays change with the seasons using a
basic numeric summary and a boxplot. The boxplot can be used to identify
outliers.

It does not make much sense to keep both *season* and *mnth* in the
model, so I decided to eliminate *season*.

``` r
getSum(varName = "season", colName = "Season")
```

| Season | Minimum | 1st Quartile | Median |      Mean | 3rd Quartile | Maximum | Number of Observations |
| :----- | ------: | -----------: | -----: | --------: | -----------: | ------: | ---------------------: |
| winter |       1 |           20 |   59.0 |  94.34953 |       126.75 |     554 |                    638 |
| spring |       2 |           47 |  143.0 | 208.10594 |       358.00 |     686 |                    623 |
| summer |       1 |           73 |  186.0 | 224.36143 |       356.00 |     757 |                    617 |
| fall   |       1 |           50 |  125.5 | 185.49840 |       293.50 |     776 |                    624 |

``` r
ggplot(dayData, aes(x = season, y = cnt)) + 
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Season"), 
       x = "Season", 
       y = "Number of Rentals") 
```

![](Sunday_files/figure-gfm/Season-1.png)<!-- -->

### Year

Looking at total rentals each year gives us some idea of the long term
trend in bike rentals on sundays. It would be helpful to have data from
more years, though.

``` r
yearSum <- dayData %>% 
  group_by(yr) %>% 
  summarize(totalRentals = sum(cnt))

yearSum %>% kable(col.names = c("Year", "Total Rentals"))
```

| Year | Total Rentals |
| :--- | ------------: |
| 2011 |        177074 |
| 2012 |        266953 |

### Month

Explore how bike rentals on sundays change depending on the month using
a basic numeric summary and a boxplot. The boxplot can be used to
identify outliers.

As already noted, it is probably not worth including *mnth* and *season*
in the model, so *season* has been eliminated.

``` r
getSum(varName = "mnth", colName = "Month")
```

| Month | Minimum | 1st Quartile | Median |      Mean | 3rd Quartile | Maximum | Number of Observations |
| :---- | ------: | -----------: | -----: | --------: | -----------: | ------: | ---------------------: |
| jan   |       1 |        18.00 |   55.0 |  76.62025 |       105.00 |     351 |                    237 |
| feb   |       1 |        23.00 |   63.0 |  95.13228 |       154.00 |     353 |                    189 |
| mar   |       2 |        23.00 |   78.5 | 140.46809 |       218.75 |     554 |                    188 |
| apr   |       3 |        36.00 |   95.5 | 184.03704 |       304.50 |     681 |                    216 |
| may   |       5 |        63.25 |  169.5 | 221.67593 |       366.25 |     637 |                    216 |
| jun   |       6 |        85.50 |  209.5 | 247.51562 |       396.25 |     686 |                    192 |
| jul   |       1 |        90.75 |  189.5 | 220.75417 |       346.00 |     628 |                    240 |
| aug   |       1 |        66.00 |  183.0 | 203.37297 |       313.00 |     626 |                    185 |
| sep   |       1 |        78.25 |  187.5 | 256.64815 |       403.25 |     776 |                    216 |
| oct   |       3 |        53.25 |  132.0 | 197.28704 |       322.75 |     675 |                    216 |
| nov   |       2 |        43.75 |  121.5 | 171.92188 |       276.25 |     724 |                    192 |
| dec   |       1 |        27.50 |   85.0 | 114.69302 |       171.50 |     520 |                    215 |

``` r
ggplot(dayData, aes(x = mnth, y = cnt)) + 
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Month"), 
       x = "Month", 
       y = "Number of Rentals")
```

![](Sunday_files/figure-gfm/Month-1.png)<!-- -->

### Holiday

Explore how bike rentals change depending on whether the sunday in
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
| no      |       1 |           40 |    116 | 177.4688 |          288 |     776 |                   2502 |

``` r
ggplot(dayData, aes(x = holiday, y = cnt)) + 
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Holiday"), 
       x = "Is it a Holiday?", 
       y = "Number of Rentals")
```

![](Sunday_files/figure-gfm/Holiday-1.png)<!-- -->

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
| no          |       1 |           40 |    116 | 177.4688 |          288 |     776 |                   2502 |

``` r
ggplot(dayData, aes(x = workingday, y = cnt)) +
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Working Day"), 
       x = "Is it a Working Day?", 
       y = "Number of Rentals")
```

![](Sunday_files/figure-gfm/Workingday-1.png)<!-- -->

### Weather Condition

Explore how bike rentals on sundays change depending on the weather
using a basic numeric summary and a boxplot. The boxplot can be used to
identify outliers.

``` r
getSum(varName = "weathersit", colName = "Weather Condition")
```

| Weather Condition  | Minimum | 1st Quartile | Median |     Mean | 3rd Quartile | Maximum | Number of Observations |
| :----------------- | ------: | -----------: | -----: | -------: | -----------: | ------: | ---------------------: |
| pleasant           |       1 |           49 |    132 | 194.6703 |          314 |     776 |                   1765 |
| less pleasant      |       1 |           28 |     93 | 142.1778 |          230 |     626 |                    568 |
| even less pleasant |       1 |           27 |     68 | 116.4320 |          173 |     626 |                    169 |

``` r
ggplot(dayData, aes(x = weathersit, y = cnt)) +
  geom_boxplot() + 
  labs(title = paste0("Rentals on ", paste0(params$day, "s"), " by Weather Condition"), 
       x = "What is the Weather Like?", 
       y = "Number of Rentals")
```

![](Sunday_files/figure-gfm/Weather-1.png)<!-- -->

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

My final non-ensemble tree model uses a *cp* of 0.0087132. Its root mean
square error on the training set is 76.1406353.

More information about this model is below.

``` r
tree
```

    ## CART 
    ## 
    ## 1752 samples
    ##    8 predictor
    ## 
    ## No pre-processing
    ## Resampling: Leave-One-Out Cross-Validation 
    ## Summary of sample sizes: 1751, 1751, 1751, 1751, 1751, 1751, ... 
    ## Resampling results across tuning parameters:
    ## 
    ##   cp           RMSE       Rsquared    
    ##   0.008713219   76.14064  0.7966962210
    ##   0.009630650   78.16743  0.7857810468
    ##   0.012681059   82.53138  0.7614323260
    ##   0.018030687   85.13892  0.7461702122
    ##   0.024663038   90.50624  0.7127864751
    ##   0.048859856   98.53953  0.6597247949
    ##   0.052167140  106.10045  0.6056775594
    ##   0.116254292  121.14185  0.4948376679
    ##   0.179041235  152.04571  0.2230183908
    ##   0.346949714  177.92031  0.0009529839
    ##   MAE      
    ##    57.54521
    ##    59.06332
    ##    61.29459
    ##    62.39522
    ##    67.53981
    ##    73.50135
    ##    81.78655
    ##    91.05641
    ##   119.91852
    ##   160.02679
    ## 
    ## RMSE was used to select the
    ##  optimal model using the
    ##  smallest value.
    ## The final value used for the model
    ##  was cp = 0.008713219.

``` r
plot(tree$finalModel)
text(tree$finalModel)
```

![](Sunday_files/figure-gfm/Train%20Tree%20Info-1.png)<!-- -->

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

Its root mean square error on the training set is 46.0839684.

More information about this model is below.

``` r
boostTree
```

    ## Stochastic Gradient Boosting 
    ## 
    ## 1752 samples
    ##    8 predictor
    ## 
    ## No pre-processing
    ## Resampling: Cross-Validated (10 fold) 
    ## Summary of sample sizes: 1576, 1576, 1576, 1578, 1577, 1579, ... 
    ## Resampling results across tuning parameters:
    ## 
    ##   shrinkage  interaction.depth
    ##   0.05       1                
    ##   0.05       1                
    ##   0.05       1                
    ##   0.05       1                
    ##   0.05       1                
    ##   0.05       1                
    ##   0.05       1                
    ##   0.05       1                
    ##   0.05       1                
    ##   0.05       2                
    ##   0.05       2                
    ##   0.05       2                
    ##   0.05       2                
    ##   0.05       2                
    ##   0.05       2                
    ##   0.05       2                
    ##   0.05       2                
    ##   0.05       2                
    ##   0.05       3                
    ##   0.05       3                
    ##   0.05       3                
    ##   0.05       3                
    ##   0.05       3                
    ##   0.05       3                
    ##   0.05       3                
    ##   0.05       3                
    ##   0.05       3                
    ##   0.10       1                
    ##   0.10       1                
    ##   0.10       1                
    ##   0.10       1                
    ##   0.10       1                
    ##   0.10       1                
    ##   0.10       1                
    ##   0.10       1                
    ##   0.10       1                
    ##   0.10       2                
    ##   0.10       2                
    ##   0.10       2                
    ##   0.10       2                
    ##   0.10       2                
    ##   0.10       2                
    ##   0.10       2                
    ##   0.10       2                
    ##   0.10       2                
    ##   0.10       3                
    ##   0.10       3                
    ##   0.10       3                
    ##   0.10       3                
    ##   0.10       3                
    ##   0.10       3                
    ##   0.10       3                
    ##   0.10       3                
    ##   0.10       3                
    ##   0.15       1                
    ##   0.15       1                
    ##   0.15       1                
    ##   0.15       1                
    ##   0.15       1                
    ##   0.15       1                
    ##   0.15       1                
    ##   0.15       1                
    ##   0.15       1                
    ##   0.15       2                
    ##   0.15       2                
    ##   0.15       2                
    ##   0.15       2                
    ##   0.15       2                
    ##   0.15       2                
    ##   0.15       2                
    ##   0.15       2                
    ##   0.15       2                
    ##   0.15       3                
    ##   0.15       3                
    ##   0.15       3                
    ##   0.15       3                
    ##   0.15       3                
    ##   0.15       3                
    ##   0.15       3                
    ##   0.15       3                
    ##   0.15       3                
    ##   n.minobsinnode  n.trees  RMSE     
    ##    9               50      116.08121
    ##    9              100       96.67881
    ##    9              150       87.20036
    ##   10               50      115.60250
    ##   10              100       96.55833
    ##   10              150       87.04667
    ##   11               50      115.71276
    ##   11              100       96.53957
    ##   11              150       87.06763
    ##    9               50       83.38828
    ##    9              100       67.97545
    ##    9              150       62.63007
    ##   10               50       83.60997
    ##   10              100       67.97914
    ##   10              150       62.77724
    ##   11               50       83.51833
    ##   11              100       68.07164
    ##   11              150       62.78925
    ##    9               50       70.54146
    ##    9              100       56.96929
    ##    9              150       52.18226
    ##   10               50       70.40512
    ##   10              100       56.91430
    ##   10              150       52.18785
    ##   11               50       71.03115
    ##   11              100       57.21945
    ##   11              150       52.40779
    ##    9               50       96.15235
    ##    9              100       82.12442
    ##    9              150       77.21962
    ##   10               50       96.03494
    ##   10              100       82.02302
    ##   10              150       77.16684
    ##   11               50       96.20011
    ##   11              100       82.21335
    ##   11              150       77.29046
    ##    9               50       68.19143
    ##    9              100       60.05583
    ##    9              150       56.94104
    ##   10               50       68.00450
    ##   10              100       60.00951
    ##   10              150       56.64713
    ##   11               50       68.03244
    ##   11              100       59.68535
    ##   11              150       56.47551
    ##    9               50       56.53149
    ##    9              100       49.60382
    ##    9              150       47.15477
    ##   10               50       57.11276
    ##   10              100       50.01285
    ##   10              150       47.81256
    ##   11               50       56.62891
    ##   11              100       49.78635
    ##   11              150       47.67277
    ##    9               50       86.92354
    ##    9              100       77.53127
    ##    9              150       74.39911
    ##   10               50       86.52942
    ##   10              100       77.13255
    ##   10              150       73.88240
    ##   11               50       86.99139
    ##   11              100       77.38478
    ##   11              150       74.03429
    ##    9               50       62.60936
    ##    9              100       56.27081
    ##    9              150       54.16062
    ##   10               50       62.63218
    ##   10              100       56.46920
    ##   10              150       54.12079
    ##   11               50       62.61150
    ##   11              100       56.47976
    ##   11              150       54.43547
    ##    9               50       52.07586
    ##    9              100       47.64639
    ##    9              150       46.08397
    ##   10               50       52.74553
    ##   10              100       48.43596
    ##   10              150       46.90050
    ##   11               50       52.55416
    ##   11              100       48.14636
    ##   11              150       46.68822
    ##   Rsquared   MAE     
    ##   0.6474695  89.47772
    ##   0.7372006  72.59738
    ##   0.7641346  65.75609
    ##   0.6527233  89.11421
    ##   0.7373100  72.54782
    ##   0.7649467  65.67654
    ##   0.6497846  88.99099
    ##   0.7383157  72.54514
    ##   0.7653507  65.74451
    ##   0.8136608  63.02463
    ##   0.8514564  49.93712
    ##   0.8698609  45.59292
    ##   0.8126519  63.24935
    ##   0.8510492  50.04101
    ##   0.8685750  45.91459
    ##   0.8132137  63.29874
    ##   0.8506392  50.06490
    ##   0.8688496  45.81184
    ##   0.8607531  54.67316
    ##   0.8927923  41.70036
    ##   0.9076729  37.06598
    ##   0.8620460  54.43804
    ##   0.8934476  41.52797
    ##   0.9078860  37.06557
    ##   0.8591684  55.04416
    ##   0.8920326  41.69171
    ##   0.9071834  37.17334
    ##   0.7389194  72.28429
    ##   0.7795243  62.43412
    ##   0.7976171  59.39078
    ##   0.7393389  72.11485
    ##   0.7801854  62.31857
    ##   0.7986468  59.18454
    ##   0.7384737  72.12487
    ##   0.7786459  62.43716
    ##   0.7977483  59.32788
    ##   0.8493172  50.23163
    ##   0.8776464  43.86763
    ##   0.8886358  41.88310
    ##   0.8495814  49.99711
    ##   0.8781094  43.91849
    ##   0.8891981  41.73745
    ##   0.8497975  50.08596
    ##   0.8794313  43.53257
    ##   0.8898748  41.51520
    ##   0.8947183  41.15862
    ##   0.9158092  35.14318
    ##   0.9230974  33.42876
    ##   0.8920845  41.67877
    ##   0.9136357  35.63453
    ##   0.9204660  34.26227
    ##   0.8938471  41.30823
    ##   0.9147100  35.19171
    ##   0.9210115  33.70304
    ##   0.7612003  65.73673
    ##   0.7956620  59.63359
    ##   0.8086617  57.61305
    ##   0.7640860  65.38207
    ##   0.7982587  59.09673
    ##   0.8115833  57.00319
    ##   0.7616753  65.64374
    ##   0.7968353  59.51229
    ##   0.8111723  57.30160
    ##   0.8693152  45.68971
    ##   0.8910663  41.48376
    ##   0.8981924  39.89943
    ##   0.8695081  45.75263
    ##   0.8901703  41.52055
    ##   0.8982119  39.78496
    ##   0.8679354  45.67492
    ##   0.8897904  41.75202
    ##   0.8966481  40.23307
    ##   0.9074535  37.21569
    ##   0.9209530  33.93373
    ##   0.9257899  32.91732
    ##   0.9048063  37.57359
    ##   0.9182107  34.45518
    ##   0.9229781  33.24370
    ##   0.9056807  37.48796
    ##   0.9190915  34.44642
    ##   0.9237486  33.58180
    ## 
    ## RMSE was used to select the
    ##  optimal model using the
    ##  smallest value.
    ## The final values used for the
    ##  shrinkage = 0.15 and n.minobsinnode
    ##  = 9.

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
| Non-Ensemble Tree |   76.14064 |  76.59745 |
| Boosted Tree      |   46.08397 |  45.20287 |

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
    ## There were 20 predictors of which 17 had non-zero influence.
