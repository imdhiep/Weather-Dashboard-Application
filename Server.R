library(shiny)
library(shinydashboard)
library(httr)
library(jsonlite)
library(plotly)
library(leaflet)
library(memoise)

# thiet lap api va "hanoi" la thanh pho mac dinh
CONSTANTS <- list(
  DEFAULT_CITY = list(lat = 21.003, lon = 105.8612, name = "Hanoi"),
  API_KEY = 'YOUR_API_KET',
  BASE_URL = "http://api.openweathermap.org/data/2.5",
  CACHE_TIMEOUT = 300  
)

# kiem tra call API co loi hay khong
handle_api_error <- function(response) {
  if (http_error(response)) {
    error_msg <- fromJSON(content(response, "text"))$message
    stop(paste("API Error:", error_msg))
  }
}

# luu lai toa do thanh pho
get_coordinates <- memoise(function(city_name) {
  tryCatch({
    if (nchar(trimws(city_name)) == 0) {
      return(CONSTANTS$DEFAULT_CITY[c("lat", "lon")])
    }
    
    url <- paste0(
      CONSTANTS$BASE_URL, 
      "/weather?q=", URLencode(city_name), 
      "&appid=", CONSTANTS$API_KEY
    )
    
    response <- GET(url)
    handle_api_error(response)
    
    data <- fromJSON(content(response, "text"), flatten = TRUE)
    return(c(data$coord$lat, data$coord$lon))
  }, 
  error = function(e) {
    warning(paste("Error fetching coordinates:", e$message))
    return(CONSTANTS$DEFAULT_CITY[c("lat", "lon")])
  })
}, cache = cachem::cache_mem(max_age = CONSTANTS$CACHE_TIMEOUT))

# lay du lieu thoi tiet
get_weather_data <- memoise(function(lat, lon) {
  tryCatch({
    url <- paste0(
      CONSTANTS$BASE_URL,
      "/forecast?lat=", lat,
      "&lon=", lon,
      "&appid=", CONSTANTS$API_KEY
    )
    
    response <- GET(url)
    handle_api_error(response)
    
    data <- fromJSON(content(response, "text"), flatten = TRUE)
    
    # Tạo data frame với dữ liệu thời tiết
    forecast_data <- data.frame(
      time = as.POSIXct(data$list$dt_txt, format="%Y-%m-%d %H:%M:%S", tz="UTC"),
      temp = data$list$main.temp - 273.15,
      feels_like = data$list$main.feels_like - 273.15,
      temp_min = data$list$main.temp_min - 273.15,
      temp_max = data$list$main.temp_max - 273.15,
      pressure = data$list$main.pressure,
      sea_level = data$list$main.sea_level,
      grnd_level = data$list$main.grnd_level,
      humidity = data$list$main.humidity,
      speed = data$list$wind.speed,
      deg = data$list$wind.deg,
      gust = data$list$wind.gust
    )
    
    return(list(
      city = data$city,
      forecast = forecast_data
    ))
  },
  error = function(e) {
    warning(paste("Error fetching weather data:", e$message))
    return(NULL)
  })
}, cache = cachem::cache_mem(max_age = CONSTANTS$CACHE_TIMEOUT))

