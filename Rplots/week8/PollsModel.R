#### Poll Model ####
#### Gov 1347: Election Analysis (2020)
#### Grace Kim

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#

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
#####  Model Polls Historical ####
#####------------------------------------------------------#

## Historical Election polls model
dat_poll     <- dat[!is.na(dat$avg_support),]
dat_poll_inc <- dat_poll[dat_poll$incumbent_party,]
dat_poll_chl <- dat_poll[!dat_poll$incumbent_party,]
mod_poll_inc <- lm(pv ~ avg_support, data = dat_poll_inc)
mod_poll_chl <- lm(pv ~ avg_support, data = dat_poll_chl)

summary(mod_poll_inc)
summary(mod_poll_chl)

incumbent.labs <- c("Incumbent", "Challenger")
names(incumbent.labs) <- c(TRUE,FALSE)

## Popular Vote Vs. Polling Historical Election Data
dat_poll %>%
  ggplot(aes(x=avg_support, y=pv,
             label=year)) + 
  geom_label_repel(aes(fill = factor(party)),
                   colour = "white",
                   fontface = "bold", 
                   size = 4,
                   force =0.005) +
  scale_fill_manual(values = c("#007FFF", "#DC143C"), name = "")+
  geom_smooth(method="lm", formula = y ~ x, color = "#003466") +
  geom_hline(yintercept=median(dat_poll$pv), lty=2) +
  geom_vline(xintercept=median(dat_poll$avg_support), lty=2) + # median
  xlab("Average Voter Support 6 weeks Before Election") +
  ylab("National popular vote percentages") +
  theme_bw()+
  facet_wrap(~incumbent_party, labeller  = labeller(incumbent_party = incumbent.labs)) +
  blogGraphics_theme

ggsave("PopularVoteVSPolling.png", height = 5, width = 8)

#####------------------------------------------------------#
#####  Model Polls 2020 ####
#####------------------------------------------------------#

# Data Cleaning
clean_poll_2020 <- poll_df_2020 %>% 
  filter(candidate_id %in% c(13254, 13256)) %>% 
  filter(is.na(state)) %>% 
  filter(!is.na(end_date)) %>% 
  group_by(end_date, candidate_name) %>% 
  summarise(pct=mean(pct))

clean_poll_2020$end_date <- as.Date(clean_poll_2020$end_date, "%m/%d/%Y")

# Timeline of Poll Data Over april to present 2020
clean_poll_2020 %>% 
  ggplot(aes(x = end_date, y = pct, color = candidate_name)) +
  geom_line() +
  geom_point(size = 1) +
  geom_rect(xmin=as.Date("0020-08-17"), xmax=as.Date("0020-08-20"), ymin= 50, ymax=100, alpha=0.01, colour=NA, fill="dark grey") +
  annotate("text", x=as.Date("0020-08-15"), y=55, label="DNC", size=4) +
  geom_rect(xmin=as.Date("0020-08-24"), xmax=as.Date("0020-08-27"), ymin=0, ymax=43, alpha=0.01, colour=NA, fill="dark grey") +
  annotate("text", x=as.Date("0020-08-30"), y=35, label="RNC", size=4) +
  xlab("") +
  ylab("Polling Approval Average") +
  scale_x_date(limits = as.Date(c("0020-04-01","0020-10-1")), date_labels = "%b %d")+
  scale_color_manual(values = c("#DC143C","#007FFF"), name = "")+
  blogGraphics_theme +
  theme(legend.box.margin=margin(-25,0,0,0))

ggsave("JoeVSDonald.png", height = 5, width = 8)

# 2020 Poll Models
dat_poll_Dem2020 <- clean_poll_2020 %>% 
  filter(candidate_name == "Joseph R. Biden Jr.") %>% 
  filter(end_date >= as.Date("0020-04-01"))

dat_poll_Rep2020 <- clean_poll_2020 %>% 
  filter(candidate_name == "Donald Trump") %>% 
  filter(end_date >= as.Date("0020-04-01"))

mod_poll_Dem2020 <- lm(pct ~ end_date, data = dat_poll_Dem2020)
mod_poll_Rep2020 <- lm(pct ~ end_date, data = dat_poll_Rep2020)

summary(mod_poll_Dem2020)
summary(mod_poll_Rep2020)


#####------------------------------------------------------#
#####  Out of Sample Testing ####
#####------------------------------------------------------#

# For Historical Election Data
all_years <- seq(from=1968, to=2016, by=4)
outsamp_dflist <- lapply(all_years, function(year){
  
  true_inc <- unique(dat$pv[dat$year == year & dat$incumbent_party])
  true_chl <- unique(dat$pv[dat$year == year & !dat$incumbent_party])
  
  ## Historical Poll model out-of-sample prediction
  mod_poll_inc_ <- lm(pv ~ avg_support, data = dat_poll_inc[dat_poll_inc$year != year,])
  mod_poll_chl_ <- lm(pv ~ avg_support, data = dat_poll_chl[dat_poll_chl$year != year,])
  pred_poll_inc <- predict(mod_poll_inc_, dat_poll_inc[dat_poll_inc$year == year,])
  pred_poll_chl <- predict(mod_poll_chl_, dat_poll_chl[dat_poll_chl$year == year,])
  
  cbind.data.frame(year,
                   poll_margin_error_historical = (pred_poll_inc-pred_poll_chl) - (true_inc-true_chl),
                   poll_winner_correct_historical = (pred_poll_inc > pred_poll_chl) == (true_inc > true_chl)
  )
})
outsamp_df <- do.call(rbind, outsamp_dflist) #

