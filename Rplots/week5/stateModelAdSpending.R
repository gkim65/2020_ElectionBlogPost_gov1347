#### Air War: State Model Ad Spending ####
#### Gov 1347: Election Analysis (2020)
#### Grace Kim

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#

library(tidyverse)
library(ggplot2)
library(geofacet) ## map-shaped grid of ggplots

#####------------------------------------------------------#
##### Read and merge data ####
#####------------------------------------------------------#
ads_2020    <- read_csv("Data/ads_2020.csv")


pvstate_df    <- read_csv("Data/popvote_bystate_1948-2016.csv")
economy_df    <- read_csv("Data/econ.csv")
pollstate_df  <- read_csv("Data/pollavg_bystate_1968-2016.csv")

#####------------------------------------------------------#
##### Map of PROBABILISTIC univariate poll-based state forecasts ####
#####------------------------------------------------------#
vep_df <- read_csv("Data/vep_1980-2020.csv")
poll_pvstate_vep_df <- pvstate_df %>%
  mutate(D_pv = D/total) %>%
  inner_join(pollstate_df %>% filter(weeks_left == 5)) %>%
  left_join(vep_df)
state_glm_forecast <- list()
state_glm_forecast_outputs <- data.frame()
poll_pvstate_vep_df$state_abb <- state.abb[match(poll_pvstate_vep_df$state, state.name)]
for (s in unique(poll_pvstate_vep_df$state_abb)) {
  
  state_glm_forecast[[s]]$dat_D <- poll_pvstate_vep_df %>% 
    filter(state_abb == s, party == "democrat")
  state_glm_forecast[[s]]$mod_D <- glm(cbind(D, VEP - D) ~ avg_poll, 
                                       state_glm_forecast[[s]]$dat_D,
                                       family = binomial(link="logit"))
  
  state_glm_forecast[[s]]$dat_R <- poll_pvstate_vep_df %>% 
    filter(state_abb == s, party == "republican")  
  state_glm_forecast[[s]]$mod_R <- glm(cbind(R, VEP - R) ~ avg_poll, 
                                       state_glm_forecast[[s]]$dat_R,
                                       family = binomial(link="logit"))
  
  if (nrow(state_glm_forecast[[s]]$dat_R) > 2) {
    for (hypo_avg_poll in seq(from=0, to=100, by=10)) {
      Dpred_voteprob <- predict(state_glm_forecast[[s]]$mod_D, 
                                newdata=data.frame(avg_poll=hypo_avg_poll), se=T, type="response")
      Dpred_q <- qt(0.975, df = df.residual(state_glm_forecast[[s]]$mod_D)) ## used in pred interval formula
      
      Rpred_voteprob <- predict(state_glm_forecast[[s]]$mod_R, 
                                newdata=data.frame(avg_poll=hypo_avg_poll), se=T, type="response")
      Rpred_q <- qt(0.975, df = df.residual(state_glm_forecast[[s]]$mod_R)) ## used in pred interval formula
      
      state_glm_forecast_outputs <- rbind(
        state_glm_forecast_outputs,
        cbind.data.frame(state = s, party = "democrat", x = hypo_avg_poll, 
                         y = Dpred_voteprob$fit*100, 
                         ymin = (Dpred_voteprob$fit - Rpred_q*Dpred_voteprob$se.fit)*100,
                         ymax = (Dpred_voteprob$fit + Rpred_q*Dpred_voteprob$se.fit)*100),
        cbind.data.frame(state = s, party = "republican", x = hypo_avg_poll, 
                         y = Rpred_voteprob$fit*100, 
                         ymin = (Rpred_voteprob$fit - Rpred_q*Rpred_voteprob$se.fit)*100,
                         ymax = (Rpred_voteprob$fit + Rpred_q*Rpred_voteprob$se.fit)*100)
      )
    }
  }
}