# logic server
shinyServer(function(input, output, session) {
  # toa do thanh pho mac dinh
  lat_lon <- reactiveValues(
    lat = CONSTANTS$DEFAULT_CITY$lat, 
    lon = CONSTANTS$DEFAULT_CITY$lon
  )
  
  # quan sat thay doi ten thanh pho
  observeEvent(input$city_name, {
    if (!is.null(input$city_name) && nchar(trimws(input$city_name)) > 0) {
      coords <- get_coordinates(input$city_name)
      if (!is.null(coords)) {
        lat_lon$lat <- coords[1]
        lat_lon$lon <- coords[2]
      }
    }
  })
  
  # phan hoi du lieu thoi tiet
  weather_data <- reactive({
    data <- get_weather_data(lat_lon$lat, lat_lon$lon)
    if (is.null(data)) {
      showNotification(
        "Error fetching weather data. Using cached data if available.",
        type = "warning"
      )
    }
    return(data)
  })
  
  # dinh dang du lieu
  format_output <- function(value, unit = "", digits = 1) {
    if (is.numeric(value)) {
      value <- round(value, digits)
    }
    paste(value, unit)
  }
  
  # hien thi du lieu
  output$city1 <- renderText({
    req(weather_data())
    weather_data()$city$name
  })
  
  output$city2 <- renderText({
    req(weather_data())
    weather_data()$city$name
  })
  
  output$datetime <- renderText({
    req(weather_data())
    format(as.Date(weather_data()$forecast$time[1]), "%Y-%m-%d")
  })
  
  output$temperature <- renderText({
    req(weather_data())
    format_output(weather_data()$forecast$temp[1], "°C")
  })
  
  output$feels_like <- renderText({
    req(weather_data())
    format_output(weather_data()$forecast$feels_like[1], "°C")
  })
  
  output$humidity <- renderText({
    req(weather_data())
    format_output(weather_data()$forecast$humidity[1], "%")
  })
  
  output$weather_condition <- renderText({
    req(weather_data())
    weather_data()$forecast$weather_condition[1]
  })
  
  output$visibility <- renderText({
    req(weather_data())
    format_output(weather_data()$forecast$visibility[1] / 1000, "km")
  })
  
  output$wind_speed <- renderText({
    req(weather_data())
    format_output(weather_data()$forecast$speed[1], "km/h")
  })
  
  output$pressure <- renderText({
    req(weather_data())
    format_output(weather_data()$forecast$pressure[1], "hPa")
  })
  
  output$wind_direction <- renderText({
    req(weather_data())
    format_output(weather_data()$forecast$deg[1], "°")
  })
  
  output$wind_gust <- renderText({
    req(weather_data())
    format_output(weather_data()$forecast$gust[1], "km/h")
  })
  
  output$temp_min <- renderText({
    req(weather_data())
    format_output(weather_data()$forecast$temp_min[1], "°C")
  })
  
  output$temp_max <- renderText({
    req(weather_data())
    format_output(weather_data()$forecast$temp_max[1], "°C")
  })
  
  output$sea_level <- renderText({
    req(weather_data())
    format_output(weather_data()$forecast$sea_level[1], "hPa")
  })
  
  output$grnd_level <- renderText({
    req(weather_data())
    format_output(weather_data()$forecast$grnd_level[1], "hPa")
  })
  
  # hien thi ban do
  output$map <- renderLeaflet({
    req(weather_data())
    leaflet() %>%
      addTiles() %>%
      setView(lng = lat_lon$lon, lat = lat_lon$lat, zoom = 10) %>%
      addMarkers(
        lng = lat_lon$lon, 
        lat = lat_lon$lat,
        popup = paste0(
          "<b>", weather_data()$city$name, "</b><br>",
          "Temperature: ", format_output(weather_data()$forecast$temp[1], "°C"), "<br>",
          "Condition: ", weather_data()$forecast$weather_condition[1]
        )
      ) %>%
      addControl(
        html = "<div style='padding: 6px; background-color: white; border-radius: 4px;'><b>Click on map to select location</b></div>",
        position = "topright"
      )
  })
  
  # xu ly su kien click tren ban do
  observeEvent(input$map_click, {
    click <- input$map_click
    if (!is.null(click)) {
      # cap nhat toa do moi
      lat_lon$lat <- click$lat
      lat_lon$lon <- click$lng
      
      # hien thi thong bao
      showNotification(
        paste("New location - Latitude:", round(click$lat, 4), "Longitude:", round(click$lng, 4)),
        type = "message",
        duration = 3
      )

      # cap nhat ban do voi marker moi
      leafletProxy("map") %>%
        clearMarkers() %>%
        setView(lng = click$lng, lat = click$lat, zoom = 10) %>%
        addMarkers(
          lng = click$lng, 
          lat = click$lat,
          popup = paste0(
            "<b>Selected location</b><br>",
            "Latitude: ", round(click$lat, 4), "<br>",
            "Longitude: ", round(click$lng, 4)
          )
        )
    }
  })
  
  # hien thi bieu do thoi tiet
  output$weatherPlot <- renderPlotly({
    req(weather_data(), input$feature)
    
    # ten cac thuoc tinh
    feature_names <- c(
      "temp" = "Temperature (°C)",
      "feels_like" = "Feels Like (°C)",
      "temp_min" = "Minimum Temperature (°C)",
      "temp_max" = "Maximum Temperature (°C)",
      "pressure" = "Pressure (hPa)",
      "sea_level" = "Sea Level (hPa)",
      "grnd_level" = "Ground Level (hPa)",
      "humidity" = "Humidity (%)",
      "speed" = "Wind Speed (km/h)",
      "deg" = "Wind Direction (°)",
      "gust" = "Wind Gust (km/h)"
    )
    
    y_label <- feature_names[input$feature]
    if (is.na(y_label)) y_label <- input$feature
    
    plot_data <- weather_data()$forecast
    
    p <- plot_ly(plot_data, x = ~time) %>%
      add_lines(y = as.formula(paste0("~", input$feature)), 
                name = y_label,
                line = list(color = '#3498db', width = 2)) %>%
      add_markers(y = as.formula(paste0("~", input$feature)),
                 name = y_label,
                 marker = list(color = '#2c3e50', size = 6)) %>%
      layout(
        title = paste("Weather Forecast -", y_label),
        xaxis = list(title = "Time", tickangle = -45),
        yaxis = list(title = y_label),
        hovermode = "x unified",
        showlegend = FALSE
      )
    
    return(p)
  })
})
