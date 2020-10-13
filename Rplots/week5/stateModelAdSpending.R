#### Air War: State Model Ad Spending ####
#### Gov 1347: Election Analysis (2020)
#### Grace Kim

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#

library(tidyverse)
library(ggplot2)
library(dplyr)
library(geofacet) ## map-shaped grid of ggplots
library(usmap)
library(extrafont)
library(flextable)
library(webshot)
loadfonts(device = "win")


## Made my pretty theme for my map graphics :D
blogMapGraphics_theme <- theme(panel.border = element_blank(),
                               text         = element_text(family = "Garamond"),
                               plot.title   = element_text(size = 15, hjust = 0.5), 
                               strip.text   = element_text(size = 18),
                               plot.caption = element_text(size = 18),
                               line = element_line(color= "white"),
                               legend.position = "bottom",
                               legend.direction = "horizontal",
                               legend.text = element_text(size = 12))

#####------------------------------------------------------#
##### Read and merge data ####
#####------------------------------------------------------#
ads_campaigns    <- read_csv("Data/ad_campaigns_2000-2012.csv")

pollstate_df  <- read_csv("Data/pollavg_bystate_1968-2016.csv")

# Get ad spending over time
ads<-ads_campaigns %>% select(state, total_cost,party,air_date) %>% 
  mutate(year = as.numeric(substr(air_date, 1, 4))) %>%
  group_by(state, year, party) %>% 
  summarize(total_cost = sum(total_cost)) %>% 
  filter(!is.na(year))
ads$state<-state.name[match(ads$state,state.abb)]

# Merge ad spending data per state with poll data
vep_df <- read_csv("Data/vep_1980-2020.csv")

poll_pvstate_vep_df <- pvstate_df %>%
  mutate(D_pv = D/total) %>%
  inner_join(pollstate_df %>% filter(weeks_left == 5)) %>%
  left_join(vep_df) %>% 
  left_join(ads)
poll_pvstate_vep_df$total_cost[is.na(poll_pvstate_vep_df$total_cost)] <- 0
poll_pvstate_vep_df$VEP[is.na(poll_pvstate_vep_df$VEP)] <- 0;


# NEED TO GET VALUES TO PREDICT 2020 DATA!
# First get totals from both biden ads and trump ads
biden_ads_2020 <- read_csv("Data/Biden_2020AdSpending.csv")
trump_ads_2020 <- read_csv("Data/Trump_2020AdSpending.csv")

bidenAds_clean <- biden_ads_2020 %>% 
  select(recipient_state, disbursement_date,disbursement_amount) %>% 
  group_by(recipient_state) %>%
  summarise(total_cost = sum(disbursement_amount)) %>% 
  mutate(party = "democrat")

trumpAds_clean <- trump_ads_2020 %>% 
  select(recipient_state, disbursement_date,disbursement_amount) %>% 
  group_by(recipient_state) %>%
  summarise(total_cost = sum(disbursement_amount)) %>% 
  mutate(party = "republican")

# bind the two data sets from trump and biden together
AllAds <- rbind(trumpAds_clean, bidenAds_clean) %>% 
  mutate(state = state.name[match(recipient_state,state.abb)]) %>% 
  select(total_cost, party,state) %>% 
  filter(!is.na(state))

poll2020_df    <- read_csv("Data/president_polls_2020.csv")

predictData_2020 <- poll2020_df %>% 
  select(pct, state, candidate_party) %>% 
  filter(!is.na(state), candidate_party == c("DEM" , "REP")) %>%
  mutate(party = ifelse(candidate_party == "DEM" , "democrat", "republican")) %>% 
  group_by(state, party) %>% 
  summarize(avg_poll = mean(pct)) %>% 
  full_join(AllAds) %>% 
  mutate_all(~replace(., is.na(.), 0))
  

#####------------------------------------------------------#
##### Map of PROBABILISTIC univariate poll-based state forecasts ####
#####------------------------------------------------------#

