library(tidyverse)
library(ggplot2)
library(statebins)
library("reshape2")
library(extrafont)
library(stargazer)
library(geofacet)
loadfonts(device = "win")

#####------------------------------------------------------#
##### Read and merge data ####
#####------------------------------------------------------#


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

demog <- read_csv("Data/demographic_1990-2018.csv")
pvstate_df    <- read_csv("Data/popvote_bystate_1948-2016.csv")
pollstate_df  <- read_csv("Data/pollavg_bystate_1968-2016.csv")


### United States 2019 Population estimates
population_2020 <- read_csv("Data/2019_US_population_estimates.csv")

# calculate labels of piechart 
dat <- population_2020 %>% 
  arrange(desc(Race))
ggplot(dat, aes(x="", y=Population_Percent, fill = Race)) +
  geom_bar(stat="identity", width=1, color="white") +
  coord_polar("y", start=0) + theme_void() + 
  scale_fill_brewer(palette = "Paired") +
  theme(text = element_text(family = "Garamond", size = 18)) +
  labs(title = "2019 Census Estimates of United States Demographics")

ggsave("demographics_2019.png", height = 6, width = 8)

### Population changes by State
demog_df <- melt(demog, id.vars=c("year","state"), 
                 measure.vars =c("Asian", 
                                 "Black", 
                                 "Hispanic", 
                                 "Indigenous", 
                                 "White", 
                                 "Female", 
                                 "Male"))
ggplot(demog_df, aes(x = year, y = value, group=variable, color = variable)) +
  geom_line()+ blogGraphics_theme +
  facet_geo(~ state, scales="free_x")
  ylabs("Percentages")
  
ggsave("demographics.png", height = 10, width = 12)
  
### predictions with demographics
pvstate_df$state <- state.abb[match(pvstate_df$state, state.name)]
pollstate_df$state <- state.abb[match(pollstate_df$state, state.name)]

dat <- pvstate_df %>% 
  full_join(pollstate_df %>% 
              filter(weeks_left == 3) %>% 
              group_by(year,party,state) %>% 
              summarise(avg_poll=mean(avg_poll)),
            by = c("year" ,"state")) %>%
  left_join(demog %>%
              select(-c("total")),
            by = c("year" ,"state"))

dat$region <- state.division[match(dat$state, state.abb)]
demog$region <- state.division[match(demog$state, state.abb)]

dat_change <- dat %>%
  group_by(state) %>%
  mutate(Asian_change = Asian - lag(Asian, order_by = year),
         Black_change = Black - lag(Black, order_by = year),
         Hispanic_change = Hispanic - lag(Hispanic, order_by = year),
         Indigenous_change = Indigenous - lag(Indigenous, order_by = year),
         White_change = White - lag(White, order_by = year),
         Female_change = Female - lag(Female, order_by = year),
         Male_change = Male - lag(Male, order_by = year),
         age20_change = age20 - lag(age20, order_by = year),
         age3045_change = age3045 - lag(age3045, order_by = year),
         age4565_change = age4565 - lag(age4565, order_by = year),
         age65_change = age65 - lag(age65, order_by = year)
  )

mod_demog_change_D <- lm(D_pv2p ~ Black_change + Hispanic_change + Asian_change +
                         Female_change +
                         age3045_change + age4565_change + age65_change +
                         as.factor(region), data = dat_change)

mod_demog_change_R <- lm(R_pv2p ~ White_change + Male_change + Asian_change +
                           Hispanic_change +
                           age4565_change + age65_change +
                           as.factor(region), data = dat_change)


stargazer(mod_demog_change_D, header=FALSE, type='html', no.space = TRUE,
          column.sep.width = "3pt", font.size = "scriptsize", single.row = TRUE,
          keep = c(1:7, 62:66), omit.table.layout = "sn",
          title = "The electoral effects of demographic change (across states)",out = "forcastD.htm")
stargazer(mod_demog_change_R, header=FALSE, type='html', no.space = TRUE,
          column.sep.width = "3pt", font.size = "scriptsize", single.row = TRUE,
          keep = c(1:6, 62:66), omit.table.layout = "sn",
          title = "The electoral effects of demographic change (across states)",out = "forcastR.htm")

