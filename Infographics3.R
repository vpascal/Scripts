# There are a number of components that have to be changed manually. Plese search for "manually," to see what/where things need to be changed.

library(maptools)
gpclibPermit()
library(rgeos)
library(sp)
library(rgdal)
library(rgeos)
library(ggmap)
library(plyr)
library(ggplot2)
library(reshape)
library(gridExtra)
library(scales)
library(extrafont)
loadfonts()

# source('http://research.stowers-institute.org/efg/R/Color/Chart/ColorChart.R')

setwd("C:/Users/Vladislav Pascal/Documents")

options(stringsAsFactors = FALSE)
data <- read.delim("report_2014-10-19.csv", header = T, sep = "\t")

# data cleaning #########################################

trim <- function(x) gsub("^\\s+|\\s+$+|\\?", "", x)
replace <- function(x) gsub("unic", "unique", x)
data <- as.data.frame(apply(data, MARGIN = 2, FUN = trim))
data <- as.data.frame(apply(data, MARGIN = 2, FUN = replace))
data <- data[which(data$Question != "Upload other documents" & data$Question != "Upload photos"), ]
data <- data[which(data$Name != "Biblioteca Publica de Drept" & data$Name != "Biblioteca Nationala a Republicii Moldova"), ]
data <- data[data$Raion != "Chisinau", ]
data$Date <- as.Date(data$Date)
######################################################### 

z <- c("users", "gender", "age", "visits", "workNovateca", "loans", "participants", "webpage", "web_visits", "staff", "trained_inds", 
    "training_topics")

lookup <- c("Number of all unique users to library", "Total number of registered/unic users of each gender", "year", "physical visits", 
    "Novateca workstation", "Total number of loans of library materials", "Total number of event visitors", "Does your library have a web page", 
    "If answered yes to previous question", "How many people work in the library", "Number of trained persons", "Topic/title of each training")

lookup <- data.frame(cbind(z, lookup))


for (i in lookup[, 2]) {
    pattern <- agrep(i, x = data$Question, useBytes = T)
    assign(lookup[which(lookup$lookup == i), 1], data[pattern, ])
}
rm("pattern", "z", "i", "lookup")
######################################################### 

# Users
users$Answer <- as.numeric(users$Answer)
users <- ddply(users, .(Date, Question), summarize, Value = sum(Answer, na.rm = T))
users$Date <- as.Date(users$Date)
###### Gender
gender$Answer <- as.numeric(gender$Answer)
gender <- ddply(gender, .(Date, Question), summarize, Value = sum(Answer, na.rm = T))
gender <- cast(gender, Date ~ Question)
gender$Total <- gender[, 2] + gender[, 3]
gender$Percent_Female <- gender[, 2]/gender[, 4] * 100
gender$Percent_Male <- gender[, 3]/gender[, 4] * 100
gender$Date <- as.Date(gender$Date)
# Age
age$Answer <- as.numeric(age$Answer)
age <- cast(age, Date ~ Question, sum, na.rm = T)
age$Total <- age[, 2] + age[, 3] + age[, 4] + age[, 5]
age$Percent_0_16 <- age[, 2]/age$Total * 100
age$Percent_17_30 <- age[, 3]/age$Total * 100
age$Percent_31_57 <- age[, 4]/age$Total * 100
age$Percent_58_above <- age[, 5]/age$Total * 100
age$Date <- as.Date(age$Date)
# Visits
visits$Answer <- as.numeric(visits$Answer)
visits <- cast(visits, Date ~ Question, sum, na.rm = T)
# Workstation
workNovateca$Answer <- as.numeric(workNovateca$Answer)
workNovateca <- cast(workNovateca, Date ~ Question, sum, na.rm = T)
workNovateca$Total <- workNovateca[, 2] + workNovateca[, 3]
workNovateca$Percent_Non_Novateca <- workNovateca[, 2]/workNovateca[, 4] * 100
workNovateca$Percent_Novateca <- workNovateca[, 3]/workNovateca[, 4] * 100
workNovateca$Date <- as.Date(workNovateca$Date)
# Loans
loans$Answer <- as.numeric(loans$Answer)
loans <- ddply(loans, .(Date, Question), summarize, Value = sum(Answer, na.rm = T))
# Participants
participants$Answer <- as.numeric(participants$Answer)
participants <- ddply(participants, .(Date, Question), summarize, Value = sum(Answer, na.rm = T))
participants$Date <- as.Date(participants$Date)
# Webpage
webpage <- as.data.frame(ftable(webpage$Answer ~ webpage$Date))
# selecting manually last two months
webpage <-webpage[which(webpage$webpage.Date =="2014-07-01"|webpage$webpage.Date =="2014-06-01"),]
# webPage visits
web_visits$Answer <- as.numeric(web_visits$Answer)
web_visits <- ddply(web_visits, .(Date, Question), summarize, Value = sum(Answer, na.rm = T))
web_visits$Date<-as.Date(web_visits$Date)
web_visits<-web_visits[web_visits$Date==max(web_visits$Date),]
############# Staff
staff$Answer <- as.numeric(staff$Answer)
staff <- ddply(staff, .(Date, Question), summarize, Value = sum(Answer, na.rm = T))
staff<-staff[staff$Date==max(staff$Date),]
# Training hours
pattern <- grep("The total hours per training|Total number of hours per training, duration in hours", data$Question, useBytes = T)
training_hours <- data[pattern, ]
training_hours$Question[training_hours$Question == "Total number of hours per training, duration in hours"] <- "The total hours per training"

