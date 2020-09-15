#### Visualization Customization Blog Extension ####
#### Gov 1347: Election Analysis (2020)
#### Grace Kim

## install via `install.packages("name")`
library(tidyverse)
library(ggplot2)
library(usmap)
library(dplyr)
library(janitor)
library(stringr)


## Wanted to have a pretty font in my plot theme :D
library(extrafont)
loadfonts(device = "win")

setwd("~/Harvard/Classes/Fall_2020/Gov 1347/2020_ElectionBlogPost_gov1347/Rplots/week1")

####----------------------------------------------------------#
#### Read and clean pres pop vote ####
####----------------------------------------------------------#

## read in data
popvote_df <- read_csv("Data/popvote_1948-2016.csv") 


## Made my "pretty" customized theme
blogGraphics_theme <- theme_bw()+
    theme(panel.border = element_blank(),
        text         = element_text(family = "Garamond"),
        plot.title   = element_text(size = 15, hjust = 0.5), 
        axis.text.x  = element_text(angle = 45, hjust = 1),
        axis.text    = element_text(,size = 12),
        strip.text   = element_text(size = 18),
        axis.line    = element_line(colour = "black"),
        legend.position = "bottom",
        legend.direction = "horizontal",
        legend.text = element_text(size = 12))


## line plot of Presidential vote share
ggplot(popvote_df, aes(x = year, y = pv2p, colour = party)) +
  geom_line(stat = "identity") +
  scale_color_manual(values = c("#007FFF", "#DC143C"), name = "") +
  xlab("") + ## no need to label an obvious axis
  ylab("popular vote %") +
  ggtitle("Presidential Vote Share (1948-2016)") + 
  scale_x_continuous(breaks = seq(from = 1948, to = 2016, by = 4)) +
  blogGraphics_theme

ggsave("PV_national_historical.png", height = 4, width = 8)


####----------------------------------------------------------#
#### State-by-state map of voter turnout rates from Nov 2016 ####
####----------------------------------------------------------#

## Make pretty map theme :D
blogMapGraphics_theme <- theme(panel.border = element_blank(),
                               text         = element_text(family = "Garamond"),
                               plot.title   = element_text(size = 15, hjust = 0.5), 
                               strip.text   = element_text(size = 18),
                               legend.position = "bottom",
                               legend.direction = "horizontal",
                               legend.text = element_text(size = 12))


## read in voting turnout rates data
votingRates_df <- read_csv("Data/2016NovemberGeneralElection-Turnout Rates.csv", skip = 1) %>% 
                  clean_names() %>% 
                  select(x1, vep_total_ballots_counted)

## voting turnout rate is in percentage which isn't taken by R; changed this
changePercentage <- str_replace(votingRates_df$vep_total_ballots_counted, pattern="%", "")
votingRates_df$vep_total_ballots_counted <- as.numeric(changePercentage)
names(votingRates_df)[names(votingRates_df) == "x1"] <- "state"

## shapefile of states from `usmap` library
states_map <- usmap::us_map()
head(states_map)

## map: plot voting rates in the 2016 election
## just to show how many eligible voters are NOT voting
map <- plot_usmap(data = votingRates_df, 
           regions = "states", 
           values = "vep_total_ballots_counted", labels = TRUE, label_color = "black") + 
  labs()+
  scale_fill_continuous(
    high = "Purple",
    low = "white",
    na.value="grey90",
    breaks = c(45,55,60,65,75), 
    limits = c(43,75),
    name = "Voter Turnout Rating Percentage",
    guide = guide_colourbar(barwidth = 25, barheight = 0.4,
                            title.position = "top")
  ) + 
  theme_void() + blogMapGraphics_theme

## tried to change map state labels
map$layers[[2]]$aes_params$size <- 3
map$layers[[2]]$aes_params$font <- "Garamond"

map
ggsave("VoterTurnout_states_2016.png", height = 7, width = 8)