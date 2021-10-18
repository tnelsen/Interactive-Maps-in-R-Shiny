library(shiny)
library(leaflet)

ui <- fluidPage(
  leafletOutput(outputId = "map")
)

server <- function(input, output){
  
  output$map <- renderLeaflet({
    leaflet() %>% 
      addTiles()
  })
}

shinyApp(ui, server)