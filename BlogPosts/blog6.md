# Blog 6: The Ground Game
## 10/19/20

### The Ground Game

Following our analysis of campaigns itself, we will now be taking a look at each campaign's Ground Game efforts within the 2020 election. This can be in many forms, such as field offices, door to door volunteer knocks, text/phone banks, personal letters to voters, and more!

There are clearly many ways that candidates can reach out to voters. But which are most effective? Have campaigns been effectively using their resources to reach out to voters? How has the pandemic affected some of these candidate to voter interactions?

With these explorations, we will try to predict voter turnout rates based on current trends of early voting and ground game efforts from each candidate to bring out their supporters to the polls. However, I also do want to take some time to explore voting blocs and specific correlations demographics will have in this year's presidential election!

So, lets get on with it.

## Demographics By State

When plotting the various demographic trends within US state boundaries, there seems to be diverse waves of increase and decreases in populations for most ethnic groups within the US. In order to view this properly state by state, you can track the demographic trends from 1990 to 2018 for all 50 states below in Figure 1.

![](../Rplots/week6/demographics.png)
[Figure 1: Demographics for US population by State](../Rplots/week6/demographics.png)

Most states have seen decreases within levels of white populations, and increases in minority groups over this time period; this does exhibit possibiltiies of a minority majority in future years as we enter 2020 and beyond. 

For a more holistic view of the entire US population, we can check different demographic percentages of each Race through the pie chart below in Figure 2. There still is a majority of white individuals within the US, with Hispanic and Black populations following after.

![](../Rplots/week6/demographics_2019.png)
[Figure 2: 2019 United States Demographics Census Estimates ](../Rplots/week6/demographics_2019.png)
*The ad spending data for this plot was provided from https://data.census.gov/cedsci/all?q=demographics*

With information on the composition of the United States' different racial groups, we can correlate the relationships of the growth in different ethnic populations with increases for each party's eventual popular vote percentages. 

### Demographic Relations between Party

Now lets model the relationship between different US demographic populations with each party's popular vote percentages. After some initial exploration of various demographic variables influence on the popular vote correlations of each party, we can choose specific variables that have the highest levels of correlation with each party. Some demographic variables had minimal impacts on the actual model of the popular vote with each party, but each party did have specific demographic variables with high correlations for their popular vote percentages. 

Lets first view the democratic party relationships:

![](../Rplots/week6/demographicChangeEffects_Dem.png)
[Figure 3: Dem ](../Rplots/week6/demographicChangeEffects_Dem.png)



![](../Rplots/week6/demographicChangeEffects_Rep.png)
[Figure 3: US populations](../Rplots/week6/demographicChangeEffects_Rep.png)

## State Level Predictions based on Ad Spending


```markdown
  state_R_ads_glm <- glm(cbind(R, VEP-R) ~ avg_poll+total_cost, state_R, family = binomial)
  state_D_ads_glm <- glm(cbind(D, VEP-D) ~ avg_poll+total_cost, state_D, family = binomial)

```
![](../Rplots/week5/VoterTurnout2020.png)
[Figure 4: Voter Turnout 2020](../Rplots/week5/VoterTurnout2020.png)

### Sooo Who wins the Electoral College?

![](../Rplots/week5/2020AdPrediction.png)
[Figure 5: Electoral College Ad Spending Map ](../Rplots/week5/2020AdPrediction.png)

