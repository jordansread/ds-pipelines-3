do_state_tasks <- function(remakefile, oldest_active_sites, ...) {

  sources <- c(...)

  split_inventory(summary_file = '1_fetch/tmp/state_splits.yml', sites_info = oldest_active_sites)
  # Define task table rows
  tasks <- oldest_active_sites$state_cd

  # Define task table columns
  download_step <- create_task_step(
    step_name = 'download',
    target_name = function(task_name, step_name, ...) {
      sprintf('%s_data', task_name)
    },
    command = function(task_name, ...){
      sprintf("get_site_data('1_fetch/tmp/inventory_%s.tsv', state = I('%s'), parameter = parameter)", task_name, task_name)
    }
  )

  plot_step <- create_task_step(
    step_name = 'plot',
    target_name = function(task_name, step_name, ...) {
      sprintf('3_visualize/out/timeseries_%s.png', task_name)
    },
    command = function(task_name, ...){
      sprintf("plot_site_data(target_name, site_data = %s_data, parameter = parameter)", task_name)
    }
  )

  tally_step <- create_task_step(
    step_name = 'tally',
    target_name = function(task_name, step_name, ...) {
      sprintf('%s_tally', task_name)
    },
    command = function(task_name, ...){
      sprintf("tally_site_obs(site_data = %s_data)", task_name)
    }
  )

  task_plan <- create_task_plan(
    task_names = tasks,
    task_steps = list(download_step, tally_step, plot_step),
    final_steps = c('tally','plot'),
    add_complete = FALSE)

  # Create the task remakefile
  create_task_makefile(
    task_plan = task_plan,
    makefile = remakefile,
    packages = c('dataRetrieval','dplyr', 'ggplot2', 'lubridate'),
    sources = sources,
    include = 'remake.yml',
    final_targets = c('combined_tally', '3_visualize/out/timeseries_plots.yml'),
    finalize_funs = c('combine_tallies', 'summarize_timeseries_plots'),
    tickquote_combinee_objects=TRUE,
    as_promises=FALSE)

  combined_tally <- scmake('combined_tally', remake_file=remakefile)


  timeseries_plots_info <- scmake('3_visualize/out/timeseries_plots.yml', remake_file=remakefile)
  timeseries_plots_info <- yaml::yaml.load_file('3_visualize/out/timeseries_plots.yml') %>%
    tibble::enframe(name = 'filename', value = 'hash') %>%
    mutate(hash = purrr::map_chr(hash, `[[`, 1))


  return(list(obs_tallies=combined_tally, timeseries_plots_info=timeseries_plots_info))
}

combine_tallies <- function(...){
  dots <- list(...)
  tally_dots <- dots[purrr::map_lgl(dots, is_tibble)]
}

split_inventory <- function(summary_file, sites_info) {

  files_out <- c()
  for (state_abr in sites_info$state_cd){
    this_file <- sprintf('1_fetch/tmp/inventory_%s.tsv', state_abr)
    filter(sites_info, state_cd == state_abr) %>%
      readr::write_tsv(path = this_file)
    files_out <- c(files_out, this_file)
  }

  scipiper::sc_indicate(ind_file = summary_file, data_file = sort(files_out))
}

summarize_timeseries_plots <- function(ind_file, ...) {
  # filter to just those arguments that are character strings (because the only
  # step outputs that are characters are the plot filenames)
  dots <- list(...)
  plot_dots <- dots[purrr::map_lgl(dots, is.character)]
  do.call(combine_to_ind, c(list(ind_file), plot_dots))
}
