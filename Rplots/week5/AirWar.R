#### Air War ####
#### Gov 1347: Election Analysis (2020)
#### Grace Kim

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#

## install via `install.packages("name")`
library(tidyverse)
library(ggplot2)
library(scales)
library(extrafont)
library(tibble)
library(webshot)
library(flextable)
library(dplyr)
library(tibble)
library(cowplot)
loadfonts(device = "win")

## set working directory here
setwd("~")

## Made my "pretty" customized theme
blogGraphics_theme <- theme_bw()+
  theme(panel.border = element_blank(),
        text         = element_text(family = "Garamond"),
        plot.title   = element_text(size = 18, hjust = 0.5),
        axis.text    = element_text(size = 12),
        strip.text   = element_text(size = 15),
        axis.title   = element_text(size = 15),
        axis.line    = element_line(colour = "black"),
        strip.background =element_rect(fill="white"),
        legend.position = "bottom",
        legend.direction = "horizontal",
        legend.text = element_text(size = 12))

ad_campaigns <- read_csv("ad_campaigns_2000-2012.csv")

####----------------------------------------------------------#
#### Campaign Ad Spending over time
####----------------------------------------------------------#

## Campaign ad spending over time 2000-2012

ad_campaigns %>%
  mutate(year = as.numeric(substr(air_date, 1, 4))) %>%
  mutate(month = as.numeric(substr(air_date, 6, 7))) %>%
  filter(year %in% c(2000, 2004, 2008, 2012), month > 7) %>%
  group_by(cycle, air_date, party) %>%
  summarise(total_cost = sum(total_cost)) %>%
  ggplot(aes(x=air_date, y=total_cost, color=party)) +
  # scale_x_date(date_labels = "%b, %Y") +
  scale_y_continuous(labels = dollar_format()) +
  scale_color_manual(values = c("#007FFF", "#DC143C"), name = "") +
  geom_line() + geom_point(size=0.5) +
  facet_wrap(cycle ~ ., scales="free") +
  xlab("") + ylab("Ad spending levels") +
  theme_bw() +
  blogGraphics_theme

#####------------------------------------------------------#
##### 2020 Campaign Ad spending over time vs. national polling averages 2020
#####------------------------------------------------------#

# First get data from both biden ads and trump ads
biden_ads_2020 <- read_csv("Data/Biden_2020AdSpending.csv")
trump_ads_2020 <- read_csv("Data/Trump_2020AdSpending.csv")

bidenAds_clean <- biden_ads_2020 %>% 
  select(recipient_state, disbursement_date,disbursement_amount) %>% 
  group_by(disbursement_date) %>%
  summarise(total_cost = sum(disbursement_amount)) %>% 
  mutate(candidate_name = "Joseph R Biden Jr.")
  
trumpAds_clean <- trump_ads_2020 %>% 
  select(recipient_state, disbursement_date,disbursement_amount) %>% 
  group_by(disbursement_date) %>%
  summarise(total_cost = sum(disbursement_amount)) %>% 
  mutate(candidate_name = "Donald Trump")

# bind the two data sets from trump and biden together
AllAds <- rbind(trumpAds_clean, bidenAds_clean)

# plot the ads dataset over time
AdPlot2020 <- AllAds %>% 
  ggplot(aes(x=disbursement_date, y=total_cost, color = candidate_name)) +
  scale_y_continuous(labels = dollar_format()) +
  geom_line() + geom_point(size=0.5) +
  scale_color_manual(values = c("#DC143C","#007FFF"), name = "") +
  xlab("") + ylab("Ad spending levels") +
  theme_bw() +
  blogGraphics_theme +
  theme(legend.box.margin=margin(-25,0,0,0))

AdPlot2020
ggsave("2020AdSpending.png", height = 5, width = 8)

# Now revisit polls data set from blog 3
poll_df_2020 <- read_csv("Data/polls_2020.csv")

# Data Cleaning
clean_poll_2020 <- poll_df_2020 %>% 
  filter(candidate_id %in% c(13254, 13256)) %>% 
  filter(is.na(state)) %>% 
  filter(!is.na(end_date)) %>% 
  group_by(end_date, candidate_name) %>% 
  summarise(pct=mean(pct))

clean_poll_2020$end_date <- as.Date(clean_poll_2020$end_date, "%m/%d/%Y")

# Timeline of Poll Data Over april to present 2020
pollAveragePlot <- clean_poll_2020 %>% 
  ggplot(aes(x = end_date, y = pct, color = candidate_name)) +
  geom_line() +
  geom_point(size = 1) +
  xlab("") +
  ylab("Polling Approval Average") +
  scale_x_date(limits = as.Date(c("0020-04-01","0020-10-1")), date_labels = "%b")+
  scale_color_manual(values = c("#DC143C","#007FFF"), name = "")+
  blogGraphics_theme +
  theme(legend.box.margin=margin(-25,0,0,0))
pollAveragePlot

# Put ad spending and poll data side by side
plot_grid(AdPlot2020, pollAveragePlot, rel_widths = c(4, 3))
ggsave("JoeVSDonald.png", height = 5, width = 8)
