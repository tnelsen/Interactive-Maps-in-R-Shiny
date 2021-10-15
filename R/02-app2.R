library(shiny)
library(googleway)

ui <- fluidPage(
  google_mapOutput(outputId = "map")
)

server <- function(input, output){
  
  map_key <-  "google_maps_api_key"
  
  output$map <- renderGoogle_map({
    google_map(key = map_key,
               location = c(38.533867, -121.771598), # center the map in Davis, CA
               zoom = 8, # set the zoom level
               zoom_control = TRUE, # give the user zoom control
               search_box = FALSE, # remove the search box
               street_view_control = FALSE, # remove street view
               width = '100%',
               height = '100%')
  })
}

shinyApp(ui, server)