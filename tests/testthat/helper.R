is_exported <- function(fn) {
  tryCatch( {
    fn
    TRUE
  }, error=function(e) FALSE
  )
}

s1ocn_the$get_attributes_list()
