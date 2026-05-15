library(shiny)
library(plotly)
library(bslib)
library(markdown)

## ------ build your ui 

ui <- page_sidebar(
  title = tagList(
    
    h1("A Generalized Model for Fire Radiative Power"),
    div(
    p("Interactive dashboard for exploring relationships between spectral radiance and fire radiative power (FRP).",
      class = "text-muted"),
    p("Katherine Mistick and Philip Dennison, University of Utah, 2026.",
      style = "font-size: 0.85rem; color: #9aa0a6;",
      class = "mb-0")
    )),
  
  withMathJax(),
  
  sidebar = sidebar(
    
    # start by setting some "global" styling
    # .accordion-button == bold accordion drawer names
    # .accordion-body .btn == increase button margins for download buttons (will do to ANY button though!)
    tags$style(HTML(".accordion-button {font-size: 1.1rem;font-weight: 600;}              
                    .accordion-body .btn { margin-bottom: 10px; margin-right: 5px; }")),  
    
    bg = "white",
    width=350,
    
    
    accordion(
      open =  FALSE, # don't open any of the sidebar panels by default
      
      div(
        class = "ps-3", 
        p("This dashboard models surface-leaving radiance from mixtures of smoldering (EM1), flaming (EM2) and background radiance (EM3). Radiance mixtures are compared against area-independent Fire Radiative Power Density (FRPD)."),
        p("Spectral radiance is mixed according to: "),
        p(paste0(
                 " \\( L(\\lambda, T)_{total} = L(\\lambda, T)_{EM1} f_{EM1} \\varepsilon_{EM1} + \\) ",
                 "\\( L(\\lambda, T)_{EM2} f_{EM2} \\varepsilon_{EM2} + \\)",
                 "\\( L_{EM3} f_{EM3} \\)")),
        p(
          "The controls below allow users to customize the data space by adjusting controls for both emitted (EM1, EM2) and background (EM3) endmembers."
          ),
        p("For more in-depth description of inputs, see the Documentation section below the plot descriptions at right.")
      ),
      accordion_panel(
        
        title = tagList(
          "Radiance vs. FRPD controls",
          tooltip(
            icon("info-circle"),
            "Global controls for wavelength and number of samples will be applied to the entire dashboard."
          )
        ),
        value = "Radiance vs. FRPD controls", # need a value to function as in ID for the accordion since title is now a tagList() 
        
        
        
        numericInput("wavelength", "Wavelength (μm)", value = 4.07),
        numericInput("samples",
                       label = tagList("Number of samples",
                                       tooltip(icon("info-circle"),
                                                    "Highly restrictive fractional limits on emitted endmembers may affect the ability to plot the full sample size."))
                       , value = 5000)#,
          
      ),
      accordion_panel(
        
        title = tagList(
          "Emitted Endmember 1 (EM1)",
          tooltip(icon("info-circle"),
                  "Control the temperatures, fractions, and emissivity for EM1. The default values represent emitted radiance from smoldering combustion"
                  )
        ),
        value = "Emitted Endmember 1 (EM1)", 
        
        
        div(
          sliderInput('temp1_slider',
                      label = tagList(
                                      tags$small("Temperature Range (Kelvin)"),
                                      tooltip(
                                        icon("info-circle"),
                                        "The default temperature range for smoldering combustion in wildland fire is 500 to 850 K (Yang et al. 2026)"
                                      )
                                      ),
                      min = 300, max = 2000, step=50,
                      value=c(500,850)),
          sliderInput('frac1_slider',
                      label = tagList(
                                      tags$small("Fraction Maximum"),
                                      ),
                      min = 0, max = 1, step=0.01,
                      value=c(0.5)
                      ),
          
          sliderInput('emis_spec_1_slider',
                      label = tagList(
                        tags$small(
                          HTML("Emissivity, spectral (\\(\\varepsilon_{\\lambda}\\))"
                          )
                        ),
                        tooltip(
                          icon("info-circle"),
                          "Spectral emissivity of smoldering wildland fuels is highly variable, the default range of 0.6 to 0.7 is supported by Aldushin et al. 2007, Manzello et al. 2009, and Suuberg et al. 1994"
                        ),
                      ),
                      min = 0.1, max = 1, step=0.05,
                      value=c(0.6, 0.7)
          ),
          
        
          
          sliderInput('emis_aw_1_slider',
                      label = tagList(
                        tags$small(
                          HTML("Emissivity, all-wave (\\(\\varepsilon_{aw}\\))"
                          )
                        ),
                      ),
                      min = 0.1, max = 1, step=0.05,
                      value=c(0.65) # smoldering allwave emissivity
          )
          
        )
      ),
        accordion_panel(
          title = tagList(
            "Emitted Endmember 2 (EM2)",
            tooltip(icon("info-circle"),
                    "Control the temperatures, fractions, and emissivity for EM2. The default values represent emitted radiance from flaming combustion"
            )
          ),
          value = "Emitted Endmember 2 (EM2)", 
          
        div(
        
          sliderInput('temp2_slider',
                      label = tagList(
                                      tags$small("Temperature Range (Kelvin)"),
                                      tooltip(
                                        icon("info-circle"),
                                        "The default temperature range for flaming combustion in wildland fire is 950 to 1450 K (Wotton et al. 2012)"
                                      )
                                      ),
                      min = 300, max = 2000, step=50,
                      value=c(950,1450)),
          
          sliderInput('frac2_slider',
                      label = tagList(
                        tags$small("Fraction Maximum"),
                      ),
                      min = 0, max = 1, step=0.01,
                      value=c(0.25)),
          
          sliderInput('emis_spec_2_slider',
                      label = tagList(
                        tags$small(
                          HTML("Emissivity, spectral (\\(\\varepsilon_{\\lambda}\\))"
                          )),
                          tooltip(
                            icon("info-circle"),
                            "The default range for flaming emissivity in wildland fire is based on the relationship between emissivity and flame thickness"
                          ),
                      ),
                      min = 0.1, max = 1, step=0.05,
                      value=c(0.6, 0.9)
          ),
          
          tooltip(
            tags$div( 
              textOutput("emis_spec_flamelength", inline = TRUE), # Set to TRUE
              span(icon("info-circle"), style = "margin-left: 5px;"),
              class = "text-muted small fst-italic mt-1 mb-3", 
              style = "margin-left: 1rem;color: #9aa0a6;" 
            ),
            
            "In accordance with Kirchoff's law and Beer's law, emissivity (\\( \\varepsilon\\)) is related to path length ( \\(l\\); flame thickness) according to \\(  \\varepsilon = 1 - \\exp(-kl) \\) where the extinction coefficient \\(k\\) is 0.77 (Johnston et al. 2014)",
            placement = 'right'
          ),
          
          sliderInput('emis_aw_2_slider',
                      label = tagList(
                        tags$small(
                          HTML("Emissivity, all-wave (\\(\\varepsilon_{aw}\\))"
                               )
                          ),
                      ),
                      min = 0.1, max = 1, step=0.05,
                      value=c(0.75) # flaming emissivity 
                      )
        )
        ),
        accordion_panel(
          title = tagList(
            "Background Endmember (EM3)",
            tooltip(icon("info-circle"),
                    "Control the magnitude of background radiance"
            )
          ),
          value = "Background Endmember (EM3)", 
        div(
          numericInput("background_rad",
                       label=(
                         tagList(
                           tags$small("Background radiance"),
                           tags$br(),
                           tags$span("(W m⁻² sr⁻¹ μm⁻¹)", style="font-size: 0.7em; color: #666;")
                         )
                       ),
                       value = 0, min=0) #reset default value to 0 from 0.8 -- discuss
        )
        
  
        
        ), # this parenthesis closes the accordion for Rad/frpd
      
    
    )
  ),
  
  accordion(
    open = c("Radiance vs. FRPD"),
    
    accordion_panel(
      "Radiance vs. FRPD",
      plotlyOutput("frpdPlot"),
      br(),
      downloadButton("downloadfrpdplot", "Download data"),
      br(),
      
    ),
    accordion_panel("Plot description",
                    includeMarkdown("frpd_radiance_plot_description.md")
                    ),
    
    accordion_panel(
      "Emissivity sensitivity analysis",
      plotlyOutput("emisPlot")
    ),
    accordion_panel("Plot description",
                    includeMarkdown("emissivity_nrmse_plot_description.md")
    ),
    
    accordion_panel(
      "Documentation",
      includeMarkdown("guide.md")
      
    ),
    
    accordion_panel(
      "References",
      includeMarkdown("refs.md")
      
    )
  )
)


