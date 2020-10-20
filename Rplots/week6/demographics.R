library(tidyverse)
library(ggplot2)
library(statebins)
library("reshape2")
library(extrafont)
library(stargazer)
library(geofacet)
library(cowplot)
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

### Prediction of maps

# new data for 2020
demog_2020 <- subset(demog, year == 2018)
demog_2020 <- as.data.frame(demog_2020)
rownames(demog_2020) <- demog_2020$state
demog_2020 <- demog_2020[state.abb, ]

demog_2020_change <- demog %>%
  filter(year %in% c(2016, 2018)) %>%
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
  ) %>%
  filter(year == 2018)
demog_2020_change <- as.data.frame(demog_2020_change)
rownames(demog_2020_change) <- demog_2020_change$state
demog_2020_change <- demog_2020_change[state.abb, ]

# prediction
predict(mod_demog_change_D, newdata = demog_2020_change) + # original model (mod_demog_change) parameters with new data for 2020 which predicts double hispanic vote turnout - Latino surge 
  (1.28-0.64)*demog_2020$Hispanic
his_original <- tibble(predict(mod_demog_change, newdata = demog_2020_change), state = state.abb, pred = `predict(mod_demog_change, newdata = demog_2020_change)`)
his1 <- tibble(predict(mod_demog_change, 
                       newdata = demog_2020_change) + 
                 (5.6946*0.01)*demog_2020$Black + (7.0143*0.01)*demog_2020$Female, 
               state = state.abb, pred = `+...`)
plot_original <- his_original %>%  ##`statebins` needs state to be character, not factor!
  mutate(state = as.character(state)) %>%
  ggplot(aes(state = state, fill = (pred >= 50))) +
  geom_statebins(lbl_size = 5, dark_lbl = "white", light_lbl = "black") +
  theme_statebins(base_family = "Garamond") +
  labs(title = "2020 Presidential Election Prediction",
       subtitle = "Historical demographic change effect, no predicted change in voter demographics",
       fill = "") +
  theme(legend.position = "none") +
  theme(text = element_text(family = "Garamond"),
        plot.title = element_text(size = 20),
        plot.subtitle = element_text(size = 10))
  

plot_1 <- his1 %>% 
  mutate(state = as.character(state)) %>% ##`statebins` needs state to be character, not factor!
  ggplot(aes(state = state, fill = (pred >= 50))) +
  geom_statebins(lbl_size = 5, dark_lbl = "white", light_lbl = "black") +
  theme_statebins(base_family = "Garamond") +
  labs(title = "2020 Presidential Election Prediction",
       subtitle = "Hypothetical Black and Female voters 1% demographic increases",
       fill = "") +
  theme(legend.position = "none")+
  theme(text = element_text(family = "Garamond"),
        plot.title = element_text(size = 20),
        plot.subtitle = element_text(size = 10))
  

plot_grid(plot_1,plot_original)
ggsave("demographics_electoralCollegeMap.png", height = 5, width = 12)



his_original$state <- state.name[match(his_original$state, state.abb)]
his1$state <- state.name[match(his1$state, state.abb)]

## Electoral college numbers
electoralCollege <- read.csv("Data/ElectoralCollegePost1948.csv")
electoralCollege %>% select(X,X2020) %>% 
  filter(!is.na(X2020)) %>% 
  mutate(state = X) %>% 
  left_join(his_original) %>%
  mutate(win = ifelse(pred > 50, "D","R")) %>%  
  group_by(win) %>% 
  summarize(X2020 = sum(X2020))

electoralCollege %>% select(X,X2020) %>% 
  filter(!is.na(X2020)) %>% 
  mutate(state = X) %>% 
  left_join(his1) %>%
  mutate(win = ifelse(pred > 50, "D","R")) %>%  
  group_by(win) %>% 
  summarize(X2020 = sum(X2020))
