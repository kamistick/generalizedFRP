# Shiny Dashboard: A Generalized Model for Fire Radiative Power
This repository contains supporting documents for the Shiny dashboard 'A Generalized Model for Fire Radiative Power'.

## How to run the dashboard
### Online 
The dashboard is hosted with Shiny at https://mistick.shinyapps.io/FireRadiativePower/ 
### Via GitHub  
To run locally via R run these lines in your console:
```r
# install Shiny if it is not already installed
install.packages("shiny")
    
# run the application directly from GitHub
shiny::runGitHub("generalizedFRP", "kamistick")
```
**Note:** this will automatically attempt to install needed packages if they have not been installed. However, package versioning is not enforced, you may need to update existing local packages if you encounter compatibility errors. 

### Via clone/file download
1. Download or clone this repository to a directory on your machine.
2. In R Studio set your working directory to the folder containing the downloaded repository.
3. Run the application using:
```r
# install Shiny if it is not already installed
install.packages("shiny")
    
# run the application locally
shiny::runApp()
```
