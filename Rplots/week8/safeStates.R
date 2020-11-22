#### Poll Model ####
#### Gov 1347: Election Analysis (2020)
#### Grace Kim

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#
library(usmap)
library(tidyverse)
library(ggplot2)
library(janitor)
library(extrafont)
library(ggrepel)
library(gt)

library(webshot)
library(flextable)
library(broom)
loadfonts(device = "win")

setwd("~")

blogMapGraphics_theme <- theme(panel.border = element_blank(),
                               text         = element_text(family = "Garamond"),
                               plot.title   = element_text(size = 15, hjust = 0.5), 
                               strip.text   = element_text(size = 18),
                               legend.position = "bottom",
                               legend.direction = "horizontal",
                               legend.text = element_text(size = 12))


# pretty blog theme :D
blogGraphics_theme <- theme_bw()+
  theme(panel.border = element_blank(),
        text         = element_text(family = "Garamond"),
        plot.title   = element_text(size = 18, hjust = 0.5),
        axis.text    = element_text(size = 12),
        strip.text   = element_text(size = 15),
        axis.title   = element_text(size = 15),
        axis.line    = element_line(colour = "black"),
        plot.caption = element_text(size = 12),
        plot.caption.position = "plot",
        legend.position = "bottom",
        legend.direction = "horizontal",
        legend.text = element_text(size = 12))

#####------------------------------------------------------#
##### Read and merge data ####
#####------------------------------------------------------#

popvote_df <- read_csv("Data/popvote_bystate_1948-2016.csv")
economy_df <- read_csv("Data/econ.csv")
poll_df    <- read_csv("Data/pollavg_1968-2016.csv")
poll_df_2020 <- read_csv("Data/polls_2020.csv")

dat <- popvote_df %>% 
  full_join(poll_df %>% 
              filter(weeks_left == 1) %>% 
              group_by(year,party) %>% 
              summarise(avg_support=mean(avg_support)))

#####------------------------------------------------------#
#####  Out of Sample Testing Polls - Find the safe states
#####------------------------------------------------------#
dat_test <- dat %>% 
  select(year,state,R_pv2p,D_pv2p,avg_support,party)

all_years <- seq(from=1976, to=2016, by=4)
all_states <- state.name
outsamp_dflist <- lapply(all_states, function(state_name){
  year <- lapply(all_years, function(year){
    test <- dat_test %>% 
      filter(state == state_name)
    true_rep <- unique(test$R_pv2p[test$year == year])
    true_dem <- unique(test$D_pv2p[test$year == year])

    ## Historical Poll model out-of-sample prediction
    mod_poll_rep_ <- glm(R_pv2p ~ avg_support, data = test[test$year != year,] %>% filter(party == "republican"))
    mod_poll_dem_ <- glm(D_pv2p ~ avg_support, data = test[test$year != year,] %>% filter(party == "democrat"))
    pred_poll_rep <- predict(mod_poll_rep_, test[test$year == year,]%>% filter(party == "republican"))
    pred_poll_dem <- predict(mod_poll_dem_, test[test$year == year,]%>% filter(party == "democrat"))
    
    cbind.data.frame(year,
                     state_name,
                     error = (pred_poll_rep-pred_poll_dem) - (true_rep-true_dem),
                     winner_correct = (pred_poll_rep > pred_poll_dem) == (true_rep > true_dem))
  })
})
outsamp_df <- do.call(rbind, outsamp_dflist) 

poll_stats <- lapply(1:50,function(y){
  do.call(rbind, outsamp_df[y,]) %>% 
    group_by(state_name) %>% 
    summarize(error = mean(error), 
              winner_correct = sum(winner_correct)/11)
})
poll_stats <- do.call(rbind, poll_stats)

safe_states <- poll_stats %>% 
  filter(winner_correct > 0.9)

