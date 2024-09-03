is_exported <- function(fn) {
  tryCatch( {
    fn
    TRUE
  }, error=function(e) FALSE
  )
}
