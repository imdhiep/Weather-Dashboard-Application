library(shiny)
library(shinydashboard)
library(httr)
library(jsonlite)
library(plotly)
library(leaflet)

# Your OpenWeatherMap API key
api_key <- '1d29e17b428b35c8301430b8b3c78c3d'

# Function to get coordinates (latitude and longitude) based on city name
get_coordinates <- function(city_name, api_key) {
  # URL encode the city name to handle spaces or special characters
  city_name_encoded <- URLencode(city_name)
  
  # Construct the URL with the encoded city name
  url <- paste0("http://api.openweathermap.org/data/2.5/weather?q=", city_name_encoded, "&appid=", api_key)
  
  # Perform the GET request
  response <- GET(url)
  
  # Parse the response JSON
  data <- fromJSON(content(response, "text"), flatten = TRUE)
  
  # Check if the "coord" field exists in the response (i.e., city found)
  if ("coord" %in% names(data)) {
    lat <- data$coord$lat
    lon <- data$coord$lon
    return(c(lat, lon))  # Return coordinates
  } else {
    return(NULL)  # Return NULL if city is not found
  }
}

# Function to fetch weather data based on latitude and longitude
get_weather_data <- function(api_key, lat, lon) {
  url <- paste0("http://api.openweathermap.org/data/2.5/forecast?lat=", lat,
                "&lon=", lon, "&appid=", api_key)
  response <- GET(url)
  data <- fromJSON(content(response, "text"), flatten = TRUE)
  
  city_info <- data$city
  forecast_list <- data$list
  
  forecast_data <- data.frame(
    time = as.POSIXct(forecast_list$dt_txt, format="%Y-%m-%d %H:%M:%S", tz="UTC"),
    temp = forecast_list$main.temp - 273.15,
    feels_like = forecast_list$main.feels_like - 273.15,
    temp_min = forecast_list$main.temp_min - 273.15,
    temp_max = forecast_list$main.temp_max - 273.15,
    pressure = forecast_list$main.pressure,
    sea_level = forecast_list$main.sea_level,
    grnd_level = forecast_list$main.grnd_level,
    humidity = forecast_list$main.humidity,
    speed = forecast_list$wind.speed,
    deg = forecast_list$wind.deg,
    gust = forecast_list$wind.gust,
    weather_condition = forecast_list$weather[[1]]$description,
    visibility = forecast_list$visibility
  )
  
  list(
    city = city_info,
    forecast = forecast_data
  )
}

# Define server logic
shinyServer(function(input, output, session) {
  
  # Default coordinates (Hanoi)
  lat_lon <- reactiveValues(lat = 20.954050, lon = 105.758869)
  
  # Observe the input for city name and fetch coordinates
  observeEvent(input$city_name, {
    # Call the OpenWeatherMap Geocoding API to get coordinates
    coords <- get_coordinates(input$city_name, api_key)
    
    # If valid coordinates are returned, update the lat_lon reactive values
    if (!is.null(coords)) {
      lat_lon$lat <- coords[1]
      lat_lon$lon <- coords[2]
    } else {
      # If city is not found, keep default coordinates (Hanoi)
      lat_lon$lat <- 20.954050
      lat_lon$lon <- 105.758869
    }
  })
  
  # Reactive expression to fetch weather data based on the coordinates
  weather_data <- reactive({
    get_weather_data(api_key, lat_lon$lat, lat_lon$lon)
  })
  
  # Render weather information dynamically
  output$city1 <- renderText({
    paste(weather_data()$city$name)
  })
  
  output$datetime <- renderText({
    format(as.Date(weather_data()$forecast$time[1]), "%Y-%m-%d")
  })
  
  output$temperature <- renderText({
    paste(weather_data()$forecast$temp[1], "°C")
  })
  
  output$feels_like <- renderText({
    paste(weather_data()$forecast$feels_like[1], "°C")
  })
  
  output$humidity <- renderText({
    paste(weather_data()$forecast$humidity[1], "%")
  })
  
  output$weather_condition <- renderText({
    weather_data()$forecast$weather_condition[1]
  })
  
  output$visibility <- renderText({
    paste(weather_data()$forecast$visibility[1] / 1000, "km")
  })
  
  output$wind_speed <- renderText({
    paste(weather_data()$forecast$speed[1], "km/h")
  })
  
  output$pressure <- renderText({
    paste(weather_data()$forecast$pressure[1], "hPa")
  })
  
  # Render map with updated coordinates
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = lat_lon$lon, lat = lat_lon$lat, zoom = 10)
  })
  
  # Plot the weather forecast based on selected feature
  output$weatherPlot <- renderPlotly({
    selected_feature <- weather_data()$forecast[[input$feature]]
    ggplot(weather_data()$forecast, aes(x = time)) +
      geom_line(aes(y = selected_feature), color = 'blue') +
      geom_point(aes(y = selected_feature), color = 'red') +
      labs(y = input$feature, x = "Time") +
      theme_minimal() +
      scale_x_datetime(date_labels = "%Y-%m-%d %H:%M:%S", date_breaks = "12 hour") +
      theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))
  })
})