## graphs: polls in different states / parties different levels 
##         of strength / significance of outcome
ggplot(state_glm_forecast_outputs, aes(x=x, y=y, ymin=ymin, ymax=ymax)) + 
  facet_geo(~ state) +
  geom_line(aes(color = party)) + 
  geom_ribbon(aes(fill = party), alpha=0.5, color=NA) +
  coord_cartesian(ylim=c(0, 100)) +
  scale_color_manual(values = c("blue", "red")) +
  scale_fill_manual(values = c("blue", "red")) +
  xlab("hypothetical poll support") +
  ylab('probability of state-eligible voter voting for party') +
  theme_bw()

## North Dakota and Texas
state_glm_forecast_outputs %>%
  filter(state == "ND" | state == "TX") %>%
  ggplot(aes(x=x, y=y, ymin=ymin, ymax=ymax)) + 
  facet_wrap(~ state) +
  geom_line(aes(color = party)) + 
  geom_ribbon(aes(fill = party), alpha=0.5, color=NA) +
  coord_cartesian(ylim=c(0, 100)) +
  geom_text(data = poll_pvstate_df %>% filter(state == "ND", party=="democrat"), 
            aes(x = avg_poll, y = D_pv, ymin = D_pv, ymax = D_pv, color = party, label = year), size=1.5) +
  geom_text(data = poll_pvstate_df %>% filter(state == "ND", party=="republican"), 
            aes(x = avg_poll, y = D_pv, ymin = D_pv, ymax = D_pv, color = party, label = year), size=1.5) +
  geom_text(data = poll_pvstate_df %>% filter(state == "TX", party=="democrat"), 
            aes(x = avg_poll, y = D_pv, ymin = D_pv, ymax = D_pv, color = party, label = year), size=1.5) +
  geom_text(data = poll_pvstate_df %>% filter(state == "TX", party=="republican"), 
            aes(x = avg_poll, y = D_pv, ymin = D_pv, ymax = D_pv, color = party, label = year), size=1.5) +
  scale_color_manual(values = c("blue", "red")) +
  scale_fill_manual(values = c("blue", "red")) +
  xlab("hypothetical poll support") +
  ylab('probability of\nstate-eligible voter\nvoting for party') +
  ggtitle("Binomial logit") + 
  theme_bw() + theme(axis.title.y = element_text(size=6.5))

#####------------------------------------------------------#
##### Simulating a distribution of election results (PA) ####
#####------------------------------------------------------#

stateList <- vep_df %>% 
  filter(year == 2020, state != "United States")%>% 
  select(state)

