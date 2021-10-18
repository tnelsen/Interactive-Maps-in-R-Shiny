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

First add a polygon data to the map and set the coloring of the polygon. This polygon has two type of `region`. There is a region `ag` where agricultural production has been recorded as having taken place in California and the area outside of that region that has `NA` values for its `region`.

```r
library(dplyr)

shapefile <- sf::st_read("data/ca_ag_regions.shp")

shapefile <- sf::st_as_sf(shapefile)  %>%
  mutate(fill_color = if_else(!is.na(region), "#1C00ff00", "#A9A9A9"))

ui <- fluidPage(
  google_mapOutput(outputId = "map")
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
                   update_map_view = FALSE)
  })
```

In addition, add point data onto the map.

```r
library(dplyr)

shapefile <- sf::st_read("data/ca_ag_regions.shp")

shapefile <- sf::st_as_sf(shapefile)  %>%
  mutate(fill_color = if_else(!is.na(region), "#1C00ff00", "#A9A9A9"))

ui <- fluidPage(
  google_mapOutput(outputId = "map")
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
```

To make a map fully interactive user inputs should be collected and users given feedback on their inputs.

## Collect and use user inputs

Interactive map creators should think about a typical user's behavior and the instructions that might be needed to facilitate user inputs. What actions will the user be allowed to do?

* can the user drag the marker?
* can the user click on the map?

In more complicated applications, 
* is the application going to use the users geolocation?
* how is the the application going to respond to a search function?

Using the googleway package, observing the inputs of the map (dragging markers, clicking on map) can give the creator a lot of information. 

```r
  observeEvent(input$map_marker_drag, {
    print(input$map_marker_drag)
  })

observeEvent(input$map_polygon_click, {
  print(input$map_polygon_click$lat)
  print(input$map_polygon_click$lon)
}) 

```

## Give feedback to user

In order to give feedback to the user, a place in the ui function must be created to place the outputs. 

```r
ui <- fluidPage(
  google_mapOutput(outputId = "map"),
  textOutput("text")
)
```

What piece of information is going to output is defined in the server function.

```r
output$text <- renderText({input$map_polygon_click$lat})
```


## Make the application user friendly

An interactive application and/or map should be as intuitive as possible. 

With an interactive map, a few things should be added:

* explanation/instructions for the user
* limits to what the user can/cannot change
+ consistent behavior
+ errors if a user is outside of the bounds of receiving outputs
* easy to see and understand outputs 

### Use a reactive value to update the map

To allow several inputs to change the same outputs and to be used in more complex processes to access information outside of the map (such as soil and weather data from a database) values should be assigned to a reactive value. 

```r
current_markers <- reactiveValues(
    lat=38.533867, lon=-121.771598)
```

The same `observeEvent` functions can be used to update a reactive value.

```r
  observeEvent(input$map_marker_drag, {
    current_markers$lat <- input$map_marker_drag$lat
    current_markers$lon <- input$map_marker_drag$lon
  })
  
  observeEvent(input$map_polygon_click, {
    
    google_map_update(map_id = "map") %>%
      clear_markers() %>%
      add_markers(data = data.frame(lat = input$map_polygon_click$lat, lon = input$map_polygon_click$lon),
                  draggable = TRUE,
                  update_map_view = FALSE)
    
    current_markers$lat <- input$map_polygon_click$lat
    current_markers$lon <- input$map_polygon_click$lon
  })  
```

### Limit what the user can/cannot change

Limit the user to dragging the marker to locations in California.

#### Define a function

For this, it is easiest to define a function since we will want to use it multiple times throughout the application. 

```r
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
```

### Return an error

The function returns the information from the shape data. It can be used to determine if the marker is within the defined area. Then an error can be shown and the map updated accordingly using `google_map_update`.  

```r

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

```

## Make sure behavior is consistant and intuative

To update the marker location on user click as well as drag, use `google_map_update` when observing a map_polygon_click. 

```r
  observeEvent(input$map_polygon_click, {
    google_map_update(map_id = "map") %>%
      clear_markers() %>%
      add_markers(data = data.frame(lat = input$map_polygon_click$lat, lon = input$map_polygon_click$lon),
                  draggable = TRUE,
                  update_map_view = FALSE)
  }) 
```



## Output the information for the user as text

Note that a desination in the ui function will have to be made as well (see below).

```
  output$text <- renderText({
    
    paste0("Current marker latitide: ", current_markers$lat, " <br> ",
           "Current marker longitude: ", current_markers$lon, " <br> ",
           if_else(!is.na(region_data(shapefile = shapefile, markers = current_markers)$region), "The marker is in an agricultural region of California.", "The marker is NOT in an agricultural region of California."))
    })
```

## Make the layout user friendly

Using a something like `shinydashboard` can help with layout. 

Add an explanation/instructions for the user, a title to show up in the browser tab, and a place for the outputs in the ui function.

```r

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
```

## Resources 

https://cran.r-project.org/web/packages/googleway/vignettes/googleway-vignette.html


## Next steps

Now you are ready to move on to [Create interactive shiny maps with leaflet](03-leaflet-shiny-maps.md)
