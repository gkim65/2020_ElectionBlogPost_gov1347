#### Poll Model ####
#### Gov 1347: Election Analysis (2020)
#### Grace Kim

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#
library(usmap)
library(tidyverse)
library(ggplot2)
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
states$state

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