ft<- flextable(poll_stats) %>% 
  add_header_lines("Determining Safe states, Poll Model Error and Correct Winner Predictions 1976-2016") %>% 
  font(fontname = "Garamond", part = "all") %>% 
  fontsize(i = NULL, j = NULL, size = 14, part = "header") %>% 
  align(align = "center", part = "all") %>% 
  width(width = 1.5) %>% 
  footnote(part = "header", i = 2, j = 3,
           value = as_paragraph(
             c("Correctness percentages calculated from out of sample testing of 11 elections between 1976-2016")))

scale = scales::col_numeric(domain= c(-1, 1), palette ="RdBu")
ft <- color(ft, j = 3, color = scale)
ft
save_as_image(x = ft, path = "OutOfSampleTestingPolls.png")


#####------------------------------------------------------#
#####  Safe States predictions
#####------------------------------------------------------#
clean_poll_2020 <- poll_df_2020 %>% 
  filter(candidate_id %in% c(13254, 13256)) %>% 
  filter(!is.na(state)) %>% 
  filter(!is.na(end_date)) %>% 
  group_by(state, candidate_name) %>% 
  summarise(pct=mean(pct))

colnames(clean_poll_2020) <- c("state", "candidate", "avg_support")

## Get names for safe states
states<-clean_poll_2020 %>% 
  filter(state %in% statesNames) %>% 
  slice(which(row_number() %% 2 == 1))


safeStates_Predictions <- lapply(states$state, function(state_name){

  poll_2020_R <- clean_poll_2020 %>% filter(state == state_name & candidate == "Donald Trump")
  poll_2020_D <- clean_poll_2020 %>% filter(state == state_name & candidate == "Joseph R. Biden Jr.")
  
  mod_poll_rep_ <- glm(R_pv2p ~ avg_support, data = dat_test %>% filter(party == "republican" & state == state_name))
  mod_poll_dem_ <- glm(D_pv2p ~ avg_support, data = dat_test %>% filter(party == "democrat" & state == state_name))
  pred_poll_rep <- predict(mod_poll_rep_, poll_2020_R) 
  pred_poll_dem <- predict(mod_poll_dem_, poll_2020_D)
  
  cbind.data.frame(state = state_name,
                   pred_Rpvp = pred_poll_rep,
                   pred_Dpvp = pred_poll_dem,
                   win_margin = pred_poll_dem - pred_poll_rep)
})
safeStates_Predictions_map <- do.call(rbind, safeStates_Predictions)
plot_usmap(data = safeStates_Predictions_map, regions = "states", values = "win_margin") +
  scale_fill_gradient2(
  high = "#007FFF", 
  #mid = scales::muted("purple"), ##TODO: purple or white better?
  mid = "white", 
  low = "#DC143C", 
  breaks = c(-50,-25,0,25,50), 
  limits = c(-50,50),
  name = "Popular Vote Win Margins",
  guide = guide_colourbar(barwidth = 20, barheight = 0.4,
                          title.position = "top"))+
  labs(title = "Safe States Predicted Win Margins 2020")+
  theme_void()+
  blogMapGraphics_theme
ggsave("WinMarginsSafeStates2020.png", height = 8, width = 8)

ft<- flextable(safeStates_Predictions_map) %>% 
  add_header_lines("Safe states, Predicted Popular Vote Percentages and Win Margins") %>% 
  font(fontname = "Garamond", part = "all") %>% 
  fontsize(i = NULL, j = NULL, size = 14, part = "header") %>% 
  align(align = "center", part = "all") %>% 
  width(width = 1.5) %>% 
  footnote(part = "header", i = 2, j = 3,
           value = as_paragraph(
             c("Safe states determined from poll model that had at least 90% correct match percentage for previous 11 elections")))

ft <- color(ft, i = ~ (pred_Dpvp > pred_Rpvp), color = "Blue", j = 4 )
ft <- color(ft, i = ~ (pred_Dpvp < pred_Rpvp), color = "Red", j = 4 )

ft
save_as_image(x = ft, path = "SafeStatesPollModelTable.png")


