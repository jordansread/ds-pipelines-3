do_state_tasks <- function(remakefile, oldest_active_sites) {

  # Define task table rows
  tasks <- oldest_active_sites$state_cd

  # Define task table columns
  download_step <- create_task_step(
    step_name = 'download',
    target_name = function(task_name, step_name, ...) {
      sprintf('%s_data', task_name)
    },
    command = function(task_name, ...){
      sprintf("get_site_data(oldest_active_sites, state = I('%s'), parameter = parameter)", task_name)
    }
  )

  task_plan <- create_task_plan(
    task_names = tasks,
    task_steps = list(download_step),
    add_complete = FALSE)

  # Create the task remakefile
  create_task_makefile(
    task_plan = task_plan,
    makefile = remakefile,
    packages = c('dataRetrieval','dplyr'),
    sources = '1_fetch/src/get_site_data.R',
    include = 'remake.yml',
    tickquote_combinee_objects = FALSE,
    finalize_funs = c())

  scmake(tools::file_path_sans_ext(remakefile), remake_file=remakefile)
  return()
}
