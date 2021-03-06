#### Incumbency ####
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
#### The incumbency advantage: simple descriptive statistics ####
####----------------------------------------------------------#

popvote_df <- read_csv("Data/popvote_1948-2016.csv") 

incumbentPresidentW <- popvote_df %>%
  filter(winner) %>%
  select(year, winparty = party, wincand = candidate) %>%
  mutate(winparty_last = lag(winparty, order_by = year),
         wincand_last  = lag(wincand,  order_by = year)) %>%
  mutate(reelect.president = ifelse(wincand_last == wincand, "Incumbent", "Challenger")) %>%
  mutate(reelect.party = ifelse(winparty_last == winparty, "Incumbent", "Challenger")) %>%
  filter(year > 1948) %>%
  group_by(reelect.president,reelect.party) %>% 
  summarise(n = n()) %>% 
  as.data.frame()

colnames(incumbentPresidentW) <- c("President Election Winner", "Party Election Winner", "Number")

ft <- flextable(incumbentPresidentW) %>% 
  add_header_lines("Election Wins factoring Incumbency in the years 1948 - 2016") %>% 
  font(fontname = "Garamond", part = "all") %>% 
  fontsize(i = NULL, j = NULL, size = 14, part = "header") %>% 
  align(align = "center", part = "all") %>% 
  width(width = 2) 

save_as_image(x = ft, path = "IncumbentPresW.png")

####----------------------------------------------------------#
#### Incumbency Vs. Challengers
####----------------------------------------------------------#

dat <- popvote_df %>% 
  select(incumbent_party, pv2p,year,party) %>% 
  mutate(pv2p_incumbent = ifelse(incumbent_party == TRUE , pv2p, NA)) %>% 
  mutate(pv2p_challenger = ifelse(incumbent_party == FALSE , pv2p, NA)) %>% 
  mutate(party_incumbent = ifelse(is.na(pv2p_incumbent) , NA, ifelse(party == "democrat", 0,1))) %>% 
  mutate(party_challenger = ifelse(is.na(pv2p_challenger), NA, ifelse(party == "democrat", 0,1))) %>% 
  group_by(year) %>% 
  summarise_if(
    is.numeric,
    sum,
    na.rm = TRUE
  )

## scatterplot + line
ggplot(dat, color = (party_incumbent)) + 
  geom_segment(aes(x=year, xend = year, y = pv2p_challenger, yend = pv2p_incumbent), color="gray")+
  geom_point(aes(x=year, y = pv2p_incumbent), 
             size=5, 
             fill = ifelse(dat$party_incumbent == 0 , "#007FFF", "#DC143C"), 
             color = ifelse(dat$party_incumbent == 0 , "#007FFF", "#DC143C"),
             shape = 21, alpha = 0.75) +
  geom_point(aes(x=year, 
                 y = pv2p_challenger), 
             fill = ifelse(dat$party_challenger == 0 , "#007FFF", "#DC143C"), 
             color = ifelse(dat$party_challenger == 0 , c("#007FFF"), c("#DC143C")),
             size=5,
             shape = 24,alpha = 0.75) +
  theme_bw() +
  labs(title = "Challenger VS Incumbent President/Party Popular Vote",
       subtitle = "Triangle = Challenger, Circle = Incumbent")+
  xlab("Years from 1948-2016") +
  ylab("Popular Vote")+
  blogGraphics_theme

ggsave("ChallengerVsIncumbent.png", height = 8, width = 8)

####----------------------------------------------------------#
#### The relationship between economy and PV also incumbency
####----------------------------------------------------------#

economy_df <- read_csv("Data/econ.csv") 

dat <- popvote_df %>% 
#  filter(prev_admin == TRUE) %>%
  select(year, winner, pv2p, party, incumbent_party) %>%
  left_join(economy_df %>% filter(quarter == 2))

dat_incumbent <- dat %>% 
  filter(incumbent_party == TRUE)
dat_challenger <- dat %>% 
  filter(incumbent_party == FALSE)

dflist <- c("GDP", 
            "GDP_growth_qt", 
            "GDP_growth_yr", 
            "RDI", 
            "RDI_growth", 
            "inflation",
            "unemployment",
            "stock_open",
            "stock_close",
            "stock_volume")


mse_df <- lapply(dflist, function(x) {
    lm_incumbent <- lm(pv2p ~ get(x), data = dat_challenger)
    pv2p <- summary(lm_incumbent)$coefficients
  })
mse_df <- as.data.frame(do.call(rbind, mse_df))
dflist2 <- c("GDP Intercepts", 
            "GDP", 
            "GDP_growth_qt Intercepts", 
            "GDP_growth_qt", 
            "GDP_growth_yr Intercepts", 
            "GDP_growth_yr", 
            "RDI Intercepts", 
            "RDI", 
            "RDI_growth Intercepts", 
            "RDI_growth", 
            "Inflation Intercepts",
            "Inflation",
            "Unemployment Intercepts",
            "Unemployment",
            "Stock_open Intercepts",
            "Stock_open",
            "Stock_close Intercepts",
            "Stock_close",
            "Stock_volume Intercepts",
            "Stock_volume")

rownames(mse_df) = dflist2
toDelete <- seq(0, nrow(mse_df), 2)
mse_df <- mse_df[ toDelete ,]

