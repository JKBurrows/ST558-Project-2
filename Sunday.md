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

The day is Sunday.

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
    ## 1      25 2011-01-02 winter 2011  jan  
    ## 2      26 2011-01-02 winter 2011  jan  
    ## 3      27 2011-01-02 winter 2011  jan  
    ## 4      28 2011-01-02 winter 2011  jan  
    ## 5      29 2011-01-02 winter 2011  jan  
    ## 6      30 2011-01-02 winter 2011  jan  
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

| season | min | Q1 | median |      mean |     Q3 | max |
| :----- | --: | -: | -----: | --------: | -----: | --: |
| winter |   1 | 20 |   59.0 |  94.34953 | 126.75 | 554 |
| spring |   2 | 47 |  143.0 | 208.10594 | 358.00 | 686 |
| summer |   1 | 73 |  186.0 | 224.36143 | 356.00 | 757 |
| fall   |   1 | 50 |  125.5 | 185.49840 | 293.50 | 776 |

Total rentals each year

``` r
yearSum <- dayData %>% group_by(yr) %>% summarize(totalRentals = sum(cnt))
yearSum %>% kable()
```

| yr   | totalRentals |
| :--- | -----------: |
| 2011 |       177074 |
| 2012 |       266953 |

Summary statistics of rental count by dayDatath. It is probably not
worth including *dayDatath* and *season* in the model, so I eliminated
*season*.

``` r
dayDatathSum <- dayData %>% group_by(mnth) %>% summarize(min = min(cnt), Q1 = quantile(cnt, probs = c(.25), names = FALSE), median = median(cnt), mean = mean(cnt), Q3 = quantile(cnt, probs = c(.75), names = FALSE), max = max(cnt))

dayDatathSum %>% kable()
```

| mnth | min |    Q1 | median |      mean |     Q3 | max |
| :--- | --: | ----: | -----: | --------: | -----: | --: |
| jan  |   1 | 18.00 |   55.0 |  76.62025 | 105.00 | 351 |
| feb  |   1 | 23.00 |   63.0 |  95.13228 | 154.00 | 353 |
| mar  |   2 | 23.00 |   78.5 | 140.46809 | 218.75 | 554 |
| apr  |   3 | 36.00 |   95.5 | 184.03704 | 304.50 | 681 |
| may  |   5 | 63.25 |  169.5 | 221.67593 | 366.25 | 637 |
| jun  |   6 | 85.50 |  209.5 | 247.51562 | 396.25 | 686 |
| jul  |   1 | 90.75 |  189.5 | 220.75417 | 346.00 | 628 |
| aug  |   1 | 66.00 |  183.0 | 203.37297 | 313.00 | 626 |
| sep  |   1 | 78.25 |  187.5 | 256.64815 | 403.25 | 776 |
| oct  |   3 | 53.25 |  132.0 | 197.28704 | 322.75 | 675 |
| nov  |   2 | 43.75 |  121.5 | 171.92188 | 276.25 | 724 |
| dec  |   1 | 27.50 |   85.0 | 114.69302 | 171.50 | 520 |

Scatter plot of total rentals by hour of the day

``` r
avgRentals <- dayData %>% group_by(hr) %>% summarize(meanRentals = mean(cnt))

ggplot(avgRentals, aes(x = hr, y = meanRentals)) + geom_point() + labs(title = "Total Rentals by Hour", x = "Hour of the Day", y = "Total Rentals") 
```

![](Sunday_files/figure-gfm/Hour-1.png)<!-- -->

Average rentals by holiday

``` r
dayData %>% group_by(holiday) %>% summarize(meanRentals = mean(cnt)) %>% kable()
```

| holiday | meanRentals |
| :------ | ----------: |
| no      |    177.4688 |

Average rentals by working day. Working days are neither weekends nor
holidays. I decided to eliminate this variable from the model because
some of the days under consideration are weekends.

``` r
dayData %>% group_by(workingday) %>% summarize(meanRentals = mean(cnt)) %>% kable()
```

| workingday | meanRentals |
| ---------: | ----------: |
|          0 |    177.4688 |

Average rentals by weather condition

``` r
dayData %>% group_by(weathersit) %>% summarize(meanRentals = mean(cnt)) %>% kable()
```

| weathersit | meanRentals |
| :--------- | ----------: |
| very good  |    194.6703 |
| good       |    142.1778 |
| bad        |    116.4320 |

Scatter plot of average rentals and temperature

``` r
tempAvg <- dayData %>% group_by(temp) %>% summarize(avgRentals = mean(cnt))

ggplot(tempAvg, aes(x = temp, y = avgRentals)) + geom_point() + labs(title = "Average Rentals by Temperature", x = "Normalized Temperature", "Average Rentals")
```

![](Sunday_files/figure-gfm/Temp-1.png)<!-- -->

