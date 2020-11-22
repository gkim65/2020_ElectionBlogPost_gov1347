#### Model Evaluation ####
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
        axis.text    = element_text(size = 12),
        strip.text   = element_text(size = 15),
        axis.title   = element_text(size = 15),
        axis.line    = element_line(colour = "black"),
        legend.position = "bottom",
        legend.direction = "horizontal",
        legend.text = element_text(size = 12))

####----------------------------------------------------------#
#### The relationship between economy and PV ####
####----------------------------------------------------------#

economy_df <- read_csv("Data/econ.csv") 
popvote_df <- read_csv("Data/popvote_1948-2016.csv") 

dat <- popvote_df %>%
  select(year, winner, pv2p, party, incumbent_party) %>%
  left_join(economy_df) %>% 
  filter(quarter == 3)

all_years <- seq(from=1948, to=2016, by=4)
outsamp_dflist <- lapply(all_years, function(years){
    dat_inc <- dat %>% filter(incumbent_party == TRUE & year != years)
    dat_ch <- dat %>% filter(incumbent_party == FALSE & year != years)
    
    ## Historical Poll model out-of-sample prediction
    mod_poll_rep_ <- glm(pv2p ~ GDP_growth_yr, data = dat_inc)
    mod_poll_dem_ <- glm(pv2p ~ GDP_growth_yr, data = dat_ch)
    pred_poll_rep <- predict(mod_poll_rep_, data = dat %>% filter(incumbent_party == TRUE) %>% filter(year == years))
    pred_poll_dem <- predict(mod_poll_dem_, data = dat %>% filter(incumbent_party == FALSE) %>% filter(year == years))
    
    true_inc <- dat %>% filter(incumbent_party == TRUE & year == years)
    true_inc_pv2p <- true_inc$pv2p
    true_cha <- dat %>% filter(incumbent_party == FALSE & year == years)
    true_cha_pv2p <- true_cha$pv2p
    
    cbind.data.frame(years,
                     GDP_growth_yr = true_inc$GDP_growth_yr,
                     Inc_pv2p_margin = (true_inc_pv2p-mean(pred_poll_rep)))
    })

outsamp_df <- do.call(rbind, outsamp_dflist) 
nrow(outsamp_df)
## Number of elections that economy was off by less than 3 percent pv2p
nrow(outsamp_df[abs(outsamp_df$Inc_pv2p_margin) < 3,])

dat_inc <-  dat %>% filter(incumbent_party == TRUE)
dat_cha <-  dat %>% filter(incumbent_party == FALSE)

mod_poll_inc <- glm(pv2p ~ GDP_growth_yr, data = dat_inc)
mod_poll_cha <- glm(pv2p ~ GDP_growth_yr, data = dat_cha)

### Using lowest GDP growth yearly rate predict donald trump win percentages: 45.27866
pred_poll_rep <- predict(mod_poll_inc, dat[which.min(dat$GDP_growth_yr),])

### predicted nationwide pv2p for Biden: 54.72134
pred_poll_dem <- predict(mod_poll_cha, dat[which.min(dat$GDP_growth_yr),])


colnames(four_col) <- c("MSE Q1", "MSE Q2", "MSE Q3", "MSE Q4")
four_col <- as.data.frame(four_col)


ft<- flextable(outsamp_df) %>% 
  add_header_lines("Out of Sample Economy Model predictions for Popular Vote") %>% 
  font(fontname = "Garamond", part = "all") %>% 
  fontsize(i = NULL, j = NULL, size = 14, part = "header") %>% 
  align(align = "center", part = "all") %>% 
  width(width = 1.5)

ft <- color(ft, i = ~ (abs(Inc_pv2p_margin) < 3), color = "Blue", j = 3 )
ft
save_as_image(x = ft, path = "EconomyPredictions_Pv2p.png")
