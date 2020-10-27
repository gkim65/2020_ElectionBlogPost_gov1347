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

corona_df <- read_csv("Data/national-history.csv")

#####------------------------------------------------------#
#####  Real-time 2020 Poll Averages ####
#####------------------------------------------------------#
{
  poll_2020_url <- "https://projects.fivethirtyeight.com/2020-general-data/presidential_poll_averages_2020.csv"
  poll_2020_df <- read_csv(poll_2020_url)
  
  elxnday_2020 <- as.Date("11/3/2020", "%m/%d/%Y")
  dnc_2020 <- as.Date("8/20/2020", "%m/%d/%Y")
  rnc_2020 <- as.Date("8/27/2020", "%m/%d/%Y")
  
  colnames(poll_2020_df) <- c("year","state","date","candidate_name","avg_support","avg_support_adj")
  
  poll_2020_df <- poll_2020_df %>%
    mutate(party = case_when(candidate_name == "Donald Trump" ~ "republican",
                             candidate_name == "Joseph R. Biden Jr." ~ "democrat"),
           date = as.Date(date, "%m/%d/%Y"),
           days_left = round(difftime(elxnday_2020, date, unit="days")),
           weeks_left = round(difftime(elxnday_2020, date, unit="weeks")),
           before_convention = case_when(date < dnc_2020 & party == "democrat" ~ TRUE,
                                         date < rnc_2020 & party == "republican" ~ TRUE,
                                         TRUE ~ FALSE)) %>%
    filter(!is.na(party)) %>%
    filter(state == "National")
}

# Timeline of Poll Data Over febuary to present 2020
poll_2020_df %>% 
  ggplot(aes(x = date, y = avg_support, color = candidate_name)) +
  geom_line() +
  geom_point(size = 1) +
  xlab("") +
  ylab("Polling Approval Average") +
  scale_x_date(limits = as.Date(c("2020-02-27","2020-10-26")))+
  scale_color_manual(values = c("#DC143C","#007FFF"), name = "")+
  blogGraphics_theme +
  theme(legend.box.margin=margin(-25,0,0,0))

ggsave("JoeVSDonald.png", height = 5, width = 8)


## Corona data and popular vote merge data
Corona_poll_2020_df <- corona_df %>% 
  inner_join(poll_2020_df %>% filter(candidate_name == "Donald Trump"), by = c("date"="date"))

a            <- range(Corona_poll_2020_df$avg_support)
b            <- range(Corona_poll_2020_df$positive)
scale_factor <- diff(a)/diff(b)
Corona_poll_2020_df$positive      <- ((Corona_poll_2020_df$positive - b[1]) * scale_factor) +a[1]
trans <- ~ ((. - a[1]) / scale_factor) + b[1]

### Only Trump VS Covid statistics
Corona_poll_2020_df %>%
  ggplot(aes(x = date)) +
  geom_line(aes(y=avg_support), color = "#DC143C") +
  geom_line(aes(y=positive), color = "dark blue") +
  xlab("") +
  scale_x_date(limits = as.Date(c("2020-02-27","2020-10-26")))+
  scale_y_continuous(name = "2020 Polling Averages Donald Trump",
                     sec.axis = sec_axis(trans, name="Positive Covid 19 Patients US"))+
  blogGraphics_theme +
  theme(
    axis.title.y = element_text(color = "#DC143C", size=13),
    axis.title.y.right = element_text(color = "dark blue", size=13)
  ) +
  theme(legend.box.margin=margin(-25,0,0,0))

ggsave("Donald_CovidPositives.png", height = 5, width = 8)

## Facet graph for Covid variables VS trump polling averages
Corona_poll_2020_df <- corona_df %>% 
  inner_join(poll_2020_df %>% filter(candidate_name == "Donald Trump"), by = c("date"="date"))

facet_covid = c("death", 
                "deathIncrease", 
                "inIcuCumulative",
                "inIcuCurrently",
                "hospitalizedIncrease",
                "hospitalizedCurrently",
                "hospitalizedCumulative",
                "negative",
                "negativeIncrease",
                "onVentilatorCumulative",
                "onVentilatorCurrently",
                "posNeg",
                "positive",
                "positiveIncrease",
                "recovered",
                "totalTestResults",
                "totalTestResultsIncrease",
                "avg_support")
Facet_corona <- Corona_poll_2020_df %>% 
  select(facet_covid) %>% 
  tidyr::gather(key, value, -avg_support) %>% 
  select(key,value,avg_support)

Facet_corona %>%
  ggplot(aes(x=value, y=avg_support, color = key)) + 
  geom_point() +
  geom_smooth(method="glm")+
  facet_wrap(~key, ncol = 5, scales = "free")+
  theme_bw()+
  blogGraphics_theme+
  theme(legend.position = "none")

ggsave("CovidVsTrump_models.png", height = 10, width = 12)

#####------------------------------------------------------#
#####  Models for Covid 2020 ####
#####------------------------------------------------------#

mod_covid <- lm(avg_support ~ death + onVentilatorCurrently + positiveIncrease +
                           totalTestResultsIncrease +
                           recovered + inIcuCurrently + hospitalizedCurrently + 
                          negativeIncrease, data = Corona_poll_2020_df)

stargazer(mod_covid, header=FALSE, type='html', no.space = TRUE,
          column.sep.width = "3pt", font.size = "scriptsize", single.row = TRUE,
          keep = c(1:8, 62:66), omit.table.layout = "sn",
          title = "Covid Models Against Trump's 2020 Poll Averages",out = "forcast_covid.htm")
mod_covid_deaths <- lm(avg_support ~ death,
                       data = Corona_poll_2020_df)
stargazer(mod_covid_deaths, header=FALSE, type='html', no.space = TRUE,
          column.sep.width = "3pt", font.size = "scriptsize", single.row = TRUE,
          keep = c(1:8, 62:66), omit.table.layout = "sn",
          title = "Covid Death Model Against Trump's 2020 Poll Averages",out = "forcast_covidDeath.htm")

covid_2020_change <- head(Corona_poll_2020_df, 1)
## expected covid death rate on election day
covid_2020_change$death <- 232957.8
predict(mod_covid, newdata = covid_2020_change)