training_hours$Answer <- as.numeric(training_hours$Answer)
training_hours <- ddply(training_hours, .(Date, Question), summarize, Value = sum(Answer, na.rm = T))
training_hours$Date <- as.Date(training_hours$Date)


# Trained individuals
trained_inds$Answer <- as.numeric(trained_inds$Answer)
trained_inds <- ddply(trained_inds, .(Date, Question), summarize, Value = sum(Answer, na.rm = T))

###################### 

data$Question[data$Question == "Total number of consultations in June"] <- "Number of consultations"
data$Question[data$Question == "Total number of consultations"] <- "Number of consultations"
data$Question[data$Question == "Number of consultations in June"] <- "Number of consultations"
data$Question[data$Question == "Communiqueation"] <- "Communication"

pattern <- grep("Communiqueation|Digital Inclusion|Economic Development|Culture and Leisure|Other consultations| of consultations|Electronic Governance|Health|Education", 
                data$Question, useBytes = T)
consultations <- data[pattern, ]

consultations_total <- consultations[consultations$Question == "Number of consultations", ]
consultations_total$Answer <- as.numeric(consultations_total$Answer)
consultations_total <- ddply(consultations_total, .(Date, Question), summarize, Value = sum(Answer, na.rm = T))

consultations_type <- consultations[consultations$Question != "Number of consultations", ]
consultations_type$Answer <- as.numeric(consultations_type$Answer)
consultations_type <- ddply(consultations_type, .(Date, Question), summarize, Value = sum(Answer, na.rm = T))

# selecting manually the most recent month
consultations_type_feb <- consultations_type[consultations_type$Date == "2014-07-01", ]
consultations_type_feb$Percent <- consultations_type_feb$Value/sum(consultations_type_feb$Value) * 100
consultations_type_feb <- consultations_type_feb[with(consultations_type_feb, order(-Percent)), ]

############# 
pattern <- grep("o |nu a avut loc|Nu am avut |nu am avut|Nu am petrecut|0", ignore.case = T, x = training_topics$Answer, 
                useBytes = T)
training_topics <- training_topics[-pattern, ]
training_topics<- subset(training_topics, Answer!="")


#####################################

pattern <- grep("Did you library receive any technology donations ", data$Question, 
                useBytes = T)
tech_donations <- data[pattern, ]

pattern <- grep("volunteers ", data$Question, 
                useBytes = T)
volunteers <- data[pattern,] 

pattern <- grep("Did you library receive any capital donations", data$Question, useBytes = T)
cap_donations <- data[pattern, ]
cap_donations<-as.data.frame(ftable(cap_donations$Answer~cap_donations$Date))
cap_donations$cap_donations.Date<-as.Date(cap_donations$cap_donations.Date)
cap_donations<-cap_donations[cap_donations$cap_donations.Date == max(cap_donations$cap_donations.Date),]
cap_donations<-cap_donations[cap_donations$Freq>0,]

tech_donations<-as.data.frame(ftable(tech_donations$Answer~tech_donations$Date))
tech_donations$tech_donations.Date<-as.Date(tech_donations$tech_donations.Date)
tech_donations<-tech_donations[tech_donations$tech_donations.Date == max(tech_donations$tech_donations.Date),]
tech_donations<-tech_donations[tech_donations$Freq>0,]


volunteers<-as.data.frame(ftable(volunteers$Answer~volunteers$Date))
volunteers$volunteers.Date<-as.Date(volunteers$volunteers.Date)

volunteers<-volunteers[volunteers$volunteers.Date == max(volunteers$volunteers.Date),]
volunteers<-volunteers[volunteers$Freq>0,]

########## plotting

