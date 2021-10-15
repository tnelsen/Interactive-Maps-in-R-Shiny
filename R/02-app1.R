library(shiny)
library(googleway)

ui <- fluidPage(
  google_mapOutput(outputId = "map")
)

server <- function(input, output){
  
  map_key <-  "google_maps_api_key"
  
  output$map <- renderGoogle_map({
    google_map(key = map_key)
  })
}

shinyApp(ui, server)