# Get state list for lapply function
stateList <- state.name
stateList <- stateList[-45]

  state_predictions_df <- lapply(stateList, function(y){
  ## Get relevant data
  state_D <- poll_pvstate_vep_df %>% dplyr::filter(state  == y) %>% 
    dplyr::filter(party=="democrat")
  state_R <- poll_pvstate_vep_df %>% dplyr::filter(state  == y)%>% dplyr::filter(party=="republican")
  
  state_R_ads_glm <- glm(cbind(R, VEP-R) ~ avg_poll+total_cost, state_R, family = binomial)
  state_D_ads_glm <- glm(cbind(D, VEP-D) ~ avg_poll+total_cost, state_D, family = binomial)
  
  avg_poll_R <- predictData_2020 %>%
    filter(state == y, party == "republican") %>%
    select(avg_poll)
  avg_poll_R <- avg_poll_R$avg_poll[[1]]
  
  avg_poll_D <- predictData_2020 %>%
    filter(state == y, party == "democrat") %>%
    select(avg_poll)
  avg_poll_D <- avg_poll_D$avg_poll[[1]]
  
  total_cost_R <- predictData_2020 %>%
    filter(state == y, party == "republican") %>%
    select(total_cost)
  total_cost_R <- total_cost_R$total_cost[[1]]
  
  total_cost_D <- predictData_2020 %>%
    filter(state == y, party == "democrat") %>%
    select(total_cost)
  total_cost_D <- total_cost_D$total_cost[[1]]
  
  prob_Dvote_2020 <- predict(state_D_ads_glm, newdata = data.frame(avg_poll=avg_poll_D, total_cost = total_cost_D), type="response")[[1]]
  prob_Rvote_2020 <- predict(state_R_ads_glm, newdata = data.frame(avg_poll=avg_poll_R, total_cost = total_cost_R), type="response")[[1]]
  
  cbind.data.frame(y , prob_Dvote_2020 , prob_Rvote_2020)
  
  
})
  
state_predictions_df_og <- do.call(rbind, state_predictions_df)
state_predictions_df <- state_predictions_df_og %>% 
  mutate(win_margin = ifelse(prob_Dvote_2020>=prob_Rvote_2020, "Democrat", "Republican")) %>% 
  mutate(state = y) %>%
  select(state,win_margin)

state_predictions_df <- as.data.frame(state_predictions_df, col.names = c("win_margin", "state"))

electoralCollege <- read.csv("Data/ElectoralCollegePost1948.csv")
electoralCollege %>% select(X,X2020) %>% 
  filter(!is.na(X2020)) %>% 
  mutate(state = X) %>% 
  left_join(state_predictions_df) %>% 
  filter(!is.na(win_margin)) %>%
  group_by(win_margin) %>% 
  summarize(X2020 = sum(X2020))

plot_usmap(data = state_predictions_df, regions = "states", values = "win_margin", color = "white") +
  scale_fill_manual(values = c("blue", "#DC143C"), name = "") + 
  theme_void()+
  labs(title = "Predicted 2020 Electoral College State Wins based on Campaign Ad Spending Model",
       caption = "Joe Biden Electoral College Votes = 340
       Donald Trump Electoral College Votes = 192") +
  blogMapGraphics_theme +
  theme(legend.position = "none")+
ggsave("2020AdPrediction.png", height = 8, width = 8)

## Win Margins table
colnames(state_predictions_df_og) <- c("State", "Democrats Turnout", "Republican Turnout")
state_predictions_df_og$`Republican Turnout` = round(state_predictions_df_og$`Republican Turnout`, 2)
state_predictions_df_og$`Democrats Turnout` = round(state_predictions_df_og$`Democrats Turnout`, 2)

ft<- flextable(state_predictions_df_og) %>% 
  add_header_lines("2020 Voter Turnout For Each Party By State") %>% 
  font(fontname = "Garamond", part = "all") %>% 
  fontsize(i = NULL, j = NULL, size = 14, part = "header") %>% 
  align(align = "center", part = "all") %>% 
  width(width = 1.5)
ft <- color(ft, i = ~ (`Democrats Turnout`> `Republican Turnout`), color = "Blue", j = 2 )
ft <- color(ft, i = ~ (`Democrats Turnout` < `Republican Turnout`), color = "Red", j = 3 )

ft
save_as_image(x = ft, path = "VoterTurnout2020.png")