Scatter plot of average rentals and feeling temperature. It does not
make much sense to keep *temp* and *atemp*, so I eliminated *atemp* from
the model.

``` r
atempAvg <- dayData %>% group_by(atemp) %>% summarize(avgRentals = mean(cnt))

ggplot(atempAvg, aes(x = atemp, y = avgRentals)) + geom_point() + labs(title = "Average Rentals by Temperature", x = "Normalized Feeling Temperature", "Average Rentals")
```

![](Sunday_files/figure-gfm/aTemp-1.png)<!-- -->

Scatter plot of average rentals by humidity

``` r
humAvg <- dayData %>% group_by(hum) %>% summarize(avgRentals = mean(cnt))

ggplot(humAvg, aes(x = hum, y = avgRentals)) + geom_point() + labs(title = "Average Rentals by Humidity", x = "Normalized Humidity", y = "Average Rentals") 
```

![](Sunday_files/figure-gfm/Hum-1.png)<!-- -->

Average rentals by windspeed

``` r
windAvg <- dayData %>% group_by(windspeed) %>% summarize(avgRentals = mean(cnt))

ggplot(windAvg, aes(x = windspeed, y = avgRentals)) + geom_point() + labs(title = "Average Rentals by Windspeed", x = "Normalized Windspeed", y = "Average Rentals")
```

![](Sunday_files/figure-gfm/Wind-1.png)<!-- -->

### Correlation between Predictors

Correlation plot of quantitative predictors.

It does not make much sense to keep *temp* and *atemp*, so I eliminated
*atemp* from the model.

``` r
corr <- dayData %>% select(temp, atemp, windspeed, hum) %>% cor()

corrplot(corr)
```

![](Sunday_files/figure-gfm/Correlation-1.png)<!-- -->

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
    ##  1   17174 2012-12-23 winter 2012 
    ##  2   15536 2012-10-14 fall   2012 
    ##  3    3633 2011-06-05 spring 2011 
    ##  4    1300 2011-02-27 winter 2011 
    ##  5   12847 2012-06-24 summer 2012 
    ##  6    7982 2011-12-04 fall   2011 
    ##  7    8667 2012-01-01 winter 2012 
    ##  8    8825 2012-01-08 winter 2012 
    ##  9    7159 2011-10-30 fall   2011 
    ## 10    4636 2011-07-17 summer 2011 
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
    ##  1   17185 2012-12-23 winter 2012 
    ##  2    7150 2011-10-30 fall   2011 
    ##  3    2138 2011-04-03 spring 2011 
    ##  4   13681 2012-07-29 summer 2012 
    ##  5    8819 2012-01-08 winter 2012 
    ##  6   12505 2012-06-10 spring 2012 
    ##  7    9494 2012-02-05 winter 2012 
    ##  8    6819 2011-10-16 fall   2011 
    ##  9   14532 2012-09-02 summer 2012 
    ## 10    6820 2011-10-16 fall   2011 
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
    ##   cp         RMSE      Rsquared  
    ##   0.1513697  143.6789  0.27880562
    ##   0.2066004  167.1026  0.08931582
    ##   0.3524401  171.7707  0.01222900
    ##   MAE     
    ##   111.7920
    ##   134.8903
    ##   154.4611
    ## 
    ## RMSE was used to select the
    ##  optimal model using the
    ##  smallest value.
    ## The final value used for the model
    ##  was cp = 0.1513697.

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
    ##   n.trees  interaction.depth  RMSE    
    ##    50      1                  99.97631
    ##    50      2                  84.88782
    ##    50      3                  79.82056
    ##   100      1                  91.22898
    ##   100      2                  81.57838
    ##   100      3                  78.92905
    ##   150      1                  89.08780
    ##   150      2                  79.18490
    ##   150      3                  79.33817
    ##   Rsquared   MAE     
    ##   0.6230842  77.08080
    ##   0.7159370  65.02241
    ##   0.7505534  60.46895
    ##   0.6722638  70.86155
    ##   0.7374595  62.79495
    ##   0.7538659  59.64442
    ##   0.6860800  69.97736
    ##   0.7521686  60.87301
    ##   0.7514352  59.68463
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
    ##   n.trees  interaction.depth  RMSE    
    ##    50      1                  99.97631
    ##    50      2                  84.88782
    ##    50      3                  79.82056
    ##   100      1                  91.22898
    ##   100      2                  81.57838
    ##   100      3                  78.92905
    ##   150      1                  89.08780
    ##   150      2                  79.18490
    ##   150      3                  79.33817
    ##   Rsquared   MAE     
    ##   0.6230842  77.08080
    ##   0.7159370  65.02241
    ##   0.7505534  60.46895
    ##   0.6722638  70.86155
    ##   0.7374595  62.79495
    ##   0.7538659  59.64442
    ##   0.6860800  69.97736
    ##   0.7521686  60.87301
    ##   0.7514352  59.68463
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
