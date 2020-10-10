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

The day is Saturday.

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
    ## # ... with 12 more variables: hr <dbl>,
    ## #   holiday <fct>, weekday <fct>,
    ## #   workingday <dbl>, weathersit <fct>,
    ## #   temp <dbl>, atemp <dbl>, hum <dbl>,
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
    ## 1       1 2011-01-01 winter 2011  jan  
    ## 2       2 2011-01-01 winter 2011  jan  
    ## 3       3 2011-01-01 winter 2011  jan  
    ## 4       4 2011-01-01 winter 2011  jan  
    ## 5       5 2011-01-01 winter 2011  jan  
    ## 6       6 2011-01-01 winter 2011  jan  
    ## # ... with 12 more variables: hr <dbl>,
    ## #   holiday <fct>, weekday <fct>,
    ## #   workingday <dbl>, weathersit <fct>,
    ## #   temp <dbl>, atemp <dbl>, hum <dbl>,
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

| season | min |    Q1 | median |     mean |     Q3 | max |
| :----- | --: | ----: | -----: | -------: | -----: | --: |
| winter |   1 | 23.25 |   63.0 | 101.6610 | 129.75 | 690 |
| spring |   1 | 53.75 |  167.5 | 222.2580 | 367.00 | 730 |
| summer |   4 | 75.25 |  207.0 | 234.8816 | 367.00 | 783 |
| fall   |   1 | 53.75 |  149.0 | 204.4183 | 314.25 | 760 |

Total rentals each year

``` r
yearSum <- dayData %>% group_by(yr) %>% summarize(totalRentals = sum(cnt))
yearSum %>% kable()
```

| yr   | totalRentals |
| :--- | -----------: |
| 2011 |       179743 |
| 2012 |       298064 |

Summary statistics of rental count by dayDatath. It is probably not
worth including *dayDatath* and *season* in the model, so I eliminated
*season*.

``` r
dayDatathSum <- dayData %>% group_by(mnth) %>% summarize(min = min(cnt), Q1 = quantile(cnt, probs = c(.25), names = FALSE), median = median(cnt), mean = mean(cnt), Q3 = quantile(cnt, probs = c(.75), names = FALSE), max = max(cnt))

dayDatathSum %>% kable()
```

| mnth | min |    Q1 | median |      mean |     Q3 | max |
| :--- | --: | ----: | -----: | --------: | -----: | --: |
| jan  |   1 | 20.00 |   55.5 |  82.28505 | 100.50 | 512 |
| feb  |   1 | 26.75 |   67.5 |  94.43750 | 137.00 | 499 |
| mar  |   1 | 41.00 |  111.5 | 164.11574 | 223.00 | 690 |
| apr  |   1 | 32.00 |  102.0 | 185.23611 | 291.00 | 678 |
| may  |   2 | 66.25 |  222.0 | 249.10417 | 402.75 | 730 |
| jun  |   5 | 86.75 |  244.0 | 264.32407 | 404.00 | 702 |
| jul  |   5 | 71.75 |  210.0 | 218.01389 | 327.25 | 632 |
| aug  |   4 | 64.75 |  175.5 | 224.68280 | 370.25 | 654 |
| sep  |   5 | 79.75 |  213.5 | 266.40278 | 401.00 | 783 |
| oct  |   1 | 46.50 |  157.5 | 226.87963 | 359.25 | 760 |
| nov  |   2 | 46.75 |  142.0 | 178.66667 | 283.50 | 651 |
| dec  |   1 | 29.00 |   92.5 | 133.12083 | 195.00 | 547 |

Scatter plot of total rentals by hour of the day

``` r
avgRentals <- dayData %>% group_by(hr) %>% summarize(meanRentals = mean(cnt))

ggplot(avgRentals, aes(x = hr, y = meanRentals)) + geom_point() + labs(title = "Total Rentals by Hour", x = "Hour of the Day", y = "Total Rentals") 
```