### Simulations!!!
vep_df <- read_csv("Data/vep_1980-2020.csv") %>% 
  filter(year == 2020)

covid_deaths <- read_csv("Data/Provisional_COVID-19_Death_Counts_in_the_United_States_by_County.csv") %>% 
  clean_names()
covid_deaths <- covid_deaths %>% 
  group_by(state) %>% 
  summarize(deaths = sum(deaths_involving_covid_19))
covid_deaths$state = state.name[match(covid_deaths$state, state.abb)]

R_poll <- 43.4
D_poll <- 52.0
national_polling_avg_R <- cbind(state.name, R_poll)
national_polling_avg_D <- cbind(state.name, D_poll)
national_polls <- merge(national_polling_avg_D,national_polling_avg_R)

clean_poll_2020<-merge(clean_poll_2020 %>% 
        filter(state %in% state.name & candidate == "Donald Trump") %>% 
        select(state, avg_support_R = avg_support),
      clean_poll_2020 %>% 
        filter(state %in% state.name & candidate != "Donald Trump") %>% 
        select(state, avg_support_D = avg_support))

clean_poll_2020<- clean_poll_2020 %>% 
  filter(state %in% state.name) %>% 
  full_join(national_polls, by = c("state" = "state.name"))

clean_poll_2020$avg_support_D[clean_poll_2020$state == c("Illinois",
                                                         "Nebraska",
                                                         "Rhode Island",
                                                         "South Dakota",
                                                         "Wyoming")] <- 52

clean_poll_2020$avg_support_R[clean_poll_2020$state == c("Illinois",
                                                         "Nebraska",
                                                         "Rhode Island",
                                                         "South Dakota",
                                                         "Wyoming")] <- 43.4
clean_poll_2020
biden_popVote<- 0
trump_popVote<- 0

Polling_Predictions <- lapply(clean_poll_2020$state, function(state_name){
  
  poll_2020_R <- clean_poll_2020 %>% filter(state == state_name)
  colnames(poll_2020_R)[2] <- "avg_support"
  poll_2020_D <- clean_poll_2020 %>% filter(state == state_name)
  colnames(poll_2020_D)[2] <- "avg_support"
  
  mod_poll_rep_ <- glm(R_pv2p ~ avg_support, data = dat_test %>% filter(party == "republican" & state == state_name))
  mod_poll_dem_ <- glm(D_pv2p ~ avg_support, data = dat_test %>% filter(party == "democrat" & state == state_name))
  pred_poll_rep <- predict(mod_poll_rep_, poll_2020_R, type = "response")[[1]] 
  pred_poll_dem <- predict(mod_poll_dem_, poll_2020_D, type = "response")[[1]]
  
  pred_poll_rep <- ifelse(state_name %in% states$state, pred_poll_rep, (0.85*pred_poll_rep + 0.15* 45.27866))
  pred_poll_dem <- ifelse(state_name %in% states$state, pred_poll_dem, (0.85*pred_poll_rep + 0.15* 54.72134))
  #sim_Rvotes_2020 <- rbinom(n = 10000, size = VEP_state, prob = pred_poll_rep)
  #sim_Dvotes_2020 <- rbinom(n = 10000, size = VEP_state, prob = pred_poll_dem)
  VEP_state <- subset(vep_df, state == state_name)[3] -  subset(covid_deaths, state == state_name)[2]

  cbind.data.frame(state = state_name,
                   pred_Rpvp = pred_poll_rep /(pred_poll_dem + pred_poll_rep),
                   biden = VEP_state * pred_poll_dem/100,
                   pred_Dpvp = pred_poll_dem /(pred_poll_dem + pred_poll_rep),
                   trump = VEP_state * pred_poll_rep/100,
                   win_margin = pred_poll_dem - pred_poll_rep)
})
Predictions_map <- do.call(rbind, Polling_Predictions)
#Trump popular vote
(sum(Predictions_map[3]))/(sum(Predictions_map[3]) + sum(Predictions_map[5]))
#Biden popular vote
(sum(Predictions_map[5]))/(sum(Predictions_map[3]) + sum(Predictions_map[5]))

