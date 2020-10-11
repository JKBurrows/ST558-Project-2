Joshua Burrows Project 2
================
16 October 2020

  - [Render Code](#render-code)
  - [Introduction](#introduction)
  - [Read in Data](#read-in-data)
  - [Data](#data)
      - [EDA](#eda)
          - [Predictor Summaries and
            Plots](#predictor-summaries-and-plots)
          - [Correlation between
            Predictors](#correlation-between-predictors)
  - [Train Models](#train-models)
      - [Tree](#tree)
      - [Boosted Tree](#boosted-tree)
  - [Test Models](#test-models)
      - [Tree](#tree-1)
  - [Best Model](#best-model)

# Render Code

The following code runs in a separate R script to render a different
document for each day of the week.

# Introduction

The day is Tuesday.

# Read in Data

``` r
bikes <- read_csv(file = "../Bike-Sharing-Dataset/hour.csv")

bikes$weekday <- as.factor(bikes$weekday)
levels(bikes$weekday) <- c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday") 

bikes$season <- as.factor(bikes$season)
levels(bikes$season) <- c("winter", "spring", "summer", "fall")

bikes$yr <- as.factor(bikes$yr)
levels(bikes$yr) <- c("2011", "2012")

bikes$mnth <- as.factor(bikes$mnth)
levels(bikes$mnth) <- c("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec")

bikes$weathersit <- as.factor(bikes$weathersit)
levels(bikes$weathersit) <- c("very good", "good", "bad", "very bad")

bikes$holiday <- as.factor(bikes$holiday)
levels(bikes$holiday) <- c("no", "yes")

bikes %>% head()
```

    ## # A tibble: 6 x 17
    ##   instant dteday     season yr    mnth 
    ##     <dbl> <date>     <fct>  <fct> <fct>
    ## 1       1 2011-01-01 winter 2011  jan  
    ## 2       2 2011-01-01 winter 2011  jan  
    ## 3       3 2011-01-01 winter 2011  jan  
    ## 4       4 2011-01-01 winter 2011  jan  
    ## 5       5 2011-01-01 winter 2011  jan  
    ## 6       6 2011-01-01 winter 2011  jan  
    ## # ... with 12 more variables:
    ## #   hr <dbl>, holiday <fct>,
    ## #   weekday <fct>, workingday <dbl>,
    ## #   weathersit <fct>, temp <dbl>,
    ## #   atemp <dbl>, hum <dbl>,
    ## #   windspeed <dbl>, casual <dbl>,
    ## #   registered <dbl>, cnt <dbl>

# Data

``` r
dayData <- bikes %>% filter(weekday == params$day)
dayData %>% head()
```

    ## # A tibble: 6 x 17
    ##   instant dteday     season yr    mnth 
    ##     <dbl> <date>     <fct>  <fct> <fct>
    ## 1      70 2011-01-04 winter 2011  jan  
    ## 2      71 2011-01-04 winter 2011  jan  
    ## 3      72 2011-01-04 winter 2011  jan  
    ## 4      73 2011-01-04 winter 2011  jan  
    ## 5      74 2011-01-04 winter 2011  jan  
    ## 6      75 2011-01-04 winter 2011  jan  
    ## # ... with 12 more variables:
    ## #   hr <dbl>, holiday <fct>,
    ## #   weekday <fct>, workingday <dbl>,
    ## #   weathersit <fct>, temp <dbl>,
    ## #   atemp <dbl>, hum <dbl>,
    ## #   windspeed <dbl>, casual <dbl>,
    ## #   registered <dbl>, cnt <dbl>

``` r
set.seed(123)
dayIndex <- createDataPartition(dayData$cnt, p = .7, list = FALSE)
```

## EDA

### Predictor Summaries and Plots

Summary statistics of rental count by season

``` r
seasonSum <- dayData %>% group_by(season) %>% summarize(min = min(cnt), Q1 = quantile(cnt, probs = c(.25), names = FALSE), median = median(cnt), mean = mean(cnt), Q3 = quantile(cnt, probs = c(.75), names = FALSE), max = max(cnt))

seasonSum %>% kable()
```

| season | min |   Q1 | median |     mean |     Q3 | max |
| :----- | --: | ---: | -----: | -------: | -----: | --: |
| winter |   1 | 23.5 |   85.0 | 122.2644 | 170.00 | 801 |
| spring |   1 | 35.0 |  159.5 | 201.0401 | 285.25 | 850 |
| summer |   1 | 57.0 |  192.0 | 236.0355 | 328.00 | 970 |
| fall   |   1 | 40.0 |  157.0 | 198.2520 | 289.00 | 967 |

Total rentals each year

``` r
yearSum <- dayData %>% group_by(yr) %>% summarize(totalRentals = sum(cnt))
yearSum %>% kable()
```

| yr   | totalRentals |
| :--- | -----------: |
| 2011 |       180338 |
| 2012 |       288771 |

Summary statistics of rental count by dayDatath. It is probably not
worth including *dayDatath* and *season* in the model, so I eliminated
*season*.

``` r
dayDatathSum <- dayData %>% group_by(mnth) %>% summarize(min = min(cnt), Q1 = quantile(cnt, probs = c(.25), names = FALSE), median = median(cnt), mean = mean(cnt), Q3 = quantile(cnt, probs = c(.75), names = FALSE), max = max(cnt))

dayDatathSum %>% kable()
```

| mnth | min |    Q1 | median |     mean |     Q3 | max |
| :--- | --: | ----: | -----: | -------: | -----: | --: |
| jan  |   1 | 27.25 |   83.0 | 116.7172 | 168.75 | 559 |
| feb  |   1 | 29.50 |   86.0 | 123.4536 | 172.00 | 559 |
| mar  |   1 | 25.50 |  104.0 | 149.6093 | 220.50 | 801 |
| apr  |   1 | 29.50 |  132.0 | 189.8281 | 277.50 | 800 |
| may  |   2 | 37.50 |  175.0 | 209.3750 | 286.25 | 785 |
| jun  |   2 | 54.00 |  189.5 | 236.7031 | 328.50 | 900 |
| jul  |   2 | 72.00 |  200.0 | 243.5093 | 334.00 | 877 |
| aug  |   3 | 63.00 |  208.5 | 247.1019 | 343.25 | 878 |
| sep  |   1 | 45.50 |  172.0 | 217.1518 | 304.00 | 970 |
| oct  |   1 | 60.50 |  180.0 | 224.5369 | 317.50 | 943 |
| nov  |   1 | 27.50 |  136.5 | 168.3426 | 242.00 | 665 |
| dec  |   1 | 24.50 |  107.0 | 155.5288 | 242.00 | 743 |

Scatter plot of total rentals by hour of the day

``` r
avgRentals <- dayData %>% group_by(hr) %>% summarize(meanRentals = mean(cnt))

ggplot(avgRentals, aes(x = hr, y = meanRentals)) + geom_point() + labs(title = "Total Rentals by Hour", x = "Hour of the Day", y = "Total Rentals") 
```

![](Tuesday_files/figure-gfm/Hour-1.png)<!-- -->

Average rentals by holiday

``` r
dayData %>% group_by(holiday) %>% summarize(meanRentals = mean(cnt)) %>% kable()
```

| holiday | meanRentals |
| :------ | ----------: |
| no      |   192.63210 |
| yes     |    44.04348 |

Average rentals by working day. Working days are neither weekends nor
holidays. I decided to eliminate this variable from the model because
some of the days under consideration are weekends.

``` r
dayData %>% group_by(workingday) %>% summarize(meanRentals = mean(cnt)) %>% kable()
```

| workingday | meanRentals |
| ---------: | ----------: |
|          0 |    44.04348 |
|          1 |   192.63210 |

Average rentals by weather condition

``` r
dayData %>% group_by(weathersit) %>% summarize(meanRentals = mean(cnt)) %>% kable()
```

| weathersit | meanRentals |
| :--------- | ----------: |
| very good  |    214.8364 |
| good       |    164.7133 |
| bad        |    117.3713 |

Scatter plot of average rentals and temperature

``` r
tempAvg <- dayData %>% group_by(temp) %>% summarize(avgRentals = mean(cnt))

ggplot(tempAvg, aes(x = temp, y = avgRentals)) + geom_point() + labs(title = "Average Rentals by Temperature", x = "Normalized Temperature", "Average Rentals")
```

![](Tuesday_files/figure-gfm/Temp-1.png)<!-- -->

Scatter plot of average rentals and feeling temperature. It does not
make much sense to keep *temp* and *atemp*, so I eliminated *atemp* from
the model.

``` r
atempAvg <- dayData %>% group_by(atemp) %>% summarize(avgRentals = mean(cnt))

ggplot(atempAvg, aes(x = atemp, y = avgRentals)) + geom_point() + labs(title = "Average Rentals by Temperature", x = "Normalized Feeling Temperature", "Average Rentals")
```

![](Tuesday_files/figure-gfm/aTemp-1.png)<!-- -->

Scatter plot of average rentals by humidity

``` r
humAvg <- dayData %>% group_by(hum) %>% summarize(avgRentals = mean(cnt))

ggplot(humAvg, aes(x = hum, y = avgRentals)) + geom_point() + labs(title = "Average Rentals by Humidity", x = "Normalized Humidity", y = "Average Rentals") 
```

![](Tuesday_files/figure-gfm/Hum-1.png)<!-- -->

Average rentals by windspeed

``` r
windAvg <- dayData %>% group_by(windspeed) %>% summarize(avgRentals = mean(cnt))

ggplot(windAvg, aes(x = windspeed, y = avgRentals)) + geom_point() + labs(title = "Average Rentals by Windspeed", x = "Normalized Windspeed", y = "Average Rentals")
```

![](Tuesday_files/figure-gfm/Wind-1.png)<!-- -->

### Correlation between Predictors

Correlation plot of quantitative predictors.

It does not make much sense to keep *temp* and *atemp*, so I eliminated
*atemp* from the model.

``` r
corr <- dayData %>% select(temp, atemp, windspeed, hum) %>% cor()

corrplot(corr)
```

![](Tuesday_files/figure-gfm/Correlation-1.png)<!-- -->

# Train Models

## Tree

``` r
set.seed(123)
trialTrainIndex <- sample(1:nrow(dayData), size = 100)
trialTrain <- dayData[trialTrainIndex,]
trialTrain
```

    ## # A tibble: 100 x 17
    ##    instant dteday     season yr   
    ##      <dbl> <date>     <fct>  <fct>
    ##  1   15595 2012-10-16 fall   2012 
    ##  2    3697 2011-06-07 spring 2011 
    ##  3    1506 2011-03-08 winter 2011 
    ##  4   12906 2012-06-26 summer 2012 
    ##  5    8040 2011-12-06 fall   2011 
    ##  6    8867 2012-01-10 winter 2012 
    ##  7    8882 2012-01-10 winter 2012 
    ##  8    7361 2011-11-08 fall   2011 
    ##  9    4700 2011-07-19 summer 2011 
    ## 10   11395 2012-04-24 spring 2012 
    ## # ... with 90 more rows, and 13 more
    ## #   variables: mnth <fct>, hr <dbl>,
    ## #   holiday <fct>, weekday <fct>,
    ## #   workingday <dbl>,
    ## #   weathersit <fct>, temp <dbl>,
    ## #   atemp <dbl>, hum <dbl>,
    ## #   windspeed <dbl>, casual <dbl>,
    ## #   registered <dbl>, cnt <dbl>

``` r
trialTestIndex <- sample(1:nrow(dayData), size = 50)
trialTest <- dayData[trialTestIndex,]
trialTest
```

    ## # A tibble: 50 x 17
    ##    instant dteday     season yr   
    ##      <dbl> <date>     <fct>  <fct>
    ##  1   13740 2012-07-31 summer 2012 
    ##  2    8876 2012-01-10 winter 2012 
    ##  3   12564 2012-06-12 spring 2012 
    ##  4    9552 2012-02-07 winter 2012 
    ##  5    7020 2011-10-25 fall   2011 
    ##  6   14735 2012-09-11 summer 2012 
    ##  7    7021 2011-10-25 fall   2011 
    ##  8    1026 2011-02-15 winter 2011 
    ##  9   12394 2012-06-05 spring 2012 
    ## 10   11208 2012-04-17 spring 2012 
    ## # ... with 40 more rows, and 13 more
    ## #   variables: mnth <fct>, hr <dbl>,
    ## #   holiday <fct>, weekday <fct>,
    ## #   workingday <dbl>,
    ## #   weathersit <fct>, temp <dbl>,
    ## #   atemp <dbl>, hum <dbl>,
    ## #   windspeed <dbl>, casual <dbl>,
    ## #   registered <dbl>, cnt <dbl>

``` r
set.seed(123)
tree <- train(cnt ~ yr + mnth + hr + holiday + weathersit + temp + hum + windspeed, 
              data = trialTrain, 
              method = "rpart", 
              trControl = trainControl(method = "LOOCV"))
tree
```

    ## CART 
    ## 
    ## 100 samples
    ##   8 predictor
    ## 
    ## No pre-processing
    ## Resampling: Leave-One-Out Cross-Validation 
    ## Summary of sample sizes: 99, 99, 99, 99, 99, 99, ... 
    ## Resampling results across tuning parameters:
    ## 
    ##   cp          RMSE      Rsquared  
    ##   0.09020345  154.4861  0.26814171
    ##   0.19200236  174.8631  0.09363696
    ##   0.21474198  182.2383  0.01044437
    ##   MAE     
    ##   107.6569
    ##   130.0359
    ##   144.2623
    ## 
    ## RMSE was used to select the
    ##  optimal model using the
    ##  smallest value.
    ## The final value used for the model
    ##  was cp = 0.09020345.

## Boosted Tree

``` r
set.seed(123)
boostTree <- train(cnt ~ yr + mnth + hr + holiday + weathersit + temp + hum + windspeed, 
                   data = trialTrain, 
                   method = "gbm", 
                   trControl = trainControl(method = "LOOCV"), 
                   verbose = FALSE)
boostTree
```

    ## Stochastic Gradient Boosting 
    ## 
    ## 100 samples
    ##   8 predictor
    ## 
    ## No pre-processing
    ## Resampling: Leave-One-Out Cross-Validation 
    ## Summary of sample sizes: 99, 99, 99, 99, 99, 99, ... 
    ## Resampling results across tuning parameters:
    ## 
    ##   n.trees  interaction.depth
    ##    50      1                
    ##    50      2                
    ##    50      3                
    ##   100      1                
    ##   100      2                
    ##   100      3                
    ##   150      1                
    ##   150      2                
    ##   150      3                
    ##   RMSE       Rsquared   MAE     
    ##   136.93067  0.4257408  94.98798
    ##   123.24292  0.5334416  85.49903
    ##   111.04237  0.6305317  77.40064
    ##   128.81563  0.4874594  89.22285
    ##   104.44234  0.6684128  76.51533
    ##    98.29858  0.7002202  72.10927
    ##   120.28131  0.5532146  83.79544
    ##    97.57137  0.7046891  71.81563
    ##    94.06494  0.7189826  68.81512
    ## 
    ## Tuning parameter 'shrinkage' was
    ##  'n.minobsinnode' was held constant
    ##  at a value of 10
    ## RMSE was used to select the
    ##  optimal model using the
    ##  smallest value.
    ## The final values used for the
    ##  shrinkage = 0.1 and n.minobsinnode
    ##  = 10.

# Test Models

## Tree

``` r
treePreds <- predict(tree, trialTrain)
treeRMSE <- postResample(treePreds, trialTrain$cnt)[1]

boostPreds <- predict(boostTree, trialTrain)
boostRMSE <- postResample(boostPreds, trialTrain$cnt)[1]

modelPerformance <- data.frame(model = c("Non-Ensemble Tree", "Boosted Tree"), RMSE = c(treeRMSE, boostRMSE))

best <- modelPerformance %>% filter(RMSE == min(RMSE))

if(best$model == "Non-Ensemble Tree"){
  final <- tree
} else if(best$model == "Boosted Tree"){
  final <- boostTree
} else{
  stop("Error")
}

final
```

    ## Stochastic Gradient Boosting 
    ## 
    ## 100 samples
    ##   8 predictor
    ## 
    ## No pre-processing
    ## Resampling: Leave-One-Out Cross-Validation 
    ## Summary of sample sizes: 99, 99, 99, 99, 99, 99, ... 
    ## Resampling results across tuning parameters:
    ## 
    ##   n.trees  interaction.depth
    ##    50      1                
    ##    50      2                
    ##    50      3                
    ##   100      1                
    ##   100      2                
    ##   100      3                
    ##   150      1                
    ##   150      2                
    ##   150      3                
    ##   RMSE       Rsquared   MAE     
    ##   136.93067  0.4257408  94.98798
    ##   123.24292  0.5334416  85.49903
    ##   111.04237  0.6305317  77.40064
    ##   128.81563  0.4874594  89.22285
    ##   104.44234  0.6684128  76.51533
    ##    98.29858  0.7002202  72.10927
    ##   120.28131  0.5532146  83.79544
    ##    97.57137  0.7046891  71.81563
    ##    94.06494  0.7189826  68.81512
    ## 
    ## Tuning parameter 'shrinkage' was
    ##  'n.minobsinnode' was held constant
    ##  at a value of 10
    ## RMSE was used to select the
    ##  optimal model using the
    ##  smallest value.
    ## The final values used for the
    ##  shrinkage = 0.1 and n.minobsinnode
    ##  = 10.

# Best Model
