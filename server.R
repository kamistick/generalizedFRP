# for github users check for & install packages (redundant when hosted but ok)
packages <- c("shiny", "plotly", "bslib", "viridis", "gtools", "markdown") 
installed <- packages %in% rownames(installed.packages())
if (any(!installed)) {
  install.packages(packages[!installed])
}
lapply(packages, library, character.only = TRUE)

library(shiny)
library(plotly)
library(bslib)
library(viridis)
library(gtools)

source("functions.R")

# define global variable(s)
sigma <- 5.670374419e-8

## ------ build server 

server <- function(input, output, session){
  
  
  ## --------- frpd reactive
  
  # takes in frpd/Rad data space controls, returns frpd/Radiance/Temps/Fracs/Density colors
  frpd_reacts <- reactive({
    set.seed(1234)
    
    temps_samp1 <- runif(input$samples, input$temp1_slider[1], input$temp1_slider[2]) 
    temps_samp2 <- runif(input$samples, input$temp2_slider[1], input$temp2_slider[2]) 
    
    fracs <- gtools::rdirichlet(input$samples, alpha=c(1,1,1)) # first pass getting dirichlet fracs
    
    df <- data.frame(t1 = temps_samp1, t2 = temps_samp2,
                     f1 = fracs[,1], f2 = fracs[,2], f3 = fracs[,3]) # combine temps, fracs in a dataframe
    
    # if any sample doesn't meet the fraction criteria exclude it
    df_frac_filter <- dplyr::filter(df,
                                    f1 <= input$frac1_slider,
                                    f2 <= input$frac2_slider)
    
    validate(need(nrow(df_frac_filter) > 0, "No samples satisfy the selected fraction limits. Increase limits or add more samples."))
    
   
    if(nrow(df_frac_filter) < input$samples){
      set.seed(1234)
      
      # determine acceptance rate for samples in the initial pull 
      accept_rate <- nrow(df_frac_filter)/input$samples
      
      #get number needed to satisfy constraints (fractions, samples)
      num_needed <- ceiling(input$samples/accept_rate * 1.25) # 25% buffer
      
      # get your temps and fractions
      t1_new <- runif(num_needed, input$temp1_slider[1], input$temp1_slider[2]) 
      t2_new <- runif(num_needed, input$temp2_slider[1], input$temp2_slider[2]) 
      fracs_new <- gtools::rdirichlet(num_needed, alpha = c(1, 1, 1))
      
      # build dataframe and filter for fraction maximums
      df_new <- data.frame(t1 = t1_new,t2 = t2_new,
                           f1 = fracs_new[, 1],f2 = fracs_new[, 2], f3 = fracs_new[, 3])
      df_new_filter <- dplyr::filter(df_new,
                                     f1 <= input$frac1_slider,
                                     f2 <= input$frac2_slider)
      
      # we oversample to satisfy constraints, now we subsample to get back to target no. of samples
      if(nrow(df_new_filter) > input$samples){df_new_filter <- df_new_filter[1:input$samples,]}
      
      # replace the dataframe with the new one
      df_frac_filter <- df_new_filter
    }
    
    # create sample pool for EM2 emissivities
    emis_spec_1_sample =  runif(nrow(df_frac_filter), input$emis_spec_1_slider[1], input$emis_spec_1_slider[2]) 
    df_frac_filter$emis_spec_1 = emis_spec_1_sample
    
    # create sample pool for EM1 emissivities
    emis_spec_2_sample = runif(nrow(df_frac_filter), input$emis_spec_2_slider[1], input$emis_spec_2_slider[2])  
    df_frac_filter$emis_spec_2 = emis_spec_2_sample
    
    # mix radiance
    rad <-(planck_vary_T_wvl_um(input$wavelength, df_frac_filter$t1) * df_frac_filter$f1 * df_frac_filter$emis_spec_1 ) + 
          (planck_vary_T_wvl_um(input$wavelength, df_frac_filter$t2) * df_frac_filter$f2 * df_frac_filter$emis_spec_2) + 
          (input$background_rad * df_frac_filter$f3)
    
    # calculate theoretical frpd
    frpd_vals <- ((emittance(df_frac_filter$t1) * df_frac_filter$f1 * input$emis_aw_1_slider) + 
                   (emittance(df_frac_filter$t2) * df_frac_filter$f2 * input$emis_aw_2_slider)) 
    
    # get density colors for points
    cols <- densCols(rad, frpd_vals, colramp = function(n) viridis(n))
    
    # return named list
    return(list(rad=rad, frpd=frpd_vals,
                colors = cols,
                t1s =  df_frac_filter$t1, f1s = df_frac_filter$f1, espec1 = df_frac_filter$emis_spec_1,
                t2s = df_frac_filter$t2, f2s = df_frac_filter$f2, espec2 = df_frac_filter$emis_spec_2,
                f3s = df_frac_filter$f3))
    
  })
  
  ## ---------  fitting reactives (frpd=aL^b & Wooster - separately)
  
  # best fit frpd returns a and b coefficients and fitted frpd values (a and b based on frpd=aL^b)
  frpd_fit_react <- reactive({
    frpd_plotting <- frpd_reacts() # get your frpd/radiance data space information from the other frpd reactive
    df <- data.frame(FRPD = frpd_plotting$frpd, RAD = frpd_plotting$rad) #nls needs a data frame
    b_start <- coef(lm(log(FRPD) ~ log(RAD), data = df))[["log(RAD)"]] # calculate reasonable start values for a and b
    a_start <- exp(coef(lm(log(FRPD) ~ log(RAD), data = df))[["(Intercept)"]])
    fit <- nls(FRPD ~ a * RAD^b, start = list(a = a_start, b = b_start), control=list(maxiter=400), data=df) # use nls() to fit for the coefs
    frpd_vals <- coef(fit)[["a"]]*frpd_plotting$rad^coef(fit)[["b"]] # calculate frpd using coefs
    return(list(coef_a = coef(fit)[["a"]], coef_b = coef(fit)[["b"]], frpd_fitted_vals = frpd_vals)) # return vals that will be used elsewhere
    
  })
  
  # Wooster fit frpd returns a and b coefficients and fitted frpd values (a and b based on L=aT^b)
  wooster_fit_react <- reactive({
    frpd_plotting <- frpd_reacts() # get frpd data space info from other reactive
    temps.w <- seq(650,1300,10) # define Wooster temps
    planck.vals.w <- vapply(temps.w, function(te) planck_vary_T_wvl_um(input$wavelength, te), numeric(1)) # no additional emissivity bc cancels out
    b.w <- 4 # based on the L = aT^4 fit
    start <- max(planck.vals.w)/max(temps.w)^b.w # realistic start value for a
    df <- data.frame(temps = temps.w, rads = planck.vals.w) # nls() needs data in a dataframe
    fit <- nls(rads ~ a * temps.w^b.w, start = list(a = start), control=list(maxiter=400), data=df) # find a, hold b at 4
    a.w  <- coef(fit)[["a"]] 
    w.rads <- a.w * temps.w^b.w # calculate radiances
    frpd_calc_W <- frpd(sigma, epsilon = 0.8 ,a.w, b.w, frpd_plotting$rad-input$background_rad, t=1) # epsilon (emissivity) doesn't matter here bc it will always cancel out
    return(list(coef_a = a.w, frpd_fitted_vals = frpd_calc_W))
  })
  
  ## -------- emissivity reactive
  
  # loops through all emissivities, returns nrmse values
  
  emis_react <- reactive({
    
    frpd_plotting <- frpd_reacts() # get frpd/rad data space from reactive
    frpd_df <- data.frame(frpd_plotting) # convert to data frame
    frpd_fit <- frpd_fit_react() # get frpd best fit info from reactive
    a <- frpd_fit$coef_a
    b <- frpd_fit$coef_b
    
    all_nRMSE <- c()
    woost.nRMSE <- c()
    
    # theoretical frpd does not change because allwave emissivity is not changing
    frpd_theory <- (emittance(frpd_df$t1s) * frpd_df$f1s * input$emis_aw_1_slider) +
        (emittance(frpd_df$t2s) * frpd_df$f2s * input$emis_aw_2_slider)
      
    pct.errors <- seq(-0.2, 0.2, 0.01)
      
      # this time we are looping through % error to be applied to spectral emissivity
    for (p.err in pct.errors){ 
      
      
      #calculate modeled frpd WITH ABOVE A and B
      # need new emissivity dependent radiance
      espec1.err <- (frpd_df$espec1*p.err) + frpd_df$espec1
      espec2.err <- (frpd_df$espec2*p.err) + frpd_df$espec2
      
      espec1.err <- pmin(espec1.err, 1) # Force any values > 1 to 1
      espec2.err <- pmin(espec2.err, 1)
      
      L <- (planck_vary_T_wvl_um(input$wavelength, frpd_df$t1s) * frpd_df$f1s * espec1.err) + 
        (planck_vary_T_wvl_um(input$wavelength, frpd_df$t2s) * frpd_df$f2s * espec2.err) +
        (input$background_rad * frpd_df$f3s)
      
      # then use the same a and b each time  (from outside loop)    
      frpd_mod <- a*L^b
      
      # compute nRMSE
      nRMSE <- error_mets(frpd_theory, frpd_mod)$nrmse
      
      # save in list 
      all_nRMSE <- c(all_nRMSE, nRMSE)
      
      # also calculate wooster 
      woost_fit <- wooster_fit_react()
      frpd_calc_W <- frpd(sigma, epsilon=1 ,woost_fit$coef_a, b=4, L-input$background_rad, t=1) # epsilon (emissivity) doesn't matter here bc it will always cancel out
      wnRMSE <- error_mets(frpd_theory, frpd_calc_W)$nrmse
      woost.nRMSE <- c(woost.nRMSE, wnRMSE)
      
    }
      
      return(list(nRMSEvals = all_nRMSE, pct.errors = pct.errors, woostnRMSE = woost.nRMSE ))
    
  })
  
  ## --------- PLOTS
  
  # draws output plot
  output$frpdPlot <- renderPlotly({
    
    
    #start by calling relevant reactives
    frpd_plotting <- frpd_reacts()
    frpd_fit <- frpd_fit_react()
    woost_fit <- wooster_fit_react()
    
    # create hover text
    frpd_df <- data.frame(frpd_plotting)
    frpd_df$hover_text <- paste0(
      "Emitted T1: ", round(frpd_df$t1s,0), " K <br>",
      "Fraction 1: ", round(frpd_df$f1s,2), "<br>",
      "Emitted T2: ", round(frpd_df$t2s,0), " K <br>",
      "Fraction 2: ", round(frpd_df$f2s,2), "<br>",
      "Background Fraction: ", round(frpd_df$f3s,2), "<br>","<br>",
      "Total Radiance: ", round(frpd_df$rad,0), "<br>",
      "FRPD: ", round(frpd_df$frpd,0)
    )
    
    # plot data space (points)
    p <- plot_ly() |>
      add_markers(data = frpd_df,
                  x=~rad,
                  y=~frpd,
                  name = "Random mixture",
                  marker = list(color = ~colors),
                  text = ~hover_text,
                  hoverinfo = 'text'
                  )
    
    # get Wooster info before plotting
    frpd_calc_W <- woost_fit$frpd_fitted_vals
    ems <- error_mets(frpd_plotting$frpd, frpd_calc_W)
    ems_text <- paste0(
      "nRMSE = ", round(ems$nrmse, 4)
      )
    
    # add Wooster lines & text
    hover_text_wooster <- paste0("Radiance: ", round(frpd_plotting$rad, 3), 
                                 "<br>FRPD: ", round(frpd_calc_W, 3),
                                 "<br>Alpha: ", format(woost_fit$coef_a, digits = 3, scientific = TRUE))
    
    p <- p |>
      add_lines(x=frpd_plotting$rad,
                y= frpd_calc_W,
                line = list(color = "#13e0e0"),
                name = "Indirect Fit (Wooster et al. (2003))",
                text = hover_text_wooster,       
                hoverinfo = 'text') |>
      layout(
        annotations = list(
          x = 0.07, y = 0.95,
          xref='paper',
          yref='paper',
          xanchor = 'left',
          yanchor = 'top',
          text = ems_text,
          align= "left",
          bgcolor = "white",
          bordercolor = "#13e0e0",
          borderwidth = 1,
          showarrow=FALSE,
          font = list(size = 12, color = "#13e0e0")
          )
        )
    
        
        
    # get frpd=aL^b fit info
    a <- frpd_fit$coef_a
    b <- frpd_fit$coef_b
    fitted_frpds <- frpd_fit$frpd_fitted_vals
    
    # plot lines, calcultae error, plot text
    p <- p |>
      add_lines(x=frpd_plotting$rad,
                y= fitted_frpds,
                line = list(color = "#e41a1c"),
                name = paste0("Direct Fit: FRPD= ", round(a, 3), " L^", round(b,3)))
    ems <- error_mets(frpd_plotting$frpd, fitted_frpds)
    ems_text <- paste0(
      "nRMSE = ", round(ems$nrmse, 4)
      )
    
    p <- p |>
      layout(
        annotations = list(
          x = 0.07, y = 0.88,
          xref='paper',
          yref='paper',
          xanchor = 'left',
          yanchor = 'top',
          text = ems_text,
          align= "left",
          bgcolor = "white",
          bordercolor = "#e41a1c",
          borderwidth = 1,
          showarrow=FALSE,
          font = list(size = 12, color = "#e41a1c")
          )
        )
    
    # add axis titles
    p<- p |> layout(
      xaxis=list(title=list(text="Spectral Radiance (W m⁻² sr⁻¹ μm⁻¹)")),
      yaxis = list(title=list(text="FRPD (W m⁻²)")))
    p
    
  })
  
  # draws output plot
  output$emisPlot <- renderPlotly({
    
    # call emissivity reactive & create dataframe
    emis_analysis <- emis_react()
    emis_df <- data.frame(percent.error=emis_analysis$pct.errors*100, nrmses = emis_analysis$nRMSEvals, woostnrmses = emis_analysis$woostnRMSE)
   
    p <- plot_ly() |>
      add_markers(data = emis_df,
                  x=~percent.error,
                  y=~nrmses,
                  name = "Direct Fit",
                  marker = list(color = "#e41a1c")) |>
      add_markers(data = emis_df,
                  x=~percent.error,
                  y=~woostnrmses,
                  #name = "FRPD = sigma * (L /(t * a))",
                  name = "Indirect Fit",
                  marker = list(color = "#13e0e0")) |>
      add_lines(data = emis_df,
                  x=~percent.error,
                  y=~nrmses,
                  showlegend = FALSE,
                  name = "FRPD = aL^b",
                  line = list(color = "#e41a1c")) |>
      add_lines(data = emis_df,
                  x=~percent.error,
                  y=~woostnrmses,
                  showlegend = FALSE,
                  name = "Wooster et al. (2003)",
                  line = list(color = "#13e0e0")) |>
      layout(
         xaxis=list(title=list(text="Percent error (%) in spectral emissivity")),
         yaxis = list(title=list(text="nRMSE (Theoretical FRPD vs. Modeled FRPD)"))
      )
     
    
    p
    
  })
  
  
  output$emis_spec_flamelength <- renderText({
    fl <- flame_length_react()
    fl_em2_min <- fl$flame_length_min
    fl_em2_max <- fl$flame_length_max
    paste0(
      "Flame thickness ranges from: ",
      round(fl_em2_min, 2),
      " m to ",
      round(fl_em2_max, 2),
      " m"
    )
  })
  
  flame_length_react <- reactive({
    coef_extinction <- 0.77
    emis_min <- input$emis_spec_2_slider[1]
    emis_max <- input$emis_spec_2_slider[2]
    fl_min <- log(1-emis_min)/-coef_extinction
    fl_max = log(1-emis_max)/-coef_extinction
    return(list(flame_length_min = fl_min,
                flame_length_max = fl_max))
  })
  
  ## --------- DOWNLOAD BUTTON
  
  #### ------ download everything shown in plot ####
  
  output$downloadfrpdplot <- downloadHandler(
    filename = function() {
      paste0("frpd-radiance-", Sys.Date(), ".csv")
    },
    content = function(file){
      
      # call reactives 
      frpd_plotting <- frpd_reacts() 
      frpd_fit <- frpd_fit_react()
      woost_fit <- wooster_fit_react()
      frpd_df <- data.frame(frpd_plotting)
      frpd_df$frpd_modeled <- frpd_fit$frpd_fitted_vals
      frpd_df$frpd_Wooster <- woost_fit$frpd_fitted_vals
      frpd_df <- subset(frpd_df, select=-c(colors))
      
      # build header text (comma separated - don't add commas w/in strings)
      colnames(frpd_df) <- c('spectral_radiance', 'frpd_theoretical', 'T1', "f1", "e1_spectral",'T2', 'f2', "e2_spectral", 'f3', "frpd_modeled", "frpd_wooster")
      header_text <- c(
        paste0("Wavelength: ", input$wavelength, " (um)"),
        "Spectral radiance (W m^-2 sr^-1 um^-1): ", "L = (f1 L_T1 e1_spectral) +  (f2 L_T2 e2_spectral) + (f3 L_background)",
        "      f1 = fractional conribution of emitted endmember 1",
        "      L_T1 = radiance calculated using Planck's equation at temperature T1",
        paste0("      e1_spectral = spectral emissivity for emitted endmember 1"),
        "      f2 = fractional conribution of emitted endmember 2",
        "      L_T2 = radiance calculated using Planck's equation at temperature T2",
        paste0("      e2_spectral = spectral emissivity for emitted endmember 2"),
        "      f3 = fractional conribution of background endmember",
        paste0("      L_background = ", input$background_rad , " background radiance"),
        
        "",
        
        "frpd_theoretical (W): ", "FRPD = (sigma  T1^4  f1  e1_allwave) +  (sigma  T2^4  f2  e2_allwave)",
        "      sigma (W m^-2 K^-4) = 5.67e-8 (Stefan-Boltzmann constant)",
        "      T1 (K) = temperature of emitted endmember 1",
        "      f1 = fractional conribution of emitted endmember 1",
        paste0("      e1_allwave = ", input$emis_aw_1_slider  ," all-wave emissivity for emitted endmember 1"),
        "      T2 (K) = temperature of emitted endmember 2",
        "      f2 = fractional conribution of emitted endmember 2",
        paste0("      e2_allwave = ", input$emis_aw_2_slider  ," all-wave emissivity for emitted endmember 2"),
        
        "",
        
        
        "frpd_modeled (W/m^2): ", "FRPD =  a L ^ b ",
        paste0("      a = ",  frpd_fit$coef_a), 
        paste0("      b = ",  frpd_fit$coef_b),
        "      L = mixed spectral radiance (see above)",
        
        "",
        
        "frpd_Wooster (W/m^2): ", "FRPD = sigma * (L/(t * a))",
        "      sigma (W m^-2 K^-4) = 5.67e-8 (stefan boltzmann's constant)",
        "      L = mixed spectral radiance (see above)",
        "      t (unitless) = 1 (transmittance; fixed)",
        paste0("      a = ", woost_fit$coef_a), 
        
        
        ""  # blank line before table
      )
      
      writeLines(header_text, con = file)
      write.table(
        frpd_df,
        file = file,
        sep = ",",
        row.names = FALSE,
        col.names = TRUE,
        append = TRUE # this adds the table after the header text we just wrote
      )
    }
  )
  
  
  
}