Predictions_map <- Predictions_map %>% select(win_margin,state) %>% mutate(win = ifelse(win_margin > 0, "D", "R"))

Predictions_map

popvote_2020_states <- read_csv("Data/popvote_bystate_1948-2020.csv")

offmargins <- popvote_2020_states %>% 
  filter(year == 2020) %>% 
  mutate(win_margins2020 = (D_pv2p-R_pv2p)*100) %>% 
  left_join(Predictions_map) %>% 
  mutate(offMargins = win_margin-win_margins2020) %>% 
  select(offMargins,state, win_margins2020,win_margin)
offmargins
plot_usmap(data = offmargins, regions = "state", values = "offMargins") +
  scale_fill_gradient2(
    high = "#007FFF", 
    #mid = scales::muted("purple"), ##TODO: purple or white better?
    mid = "white", 
    low = "#DC143C", 
    breaks = c(-50,-25,0,25,50), 
    limits = c(-50,50),
    name = "Margins Error",
    guide = guide_colourbar(barwidth = 20, barheight = 0.4,
                            title.position = "top"))+
  labs(title = "Error Margins")+
  theme_void()+
  blogMapGraphics_theme







plot_usmap(data = Predictions_map, regions = "states", values = "win") +
  scale_fill_manual(values = c("blue", "#DC143C"), name = "State Electoral College winner") +
  labs(title = "Electoral College Predicted Wins 2020",
       caption = "Joe Biden Electoral College Votes = 372, Donald Trump Electoral College Votes = 166")+
  theme_void()+
  blogMapGraphics_theme+
  theme(legend.position = "none")
ggsave("WinsElectoralCollege2020.png", height = 8, width = 8)

electoralCollege <- read.csv("Data/ElectoralCollegePost1948.csv")
electoralCollege %>% select(X,X2020) %>% 
  filter(!is.na(X2020)) %>% 
  mutate(state = X) %>% 
  left_join(Predictions_map) %>% 
  group_by(win) %>% 
  summarize(X2020 = sum(X2020))

ft<- flextable(Predictions_map %>% 
                 select(state, pred_Dpvp, pred_Rpvp,win)) %>% 
  add_header_lines("Final Predicted Popular Vote Percentages and Win Margins") %>% 
  font(fontname = "Garamond", part = "all") %>% 
  fontsize(i = NULL, j = NULL, size = 14, part = "header") %>% 
  align(align = "center", part = "all") %>% 
  width(width = 1.5) %>% 
  footnote(part = "header", i = 2, j = 4,
           value = as_paragraph(
             c("Ensemble Model of economy and State/national poll averages")))

ft <- color(ft, i = ~ (pred_Dpvp > pred_Rpvp), color = "Blue", j = 4 )
ft <- color(ft, i = ~ (pred_Dpvp < pred_Rpvp), color = "Red", j = 4 )
ft

save_as_image(x = ft, path = "Final PredictionsTable.png")

total_deaths <- sum(covid_deaths$deaths)
Predictions_map<-Predictions_map %>% 
  inner_join(covid_deaths) %>% 
  mutate(lwr = (win_margin - 100*deaths/total_deaths), upr = (win_margin + 100*deaths/total_deaths))

ggplot(Predictions_map, 
       aes(y=state, x=win_margin, xmin=lwr, xmax=upr, color=win), margin(5,5,100,100)) +
  geom_pointrange(position = position_dodge(width = 0.5)) + 
  scale_color_brewer(palette = "Dark2") +
  blogGraphics_theme +
  xlab("Popular Vote Win Margins")+
  ylab("States")+
  labs(title = "Uncertainty Popular Vote Win Margins")

ggsave("Uncertainty2020.png", height = 12, width = 8)