Date <- c(format(as.Date(users$Date), format = "%b %y"))  # will keep for plotting

mplot <- function(x, ...) {
    par(tcl = -0.2, mgp = c(1, 0.5, 0))
    plot(x, ylab = NA, xlab = NA, lwd = 1.5, frame.plot = F, xaxt = "n", ...)
}

pdf_datei <- "test.pdf"
cairo_pdf(bg = "grey98", pdf_datei, width = 11.7, height = 8.3)  #A4
par(oma = c(1, 3, 1, 2), mai = c(0.3, 0.1, 0.1, 0.1), family = "Lato Light", las = 1)
par(mfcol = c(4, 4))

############################ 
line <- c(paste(length(unique(data$Raion)), "Raions"))
line1 <- c(paste(length(unique(data$Name)), "Libraries"))
line2 <- c(paste(staff[1, 3], "Librarians"))
line3 <- c("thousands of")
line4 <- c("people")

par(mar = c(0.1, 0.1, 0.1, 0.1))
a <- readShapeSpatial("MDA_Adm1", repair = T)
proj4string(a) <- CRS("+proj=longlat +datum=NAD27")
a$NAME_1 <- as.character(a$NAME_1)
a$NAME_1[a$NAME_1 == "Hîncesti"] <- "Hincesti"
plot(a, col = "#00A6FF", border = "white", lwd = 0.8)
raions <- c(unique(data$Raion))
network <- a[a$NAME_1 %in% raions, ]
plot(network, border = "white", col = "orange", add = T, lwd = 0.8)
text(26.44107, 47.63414, line, col = "darkred", cex = 1.4)
text(26.59177, 47.19935, line1, col = "darkred", cex = 1.4)
text(26.68107, 46.83414, line2, col = "darkred", cex = 1.4)
text(26.92226, 46.42006, line3, col = "darkred", cex = 1.4)
text(27.39971, 45.99624, line4, col = "darkred", cex = 1.4)
mtext("Source: Online Reporting Tool", side = 3, line = -0.1, cex = 0.6, adj = 0, family = "Arial", font = 3)
############################### 

############################# users
par(mar = c(2, 1, 1, 1))
mplot(users$Value ~ users$Date, col = "tan1", type = "l", yaxt = "n", ylim = c(0, 15000))
par(new = T)
points(users[6, 3] ~ users[6, 1], col = "tan1", pch = 19, cex = 2, yaxt = "n")
points(users[1:5, 3] ~ users[1:5, 1], col = "tan1", pch = 19, cex = 1, yaxt = "n")
axis(1, at = users$Date, labels = Date, col.axis = "black", las = 1)
axis(2, col = NA, col.ticks = "black", at = seq(from = 0, to = 15000, by = 3000), labels = seq(from = 0, to = 15, by = 3))
title("Number of  New Library Users (in '000)", font = 2)

############################# gender
mplot(gender$Percent_Female ~ gender$Date, type = "l", col = "red2", axes = T, ylim = c(0, 100), yaxt = "n")
par(new = T)
mplot(gender$Percent_Male ~ gender$Date, type = "l", col = "dodgerblue", ylim = c(0, 100), yaxt = "n")
axis(1, at = users$Date, labels = Date, col.axis = "black", las = 1)
axis(2, col = NA, col.ticks = "black", at = seq(from = 0, to = 80, by = 20), labels = seq(from = 0, to = 80, by = 20))
points(gender[6, 5] ~ gender[6, 1], col = "red2", pch = 19, cex = 2, yaxt = "n")
points(gender[1:5, 5] ~ gender[1:5, 1], col = "red2", pch = 19, cex = 1, yaxt = "n")
points(gender[6, 6] ~ gender[6, 1], col = "dodgerblue", pch = 19, cex = 2, yaxt = "n")
points(gender[1:5, 6] ~ gender[1:5, 1], col = "dodgerblue", pch = 19, cex = 1, yaxt = "n")
title("Library Users by Sex (%)")
# position of the legend may need to be changed manually
legend("topleft", c("Female", "Male"), lwd=c(1,1), col=c("red2","dodgerblue"), bty="n",cex=0.8)

##################### age
mplot(age$Percent_0_16 ~ age$Date, type = "l", col = "red2", axes = T, ylim = c(0, 80), yaxt = "n")
par(new = T)
mplot(age$Percent_17_30 ~ age$Date, type = "l", col = "dodgerblue", ylim = c(0, 80), yaxt = "n")
par(new = T)
mplot(age$Percent_31_57 ~ age$Date, type = "l", col = "orange3", ylim = c(0, 80), yaxt = "n")
par(new = T)
mplot(age$Percent_58_above ~ age$Date, type = "l", col = "forestgreen", ylim = c(0, 80), yaxt = "n")
axis(1, at = users$Date, labels = Date, col.axis = "black", las = 1)
axis(2, col = NA, col.ticks = "black", at = seq(from = 0, to = 80, by = 20), labels = seq(from = 0, to = 80, by = 20))

