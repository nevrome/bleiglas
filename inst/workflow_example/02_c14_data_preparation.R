library(magrittr)

load("inst/workflow_example/epsg102013.RData")

#### set constants ####

# c14 reference zero
bol <- 1950
# 2sigma range probability threshold
threshold <- (1 - 0.9545) / 2

#### download raw C14 data ####

# radonb <- c14bazAAR::get_RADONB()
# save(radonb, file = "inst/workflow_example/radonb_....RData")
load("inst/workflow_example/radonb_04_02_2019.RData")

#### 14C data cleaning and calibration ####

dates <- radonb %>%
  tibble::as_tibble() %>%
  # remove dates without age
  dplyr::filter(!is.na(c14age) & !is.na(c14std)) %>%
  # remove dates outside of theoretical calibration range
  dplyr::filter(!(c14age < 71) & !(c14age > 46401))

dates_calibrated <- dates %>%
  dplyr::mutate(
    # add list column with the age density distribution for every date
    calage_density_distribution = Bchron::BchronCalibrate(
      ages      = dates$c14age,
      ageSds    = dates$c14std,
      calCurves = rep("intcal13", nrow(dates)),
      eps       = 1e-06
    ) %>%
      # transform BchronCalibrate result to a informative tibble
      # this tibble includes the years, the density per year,
      # the normalized density per year and the information,
      # if this year is in the two_sigma range for the current date
      pbapply::pblapply(
        function(x) {
          a <- x$densities %>% cumsum # cumulated density
          bottom <- x$ageGrid[which(a <= threshold) %>% max]
          top <- x$ageGrid[which(a > 1 - threshold) %>% min]
          center <- x$ageGrid[which.min(abs(a - 0.5))]
          tibble::tibble(
            age = x$ageGrid,
            dens_dist = x$densities,
            norm_dens = x$densities/max(x$densities),
            two_sigma = x$ageGrid >= bottom & x$ageGrid <= top,
            center = x$ageGrid == center
          )
        }
      )
  )

# transform calBP age to calBC
dates_calibrated$calage_density_distribution %<>% lapply(
  function(x) {
    x$age <- -x$age + bol
    return(x)
  }
)

# add median age column
dates_calibrated$calage_center <- vapply(
  dates_calibrated$calage_density_distribution, function(x) { x$age[x$center]}, 0
)

# add temporal resampling column
dates_calibrated$calage_sample <- lapply(
  dates_calibrated$calage_density_distribution, function(x) {
    sample(x$age, 100, replace = TRUE, prob = x$dens_dist)
  }
)

#### filter C14 to relevant time window ####

# add artifical date id
dates_calibrated <- dates_calibrated %>%
  dplyr::mutate(
    date_id = 1:nrow(.)
  )

# filter dates to only include dates in time range of interest
dates_time_selection <- dates_calibrated %>%
  dplyr::mutate(
    in_time_of_interest =
      purrr::map(calage_density_distribution, function(x){
        any(x$age >= -2200 & x$age <= -800 & x$two_sigma)
      })
  ) %>%
  dplyr::filter(
    in_time_of_interest == TRUE
  ) %>%
  dplyr::select(-in_time_of_interest)

#### select dates relevant for the research question ####

dates_research_selection <- dates_time_selection %>%
  # reduce variable selection to necessary information
  dplyr::select(
    -sourcedb, -c13val, -country, -shortref
  ) %>%
  # filter by relevant site types
  dplyr::filter(
    sitetype %in% c(
      "Grave", "Grave (mound)", "Grave (flat) inhumation",
      "Grave (cremation)", "Grave (inhumation)", "Grave (mound) cremation",
      "Grave (mound) inhumation", "Grave (flat) cremation", "Grave (flat)",
      "cemetery"
    )
  ) %>%
  # transform sitetype field to tidy data about burial_type and 
  # burial_construction
  dplyr::mutate(
    burial_type = ifelse(
      grepl("cremation", sitetype), "cremation",
      ifelse(
        grepl("inhumation", sitetype), "inhumation",
        "unknown"
      )
    ),
    burial_construction = ifelse(
      grepl("mound", sitetype), "mound",
      ifelse(
        grepl("flat", sitetype), "flat",
        "unknown"
      )
    )
  ) %>%
  # reduce variable selection to necessary information
  dplyr::select(
    -sitetype
  )

#### remove dates without coordinates ####

dates_coordinates <- dates_research_selection %>% dplyr::filter(
  !is.na(lat) & !is.na(lon)
)

#### crop date selection to research area ####

load("inst/workflow_example/research_area.RData")

# transform data to sf and the correct CRS
dates_sf <- dates_coordinates %>% sf::st_as_sf(coords = c("lon", "lat"))
sf::st_crs(dates_sf) <- 4326
dates_sf %<>% sf::st_transform(epsg102013)

# get dates within research area
dates_research_area <- sf::st_intersection(dates_sf, research_area) %>%
  sf::st_set_geometry(NULL) %>%
  dplyr::select(-id)

# add lon and lat columns again
dates_research_area %<>%
  dplyr::left_join(
    dates_coordinates[, c("date_id", "lat", "lon")], by = "date_id"
  )

#### remove labnr duplicates ####

# identify dates without correct labnr
ids_incomplete_labnrs <- dates_research_area$date_id[
  grepl('n/a', dates_research_area$labnr)
]

# remove labnr duplicates, except for those with incorrect labnrs
duplicates_removed_dates_research_area_ids <- dates_research_area %>%
  dplyr::select(-calage_sample) %>%
  dplyr::filter(
    !(date_id %in% ids_incomplete_labnrs)
  ) %>%
  dplyr::select(-calage_density_distribution) %>%
  c14bazAAR::as.c14_date_list() %>%
  c14bazAAR::remove_duplicates() %$%
  date_id

# merge removed selection with incorrect labnr selection
dates_labnr_dedupe <- dates_research_area %>%
  dplyr::filter(
    date_id %in% c(
      duplicates_removed_dates_research_area_ids, ids_incomplete_labnrs
    )
  )

#### add transformed coordinate information ####

dates_transformed_coords <- dates_labnr_dedupe %>% 
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = F) %>% 
  sf::st_transform(epsg102013) %>%
  dplyr::mutate(
    x = sf::st_coordinates(.)[,1],
    y = sf::st_coordinates(.)[,2]
  ) %>%
  tibble::as_tibble()

#### store final dataset reduced to the relevant variables ####

dates_prepared <- dates_transformed_coords %>%
  dplyr::select(burial_type, burial_construction, x, y, calage_center, calage_sample)

save(dates_prepared, file = "inst/workflow_example/dates_prepared.RData")
