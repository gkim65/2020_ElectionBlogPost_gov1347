#### Prediction ####
#### Gov 1347: Election Analysis (2020)
#### Grace Kim

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#

## install via `install.packages("name")`
library(tidyverse)
library(ggplot2)
library(extrafont)
library(tibble)
library(webshot)
library(flextable)
library(dplyr)
library(tibble)
loadfonts(device = "win")

## set working directory here
setwd("~")

## Made my "pretty" customized theme
blogGraphics_theme <- theme_bw()+
  theme(panel.border = element_blank(),
        text         = element_text(family = "Garamond"),
        plot.title   = element_text(size = 18, hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5),
        axis.text    = element_text(size = 12),
        strip.text   = element_text(size = 15),
        axis.title   = element_text(size = 15),
        axis.line    = element_line(colour = "black"),
        legend.position = "bottom",
        legend.direction = "horizontal",
        legend.text = element_text(size = 12))

####----------------------------------------------------------#
#### Predicting Trump's pv2p according to unemployment rates
####----------------------------------------------------------#

economy_df <- read_csv("Data/econ.csv") 
popvote_df <- read_csv("Data/popvote_1948-2016.csv") 

dat<- popvote_df %>%
  filter(prev_admin == TRUE) %>%
  select(year, winner, pv2p, party) %>%
  left_join(economy_df %>% filter(quarter == 1))

dat_trump <- economy_df %>% 
  subset(year == 2020 & quarter == 1) %>% 
  select(unemployment, RDI_growth)

trumpPrediction_mod <- lm(pv2p ~ unemployment, data = dat)
trumpPrediction_mod_RDI <- lm(pv2p ~ RDI_growth, data = dat)
trumpPrediction <- predict(trumpPrediction_mod_RDI, dat_trump)
trumpPrediction
dat_trump<-dat_trump %>% add_column("year" = 2020,
                                    "pv2p" = trumpPrediction,
                                    "party" = "Republican")

## scatterplot + line
dat %>%
  ggplot(aes(x=RDI_growth, y=pv2p,
             label=year)) + 
  geom_label(aes(fill = factor(party)),
             colour = "white",
             fontface = "bold", 
             size = 4,
             alpha = 0.7) +
  scale_fill_manual(values = c("#007FFF", "#DC143C"), name = "")+
  geom_smooth(method="lm", formula = y ~ x, color = "#003466") +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=median(dat$RDI_growth), lty=2) + # median
  xlab("RDI Growth Rates") +
  ylab("Incumbent president's national popular vote percentages") +
  labs(title = "Quarter 2 Election Cycle, RDI Growth Rates vs Popular Vote",
       subtitle = "With Prediction for President Trump's Popular Vote Ratings")+
  theme_bw() +
  geom_point(aes(x = dat_trump$RDI_growth, y = trumpPrediction, color = "#DC143C"), show.legend = FALSE)+
  geom_label(data = dat_trump, aes(fill = factor(party)),
             colour = "white",
             fontface = "bold", 
             size = 4,
             alpha = 0.7)+
##  facet_wrap(~quarter, labeller  = labeller(quarter = quarter.labs)) +
  blogGraphics_theme


ggsave("RDI_GrowthPredictionTrump.png", height = 8, width = 8)

ggsave("unemploymentPredictionTrump.png", height = 8, width = 8)
