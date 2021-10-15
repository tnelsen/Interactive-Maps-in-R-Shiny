# Create interactive shiny maps with googleway

The googleway package allows shiny creators to use Google Maps layers and tools. Most users are familiar with the way Google Maps looks and works. To use, creators must sign up for an [API key](https://console.cloud.google.com/google/maps-apis/overview).

When creating any of these applications you will need both the `shiny` package and the `googleway` package libraries.

```r
library(shiny)
library(googleway)
```


## Create a base map

First create a simple application that shows a map.

```r
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
```

### Map options

There are many options when setting up the base map. 

* Where should the map be centered? `location`
* How zoomed in should the map be? `zoom`
* Should the user have zoom control? `zoom_control`
* Should the users be able to search the map? `search_box`
* and more. see `?google_map`

Update the maps with options.

```r
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
```

## Add data to map

First add a polygon data to the map and set the coloring of the polygon. 

```r
library(dplyr)

shapefile <- sf::st_read("data/ca_ag_regions.shp")

shapefile <- sf::st_as_sf(shapefile)  %>%
  mutate(fill_color = if_else(!is.na(region), "#1C00ff00", "#A9A9A9"))

ui <- fluidPage(
  google_mapOutput(outputId = "map")
)

server <- function(input, output){
  
  map_key <-  "AIzaSyBq-aPhxeywj7F6lW0bQWR1dzgwd3omJ5c"
  
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
                   update_map_view = FALSE)
  })
```

## Collect and use user inputs

## Give feedback to user
Feedback based on combined data and user inputs

## Resources 

https://cran.r-project.org/web/packages/googleway/vignettes/googleway-vignette.html


## Next steps

Now you are ready to move on to [Create interactive shiny maps with leaflet](03-leaflet-shiny-maps.md)