![](Saturday_files/figure-gfm/Hour-1.png)<!-- -->

Average rentals by holiday

``` r
dayData %>% group_by(holiday) %>% summarize(meanRentals = mean(cnt)) %>% kable()
```

| holiday | meanRentals |
| :------ | ----------: |
| no      |    190.2098 |

Average rentals by working day. Working days are neither weekends nor
holidays. I decided to eliminate this variable from the model because
some of the days under consideration are weekends.

``` r
dayData %>% group_by(workingday) %>% summarize(meanRentals = mean(cnt)) %>% kable()
```

| workingday | meanRentals |
| ---------: | ----------: |
|          0 |    190.2098 |

Average rentals by weather condition

``` r
dayData %>% group_by(weathersit) %>% summarize(meanRentals = mean(cnt)) %>% kable()
```

| weathersit | meanRentals |
| :--------- | ----------: |
| very good  |    207.5707 |
| good       |    171.0077 |
| bad        |    102.6064 |
| very bad   |     23.0000 |

Scatter plot of average rentals and temperature

``` r
tempAvg <- dayData %>% group_by(temp) %>% summarize(avgRentals = mean(cnt))

ggplot(tempAvg, aes(x = temp, y = avgRentals)) + geom_point() + labs(title = "Average Rentals by Temperature", x = "Normalized Temperature", "Average Rentals")
```

![](Saturday_files/figure-gfm/Temp-1.png)<!-- -->

Scatter plot of average rentals and feeling temperature. It does not
make much sense to keep *temp* and *atemp*, so I eliminated *atemp* from
the model.

``` r
atempAvg <- dayData %>% group_by(atemp) %>% summarize(avgRentals = mean(cnt))

ggplot(atempAvg, aes(x = atemp, y = avgRentals)) + geom_point() + labs(title = "Average Rentals by Temperature", x = "Normalized Feeling Temperature", "Average Rentals")
```

![](Saturday_files/figure-gfm/aTemp-1.png)<!-- -->

Scatter plot of average rentals by humidity

``` r
humAvg <- dayData %>% group_by(hum) %>% summarize(avgRentals = mean(cnt))

ggplot(humAvg, aes(x = hum, y = avgRentals)) + geom_point() + labs(title = "Average Rentals by Humidity", x = "Normalized Humidity", y = "Average Rentals") 
```

![](Saturday_files/figure-gfm/Hum-1.png)<!-- -->

Average rentals by windspeed

``` r
windAvg <- dayData %>% group_by(windspeed) %>% summarize(avgRentals = mean(cnt))

ggplot(windAvg, aes(x = windspeed, y = avgRentals)) + geom_point() + labs(title = "Average Rentals by Windspeed", x = "Normalized Windspeed", y = "Average Rentals")
```

![](Saturday_files/figure-gfm/Wind-1.png)<!-- -->

### Correlation between Predictors

Correlation plot of quantitative predictors.

It does not make much sense to keep *temp* and *atemp*, so I eliminated
*atemp* from the model.

``` r
corr <- dayData %>% select(temp, atemp, windspeed, hum) %>% cor()

corrplot(corr)
```

![](Saturday_files/figure-gfm/Correlation-1.png)<!-- -->

# Train Models

## Tree

