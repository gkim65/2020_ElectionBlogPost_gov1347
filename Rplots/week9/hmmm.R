
margins<-dat_test%>%   
  group_by(state) %>%
  mutate(win_margins = D_pv2p - R_pv2p)%>%
  mutate(win_margins_poll = avg_support - lag(avg_support, default = avg_support[1]))%>%
  mutate(Win = ifelse(win_margins_poll>0, "R","D"))
view(margins[seq(2, nrow(margins), 2), ])

cleaner_2020<-merge(clean_poll_2020 %>% 
                      filter(state %in% state.name & candidate == "Donald Trump") %>% 
                      select(state, avg_support_R = avg_support),
                    clean_poll_2020 %>% 
                      filter(state %in% state.name & candidate != "Donald Trump") %>% 
                      select(state, avg_support_D = avg_support)) %>% 
  filter(state %in% state.name) %>% 
  full_join(national_polls, by = c("state" = "state.name"))

cleaner_2020$avg_support_D[cleaner_2020$state == c("Illinois",
                                                   "Nebraska",
                                                   "Rhode Island",
                                                   "South Dakota",
                                                   "Wyoming")] <- 52

cleaner_2020$avg_support_R[cleaner_2020$state == c("Illinois",
                                                   "Nebraska",
                                                   "Rhode Island",
                                                   "South Dakota",
                                                   "Wyoming")] <- 43.4
view(clean_poll_2020)
polls_only<- cleaner_2020 %>%   
  group_by(state) %>%
  mutate(win_margins_poll = 8.6)%>%
  mutate(Win = ifelse(win_margins_poll>0, "D","R"))
view(polls_only[seq(2, nrow(polls_only), 2), ])


Polling_Predictions <- lapply(cleaner_2020$state, function(state_name){
  
  poll_2020_R <- cleaner_2020 %>% filter(state == state_name)
  colnames(poll_2020_R)[2] <- "avg_support"
  poll_2020_D <- cleaner_2020 %>% filter(state == state_name)
  colnames(poll_2020_D)[2] <- "avg_support"
  df<- margins %>% filter(state == state_name)

  mod_poll_rep_ <- glm(R_pv2p ~ avg_support, data = margins %>% filter(party == "republican" & state == state_name))
  mod_poll_dem_ <- glm(D_pv2p ~ avg_support, data = margins %>% filter(party == "democrat" & state == state_name))
  mod_poll_margin_ <- glm(win_margins ~ win_margins_poll, data = df[seq(2, nrow(df), 2), ])
  pred_poll_rep <- predict(mod_poll_rep_, poll_2020_R, type = "response")[[1]] 
  pred_poll_dem <- predict(mod_poll_dem_, poll_2020_D, type = "response")[[1]]
  pred_poll_margin <- predict(mod_poll_margin_, 8.6, type = "response")[[1]]
  
  #pred_poll_rep <- ifelse(state_name %in% states$state, pred_poll_rep, (0.85*pred_poll_rep + 0.15* 45.27866))
  #pred_poll_dem <- ifelse(state_name %in% states$state, pred_poll_dem, (0.85*pred_poll_dem + 0.15* 54.72134))
  #sim_Rvotes_2020 <- rbinom(n = 10000, size = VEP_state, prob = pred_poll_rep)
  #sim_Dvotes_2020 <- rbinom(n = 10000, size = VEP_state, prob = pred_poll_dem)
  VEP_state <- subset(vep_df, state == state_name)[3] -  subset(covid_deaths, state == state_name)[2]
  
  cbind.data.frame(state = state_name,
                   win_margin = pred_poll_margin,
                   pred_Rpvp = pred_poll_rep /(pred_poll_dem + pred_poll_rep),
                   biden = VEP_state * pred_poll_dem/100,
                   pred_Dpvp = pred_poll_dem /(pred_poll_dem + pred_poll_rep),
                   trump = VEP_state * pred_poll_rep/100,
                   win_margin = pred_poll_dem - pred_poll_rep)
})

Polling_Predictions2 <- lapply(polls_only$state, function(state_name){
  
  poll_2020_R <- polls_only %>% filter(state == state_name)
  #colnames(poll_2020_R)[6] <- "win_margins_poll"
  poll_2020_D <- polls_only %>% filter(state == state_name)
  #colnames(poll_2020_D)[6] <- "win_margins_poll"
  df<- margins %>% filter(state == state_name)
  
  #mod_poll_rep_ <- glm(R_pv2p ~ avg_support, data = margins %>% filter(party == "republican" & state == state_name))
  #mod_poll_dem_ <- glm(D_pv2p ~ avg_support, data = margins %>% filter(party == "democrat" & state == state_name))
  mod_poll_margin_ <- lm(win_margins ~ win_margins_poll, data = df[seq(2, nrow(df), 2), ])
  #pred_poll_rep <- predict(mod_poll_rep_, poll_2020_R, type = "response")[[1]] 
  #pred_poll_dem <- predict(mod_poll_dem_, poll_2020_D, type = "response")[[1]]
  pred_poll_margin <- predict(mod_poll_margin_, poll_2020_D, type = "response")
  
  #pred_poll_rep <- ifelse(state_name %in% states$state, pred_poll_rep, (0.85*pred_poll_rep + 0.15* 45.27866))
  #pred_poll_dem <- ifelse(state_name %in% states$state, pred_poll_dem, (0.85*pred_poll_dem + 0.15* 54.72134))
  #sim_Rvotes_2020 <- rbinom(n = 10000, size = VEP_state, prob = pred_poll_rep)
  #sim_Dvotes_2020 <- rbinom(n = 10000, size = VEP_state, prob = pred_poll_dem)
  VEP_state <- subset(vep_df, state == state_name)[3] -  subset(covid_deaths, state == state_name)[2]
  
  cbind.data.frame(state = state_name,
                   win_margin = pred_poll_margin)
                   #pred_Rpvp = pred_poll_rep /(pred_poll_dem + pred_poll_rep),
                   #biden = VEP_state * pred_poll_dem/100,
                   #pred_Dpvp = pred_poll_dem /(pred_poll_dem + pred_poll_rep),
                   #trump = VEP_state * pred_poll_rep/100,
                   #win_margin = pred_poll_dem - pred_poll_rep)
})

Predictions_map2 <- do.call(rbind, Polling_Predictions2)
Predictions_map2 %>% 
  mutate(win_margins = win_margin+8.6) %>% 
  mutate(win = ifelse(win_margins>0,"D","R"))

summary(glm(R_pv2p ~ avg_support, data = margins %>% filter(party == "democrat" & state == "Hawaii")))
plot_usmap(data = Predictions_map2 %>% 
             mutate(win_margins = win_margin+8.6) %>% 
             mutate(win = ifelse(win_margins>0,"D","R")), regions = "state", values = "win") +
  scale_fill_manual(values = c("blue", "#DC143C"), name = "State Electoral College winner") +
  labs(title = "Safe States Predicted Win Margins 2020")+
  theme_void()+
  blogMapGraphics_theme
