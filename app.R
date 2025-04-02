library(tidyverse)
library(shiny)
library(shinyFiles)
library(shinyWidgets)
library(shinythemes)
options(dplyr.summarise.inform = FALSE)
load("data/Functions.RData")

# setwd("/Users/yuriniella/Documents/GitHub/IMOS-ATF-to-DC-converter")
# App version control
app_version <- "1.0.0"
Month <- "March"
Year <- "2025"
files.process <- c("Animal measurements", 
  "Animal releases", 
  "Receiver deployments", 
  "Sensor measurements", 
  "Animal detections")
max.progress <- length(files.process)
   
# App starts
ui <- shinyUI(
  # navbarPage(paste("IMOS ATF - Darwin Core converter", app_version),
  tabPanel("Converter", uiOutput('Converter'))
)

server <- shinyServer(function(input, output, session) {
  options(shiny.maxRequestSize=200*1024^2)
  output$Converter <- renderUI({
    fluidPage(
      theme = shinytheme("slate"),
      br(),
      img(src = "logo_v1.png",
        width = "230px", height = "130px"
      ),
      titlePanel(
        p("Acoustic Telemetry to Darwin Core converter"),
        ),
        # setBackgroundColor("white"),
        sidebarLayout(
        sidebarPanel = sidebarPanel(width = 5,
            p("This app converts the summarised version of the quality controlled IMOS Animal Tracking Facility 
            acoustic telemetry dataset into Darwin Core format. For more information about the Darwin Core format, please ",
            tags$a(href = "https://www.tdwg.org/standards/dwc/#maintenance-group%22%3E", 
              "click here.", target = "_blank")),
            br(),
            p("Please first download the summarised version of the Acoustic Tracking dataset you would like to convert
              from the ",
              tags$a(href = "https://portal.aodn.org.au/search", 
                "AODN database.", target = "_blank")
              ),
            br(),
            p("To convert the files to Darwin Core format, please provide below the folder where the
              IMOS acoustic telemetry summarised data was downloaded in your computer (input). 
              Also, please select the output folder where you would like to export the converted files:"), 
            br(),
            shinyDirButton('INPUTfolder', 
              'Select input folder', FALSE),
            br(),br(),
            shinyDirButton('OUTPUTfolder', 
              'Select output folder', FALSE),
            br(),br(),
          ),
        # Process summarised dataset
        mainPanel = mainPanel(align = "center",
          h3("Selected input folder"),
          verbatimTextOutput(outputId = "INPUTpath", placeholder = TRUE),
          br(),
          h3("Selected output folder"),
          verbatimTextOutput(outputId = "OUTPUTpath", placeholder = TRUE),
          br(),
          tags$b("Processing status"), 
              progressBar(
                id = "pb",
                value = 0,
                total = NULL,
                title = "",
                display_pct = TRUE,
                status = "custom"),
              tags$style(".progress-bar-custom {background-color: #3b6e8f;}"),
          actionButton(inputId = 'runConvertion',
              label = "Convert files"),
          br(),br(),br(),br(),
          h4(paste0("Version ", app_version), align = "center"),
          h4(paste0("Last updated: ", Month, " ", Year), align = "center"),
          br()
        )
      )
    )
  })
  # Reactive options to select INPUT/OUTPUT folders  
  volumes = getVolumes()()
  shinyDirChoose(input, 'INPUTfolder', roots = volumes, filetypes = c('csv'))
  inputdir <- reactive({parseDirPath(volumes, input$INPUTfolder)})
  shinyDirChoose(input, 'OUTPUTfolder', roots = volumes, filetypes = c('csv'))
  outputdir <- reactive({parseDirPath(volumes, input$OUTPUTfolder)})
  # Display paths in main tab
  observeEvent(input$INPUTfolder, {
    output$INPUTpath <- renderText({  # use renderText instead of renderPrint
      {parseDirPath(volumes, input$INPUTfolder)}
    })
  })
  observeEvent(input$OUTPUTfolder, {
    output$OUTPUTpath <- renderText({  # use renderText instead of renderPrint
      {parseDirPath(volumes, input$OUTPUTfolder)}
    })
  })
  # Process data 
  observeEvent(input$runConvertion, {
    input_path = parseDirPath(volumes, input$INPUTfolder)
    output_path = parseDirPath(volumes, input$OUTPUTfolder)

    # Rename and stack
    for (i in 1:length(files.process)) {
      if (i == 1) {
        updateProgressBar(
        session = session,
        id = "pb",
        value = 0, total = max.progress,
        title = "Processing started. Please wait..."
        )
      } 
      imos_DC(input_path = input_path, output_path = output_path,
        type = files.process[i])
      updateProgressBar(
        session = session,
        id = "pb",
        value = i, total = max.progress,
        title = paste("File created:", paste0(files.process[i], ".csv"))
      )
      if (i == length(files.process)) {
        updateProgressBar(
        session = session,
        id = "pb",
        value = i, total = max.progress,
        title = "Processing finished!"
        )
      } 
    }
  })
})

shinyApp(ui, server)