# Blog 2: The Polls
## 9/28/20

### Polling

Polls are one of the best ways we can get *direct* access to the preferences of voters before the actual election. By taking a diverse and large sample of voter preferences, polling provides us a way to truly guage how voters are thinking in the days before the election that immutable variables like the economy cannot. However with polls, they have their own sets of disadvantages. When taking data from individuals way in advance of an election, this doesn't take into account that preferences might change due to future events closer to the election. With Differential non-responsive bias, certain participants are disproportionately likely not to rspond to the poll, not representing the total population correctly. Seeing these issues begs the question: **how accurate are polls?**

## Polling Average Error

The following figure was created with FiveThirtyEight's Pollster Ratings data available from [github](https://github.com/fivethirtyeight/data/tree/master/pollster-ratings), and specifically focused on the average error of each pollster during the 2016 general election. 

![](../Rplots/week3/pollQuality2.png)
[Figure 1: Polling Average Error](../Rplots/week3/pollQuality2.png)

For the *simple average error*, this variable calculated for each pollster the difference between the polled result and the actual result for the margin separating the top two finishers in the race. *Advanced Plus-Minus* is a score that compares a pollster's result against other polling firms surveying the same races and that weights recent results more heavily. Negative scores are favorable and indicate above-average quality. 

The top scatterplot in Figure 1 clearly exhibits a correlation between the Advanced Plus-Minus variable with the simple average error, with higher simple average error leading to a worse score in Advanced Plus-Minus. Most of the polls are concentrated in the lower left region of the plot, with most simple average error percentages around 5-7%. Although that percentage error definitely can either make or break specific election results (resulting in wrong overall predictions through polls) we definitely can use this information to our advantage by aggregating multiple poll results together rather than looking at each individual poll separately.

The two histograms below the scatterplot also show similar simple average error means and distributions for polls with bias towards Democrats, and polls with bias towards Republicans, proving there are limited differences in average poll error even when considering party bias.

### Modeling with Polls - Historical Election Data

First, lets analyze and model the election using historical poll data from previous elections. Below, Figure 2 plots the average voter support against final popular vote data 6 weeks before each election. The challenger and incumbent are separated into two models.

![](../Rplots/week3/PopularVoteVSPolling.png)
[Figure 2: Historical Election Data](../Rplots/week3/PopularVoteVSPolling.png)

For the incumbent, every percentage increase in *avg_support* results in a *0.7294* increase in the popular vote. The results are seen to be statistically significant as the t-value is seen to be *6.966*, which is larger than 2 (the baseline acceptable value). The higher the t-value, we can have greater confidence in the coefficient we found to be a predictor.

Now for the challenger, every percentage increase in *avg_support* results in a *0.4907* increase in the popular vote. The results are seen to be statistically significant as the t-value is seen to be *2.692*, but we do have a lower confidence value in this coefficient in predicting the challenger's popular vote based on polling information.

## Economic or Poll Modeling?