OutSampleTests <- data.frame( "PollType" = "Historical", 
                              "Error" = colMeans(abs(outsamp_df[2]), na.rm=T), 
                              "Percentage Correct" = colMeans(outsamp_df[3], na.rm=T))

outsamp_df[,c("year","econ_winner_correct","poll_winner_correct","plus_winner_correct")] #

# Out of Sample Testing for 2020 Election Data

dates <- dat_poll_Dem2020$end_date
outsamp_dflist_2020 <- lapply(dates, function(date){
  
  true_inc <- unique(dat_poll_Dem2020$pct[dat_poll_Dem2020$end_date == date])
  true_chl <- unique(dat_poll_Rep2020$pct[dat_poll_Rep2020$end_date == date])
  
  ## This Year's poll model out of sample prediction
  mod_poll_Dem2020 <- lm(pct ~ end_date, data = dat_poll_Dem2020[dat_poll_Dem2020$end_date != date,])
  mod_poll_Rep2020 <- lm(pct ~ end_date, data = dat_poll_Rep2020[dat_poll_Rep2020$end_date != date,])
  pred_poll_inc <- predict(mod_poll_Rep2020, data = dat_poll_Rep2020[dat_poll_Rep2020$end_date != date,])
  pred_poll_chl <- predict(mod_poll_Dem2020, data = dat_poll_Dem2020[dat_poll_Dem2020$end_date != date,])
  
  cbind.data.frame(date,
                   poll_margin_error_2020 = (pred_poll_inc-pred_poll_chl) - (true_inc-true_chl),
                   poll_winner_correct = (pred_poll_inc - true_inc + pred_poll_chl - true_chl) < 2
  )
})
outsamp_df_2020 <- do.call(rbind, outsamp_dflist_2020) #
OutSampleTests <- rbind(OutSampleTests, list("2020",
                                             colMeans(abs(outsamp_df_2020[2]), na.rm=T), 
                                             colMeans(outsamp_df_2020[3], na.rm=T)
))
rownames(OutSampleTests) <- c("Historical", "2020")
colnames(OutSampleTests) <- c("", "Poll Margin Error", "Percentage Correct")
OutSampleTests <- as.data.frame(OutSampleTests %>% t())

# Final Combined table of Out of Sample Testing
ft<- flextable(OutSampleTests[2:3,] %>% rownames_to_column(" ")) %>% 
  add_header_lines("Out of Sample Testing Conducted Over All Historical and 2020 Polls") %>% 
  font(fontname = "Garamond", part = "all") %>% 
  fontsize(i = NULL, j = NULL, size = 14, part = "header") %>% 
  align(align = "center", part = "all") %>% 
  width(width = 1.5) %>% 
  footnote(part = "body", i = 2, j = 3,
           value = as_paragraph(
             c("Correctness of 2020 out of sample testing was found through whether or not the predicted poll percentages were within 2% of actual recorded poll values.")))

ft
save_as_image(x = ft, path = "OutOfSampleTesting.png")


#####------------------------------------------------------#
#####  FINAL PREDICTIONS! ####
#####------------------------------------------------------#

dat_2020_inc <- data.frame(avg_support = 43.5)
dat_2020_chl <- data.frame(avg_support = 50.5)
final_Predict <- data.frame(end_date = as.Date("0020-11-03"))


(pred_poll_inc <- predict(mod_poll_inc, dat_2020_inc, 
                          interval = "prediction", level=0.95))
(pred_poll_chl <- predict(mod_poll_chl, dat_2020_chl, 
                          interval = "prediction", level=0.95))

(pred_poll_2020Rep <- predict(mod_poll_Rep2020, final_Predict, 
                              interval = "prediction", level=0.95))
(pred_poll_2020Dem <- predict(mod_poll_Dem2020, final_Predict, 
                              interval = "prediction", level=0.95))

historical_wt <- 0.6; current_wt <- 0.4;
together_trump <- historical_wt*predict(mod_poll_inc, dat_2020_inc,interval = "prediction", level=0.95) + current_wt*predict(mod_poll_Rep2020, final_Predict,interval = "prediction", level=0.95)
together_biden <- historical_wt*predict(mod_poll_chl, dat_2020_chl,interval = "prediction", level=0.95) + current_wt*predict(mod_poll_Dem2020, final_Predict,interval = "prediction", level=0.95)

pred_df <- rbind.data.frame(
  data.frame(pred_poll_2020Rep, Model="2020", candidate="Trump"),
  data.frame(pred_poll_2020Dem, Model="2020", candidate="Biden"),
  data.frame(pred_poll_inc, Model="Historical", candidate="Trump"),
  data.frame(pred_poll_chl, Model="Historical", candidate="Biden"),
  data.frame(together_trump, Model="Together", candidate="Trump"),
  data.frame(together_biden, Model="Together", candidate="Biden")
)
pred_df
ggplot(pred_df, 
       aes(x=candidate, y=fit, ymin=lwr, ymax=upr, color=Model), margin(5,5,100,100)) +
  geom_pointrange(position = position_dodge(width = 0.5)) + 
  scale_color_brewer(palette = "Dark2") +
  blogGraphics_theme +
  xlab("")+
  ylab("Predictions of Popular Vote Predictions")+
  labs(title = "Model Predictions of Popular Vote Percentage")

ggsave("predictions.png", height = 6, width = 6)
