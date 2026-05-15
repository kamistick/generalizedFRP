
#-- this keeps all our functions

# planck function that takes wavelength and temperature as arguments and returns radiance 
planck_vary_T_wvl_um <- function(wvl, Temp){ #need to provide units in um and K
  C1 <- 1.1911042e8 # units of W um^2 sr^-1 (https://ncc.nesdis.noaa.gov/Planck.php)
  C2 <- 1.4387752e4 # units of umK
  L <- C1 / (wvl^5 * (exp(C2 / (wvl * Temp)) - 1))
  return(L)
}

# frpd equation that relies on L=aT^b relationship (Wooster, b=4)
frpd <- function(sigma, epsilon, a, b, L_diff, t=1) {
  sigma * epsilon^((b-4)/b) * ((L_diff/(t * a))^(4/b)) 
}


# takes temperature as input and returns emittance according to stefan boltzmann
emittance <- function(temp){
  return(5.670374419e-8 * temp^4)
}

# error metrics function takes in a vector of observed and a vector of predicted values
error_mets <- function(obs, pred){ # where frpd_plotting$rad is observed and _calc is predicted
  residuals <- obs - pred # obs - pred
  ss_res <- sum(residuals^2)
  ss_tot <- sum((obs - mean(obs))^2)
  r_squared <- 1 - ss_res/ss_tot
  rmse <- sqrt(mean(residuals^2))
  nrmse <- rmse / mean(obs)
  return(list(r2 = r_squared, rmse = rmse, nrmse=nrmse))
}

