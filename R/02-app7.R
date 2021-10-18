# load needed packages for interactive shiny map application

library(shiny)
library(googleway)
library(dplyr)
library(shinydashboard)

# read in shape data into global environment 

shapefile <- sf::st_read("../data/ca_ag_regions.shp")

shapefile <- sf::st_as_sf(shapefile)  %>%
  mutate(fill_color = if_else(!is.na(region), "#1C00ff00", "#A9A9A9"))


# define function used in application

region_data <- function(shapefile, markers) {
  
  removeNotification(id = "region_error", session = getDefaultReactiveDomain())
  
  dat <- data.frame(Longitude = markers$lon,
                    Latitude = markers$lat,
                    names = c("Point"))
  
  dat <- sf::st_as_sf(dat,
                      coords = c("Longitude",
                                 "Latitude"))
  
  sf::st_crs(dat) <- sf::st_crs(shapefile)
  
  return(as.data.frame(shapefile)[which(sapply(sf::st_intersects(shapefile,dat), function(z) if (length(z)==0) NA_integer_ else z[1]) == 1), ])
}


ui <- dashboardPage(
  dashboardHeader(disable = TRUE),
  dashboardSidebar(disable = TRUE),
  dashboardBody(
  box(width = 6, 
      p("Click or drag the marker wihtin the state of California to see the marker coordinates (lat/long) and if it is in an agricultural region."),
      google_mapOutput(outputId = "map")
      ),
  box(width = 6,
      htmlOutput("text")
      )
),
  title = "Interactive Maps"
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
  
  current_markers <- reactiveValues(
    lat=38.533867, lon=-121.771598)
  
  observeEvent(input$map_marker_drag, {
    
    rd <- region_data(shapefile = shapefile,
                      markers = data.frame(lat = input$map_marker_drag$lat, lon = input$map_marker_drag$lon))
    
    if(nrow(rd) == 0){
      showNotification("Error: no data for this location - moving point to previous location!", id = "region_error")
    } else {
      current_markers$lat <- input$map_marker_drag$lat
      current_markers$lon <- input$map_marker_drag$lon
    }
    
    # update map after check that the mark is within the defined area
    google_map_update(map_id = "map") %>%
      clear_markers() %>%
      add_markers(data = data.frame(lat = current_markers$lat, lon = current_markers$lon),
                  draggable = TRUE,
                  update_map_view = FALSE)
    
  })
  
  observeEvent(input$map_polygon_click, {
    
    # update marker location on click
    google_map_update(map_id = "map") %>%
      clear_markers() %>%
      add_markers(data = data.frame(lat = input$map_polygon_click$lat, lon = input$map_polygon_click$lon),
                  draggable = TRUE,
                  update_map_view = FALSE)
    
    current_markers$lat <- input$map_polygon_click$lat
    current_markers$lon <- input$map_polygon_click$lon
  }) 
  
  
  output$text <- renderText({
    
    paste0("Current marker latitide: ", current_markers$lat, " <br> ",
           "Current marker longitude: ", current_markers$lon, " <br> ",
           if_else(!is.na(region_data(shapefile = shapefile, markers = current_markers)$region), "The marker is in an agricultural region of California.", "The marker is NOT in an agricultural region of California."))
    })
  
}

shinyApp(ui, server)