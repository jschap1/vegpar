# Package maintenance

library(roxygen2)
library(devtools)

setwd("/home/jschap/Documents/Codes/vegpar/")

# devtools::create("vegpar")

# build("vegpar")
document("vegpar")
install("vegpar")
# update_packages("vegpar")