ft<- flextable(mse_df %>% rownames_to_column("Economic Factor")) %>% 
  add_header_lines("Coefficients Relating Economic Factors with Popular Vote in Election Year, Challenger") %>% 
  font(fontname = "Garamond", part = "all") %>% 
  fontsize(i = NULL, j = NULL, size = 14, part = "header") %>% 
  align(align = "center", part = "all") %>% 
  width(width = 1.5) %>% 
  footnote(part = "body", i = c(1,4), j = 1,
           value = as_paragraph(
             c("Gross Domestic Product",
               "Real Disposable Income")
           )) %>% 
  bold(i = 2, j = c(1,2)) %>% 
  bold(i = 3, j = c(1,2))
ft <- color(ft, i = ~ (`Pr(>|t|)`< 0.05), color = "red", j = 5 )

save_as_image(x = ft, path = "Coefficients_Incumbent.png")
save_as_image(x = ft, path = "Coefficients_Challenger.png")


# challenger didn't have many good t values
residuals_df <- lapply(dflist, function(x) {
  lm_challenger <- lm(pv2p ~ get(x), data = dat_challenger)
  pv2p <- mean(summary(lm_incumbent)$residuals)
})
residuals_df <- as.data.frame(do.call(rbind, residuals_df))


incumbent_mod <- lm(pv2p ~ GDP_growth_qt +
                         GDP_growth_yr + RDI_growth +
                         GDP_growth_qt*GDP_growth_yr*RDI_growth, 
                    data = dat_incumbent)

dat_trump1 <- economy_df %>% 
  subset(year == 2020 & quarter == 1) %>% 
  select(GDP_growth_qt,GDP_growth_yr, RDI_growth)

dat_trump2 <- economy_df %>% 
  subset(year == 2020 & quarter == 2) %>% 
  select(GDP_growth_qt,GDP_growth_yr, RDI_growth)

trumpPrediction <- predict(incumbent_mod, dat_trump1,  
                           interval = "prediction", level=0.95)
trumpPrediction
dat_trump<-dat_trump %>% add_column("year" = 2020,
                                    "pv2p" = trumpPrediction,
                                    "party" = "Republican")


predict()
summary(incumbent_mod)
summary(challenger_mod)
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
  xlab("RDI_growth") +
  ylab("Incumbent president's national popular vote percentages") +
  theme_bw() +
  facet_wrap(~quarter, labeller  = labeller(quarter = quarter.labs)) +
  blogGraphics_theme

ggsave("GDP.png", height = 8, width = 8)
ggsave("stockVolume.png", height = 8, width = 8)
ggsave("stockOpen.png", height = 8, width = 8)
ggsave("stockClose.png", height = 8, width = 8)

ggsave("unemploymentIncumbentPres.png", height = 8, width = 8)
ggsave("Inflation.png", height = 8, width = 8)
ggsave("RDIGrowthIncumbentPres.png", height = 8, width = 8)
ggsave("RDI.png", height = 8, width = 8)
ggsave("YearlyGDPGrowthIncumbentPres.png", height = 8, width = 8)
ggsave("QuarterlyGDPGrowthIncumbentPres.png", height = 8, width = 8)

dflist <- c("GDP", 
            "GDP_growth_qt", 
            "GDP_growth_yr", 
            "RDI", 
            "RDI_growth", 
            "inflation",
            "unemployment",
            "stock_open",
            "stock_close",
            "stock_volume")
quarter_list <- c(1,2,3,4)


dat<- popvote_df %>%
  filter(prev_admin == TRUE) %>%
  select(year, winner, pv2p, party) %>%
  left_join(economy_df)

mse_df <- lapply(quarter_list, function(y){
  dat_q <- dat %>% filter(quarter == (y))
  mse_df <- lapply(dflist, function(x) {
    lm_econ <- lm(pv2p ~ get(x), data = dat_q)
    mse <- mean((lm_econ$model$pv2p - lm_econ$fitted.values)^2)
    pv2p <- sqrt(mse)
  })
})
mse_df <- as.data.frame(do.call(rbind, mse_df))
names(mse_df) = dflist
four_col <- mse_df %>% 
  t()
##sorted_mse<-mse_df[order(mse_df$V1), , drop = FALSE]

colnames(four_col) <- c("MSE Q1", "MSE Q2", "MSE Q3", "MSE Q4")
four_col <- as.data.frame(four_col)


ft<- flextable(four_col %>% rownames_to_column("Economic Factor")) %>% 
  add_header_lines("Mean Square Error Values Relating Economic Factors with Popular Vote in Election Year, Incumbent President") %>% 
  font(fontname = "Garamond", part = "all") %>% 
  fontsize(i = NULL, j = NULL, size = 14, part = "header") %>% 
  align(align = "center", part = "all") %>% 
  width(width = 1.5) %>% 
  footnote(part = "body", i = c(1,4), j = 1,
           value = as_paragraph(
             c("Gross Domestic Product",
               "Real Disposable Income")
           )) %>% 
  footnote(part = "header", i = 2, j = c(2:5),
           value = as_paragraph("Mean Square Error for each quarter of election year")) %>% 
  bold(i = 5, j = 2) %>% 
  bold(i = 7, j = 3) %>% 
  bold(i = 7, j = 4) %>%
  bold(i = 5, j = 5)


ft
flextable_dim(ft)
save_as_image(x = ft, path = "MSE_Economy_IncumbentPres.png")
