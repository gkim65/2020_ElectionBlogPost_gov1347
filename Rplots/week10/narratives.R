#### Covid Model ####
#### Gov 1347: Election Analysis (2020)
#### Grace Kim

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#

library(tidyverse)
library(ggplot2)
library(extrafont)
library(ggrepel)
library(stargazer)
library(gt)
library(janitor)

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

county2016 <- read_csv("Data/countypres_2000-2016.csv")
county2020 <- read_csv("Data/CountyResults2020 - Sheet1.csv") %>% clean_names()
corona <- read_csv("Data/covidDataCounty.csv")

county2020 <- county2020 %>% 
  select(total_vote,geographic_name,joseph_r_biden_jr,donald_j_trump) %>% 
  tail(-1)
names(county2020)[names(county2020) == 'geographic_name'] <- 'county'


county2016<- county2016 %>% 
  filter(year == 2016, candidate == "Donald Trump") %>% 
  select(county, candidatevotes)


trump2020_16 <- left_join(county2016,
                      county2020, by = "county") %>% 
  select(county, state,candidatevotes,joseph_r_biden_jr,donald_j_trump,total_vote)

trump2020_16[!duplicated(trump2020_16$county),]



full_data<- trump2020_16 %>% 
  inner_join(corona %>% 
  filter(date == as.Date("2020-12-05")), by = "county") %>% 
  mutate(corona_cases_percentage = ifelse((cases/as.numeric(total_vote))>1,
                                          1, cases/as.numeric(total_vote))) %>% 
  mutate(margin = as.numeric(donald_j_trump)-candidatevotes)

full_data<-full_data[!duplicated(full_data$county),]

### Compare trump 2016/ 2020
options(scipen=10000)
full_data %>% filter(corona_cases_percentage<0.7)%>% 
  ggplot(aes(y = as.numeric(donald_j_trump), 
             x = candidatevotes,
             color = corona_cases_percentage)) +
  geom_point()+
  scale_x_log10()+
  scale_y_log10()+
  geom_abline(a=0, b=1)+
  xlab("Trump's county level popular vote 2016") +
  ylab("Trump's county level popular vote 2020")+
  labs(legend = "Percentages of Covid-19 Case",
       title = "Trump 2020 Vs 2016 Popular Vote Share")+
  blogGraphics_theme+
  coord_equal(ratio = 1)
ggsave("2020vs2016.png", height = 8, width = 8)

my_breaks<- c(10,100,1000,3000)
## Comparison between Biden and Trump
full_data %>% filter(corona_cases_percentage<0.7)%>% 
  ggplot(aes(y = as.numeric(donald_j_trump), 
             x = as.numeric(joseph_r_biden_jr),
             color = deaths)) +
  geom_point()+
  scale_x_log10()+
  scale_y_log10()+
  scale_color_continuous(name="Covid-19 Deaths",trans="log", breaks=my_breaks, labels =my_breaks)+
  geom_abline(a=0, b=1)+
  xlab("Trump's county level popular vote 2020") +
  ylab("Biden's county level popular vote 2020")+
  labs(legend = "Percentages of Covid-19 Case",
       title = "Biden VS Trump Popular Vote Share - Covid-19")+
  blogGraphics_theme+
  theme(legend.position = "right",
        legend.direction = "vertical")
ggsave("BidenVsTrumpCovid.png", height = 8, width = 8)


full_data %>% filter(corona_cases_percentage > 0.5) %>% 
  select(county, state_po)
