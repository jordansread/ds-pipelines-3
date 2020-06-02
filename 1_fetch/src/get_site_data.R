# download data for each site
get_site_data <- function(sites_info, state, parameter) {
  site_info <- filter(sites_info, state_cd == state)
  message(sprintf('Retrieving data for site %s', site_info$site_no))

  # simulate an unreliable web service or internet connection by causing random failures
  if(runif(1) < 0.5) {
    Sys.sleep(0.1)
    stop('Ugh, the internet data transfer failed! Try again.')
  }

  # actually pull the data
  site_data <- dataRetrieval::readNWISdv(
    siteNumbers=site_info$site_no, parameterCd=parameter) %>%
    dataRetrieval::renameNWISColumns(p00010="Value", p00060="Value", p00300="Value") %>%
    as_tibble() %>%
    rename(Site=site_no, Quality=Value_cd) %>%
    mutate(State=site_info$state_cd, Parameter=c('00060'='Flow', '00010'='Wtemp', '00300'='DO')[parameter]) %>%
    select(-agency_cd) %>%
    select(State, Site, Date, Value, Quality, Parameter)
}
