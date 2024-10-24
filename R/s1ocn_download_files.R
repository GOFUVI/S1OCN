#' @export
s1ocn_download_files <- function(files, dest, username, passwd, workers = 1) {


  future::plan("multisession", workers = workers)
  # QUESTION: How is data downloaded? https://documentation.dataspace.copernicus.eu/APIs/OData.html#product-download
  # COMBAK: seguir aqui

  url <- "https://identity.dataspace.copernicus.eu/auth/realms/CDSE/protocol/openid-connect/token"

  h <- curl::new_handle()

  # Establece el método POST
  curl::handle_setopt(h, customrequest = "POST")

  # Configura el encabezado 'Content-Type'
  curl::handle_setheaders(h, "Content-Type" = "application/x-www-form-urlencoded")

  # Datos del formulario
  data <- list(
    grant_type = "password",
    username = username,       # Reemplaza <LOGIN> con tu nombre de usuario
    password = passwd,    # Reemplaza <PASSWORD> con tu contraseña
    client_id = "cdse-public"
  )

  # Función para URL-encodear los parámetros
  encode_parameters <- function(params) {
    sapply(names(params), function(n) paste0(n, "=", curl::curl_escape(params[[n]])))
  }

  # Crea la cadena de datos URL-encoded
  data_string <- paste(encode_parameters(data), collapse = "&")

  # Establece los datos de la solicitud POST
  curl::handle_setopt(h, postfields = data_string)




  result <- curl::curl(url = url, handle = h)

  result <- readLines(result) %>% jsonlite::fromJSON()



  token <- result$access_token

  refresh_token <- result$refresh_token
ids <- files$Id
filenames <- files$Name

  # TODO: usar tokem refresh token y product ids para descargar ficheros en paralelo.


  download_file <- function(id, filename, dest, ACCESS_TOKEN){

    # URL de la solicitud
    url <- glue::glue("https://catalogue.dataspace.copernicus.eu/odata/v1/Products({id})/$value")



    # Ruta del archivo de salida
    output_file <- paste0(file.path(dest,filename),".zip")

    # Crea un nuevo handle de curl
    h <- curl::new_handle()

    # Configura el encabezado 'Authorization'
    curl::handle_setheaders(h, Authorization = paste("Bearer", ACCESS_TOKEN))

    # Configura las opciones para seguir redirecciones y mantener la autenticación
    curl::handle_setopt(h,
                  followlocation = TRUE,     # Sigue redirecciones
                  unrestricted_auth = TRUE   # Mantiene la autenticación en redirecciones
    )

    # Ejecuta la solicitud y descarga el archivo
    curl::curl_download(url, destfile = output_file, handle = h)


  }


  ids %>% furrr::future_walk2(filenames, \(id, filename) download_file(id, filename, dest = dest, ACCESS_TOKEN = token))



  files$downloaded_file_path <- file.path(dest,filenames)

  return(files)

}
