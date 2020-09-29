#### Checking Pollster Quality ####
#### Gov 1347: Election Analysis (2020)
#### Grace Kim

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#

## install via `install.packages("name")`
library(tidyverse)
library(ggplot2)
library(janitor)
library(cowplot)
library(extrafont)
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
        plot.caption = element_text(size = 12),
        plot.caption.position = "plot",
        legend.position = "bottom",
        legend.direction = "horizontal",
        legend.text = element_text(size = 12))

pollQuality_2016_df <- read_csv("Data/pollster-ratings2016.csv") %>% 
  clean_names() %>% mutate(partyBias = ifelse(is.na(substr(pollQuality_2016_df$party_bias, 1,1)),"None",substr(pollQuality_2016_df$party_bias, 1,1)))

 
scatterplot <- ggplot(pollQuality_2016_df, aes(x = simple_average_error, y = advanced_plus_minus))+
  geom_point(aes(color = partyBias, alpha = (polls)), size = 2.7) +
  ylab("Advanced Plus-Minus") +
  labs(title = "Poll Average Error Percentages", caption = "Higher point transparency ~ smaller # of polls conducted by pollster") +
  xlab("Simple Average Error") +
  scale_color_manual(values = c("D" = "#007FFF", "R" = "#DC143C", "None" = "dark grey"), name = "Party Bias")+
  blogGraphics_theme+
  scale_x_continuous(limits = c(0,45)) +
  theme(legend.justification = "right", legend.box.margin=margin(0,0,-10,0)) +
  scale_alpha(guide = 'none')

histogram <- ggplot(pollQuality_2016_df, aes(x = simple_average_error))+
  geom_histogram(bins = 90, color = "white", fill = "navy", alpha = 0.5) +
  geom_vline(xintercept = mean(pollQuality_2016_df$simple_average_error), color = "Red")+
  ylab("Count")+
  labs(caption = "Red Line - Mean")+
  xlab("Simple Average Error") +
  blogGraphics_theme

dems_pollQuality <- pollQuality_2016_df %>% filter(partyBias == "D")

demHist<- ggplot(dems_pollQuality, aes(x = simple_average_error))+
  geom_histogram(bins = 90, color = "white", fill = "navy", alpha = 0.5) +
  geom_vline(xintercept = mean(dems_pollQuality$simple_average_error), color = "Red")+
  ylab("Count - Democrats")+
  labs(caption = "Red Line - Mean")+
  xlab("Simple Average Error") +
  blogGraphics_theme +
  scale_x_continuous(limits = c(0,45))

rep_pollQuality <- pollQuality_2016_df %>% filter(partyBias == "R")

rep_hist <- ggplot(rep_pollQuality, aes(x = simple_average_error))+
  geom_histogram(bins = 90, color = "white", fill = "dark red", alpha = 0.5) +
  geom_vline(xintercept = mean(rep_pollQuality$simple_average_error), color = "blue")+
  ylab("Count - Republicans")+
  labs(caption = "Blue Line - Mean")+
  xlab("Simple Average Error") +
  blogGraphics_theme+
  scale_x_continuous(limits = c(0,45))


plot_grid(scatterplot + theme(axis.title.x = element_blank()),
  demHist+ theme(axis.title.x = element_blank()),
  rep_hist,
          ncol = 1)
ggsave("pollQuality.png", height = 10, width = 8)
ggsave("pollQuality2.png", height = 10, width = 8)
