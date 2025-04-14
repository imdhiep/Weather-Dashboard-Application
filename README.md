# Weather Dashboard Application

This repository contains an R Shiny application that provides an interactive weather dashboard interface. The application allows users to view and analyze weather data for different cities, with a default focus on Hanoi, Vietnam.

## Features

- Real-time weather data visualization
- Interactive map interface using Leaflet
- Dynamic weather charts and graphs using Plotly
- City-based weather search functionality
- Responsive and modern UI with custom styling
- Data caching for improved performance
- Error handling and fallback mechanisms

## Project Structure

- `UI.R` - Contains the user interface components and layout of the dashboard
  - Custom CSS styling for modern look and feel
  - Responsive dashboard layout using shinydashboard
  - Interactive map and chart components
- `Server.R` - Contains the server-side logic and data processing
  - OpenWeatherMap API integration
  - Data caching implementation
  - Error handling and data processing
- `rsconnect/` - Directory containing deployment configuration
- `.devkit/` - Development toolkit configuration
- `.vscode/` - VS Code editor configuration

## Prerequisites

To run this application, you need:

- R (version 4.0.0 or higher)
- RStudio (recommended)
- Required R packages:
  - shiny
  - shinydashboard
  - leaflet
  - plotly
  - ggplot2
  - httr
  - jsonlite
  - memoise
  - cachem

## Installation

1. Clone this repository
2. Open RStudio
3. Install required packages:
   ```R
   install.packages(c("shiny", "shinydashboard", "leaflet", "plotly", 
                     "ggplot2", "httr", "jsonlite", "memoise", "cachem"))
   ```
4. Open either `UI.R` or `Server.R` in RStudio

## Configuration

The application uses the OpenWeatherMap API. The API key is configured in the `Server.R` file. If you need to use your own API key:

1. Sign up for an API key at [OpenWeatherMap](https://openweathermap.org/api)
2. Replace the `API_KEY` value in the `CONSTANTS` list in `Server.R`

## Running the Application

You can run the application in RStudio by:
1. Opening either `UI.R` or `Server.R`
2. Clicking the "Run App" button, or
3. Running the following command in the R console:
   ```R
   shiny::runApp()
   ```

The application will start with Hanoi as the default city. You can search for other cities using the search interface.

## Deployment

The application can be deployed using RStudio Connect. The `rsconnect` directory contains the necessary configuration for deployment.

To deploy:
1. Ensure you have RStudio Connect access
2. Use the "Publish" button in RStudio
3. Select your RStudio Connect server
4. Configure the deployment settings
5. Deploy the application

## Error Handling

The application includes comprehensive error handling:
- API connection errors
- Invalid city names
- Data processing errors
- Fallback to default values when errors occur

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request


