library(shiny)
library(leaflet)
library(dplyr)

shapefile <- sf::st_read("../data/ca_ag_regions.shp")

shapefile <- sf::st_as_sf(shapefile)  %>%
  mutate(fill_color = if_else(!is.na(region), "#1C00ff00", "#A9A9A9"))

ui <- fluidPage(
  leafletOutput(outputId = "map")
)

server <- function(input, output){
  
  output$map <- renderLeaflet({
    leaflet(shapefile) %>% 
      setView(lng = -121.771598, lat = 38.533867, zoom = 8) %>% # center the map in Davis, CA
      addPolygons(color = "black",
                  fillColor = ~fill_color,
                  fillOpacity = 0.5) %>% 
      addMarkers(lng = -121.771598,
                 lat = 38.533867,
                 options = markerOptions(draggable = TRUE)) %>% 
      #addProviderTiles('Esri.WorldImagery') %>% 
      addTiles()
    
  })
}

shinyApp(ui, server)