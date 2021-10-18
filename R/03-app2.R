library(shiny)
library(leaflet)

ui <- fluidPage(
  leafletOutput(outputId = "map")
)

server <- function(input, output){
  
  output$map <- renderLeaflet({
    leaflet() %>% 
      setView(lng = -121.771598, lat = 38.533867, zoom = 12) %>% # center the map in Davis, CA
      #addProviderTiles('Esri.WorldImagery') %>% 
      addTiles() 

  })
}

shinyApp(ui, server)