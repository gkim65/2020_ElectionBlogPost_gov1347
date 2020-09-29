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

popvote_df <- read_csv("Data/popvote_1948-2016.csv")
economy_df <- read_csv("Data/econ.csv")
poll_df    <- read_csv("Data/pollavg_1968-2016.csv")
poll_df_2020 <- read_csv("Data/polls_2020.csv")

dat <- popvote_df %>% 
  full_join(poll_df %>% 
              filter(weeks_left == 6) %>% 
              group_by(year,party) %>% 
              summarise(avg_support=mean(avg_support))) %>% 
  left_join(economy_df %>% 
              filter(quarter == 2))

#####------------------------------------------------------#
#####  Model Polls ####
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

clean_poll_2020 <- poll_df_2020 %>% 
  filter(candidate_id %in% c(13254, 13256)) %>% 
  filter(is.na(state)) %>% 
  filter(!is.na(end_date)) %>% 
  group_by(end_date, candidate_name) %>% 
  summarise(pct=mean(pct))
  
  
clean_poll_2020$end_date <- as.Date(clean_poll_2020$end_date, "%m/%d/%Y")

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

dat_poll_Dem2020 <- clean_poll_2020 %>% 
  filter(candidate_name == "Joseph R. Biden Jr.") %>% 
  filter(end_date >= as.Date("0020-04-01"))

dat_poll_Rep2020 <- clean_poll_2020 %>% 
  filter(candidate_name == "Donald Trump") %>% 
  filter(end_date >= as.Date("0020-04-01"))

mod_poll_Dem2020 <- lm(pct ~ end_date, data = dat_poll_Dem2020)

mod_poll_Rep2020 <- lm(pct ~ end_date, data = dat_poll_Rep2020)


final_Predict <- data.frame(end_date = as.Date("0020-11-03"))
joe_full <- predict(mod_poll_Dem2020, final_Predict)
donald_full <- predict(mod_poll_Rep2020, final_Predict)

pred_df <- rbind.data.frame(
  data.frame(joe_full, candidate="Biden"),
  data.frame(donald_full, candidate="Trump")
)

ggplot(pred_df, aes(x=candidate, y=fit, ymin=lwr, ymax=upr, color=model)) +
  geom_pointrange(position = position_dodge(width = 0.5)) + 
  theme_bw()
flexsummary(mod_poll_Dem2020)
ft<- flextable(tidy(mod_poll_Dem2020)) %>% 
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





all_years <- seq(from=1948, to=2016, by=4)
outsamp_dflist <- lapply(all_years, function(year){
  
  true_inc <- unique(dat$pv[dat$year == year & dat$incumbent_party])
  true_chl <- unique(dat$pv[dat$year == year & !dat$incumbent_party])
  
  ##fundamental model out-of-sample prediction
  mod_econ_inc_ <- lm(pv ~ GDP_growth_qt, data = dat_econ_inc[dat_econ_inc$year != year,])
  mod_econ_chl_ <- lm(pv ~ GDP_growth_qt, data = dat_econ_chl[dat_econ_chl$year != year,])
  pred_econ_inc <- predict(mod_econ_inc_, dat_econ_inc[dat_econ_inc$year == year,])
  pred_econ_chl <- predict(mod_econ_chl_, dat_econ_chl[dat_econ_chl$year == year,])
  
  if (year >= 1980) {
    ##poll model out-of-sample prediction
    mod_poll_inc_ <- lm(pv ~ avg_support, data = dat_poll_inc[dat_poll_inc$year != year,])
    mod_poll_chl_ <- lm(pv ~ avg_support, data = dat_poll_chl[dat_poll_chl$year != year,])
    pred_poll_inc <- predict(mod_poll_inc_, dat_poll_inc[dat_poll_inc$year == year,])
    pred_poll_chl <- predict(mod_poll_chl_, dat_poll_chl[dat_poll_chl$year == year,])
    
    ##plus model out-of-sample prediction
    mod_plus_inc_ <- lm(pv ~ GDP_growth_qt + avg_support, data = dat_plus_inc[dat_plus_inc$year != year,])
    mod_plus_chl_ <- lm(pv ~ GDP_growth_qt + avg_support, data = dat_plus_chl[dat_plus_chl$year != year,])
    pred_plus_inc <- predict(mod_plus_inc_, dat_plus_inc[dat_plus_inc$year == year,])
    pred_plus_chl <- predict(mod_plus_chl_, dat_plus_chl[dat_plus_chl$year == year,])
  } else {
    pred_poll_inc <- pred_poll_chl <- pred_plus_inc <- pred_plus_chl <- NA
  }
  
  cbind.data.frame(year,
                   econ_margin_error = (pred_econ_inc-pred_econ_chl) - (true_inc-true_chl),
                   poll_margin_error = (pred_poll_inc-pred_poll_chl) - (true_inc-true_chl),
                   plus_margin_error = (pred_plus_inc-pred_plus_chl) - (true_inc-true_chl),
                   econ_winner_correct = (pred_econ_inc > pred_econ_chl) == (true_inc > true_chl),
                   poll_winner_correct = (pred_poll_inc > pred_poll_chl) == (true_inc > true_chl),
                   plus_winner_correct = (pred_plus_inc > pred_plus_chl) == (true_inc > true_chl)
  )
})
outsamp_df <- do.call(rbind, outsamp_dflist) #
colMeans(abs(outsamp_df[2:4]), na.rm=T) #
colMeans(outsamp_df[5:7], na.rm=T) ### classification accuracy

outsamp_df[,c("year","econ_winner_correct","poll_winner_correct","plus_winner_correct")] #

