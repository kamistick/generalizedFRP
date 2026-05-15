# for github users check for & install packages (redundant when hosted but ok)
packages <- c("shiny", "plotly", "bslib", "viridis", "gtools", "markdown") 
installed <- packages %in% rownames(installed.packages())
if (any(!installed)) {
  install.packages(packages[!installed])
}
lapply(packages, library, character.only = TRUE)

