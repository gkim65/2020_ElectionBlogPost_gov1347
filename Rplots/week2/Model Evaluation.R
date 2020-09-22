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
  filter(incumbent_party == TRUE) %>%
  select(year, winner, pv2p, party) %>%
  left_join(economy_df)

quarter.labs <- c("Quarter 1", "Quarter 2", "Quarter 3", "Quarter 4")
names(quarter.labs) <- c("1","2","3","4")

## scatterplot + line
dat %>%
  ggplot(aes(x=inflation, y=pv2p,
             label=year)) + 
  geom_label(aes(fill = factor(party)),
            colour = "white",
            fontface = "bold", 
            size = 4,
            alpha = 0.7) +
  scale_fill_manual(values = c("#007FFF", "#DC143C"), name = "")+
  geom_smooth(method="lm", formula = y ~ x, color = "#003466") +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=median(dat$inflation), lty=2) + # median
  xlab("Inflation Rates") +
  ylab("Incumbent party's national popular vote percentages") +
  theme_bw() +
  facet_wrap(~quarter, labeller  = labeller(quarter = quarter.labs)) +
  blogGraphics_theme

ggsave("GDP.png", height = 8, width = 8)
ggsave("stockVolume.png", height = 8, width = 8)
ggsave("stockOpen.png", height = 8, width = 8)
ggsave("stockClose.png", height = 8, width = 8)

ggsave("unemployment.png", height = 8, width = 8)
ggsave("Inflation.png", height = 8, width = 8)
ggsave("RDIGrowth.png", height = 8, width = 8)
ggsave("RDI.png", height = 8, width = 8)
ggsave("YearlyGDPGrowth.png", height = 8, width = 8)
ggsave("QuarterlyGDPGrowthIncumbentParty.png", height = 8, width = 8)

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
  filter(incumbent == TRUE) %>%
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
  add_header_lines("Mean Square Error Values Relating Economic Factors with Popular Vote in Election Year, Incumbent Same-Party Heirs") %>% 
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
  bold(i = 3, j = 2) %>% 
  bold(i = 2, j = 3) %>% 
  bold(i = 3, j = 4) %>%
  bold(i = 3, j = 5)


ft
flextable_dim(ft)
save_as_image(x = ft, path = "MSE_Economy_IncumbentParty.png")