``` r
set.seed(123)
trialTrainIndex <- sample(1:nrow(dayData), size = 100)
trialTrain <- dayData[trialTrainIndex,]
trialTrain
```

    ## # A tibble: 100 x 17
    ##    instant dteday     season yr    mnth 
    ##      <dbl> <date>     <fct>  <fct> <fct>
    ##  1   16996 2012-12-15 fall   2012  dec  
    ##  2   17330 2012-12-29 winter 2012  dec  
    ##  3   15502 2012-10-13 fall   2012  oct  
    ##  4    3458 2011-05-28 spring 2011  may  
    ##  5    1273 2011-02-26 winter 2011  feb  
    ##  6   12813 2012-06-23 summer 2012  jun  
    ##  7    7807 2011-11-26 fall   2011  nov  
    ##  8    8634 2011-12-31 winter 2011  dec  
    ##  9    8792 2012-01-07 winter 2012  jan  
    ## 10    7127 2011-10-29 fall   2011  oct  
    ## # ... with 90 more rows, and 12 more
    ## #   variables: hr <dbl>, holiday <fct>,
    ## #   weekday <fct>, workingday <dbl>,
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
    ##    instant dteday     season yr    mnth 
    ##      <dbl> <date>     <fct>  <fct> <fct>
    ##  1   15334 2012-10-06 fall   2012  oct  
    ##  2   17151 2012-12-22 winter 2012  dec  
    ##  3    7118 2011-10-29 fall   2011  oct  
    ##  4    2107 2011-04-02 spring 2011  apr  
    ##  5   13503 2012-07-21 summer 2012  jul  
    ##  6    8643 2011-12-31 winter 2011  dec  
    ##  7   12327 2012-06-02 spring 2012  jun  
    ##  8    9461 2012-02-04 winter 2012  feb  
    ##  9    6787 2011-10-15 fall   2011  oct  
    ## 10   14498 2012-09-01 summer 2012  sep  
    ## # ... with 40 more rows, and 12 more
    ## #   variables: hr <dbl>, holiday <fct>,
    ## #   weekday <fct>, workingday <dbl>,
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
    ##   0.08187905  136.0379  0.469825551
    ##   0.30002475  173.1268  0.186827915
    ##   0.33055007  196.4847  0.004400693
    ##   MAE     
    ##   102.1130
    ##   133.4497
    ##   176.1159
    ## 
    ## RMSE was used to select the
    ##  optimal model using the
    ##  smallest value.
    ## The final value used for the model
    ##  was cp = 0.08187905.

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
    ##    50      1                  110.49457
    ##    50      2                   86.57991
    ##    50      3                   82.80033
    ##   100      1                  101.52903
    ##   100      2                   78.39846
    ##   100      3                   75.80311
    ##   150      1                  100.85693
    ##   150      2                   76.14909
    ##   150      3                   72.67850
    ##   Rsquared   MAE     
    ##   0.6523595  83.30247
    ##   0.7857590  68.02197
    ##   0.8041483  64.92025
    ##   0.6978249  80.33167
    ##   0.8228985  60.92916
    ##   0.8321577  60.54803
    ##   0.7000463  80.01397
    ##   0.8314286  58.66504
    ##   0.8447925  58.24187
    ## 
    ## Tuning parameter 'shrinkage' was
    ## 
    ## Tuning parameter 'n.minobsinnode'
    ##  was held constant at a value of 10
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
    ##    50      1                  110.49457
    ##    50      2                   86.57991
    ##    50      3                   82.80033
    ##   100      1                  101.52903
    ##   100      2                   78.39846
    ##   100      3                   75.80311
    ##   150      1                  100.85693
    ##   150      2                   76.14909
    ##   150      3                   72.67850
    ##   Rsquared   MAE     
    ##   0.6523595  83.30247
    ##   0.7857590  68.02197
    ##   0.8041483  64.92025
    ##   0.6978249  80.33167
    ##   0.8228985  60.92916
    ##   0.8321577  60.54803
    ##   0.7000463  80.01397
    ##   0.8314286  58.66504
    ##   0.8447925  58.24187
    ## 
    ## Tuning parameter 'shrinkage' was
    ## 
    ## Tuning parameter 'n.minobsinnode'
    ##  was held constant at a value of 10
    ## RMSE was used to select the
    ##  optimal model using the
    ##  smallest value.
    ## The final values used for the
    ##  shrinkage = 0.1 and n.minobsinnode
    ##  = 10.

# Best Model