points(age[6, 7] ~ age[6, 1], col = "red2", pch = 19, cex = 2, yaxt = "n")
points(age[6, 8] ~ age[6, 1], col = "dodgerblue", pch = 19, cex = 2, yaxt = "n")
points(age[6, 9] ~ age[6, 1], col = "orange3", pch = 19, cex = 2, yaxt = "n")
points(age[6, 10] ~ age[6, 1], col = "forestgreen", pch = 19, cex = 2, yaxt = "n")

points(age[1:6, 7] ~ age[1:6, 1], col = "red2", pch = 19, cex = 1, yaxt = "n")
points(age[1:6, 8] ~ age[1:6, 1], col = "dodgerblue", pch = 19, cex = 1, yaxt = "n")
points(age[1:6, 9] ~ age[1:6, 1], col = "orange3", pch = 19, cex = 1, yaxt = "n")
points(age[1:6, 10] ~ age[1:6, 1], col = "forestgreen", pch = 19, cex = 1, yaxt = "n")
title("Library Users by Age Category (%)")
legend("topleft", c("<16", "17-30","30-57","57+"), lwd=c(1,1), col=c("red2","dodgerblue","orange3","forestgreen"), bty="n",ncol=2, cex=0.8)

########################## 

# event participants
mplot(participants$Value ~ participants$Date, col = "tan1", type = "l", yaxt = "n", ylim = c(0, 15000))
par(new = T)
points(participants[6, 3] ~ participants[6, 1], col = "tan1", pch = 19, cex = 2, yaxt = "n")
points(participants[1:5, 3] ~ participants[1:5, 1], col = "tan1", pch = 19, cex = 1, yaxt = "n")
axis(1, at = participants$Date, labels = Date, col.axis = "black", las = 1)
axis(2, col = NA, col.ticks = "black", at = seq(from = 0, to = 15000, by = 3000), labels = seq(from = 0, to = 15, by = 3))
title("Event Participants (in '000)", font = 2)


# workstation
perc<-c(round(t(workNovateca[6, 5:6]),digits=1))
lab<-c("Non-Novateca","Novateca")
labels<-paste(perc,lab,sep="\n")
pie(t(workNovateca[6, 5:6]), col = c("#70C8E6", "#00A4DA"), border = "white", labels=labels)
title("Computer Usage Rate (%)")
######################### visits
mplot(visits[, 2] ~ visits[, 1], col = "tan1", type = "l", yaxt = "n", ylim = c(0, 80000))
par(new = T)
points(visits[6, 2] ~ visits[6, 1], col = "tan1", pch = 19, cex = 2)
points(visits[1:5, 2] ~ visits[1:5, 1], col = "tan1", pch = 19, cex = 1, yaxt = "n")

axis(1, at = users$Date, labels = Date, col.axis = "black", las = 1)
axis(2, col = NA, col.ticks = "black", at = seq(from = 0, to = 80000, by = 20000), labels = seq(from = 0, to = 80, by = 20))
title("Physical Visits (in '000)", font = 2)

################ 
mplot(c(1:10), type="n", yaxt="n")
# manually change the month
title("Donations: July")
text("Yes",x=9,y=8,col="darkred",cex=1.6)
text("No",x=7,y=8,col="darkred",cex=1.6)
text("Technology",x=6,y=6,col="darkred",cex=1.6, pos=2)
text("Staff",x=6,y=4,col="darkred",cex=1.6, pos=2)
text("Infrastructure",x=6,y=2,col="darkred",cex=1.6, pos=2)


text(tech_donations[1,3],x=7 ,y=6, col="darkred", cex=1.6)
text(tech_donations[2,3],x=9 ,y=6, col="darkred", cex=1.6)
text(volunteers[1,3],x=7,y=4, col="darkred", cex=1.6)
text(volunteers[2,3],x=9,y=4, col="darkred", cex=1.6)
text(cap_donations[1,3],x=7,y=2, col="darkred", cex=1.6)
text(cap_donations[2,3],x=9,y=2, col="darkred", cex=1.6)
################ 

############### webpage
webpage<-webpage[webpage$webpage.Answer!="",] 
barplot(webpage$Freq, col = c("maroon1", "maroon1", "orange", "orange"), names.arg = c(format(as.Date(webpage$webpage.Date), 
    format = "%b %y")), border = "white", yaxt = "n", ylim = c(0, 50))
