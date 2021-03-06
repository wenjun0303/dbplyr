#' @importFrom dplyr summarise
#' @export
summarise.tbl_lazy <- function(.data, ...) {
  dots <- quos(..., .named = TRUE)
  dots <- partial_eval_dots(dots, vars = op_vars(.data))
  check_summarise_vars(dots)
  add_op_single("summarise", .data, dots = dots)
}

# For each expression, check if it uses any newly created variables
check_summarise_vars <- function(dots) {
  for (i in seq_along(dots)) {
    used_vars <- all_names(get_expr(dots[[i]]))
    cur_vars <- names(dots)[seq_len(i - 1)]

    if (any(used_vars %in% cur_vars)) {
      stop(
        "`", names(dots)[[i]],
        "` refers to a variable created earlier in this summarise().\n",
        "Do you need an extra mutate() step?",
        call. = FALSE
      )
    }
  }
}

#' @export
op_vars.op_summarise <- function(op) {
  c(op_grps(op$x), names(op$dots))
}

#' @export
op_grps.op_summarise <- function(op) {
  grps <- op_grps(op$x)
  if (length(grps) == 1) {
    character()
  } else {
    grps[-length(grps)]
  }
}

#' @export
op_sort.op_summarise <- function(op) NULL

#' @export
sql_build.op_summarise <- function(op, con, ...) {
  select_vars <- translate_sql_(op$dots, con, window = FALSE, context = list(clause = "SELECT"))
  group_vars <- c.sql(ident(op_grps(op$x)), con = con)

  select_query(
    sql_build(op$x, con),
    select = c.sql(group_vars, select_vars, con = con),
    group_by = group_vars
  )
}
