#### Air War: Trump Vs. Biden State spending####
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
library(webshot)
library(geofacet) ## map-shaped grid of ggplots
loadfonts(device = "win")

## set working directory here
setwd("~")

## Made my "pretty" customized theme
blogGraphics_theme <- theme_bw()+
  theme(panel.border = element_blank(),
        text         = element_text(family = "Garamond"),
        plot.title   = element_text(size = 10, hjust = 0.5),
        axis.text    = element_text(size = 12),
        strip.text   = element_text(size = 8),
        axis.title   = element_text(size = 15),
        axis.line    = element_line(colour = "black"),
        strip.background =element_rect(fill="white"),
        legend.position = "bottom",
        legend.direction = "horizontal",
        legend.text = element_text(size = 12))

####----------------------------------------------------------#
#### State Campaign Ad Spending For Biden Vs Trump
####----------------------------------------------------------#

# First get data from both biden ads and trump ads
biden_ads_2020 <- read_csv("Data/Biden_2020AdSpending.csv")
trump_ads_2020 <- read_csv("Data/Trump_2020AdSpending.csv")

bidenAds_clean <- biden_ads_2020 %>% 
  select(recipient_state, disbursement_date,disbursement_amount) %>% 
  group_by(recipient_state) %>%
  summarise(total_cost = sum(disbursement_amount)) %>% 
  mutate(candidate_name = "Joseph R Biden Jr.")

trumpAds_clean <- trump_ads_2020 %>% 
  select(recipient_state, disbursement_date,disbursement_amount) %>% 
  group_by(recipient_state) %>%
  summarise(total_cost = sum(disbursement_amount)) %>% 
  mutate(candidate_name = "Donald Trump")

# bind the two data sets from trump and biden together
AllAds <- rbind(trumpAds_clean, bidenAds_clean)
AllAds$recipient_state <- state.name[match(AllAds$recipient_state,state.abb)] 
AllAds %>% 
  filter(!is.na(recipient_state)) %>%
  ggplot(aes(x=candidate_name, y=total_cost, fill=candidate_name)) +
  geom_bar(stat="identity") +
#  geom_rect(aes(fill=winner), xmin=-Inf, xmax=Inf, ymin=0, ymax=167631519) +
  facet_geo(~ recipient_state, scales="free_x") +
  scale_fill_manual(values = c("#DC143C","#007FFF"), name = "") +
  scale_y_sqrt(labels = unit_format(unit = "M", scale = 1e-6)) +
  xlab("") + ylab("Ad spending Per State") +
  theme_bw() +
  blogGraphics_theme +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.line.x.bottom    = element_line(colour = "black"))
  

ggsave("statespending_sqrt.png", height = 7, width = 8)
