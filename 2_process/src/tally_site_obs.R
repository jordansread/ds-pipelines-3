# Compute number of observations per year
tally_site_obs <- function(site_data) {
  site_data %>%
    mutate(Year = lubridate::year(Date)) %>%
    # group by Site and State just to retain those columns, since we're already
    # only looking at just one site worth of data
    group_by(Site, State, Year) %>%
    summarize(NumObs = length(which(!is.na(Value))))
}
