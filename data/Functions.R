# Create DarwinCore inputs from summarised dataset files
imos_DC <- function(input_path, output_path, type) {
  require(tidyverse)
  date_processing <- format(Sys.time(), "%Y%m%d")

    options(dplyr.summarise.inform = FALSE)
  #----------------#
  # Metadata files #
  #----------------#
  # Measurements
  if (type == "Animal measurements") { 
    df.meta <- read.csv(paste0(input_path, "/transmitter_metadata.csv"))
    df.meta$transmitter_deployment_datetime[nchar(df.meta$transmitter_deployment_datetime) < 12] <- paste(df.meta$transmitter_deployment_datetime[nchar(df.meta$transmitter_deployment_datetime) < 12], "00:00:00")
    df.meta$transmitter_deployment_datetime <- as.POSIXct(df.meta$transmitter_deployment_datetime,
      format = "%Y-%m-%d %H:%M:%S", tz = "UTC")    
    df.meta <- df.meta %>%
      mutate(measurementDeterminedBy = stringr::str_replace_all(tag_deployment_project_name, pattern = " ", replacement = ""),
             measurementDeterminedDate = as.Date(as.POSIXct(transmitter_deployment_datetime,
                                                            format = "%Y-%m-%d %H:%M:%S", tz = "UTC"), tz = "UTC"),
             measurementRemarks = NA,
             measurementType = stringr::str_split_fixed(measurement, pattern = " = ", n = 6)[,1],
             measurementTypeID = measurementType,
             measurementUnit = stringr::str_split_fixed(stringr::str_split_fixed(measurement, pattern = " = ", n = 6)[,2], pattern = " ", n = 2)[,2],
             measurementUnitID = measurementUnit,
             measurementValue = stringr::str_split_fixed(stringr::str_split_fixed(measurement, pattern = " = ", n = 6)[,2], pattern = " ", n = 2)[,1],    
             organismID = animal_id,
             occurrenceID = stringr::str_replace_all(paste0(
              paste("imos:atf-acoustic", 
                tag_deployment_project_name, 
                animal_id, sep = ":"),
              "_", as.Date(transmitter_deployment_datetime),
              "T",
              format(transmitter_deployment_datetime, "%H:%M:%S"), 
              "Z-release"),
        pattern = " ", replacement = ""),
             eventID = occurrenceID

      )
    df.meta$measurementUnit[df.meta$measurementUnit == "cm"] <- "CENTIMETRE"
    df.meta$measurementUnit[df.meta$measurementUnit == "mm"] <- "MILLIMETRE"
    df.meta$measurementUnit[df.meta$measurementUnit == "m"] <- "METRE"
    df.meta$measurementType <- stringr::str_split_fixed(df.meta$measurementType, pattern = " ", n = 4)[,1]
    df.meta$measurementTypeID <- df.meta$measurementType
    df.meta <- df.meta[,13:23]
    df.meta$measurementUnit[df.meta$measurementUnit == ""] <- NA
    df.meta$measurementUnitID[df.meta$measurementUnitID == ""] <- NA
    df.meta$measurementValue[df.meta$measurementValue == ""] <- NA
    write.csv(df.meta, paste0(output_path, "/IMOS_ATF-ACOUSTIC_animal_measurements_", date_processing, ".csv"), row.names = FALSE)  
  }  
  # Animal releases
  if (type == "Animal releases") {
    df.meta <- read.csv(paste0(input_path, "/transmitter_metadata.csv"))
    df.meta$transmitter_deployment_datetime[nchar(df.meta$transmitter_deployment_datetime) < 12] <- paste(df.meta$transmitter_deployment_datetime[nchar(df.meta$transmitter_deployment_datetime) < 12], "00:00:00")
    df.meta$transmitter_deployment_datetime <- as.POSIXct(df.meta$transmitter_deployment_datetime,
      format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
    df.meta <- df.meta %>%
      mutate(tagID = stringr::str_replace_all(paste("imos:atf-acoustic", tag_deployment_project_name, animal_id, sep = ":"),
                        pattern = " ", replacement = ""),
             organismID = animal_id,
             eventID = stringr::str_replace_all(paste0(
              paste("imos:atf-acoustic", 
                tag_deployment_project_name, 
                animal_id, sep = ":"),
              "_", as.Date(transmitter_deployment_datetime),
              "T",
              format(transmitter_deployment_datetime, "%H:%M:%S"), 
              "Z-release"),
        pattern = " ", replacement = ""),
             occurrenceID = eventID,
             eventDate = paste0(substr(transmitter_deployment_datetime, 1, 10),
                                "T", substr(transmitter_deployment_datetime, 12, 19), "Z"),
             decimalLatitude = transmitter_deployment_latitude,
             decimalLongitude = transmitter_deployment_longitude,
             geodeticDatum = "EPSG:4326",
             locationID = transmitter_deployment_locality,
             maximumDepthInMeters = NA,
             minimumDepthInMeters = NA,
             footprintWKT = paste0("POINT(", decimalLongitude, " ", decimalLatitude,")"),
             modified = eventDate,
             basisOfRecord = "HumanObservation",
             scientificName = species_scientific_name,
             scientificNameID = WORMS_species_aphia_id,
             vernacularName = species_common_name,
             samplingProtocol = NA,
             kingdom = "Animalia",
             taxonRank = "Species",
             sex = animal_sex,
             coordinateUncertaintyInMeters = NA
      )
    df.meta <- df.meta[,13:34]
    write.csv(df.meta, paste0(output_path, "/IMOS_ATF-ACOUSTIC_animal_releases_", date_processing, ".csv"), row.names = FALSE)
  }
  # Receiver deployments
  if (type == "Receiver deployments") {
    df.meta <- read.csv(paste0(input_path, "/receiver_metadata.csv"))
    df.meta <- df.meta %>%
      mutate(eventID = str_replace_all(paste0("imos:atf-acoustic:", receiver_project_name, ":", receiver_name, "_", receiver_deployment_id), pattern = " ", replacement = ""),
             eventDate = paste(paste0(substr(receiver_deployment_datetime, 1, 10),
                                      "T", substr(receiver_deployment_datetime, 12, 19), "Z"),
                               paste0(substr(receiver_recovery_datetime, 1, 10),
                                      "T", substr(receiver_recovery_datetime, 12, 19), "Z"), sep = "/"),
             decimalLatitude = receiver_deployment_latitude,
             decimalLongitude = receiver_deployment_longitude,
             geodeticDatum = "EPSG:4326",
             locationID = station_name,
             footprintWKT = paste0("POINT(", decimalLongitude, " ", decimalLatitude,")"),
             modified = paste0(substr(receiver_recovery_datetime, 1, 10),
                               "T", substr(receiver_recovery_datetime, 12, 19), "Z"))
    df.meta <- df.meta[,c(11,1,5,12:18)]
    write.csv(df.meta, paste0(output_path, "/IMOS_ATF-ACOUSTIC_receiver_deployments_", date_processing, ".csv"), row.names = FALSE) 
  }
  #-----------------#
  # Detection files #
  #-----------------#
  df.meta <- read.csv(paste0(input_path, "/transmitter_metadata.csv"))
  df.met2 <- read.csv(paste0(input_path, "/receiver_metadata.csv"))   
  # Load total dataset
  aux.files <- list.files(input_path)
  aux.files <- aux.files[-which(aux.files %in% c("receiver_metadata.csv", "transmitter_metadata.csv"))]
  df <- NULL
  for (i in 1:length(aux.files)) {
    aux <- read.csv(paste(input_path, aux.files[i], sep = "/"))
    df <- rbind(df, aux)
  }
  # Add metadata info
  df$tag_deployment_project_name <- df.meta$tag_deployment_project_name[match(df$animal_id, df.meta$animal_id)]
  df$receiver_project_name <- df.met2$receiver_project_name[match(df$receiver_name, df.met2$receiver_name)]  
  df$animal_sex <- df.meta$animal_sex[match(df$animal_id, df.meta$animal_id)]
  df$species_scientific_name <- df.meta$species_scientific_name[match(df$animal_id, df.meta$animal_id)]
  df$species_common_name <- df.meta$species_common_name[match(df$animal_id, df.meta$animal_id)]
  df$WORMS_species_aphia_id <- df.meta$WORMS_species_aphia_id[match(df$animal_id, df.meta$animal_id)]
  df$date <- as.Date(df$date, tz = "UTC")
  # Sensor values
  if (type == "Sensor measurements") {
    df.sensor <- df %>%
      mutate(eventID = stringr::str_replace_all(paste0("imos:atf-acoustic:", 
          receiver_project_name, ":", 
          receiver_name, "_", receiver_deployment_id), 
            pattern = " ", replacement = ""),
          organismID = animal_id,
          occurrenceID = stringr::str_replace_all(paste0("imos:atf-acoustic:",
              receiver_project_name, ":",
              receiver_name, "_", receiver_deployment_id, "_",
              animal_id, "_", date),
                pattern = " ", replacement = ""),
             measurementDeterminedDate = paste0(substr(date, 1, 10),
                                                "T", "00:00:00", "Z"),
             measurementType = transmitter_sensor_type,
             measurementTypeID = transmitter_sensor_type,
             measurementUnit = transmitter_sensor_unit,
             measurementUnitID = transmitter_sensor_unit,
             measurementValue = transmitter_sensor_mean_value,
             )
    df.sensor$measurementUnit[df.sensor$measurementUnit == "m"] <- "METRES"
    df.sensor$measurementUnitID[df.sensor$measurementUnitID == "m"] <- "METRES"
    df.sensor$measurementUnit[df.sensor$measurementUnit == "Degrees Celsius"] <- "DEGREES CELSIUS"
    df.sensor$measurementUnitID[df.sensor$measurementUnitID == "Degrees Celsius"] <- "°C"
    df.sensor <- df.sensor[,c(19:27)]
    # Calculate daily means per sensor type
    df.sensor_mean <- df.sensor %>%
      group_by(eventID, organismID, occurrenceID,
        measurementDeterminedDate, measurementType, measurementTypeID,
        measurementUnit, measurementUnitID) %>%
      summarise(val = mean(measurementValue))
    names(df.sensor_mean)[9] <- "measurementValue"
    write.csv(df.sensor_mean, paste0(output_path, "/IMOS_ATF-ACOUSTIC_sensor_measurements_", date_processing, ".csv"), row.names = FALSE)  
  }
  # Detections
  if (type == "Animal detections") {
    df.detec <- df %>%
      mutate(occurrenceID = str_replace_all(paste0("imos:atf-acoustic:", 
              tag_deployment_project_name, ":",
              receiver_name, "_", receiver_deployment_id, "_",
              animal_id, "_", date), pattern = " ", replacement = ""),
             eventID = occurrenceID,             
             parentEventID = str_replace_all(paste0("imos:atf-acoustic:", 
              receiver_project_name, ":", 
              receiver_name, "_",
              receiver_deployment_id), pattern = " ", replacement = ""),
             organismID = animal_id,
             eventDate = date,
             decimalLatitude = receiver_deployment_latitude,
             decimalLongitude = receiver_deployment_longitude,
             geodeticDatum = "EPSG:4326",
             basisOfRecord = "MachineObservation",        
             no_of_detections = nb_detections,
             dataGeneralizations = paste0("subsampled by date: first of ", no_of_detections, " record(s)"),
             scientificName = species_scientific_name,
             scientificNameID = WORMS_species_aphia_id,
             vernacularName = species_common_name,
             samplingProtocol = NA,
             kingdom = "Animalia",
             taxonRank = "Species",
             sex = animal_sex,
             coordinateUncertaintyInMeters = 500, # Assume 500 m ranges
             organismQuantityType = "Number of detections")
    # Average per day
    df.detec_day <- df.detec %>%
      group_by(occurrenceID) %>%
      summarise(organismQuantity = sum(no_of_detections))
    df.detec_day$organismID <- df.detec$organismID[match(df.detec_day$occurrenceID, df.detec$occurrenceID)]
    df.detec_day$eventID <- df.detec$eventID[match(df.detec_day$occurrenceID, df.detec$occurrenceID)]
    df.detec_day$parentEventID <- df.detec$parentEventID[match(df.detec_day$occurrenceID, df.detec$occurrenceID)]
    df.detec_day$organismID <- df.detec$organismID[match(df.detec_day$occurrenceID, df.detec$occurrenceID)]
    df.detec_day$eventDate <- df.detec$eventDate[match(df.detec_day$occurrenceID, df.detec$occurrenceID)]
    df.detec_day$decimalLatitude <- df.detec$decimalLatitude[match(df.detec_day$occurrenceID, df.detec$occurrenceID)]
    df.detec_day$decimalLongitude <- df.detec$decimalLongitude[match(df.detec_day$occurrenceID, df.detec$occurrenceID)]
    df.detec_day$geodeticDatum <- df.detec$geodeticDatum[match(df.detec_day$occurrenceID, df.detec$occurrenceID)]
    df.detec_day$basisOfRecord <- df.detec$basisOfRecord[match(df.detec_day$occurrenceID, df.detec$occurrenceID)]
    df.detec_day$dataGeneralizations <- df.detec$dataGeneralizations[match(df.detec_day$occurrenceID, df.detec$occurrenceID)]
    df.detec_day$scientificName <- df.detec$scientificName[match(df.detec_day$occurrenceID, df.detec$occurrenceID)]
    df.detec_day$scientificNameID <- df.detec$scientificNameID[match(df.detec_day$occurrenceID, df.detec$occurrenceID)]
    df.detec_day$vernacularName <- df.detec$vernacularName[match(df.detec_day$occurrenceID, df.detec$occurrenceID)]
    df.detec_day$samplingProtocol <- NA
    df.detec_day$kingdom <- "Animalia"
    df.detec_day$taxonRank <- "Species"
    df.detec_day$sex <- df.detec$sex[match(df.detec_day$occurrenceID, df.detec$occurrenceID)]
    df.detec_day$coordinateUncertaintyInMeters <- 500
    df.detec_day$organismQuantityType <- "Number of detections"
    df.detec_day <- df.detec_day[,c(1,3:ncol(df.detec_day), 2)]
    df.detec_day$individualCount <- 1
    write.csv(df.detec_day, paste0(output_path, "/IMOS_ATF-ACOUSTIC_animal_detections_", date_processing, ".csv"), row.names = FALSE)  
  }
}

save.image(file = "data/Functions.RData")