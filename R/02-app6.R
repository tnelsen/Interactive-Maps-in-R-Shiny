library(shiny)
library(googleway)
library(dplyr)

shapefile <- sf::st_read("../data/ca_ag_regions.shp")

shapefile <- sf::st_as_sf(shapefile)  %>%
  mutate(fill_color = if_else(!is.na(region), "#1C00ff00", "#A9A9A9"))

ui <- fluidPage(
  google_mapOutput(outputId = "map"),
  textOutput("text")
)

server <- function(input, output){
  
  map_key <-   "google_maps_api_key"
  
  output$map <- renderGoogle_map({
    google_map(key = map_key,
               location = c(38.533867, -121.771598), # center the map in Davis, CA
               zoom = 8, # set the zoom level
               zoom_control = TRUE, # give the user zoom control
               search_box = FALSE, # remove the search box
               street_view_control = FALSE, # remove street view
               width = '100%',
               height = '100%') %>%
      add_polygons(data = shapefile,
                   fill_colour = "fill_color",
                   stroke_colour = "#030303",
                   update_map_view = FALSE) %>% 
      add_markers(data = data.frame(lat = 38.533867, lon = -121.771598),
                  draggable = TRUE, # can the user move the point
                  update_map_view = FALSE)
  })
  
  observeEvent(input$map_marker_drag, {
    print(input$map_marker_drag)
  })
  
  observeEvent(input$map_polygon_click, {
    print(input$map_polygon_click$lat)
    print(input$map_polygon_click$lon)
  }) 
  
  output$text <- renderText({input$map_polygon_click$lat})
  
}

shinyApp(ui, server)