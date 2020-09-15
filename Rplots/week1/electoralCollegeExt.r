#### Electoral College Blog Extension ####
#### Gov 1347: Election Analysis (2020)
#### Grace Kim

## install via `install.packages("name")`
library(tidyverse)
library(ggplot2)
library(usmap)
library(dplyr)
library(tibble)

## Wanted to have a pretty font in my plot theme :D
library(extrafont)
loadfonts(device = "win")

setwd("~/Harvard/Classes/Fall_2020/Gov 1347/2020_ElectionBlogPost_gov1347/Rplots/week1")

## Made my pretty theme for my map graphics :D
blogMapGraphics_theme <- theme(panel.border = element_blank(),
                               text         = element_text(family = "Garamond"),
                               plot.title   = element_text(size = 15, hjust = 0.5), 
                               strip.text   = element_text(size = 18),
                               legend.position = "bottom",
                               legend.direction = "horizontal",
                               legend.text = element_text(size = 12))

####----------------------------------------------------------#
#### State-by-state map of pres pop votes ####
####----------------------------------------------------------#

## read in state pop vote
pvstate_df <- read_csv("Data/popvote_bystate_1948-2016.csv")
electoralCollege <-read_csv("Data/ec_1952-2020.csv")

closeYears1 <- c(2004,2000,2016)
pv_merge_data <- pvstate_df %>%
  filter(year %in% closeYears1) %>%
  group_by(year) %>%
  summarize(Democrats = sum(D, na.rm = TRUE), Republicans= sum(R, na.rm = TRUE))


library(webshot)
library(flextable)
ft <- flextable(pv_merge_data)
ft <- add_header_lines(ft, "Popular Vote count per year")
ft <- font(ft, fontname = "Garamond", part = "all")
ft <- fontsize(ft, i = NULL, j = NULL, size = 14, part = "header")
ft <- align(ft, align = "center", part = "all")
ft <- bold(ft, i = c(1,3), j = 2)
ft <- bold(ft, i = 2, j = 3)
ft
save_as_image(x = ft, path = "output.png")

closeYears <- c(2004,2000,2016)
ec_merge_data <- pvstate_df %>%
  filter(year %in% closeYears) %>%
  mutate(winner = case_when(D > R ~ "Democrats", TRUE ~ "Republicans")) %>%
  full_join(electoralCollege) %>%
  group_by(winner, year) %>% 
  summarize(SumAvg = sum(electors, na.rm = TRUE)) %>% 
  head(6) %>% 
  spread(key = (year), value = SumAvg)

ec_merge_data <- t(ec_merge_data)
ec_merge_data <- as.data.frame(ec_merge_data)
colnames(ec_merge_data) <- c("Democrats","Republicans")
ec_merge_data <- cbind(year = rownames(ec_merge_data), ec_merge_data)
ec_merge_data <- ec_merge_data[-1,]
ec_merge_data

ftEc <- flextable(ec_merge_data)
ftEc <- add_header_lines(ftEc, "Electoral College count determined from State Popular Vote")
ftEc <- font(ftEc, fontname = "Garamond", part = "all")
ftEc <- fontsize(ftEc, i = NULL, j = NULL, size = 14, part = "header")
ftEc <- align(ftEc, align = "center", part = "all")
ftEc <- bold(ftEc, i = 1, j = 3)
ftEc <- bold(ftEc, i = 2, j = 3)
ftEc <- bold(ftEc, i = 3, j = 3)
ftEc <- footnote(ftEc, part = "header", i =1,
                          value = as_paragraph(
                            c("Results of electoral college numbers determined from using winner-take-all method with popular vote data; does not account for states such as Maine and New Hampshire that do not partake in winner-take-all electoral college votes, so real numbers from election may vary.")
                          ))

ftEc
save_as_image(x = ftEc, path = "electoral.png")


ec_merge_data
## shapefile of states from `usmap` library
states_map <- usmap::us_map()
head(states_map)
pvstate_df


## map: wins
closeYears <- c(1960,2004,2000, 2016)
pv_win_map <- pvstate_df %>%
  filter(year %in% closeYears) %>%
  mutate(winner = ifelse(R > D, "republican", "democrat"))

names(pv_win_map)[names(pv_win_map) == "republican"] <- "Republican"
names(pv_win_map)[names(pv_win_map) == "democrat"] <- "Democrat"
plot_usmap(data = pv_win_map, regions = "states", values = "winner") +
  scale_fill_manual(values = c("blue", "#DC143C"), name = "State Electoral College winner") +
  theme_void() + 
  facet_grid(rows = year~.) +
  blogMapGraphics_theme
ggsave("EC_states_historical.png", height = 8, width = 8)
pvstate_df
## map: win-margins


closeYears <- c(1960,2004,2000, 2016)
pv_margins_map <- pvstate_df %>%
  filter(year %in% closeYears)%>% 
  mutate(win_margin = (R_pv2p-D_pv2p))

plot_usmap(data = pv_margins_map, regions = "states", values = "win_margin") +
  #facet_wrap(facets = year ~.)+
  facet_grid(rows = year ~.)+
  scale_fill_gradient2(
    high = "#DC143C", 
    #mid = scales::muted("purple"), ##TODO: purple or white better?
    mid = "white", 
    low = "#007FFF", 
    breaks = c(-50,-25,0,25,50), 
    limits = c(-50,50),
    name = "Popular Vote Win Margins",
    guide = guide_colourbar(barwidth = 20, barheight = 0.4,
                            title.position = "top")
  ) + 
  theme_void() + blogMapGraphics_theme
ggsave("PV_states_historical.png", height = 8, width = 8)

pv_margins_map

## map grid
pv_map_grid <- pvstate_df %>%
  filter(year >= 1980) %>%
  mutate(winner = ifelse(R > D, "republican", "democrat"))

plot_usmap(data = pv_margins_map, regions = "states", values = "win_margin", color = "white") +
  facet_wrap(facets = year ~.) + ## specify a grid by year
  blogGraphics_theme +
  scale_fill_manual(values = c("blue", "red"), name = "PV winner") +
  theme_void() +
  theme(strip.text = element_text(size = 12),
        aspect.ratio = 1)

ggsave("PV_states_historical.png", height = 8, width = 5)
## NOTE FOR MYSELF LATER WHEN I WRITE BLOG:::
##  - plots can be kind of misleading, looks like people won by a landslide of popular vote in various
## states, but you honestly just won by a bit of of a margin; so it might be easier to just show
## data in a scale of how it went
