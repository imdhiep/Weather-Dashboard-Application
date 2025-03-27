library(shiny)
library(shinydashboard)
library(leaflet)
library(plotly)
library(ggplot2)

# custom css
custom_css <- "
  /* Dashboard */
  .skin-blue .main-header .logo {
    background-color: #2c3e50;
    font-weight: bold;
    font-size: 20px;
  }
  .skin-blue .main-header .navbar {
    background-color: #2c3e50;
  }
  .skin-blue .left-side, .skin-blue .main-sidebar {
    background-color: #34495e;
  }
  .skin-blue .sidebar-menu > li:hover > a, .skin-blue .sidebar-menu > li.active > a {
    background-color: #2c3e50;
    border-left: 4px solid #3498db;
  }
  
  /* Card */
  .box {
    border-radius: 15px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    transition: transform 0.3s ease;
    margin-bottom: 15px;
  }
  .box:hover {
    transform: translateY(-5px);
  }
  .box-header {
    border-radius: 15px 15px 0 0;
  }
  
  /* User profile */
  .user-profile {
    padding: 20px;
    text-align: center;
    background: linear-gradient(135deg, #2c3e50, #3498db);
    border-radius: 10px;
    margin: 10px;
    color: white;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  }
  .user-profile img {
    border: 3px solid white;
    box-shadow: 0 2px 4px rgba(0,0,0,0.2);
  }
  
  /* Display weather */
  #location, #Time {
    color: #2c3e50;
    text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
  }
  
  /* Button */
  .btn-primary {
    background: linear-gradient(135deg, #3498db, #2980b9);
    border: none;
    border-radius: 25px;
    padding: 10px 20px;
    transition: all 0.3s ease;
  }
  .btn-primary:hover {
    background: linear-gradient(135deg, #2980b9, #3498db);
    transform: scale(1.05);
  }
  
  /* Map container */
  .leaflet-container {
    border-radius: 15px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  }
  
  /* Tab content */
  .tab-content {
    padding: 20px;
    background-color: #f8f9fa;
    border-radius: 15px;
    margin: 15px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  }
  
  /* Select feature */
  .selectize-input {
    border-radius: 25px;
    border: 2px solid #3498db;
    padding: 10px 20px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  }
  .selectize-input.focus {
    border-color: #2c3e50;
    box-shadow: 0 0 0 2px rgba(52, 152, 219, 0.2);
  }
  
  /* Plot */
  .plotly {
    border-radius: 15px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  }

  /* Loading spinner */
  .shiny-notification {
    border-radius: 10px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  }

  /* Tooltip */
  .tooltip {
    font-size: 14px;
  }
"

# User interface
shinyUI(dashboardPage(
  skin = "blue",
  # Header of dashboard
  dashboardHeader(
    title = "HiepDV Dashboard",
    titleWidth = 300,
    dropdownMenu(
      type = "notifications",
      notificationItem(
        text = "Welcome to Weather Forecast!",
        icon = icon("info"),
        status = "info"
      ),
      notificationItem(
        text = "You can search weather by entering city name or clicking directly on the map",
        icon = icon("map-marker-alt"),
        status = "success"
      )
    )
  ),
  # Thanh bên chứa menu
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      # Thông tin người dùng
      div(
        class = "user-profile",
        tags$img(
          src = "https://media.licdn.com/dms/image/v2/D5603AQG5cUGx38fcpw/profile-displayphoto-shrink_400_400/B56ZVaTpPAHQAk-/0/1740976855221?e=1748476800&v=beta&t=MYkRi9n-z4YR-IjweG_gQlvl48ZUa3gtuYzxB-hvdKk",
          width = "80px",
          height = "80px",
          class = "img-circle"
        ),
        div(
          style = "margin-top: 15px;",
          h4("HiepDV (HE181185)", style = "margin: 0; font-weight: bold;"),
          div(
            style = "margin-top: 5px;",
            icon("circle", class = "text-success", style = "font-size: 12px"),
            " Online"
          )
        )
      ),
      # Menu chính
      menuItem(
        "Weather Today", 
        tabName = "weather", 
        icon = icon("cloud"),
        selected = TRUE
      ),
      menuItem(
        "Weather Forecast", 
        tabName = "forecast", 
        icon = icon("chart-line")
      ),
      # Ô nhập tên thành phố
      div(
        style = "padding: 15px;",
        textInput(
          "city_name",
          label = tags$span(
            "Enter city name ",
            icon("info-circle", class = "text-info", 
                 title = "Enter city name in English, e.g.: Hanoi, London, Tokyo")
          ),
          value = "",
          placeholder = "Enter city name...",
          width = "100%"
        )
      )
    )
  ),
  # Phần thân chính của dashboard
  dashboardBody(
    tags$head(
      tags$style(HTML(custom_css)),
      tags$script('
        $(document).ready(function() {
          $("[data-toggle=\'tooltip\']").tooltip();
        });
      ')
    ),
    tabItems(
      # Tab thời tiết hiện tại
      tabItem(
        tabName = "weather",
        div(
          class = 'tab-content',
          fluidRow(
            column(
              width = 12,
              h1(
                "Current Weather",
                style = "font-size: 48px; color: #2c3e50; text-align: center; margin-bottom: 30px; text-shadow: 2px 2px 4px rgba(0,0,0,0.1);"
              )
            )
          ),
          splitLayout(
            cellWidths = c("50%", "50%"),
            div(
              class = "content",
              # Hiển thị tên thành phố
              fluidRow(
                column(
                  width = 12,
                  h2(
                    span(
                      icon("location-crosshairs", lib = "font-awesome", 
                           style = "font-size: 40px; margin-right: 10px; color: #3498db;"),
                      textOutput("city1"),
                      style = "font-size: 40px; font-weight: bold; display: flex; align-items: center;",
                      id = "location"
                    )
                  )
                )
              ),
              # Hiển thị ngày giờ
              fluidRow(
                column(
                  width = 12,
                  h3(
                    span(
                      textOutput("datetime"),
                      style = "font-size: 24px; color: #7f8c8d;",
                      id = "Time"
                    )
                  )
                )
              ),
              # Hiển thị nhiệt độ hiện tại
              fluidRow(
                column(
                  width = 12,
                  div(
                    style = "background: linear-gradient(135deg, #3498db, #2980b9); padding: 15px; border-radius: 15px; color: white; margin-bottom: 20px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);",
                    h2(
                      icon("temperature-three-quarters", lib = "font-awesome", 
                           style = "font-size: 28px; margin-right: 10px;"),
                      span("Current Temperature: ", style = "font-size: 28px;"),
                      span(textOutput("temperature"), 
                           style = "font-size: 36px; font-weight: bold; margin-left: 10px;")
                    )
                  )
                )
              ),
              # Các thông số thời tiết khác
              fluidRow(
                box(
                  width = 4,
                  title = div(
                    style = "display: flex; align-items: center;",
                    icon("thermometer-half", lib = "font-awesome"),
                    "Feels Like"
                  ),
                  status = "danger",
                  solidHeader = TRUE,
                  div(
                    class = "text-center",
                    span(textOutput("feels_like"), 
                         style = "font-size: 24px; font-weight: bold;")
                  )
                ),
                box(
                  width = 4,
                  title = div(
                    style = "display: flex; align-items: center;",
                    icon("tint", lib = "font-awesome"),
                    "Humidity"
                  ),
                  status = "info",
                  solidHeader = TRUE,
                  div(
                    class = "text-center",
                    span(textOutput("humidity"), 
                         style = "font-size: 24px; font-weight: bold;")
                  )
                ),
                box(
                  width = 4,
                  title = div(
                    style = "display: flex; align-items: center;",
                    icon("tachometer-alt", lib = "font-awesome"),
                    "Air Pressure"
                  ),
                  status = "info",
                  solidHeader = TRUE,
                  div(
                    class = "text-center",
                    span(textOutput("pressure"), 
                         style = "font-size: 24px; font-weight: bold;")
                  )
                ),
                box(
                  width = 4,
                  title = div(
                    style = "display: flex; align-items: center;",
                    icon("wind", lib = "font-awesome"),
                    "Wind Speed"
                  ),
                  status = "primary",
                  solidHeader = TRUE,
                  div(
                    class = "text-center",
                    span(textOutput("wind_speed"), 
                         style = "font-size: 24px; font-weight: bold;")
                  )
                ),
                box(
                  width = 4,
                  title = div(
                    style = "display: flex; align-items: center;",
                    icon("compass", lib = "font-awesome"),
                    "Wind Direction"
                  ),
                  status = "warning",
                  solidHeader = TRUE,
                  div(
                    class = "text-center",
                    span(textOutput("wind_direction"), 
                         style = "font-size: 24px; font-weight: bold;")
                  )
                ),
                box(
                  width = 4,
                  title = div(
                    style = "display: flex; align-items: center;",
                    icon("wind", lib = "font-awesome"),
                    "Wind Gust"
                  ),
                  status = "success",
                  solidHeader = TRUE,
                  div(
                    class = "text-center",
                    span(textOutput("wind_gust"), 
                         style = "font-size: 24px; font-weight: bold;")
                  )
                )
              )
            ),
            # Phần bản đồ
            div(
              class = "content",
              box(
                title = "Location Map",
                width = NULL,
                status = "primary",
                solidHeader = TRUE,
                leafletOutput("map", height = "500px")
              )
            )
          )
        )
      ),
      # Tab dự báo thời tiết
      tabItem(
        tabName = "forecast",
        div(
          class = 'tab-content',
          style = "margin: 20px;",
          fluidRow(
            column(
              width = 8,
              div(
                style = "display: flex; align-items: center;",
                h1(
                  "Weather Forecast for ",
                  style = "color: #2c3e50; margin: 0; font-size: 48px;"
                ),
                h1(
                  textOutput("city2"),
                  style = "color: #3498db; margin: 0 0 0 10px; font-size: 48px;"
                )
              )
            )
          ),
          fluidRow(
            column(
              width = 12,
              div(
                class = 'form-group shiny-input-container',
                style = "margin-bottom: 20px;",
                selectizeInput(
                  label = "Select Feature to Display:",
                  inputId = "feature",
                  choices = c(
                    "Temperature (°C)" = "temp",
                    "Feels Like (°C)" = "feels_like",
                    "Minimum Temperature (°C)" = "temp_min",
                    "Maximum Temperature (°C)" = "temp_max",
                    "Pressure (hPa)" = "pressure",
                    "Sea Level (hPa)" = "sea_level",
                    "Ground Level (hPa)" = "grnd_level",
                    "Humidity (%)" = "humidity",
                    "Wind Speed (km/h)" = "speed",
                    "Wind Direction (°)" = "deg",
                    "Wind Gust (km/h)" = "gust"
                  ),
                  selected = "temp",
                  options = list(
                    plugins = list('selectize-plugin-a11y')
                  )
                )
              ),
              div(
                class = 'plotly-container',
                style = "background: white; padding: 20px; border-radius: 15px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);",
                plotlyOutput("weatherPlot", height = "500px")
              )
            )
          )
        )
      )
    )
  )
))