title("Do you have a webpage?")
axis(2, col = NA, col.ticks = "black", at = seq(from = 0, to = 50, by = 10), labels = seq(from = 0, to = 50, by = 10))
legend("topleft",c("No", "Yes"), border="white",fill=c("maroon1","orange"), bty="n",cex=0.8)
################## 
mplot(1:5, type = "n", yaxt = "n")
mtext(format(web_visits$Value, format="d", big.mark=','), side = 3, cex = 3.3, line = -7, col = "darkred")
mtext("Virtual visits in July", side = 3, line = -2, cex = 1.2, col = "darkred")
##################################### 

########## consultations total
mplot(consultations_total$Value ~ users$Date, col = "tan1", type = "l", yaxt = "n", ylim = c(0, 30000))
par(new = T)
points(consultations_total[6, 3] ~ consultations_total[6, 1], col = "tan1", pch = 19, cex = 2)
points(consultations_total[1:5, 3] ~ consultations_total[1:5, 1], col = "tan1", pch = 19, cex = 1, yaxt = "n")
axis(1, at = consultations_total$Date, labels = Date, col.axis = "black", las = 1)
axis(2, col = NA, col.ticks = "black", at = seq(from = 0, to = 30000, by = 6000), labels = seq(from = 0, to = 30, by = 6))
title("Number of Consultations (in '000)", font = 2)

################ 
barplot(consultations_type_feb$Percent, col = "#8ACCF5", border = "white", horiz = T, xlim = c(0, 40))
axis(1, at = seq(0, 40, 10), labels = seq(0, 40, 10))
text(22, 0.75, "Culture and Leisure")
text(17, 2, "Education")
text(14, 3.15, "Communication")
text(9, 4.35, "Digital Inclusion")
text(6, 5.5, "Health")
text(11, 6.8, "Economic Development")
text(10, 8, "Electronic Governance")
title("Consultations by Category (%)")

########## training info

mplot(trained_inds$Value ~ users$Date, col = "tan1", type = "l", yaxt = "n", ylim = c(0, 1200))
par(new = T)
points(trained_inds[6, 3] ~ trained_inds[6, 1], col = "tan1", pch = 19, cex = 2)
points(trained_inds[1:5, 3] ~ trained_inds[1:5, 1], col = "tan1", pch = 19, cex = 1, yaxt = "n")
axis(1, col = "black", col.ticks = "black", at = trained_inds$Date, labels = Date)
axis(2, col = NA, col.ticks = "black", at = seq(from = 0, to = 1200, by = 200), labels = seq(from = 0, to = 1200, by = 200))
title("Number of Trained Individuals", font = 2)

mplot(training_hours$Value ~ training_hours$Date, col = "tan1", type = "l", yaxt = "n", ylim = c(0, 600))
par(new = T)
points(training_hours[6, 3] ~ training_hours[6, 1], col = "tan1", pch = 19, cex = 2)
points(training_hours[1:5, 3] ~ training_hours[1:5, 1], col = "tan1", pch = 19, cex = 1, yaxt = "n")

axis(2, col = NA, col.ticks = "black", at = seq(from = 0, to = 600, by = 100), labels = seq(from = 0, to = 600, by = 100))
axis(1, at = training_hours$Date, labels = Date, col.axis = "black", las = 1)
title("Number of Training Hours", font = 2)


########################## 
topics <- as.data.frame(count(training_topics, "Date"))
barplot(topics$freq, names.arg = Date, width = 0.5, col = "#FF34B3", border = "white", yaxt = "n", ylim = c(0, 50))
axis(2, col = NA, col.ticks = "black", at = seq(from = 0, to = 50, by = 10), labels = seq(from = 0, to = 50, by = 10))
title("Number of Trainings")

################### 

# Loans
mplot(loans[, 3] ~ loans[, 1], col = "tan1", type = "l", yaxt = "n", ylim = c(0, 240000))
par(new = T)
points(loans[6, 3] ~ loans[6, 1], col = "tan1", pch = 19, cex = 2)
points(loans[1:5, 3] ~ loans[1:5, 1], col = "tan1", pch = 19, cex = 1, yaxt = "n")
axis(1, at = loans$Date, labels = Date, col.axis = "black", las = 1)
axis(2, col = NA, col.ticks = "black", at = seq(from = 0, to = 240000, by = 40000), labels = seq(from = 0, to = 240, by = 40))

title("Library Loans (in '000)", font = 2)


############################ 

dev.off()
 