state_predictions_df <- lapply(stateList, function(y){
  ## Get relevant data
  VEP_state_2020 <- as.integer(vep_df$VEP[vep_df$state == y & vep_df$year == 2020])
  
  state_R <- poll_pvstate_vep_df %>% filter(state==y, party=="republican")
  state_D <- poll_pvstate_vep_df %>% filter(state==y, party=="democrat")
  
  ## Fit D and R models
  state_R_glm <- glm(cbind(R, VEP-R) ~ avg_poll, state_R, family = binomial)
  state_D_glm <- glm(cbind(D, VEP-D) ~ avg_poll, state_D, family = binomial)
  
  mse_df <- lapply(dflist, function(x) {
    lm_econ <- lm(pv2p ~ get(x), data = dat_q)
    mse <- mean((lm_econ$model$pv2p - lm_econ$fitted.values)^2)
    pv2p <- sqrt(mse)
  })

## Get predicted draw probabilities for D and R
prob_Rvote_PA_2020 <- predict(PA_R_glm, newdata = data.frame(avg_poll=44.5), type="response")[[1]]
prob_Dvote_PA_2020 <- predict(PA_D_glm, newdata = data.frame(avg_poll=50), type="response")[[1]]

## Get predicted distribution of draws from the population
sim_Rvotes_PA_2020 <- rbinom(n = 10000, size = VEP_PA_2020, prob = prob_Rvote_PA_2020)
sim_Dvotes_PA_2020 <- rbinom(n = 10000, size = VEP_PA_2020, prob = prob_Dvote_PA_2020)

## Simulating a distribution of election results: Biden PA PV
hist(sim_Dvotes_PA_2020, xlab="predicted turnout draws for Biden\nfrom 10,000 binomial process simulations", breaks=100)

## Simulating a distribution of election results: Trump PA PV
hist(sim_Rvotes_PA_2020, xlab="predicted turnout draws for Trump\nfrom 10,000 binomial process simulations", breaks=100)

## Simulating a distribution of election results: Biden win margin
sim_elxns_PA_2020 <- ((sim_Dvotes_PA_2020-sim_Rvotes_PA_2020)/(sim_Dvotes_PA_2020+sim_Rvotes_PA_2020))*100
hist(sim_elxns_PA_2020, xlab="predicted draws of Biden win margin (% pts)\nfrom 10,000 binomial process simulations", xlim=c(2, 7.5))

#####------------------------------------------------------#
##### Advertising effects: A hypothetical air war in PA ####
#####------------------------------------------------------#

## how much 1000 GRP buys in % votes + how much it costs
GRP1000.buy_fx.huber     <- 7.5
GRP1000.buy_fx.huber_se  <- 2.5
GRP1000.buy_fx.gerber    <- 5
GRP1000.buy_fx.gerber_se <- 1.5
GRP1000.price            <- 300

## Suppose current (at-the-time) 538 polls were the *literal* individual
## probabilities that each voter turns out to vote blue/red
sim_Dvotes_PA_2020 <- rbinom(n = 10000, size = VEP_PA_2020, prob = 0.49)
sim_Rvotes_PA_2020 <- rbinom(n = 10000, size = VEP_PA_2020, prob = 0.42)
sim_elxns_PA_2020 <- (sim_Dvotes_PA_2020-sim_Rvotes_PA_2020)/(sim_Dvotes_PA_2020+sim_Rvotes_PA_2020)*100
hist(sim_elxns_PA_2020, xlab="", main="predicted Biden win margin (%) distribution", ylab="", cex.lab=0.5, 
     cex.axis=0.5, cex=0.5, cex.main=0.4, xaxs="i", yaxs="i", yaxt="n", bty="n", breaks=100)


## How much $ for Trump to get ~2% win margin?
## --> Trump needs to gain 10% 
((10/GRP1000.buy_fx.huber) * GRP1000.price * 1000)  ## price according to Huber et al
((10/GRP1000.buy_fx.gerber) * GRP1000.price * 1000) ## price according to Gerber et al

sim_elxns_PA_2020_shift.b <- sim_elxns_PA_2020 - rnorm(10000, 10, GRP1000.buy_fx.huber_se) ## shift from that buy according to Huber et al
sim_elxns_PA_2020_shift.a <- sim_elxns_PA_2020 - rnorm(10000, 10, GRP1000.buy_fx.gerber_se) ## shift from that buy according to Huber et al


## How much $ for Trump to get ~12% win margin?
## --> Trump needs to gain 20%
## --> double the estimates from above
par(mfrow=c(1,2))
{
  hist(sim_elxns_PA_2020_shift.a, xlab="", 
       main="predicted Biden win margin (%) distribution\n - Gerber et al's estimated effect of 2000 Trump GRPs", 
       ylab="", cex.lab=0.5, cex.axis=0.5, cex=0.5, cex.main=0.4, xaxs="i", yaxs="i", yaxt="n", bty="n", 
       breaks=100, xlim=c(-10, 5))
  hist(sim_elxns_PA_2020_shift.b, xlab="", 
       main="predicted Biden win margin (%) distribution\n - Huber et al's estimated effect of 1333 Trump GRPs", 
       ylab="", cex.lab=0.5, cex.axis=0.5, cex=0.5, cex.main=0.4, xaxs="i", yaxs="i", yaxt="n", bty="n", 
       breaks=100, xlim=c(-10, 5))
}

### NOTE:
### if GRPs have diminishing returns, then this is only true 
### if Trump didn't spend more than 6500 GRPs (according to Huber et al.)

