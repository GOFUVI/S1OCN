s1ocn_build_attribute_query <- function(attribute_name, attribute_value, value_operator = "eq"){

  value_operator <- rlang::arg_match(value_operator,values = c("eq","le","ge","lt","gt"))

attributes_list <- s1ocn_the$get_attributes_list()

if(!attribute_name %in% attributes_list$Name) rlang::abort(glue::glue("{AttributeName} is not a valid attribute", AttributeName = attribute_name))

  value_type <-attributes_list %>% dplyr::filter(Name == attribute_name) %>% dplyr::pull("ValueType")

  if(rlang::is_character(attribute_value)){
    attribute_value <- glue::glue("%27{AttributeValue}%27", AttributeValue = attribute_value)
  }

  out <- glue::glue("Attributes/OData.CSC.{ValueType}Attribute/any(att:att/Name%20eq%20%27{AttributeName}%27%20and%20att/OData.CSC.{ValueType}Attribute/Value%20{ValueOperator}%20{AttributeValue})",
                    ValueType = value_type,
                    AttributeName = attribute_name,
                    AttributeValue = attribute_value,
                    ValueOperator = value_operator
                    )

  return(out)

}

#' @param max_results The default value is set to 20.The acceptable arguments for this option: Integer <0,1000>.https://documentation.dataspace.copernicus.eu/APIs/OData.html#top-option
#' @param attributes_list swathIdentifier is one of Aquisition modes here https://sentiwiki.copernicus.eu/web/s1-products#S1Products-Level-2ProductsS1-Products-Level-2-Products
s1ocn_list_files <-function(max_results = 20, attributes_search = list()){

  iterate_pages <- max_results > 1000




  url <- glue::glue("https://catalogue.dataspace.copernicus.eu/odata/v1/Products?$top={MaxResults}&$filter=Collection/Name%20eq%20%27SENTINEL-1%27", MaxResults = max_results)

  product_type_query <- s1ocn_build_attribute_query("productType","OCN") #https://sentiwiki.copernicus.eu/web/s1-products#S1Products-Level-2ProductsS1-Products-Level-2-Products

url <- glue::glue("{url}%20and%20{product_type_query}")

attributes_search$productType <- NULL

if(length(attributes_search) > 0){
  url <- purrr::reduce2(attributes_search, names(attributes_search),
                        \(url_so_far,attribute_value, attribute_name){

                          attribute_query <- s1ocn_build_attribute_query(attribute_name, attribute_value, value_operator = "eq")

                          glue::glue("{url_so_far}%20and%20{attribute_query}")

                        }, .init = url)
}

url <- as.character(url)

  con <- curl::curl(url)
  response <- suppressWarnings(readLines(con)) %>% jsonlite::fromJSON()

out <- response$value

while(iterate_pages && !is.null(response$`@odata.nextLink`)){

  url <- as.character(response$`@odata.nextLink`)

  con <- curl::curl(url)
  response <- suppressWarnings(readLines(con)) %>% jsonlite::fromJSON()

  out %<>% dplyr::bind_rows(response$value)

}


return(out)

}
