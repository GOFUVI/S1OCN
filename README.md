S1OCN: Sentinel‑1 Ocean (OCN) Products Package
==============================================

Overview
--------

**S1OCN** is an R package for browsing, downloading, and extracting data
from **Sentinel‑1 Level‑2 OCN (Ocean) products**. Sentinel‑1 OCN
products are specialized geophysical datasets derived from Sentinel‑1
SAR imagery, tailored for oceanographic
applications[\[1\]](https://documentation.dataspace.copernicus.eu/Data/SentinelMissions/Sentinel1.html#:~:text=The%20Sentinel,oil%20slicks%20or%20marine%20traffic).
Each OCN product may contain several components:

-   **Ocean Wind Field (OWI)** -- gridded estimates of surface wind
    speed and direction (at 10 m height) over the
    ocean[\[2\]](https://creodias.eu/eodata/sentinel-1/sentinel-1-l2-ocn/#:~:text=,The%20RVL%20component%20provides).

-   **Ocean Swell Spectra (OSW)** -- two-dimensional ocean surface swell
    spectra, including estimates of swell wave energy and
    direction[\[2\]](https://creodias.eu/eodata/sentinel-1/sentinel-1-l2-ocn/#:~:text=,The%20RVL%20component%20provides).

-   **Surface Radial Velocity (RVL)** -- estimates of ocean radial
    surface currents derived from Doppler frequency
    shifts[\[3\]](https://creodias.eu/eodata/sentinel-1/sentinel-1-l2-ocn/#:~:text=swell%20spectrum,of%20the%20ASAR%20Doppler%20grid).

The presence of these components depends on the acquisition mode. For
example, OCN products from Stripmap (SM), Interferometric Wide (IW), or
Extra Wide (EW) modes include OWI (wind) data, whereas Wave (WV) mode
OCN products contain OSW but no
OWI[\[4\]](https://creodias.eu/eodata/sentinel-1/sentinel-1-l2-ocn/#:~:text=OCN%20products%20are%20generated%20from,only%20contain%20OSW%20and%20RVL).
This package focuses on **OWI (wind field)** data extraction, which is
available for SM/IW/EW mode products. Using S1OCN, scientists can
**search** the Copernicus Data Space catalog for Sentinel‑1 OCN files
that match specific filters (area, date range, orbit, etc.),
**download** the product files, and **extract** the ocean wind field
data for analysis.

Under the hood, S1OCN leverages the Copernicus Data Space **OData API**
for querying the Sentinel‑1 catalog and product metadata. All searches
are constrained to Sentinel‑1 products of type `"OCN"` (Level‑2 Ocean)
to retrieve relevant files. The package handles constructing the complex
OData query strings for you (including spatial and temporal filters, and
attribute-based filters such as orbit direction or relative orbit
number). The actual Sentinel‑1 data files (in SAFE *.zip* format) are
then downloaded via authenticated requests to the Data Space API. The
OCN wind data, stored in NetCDF format inside the SAFE archive, is
automatically parsed into R structures for easy use.

Sentinel‑1 OCN data provides valuable information on sea surface
conditions (e.g. wind vectors) and is distributed openly and free of
charge as part of the Copernicus program. This package streamlines the
process of obtaining and using this data in R for research and
operational purposes.

Requirements
------------

-   **R version:** Tested with R 4.x (R 4.2 or later is recommended).

-   **Operating System:** Platform-independent (Windows, macOS, Linux),
    though Linux is often used for heavy geospatial processing.

-   **R Packages:** The package will automatically install required
    dependencies. Key imports include:

-   `curl` and `jsonlite` -- for web API requests and JSON parsing (used
    to query the Copernicus OData service and interpret responses).

-   `sf` -- for handling spatial polygons (used if you specify an area
    of interest for search). Requires system libraries for GDAL/PROJ on
    some systems.

-   `RNetCDF` -- for reading NetCDF files (used to parse the OCN wind
    data files). This may require a NetCDF library installed on your
    system.

-   `dplyr`**,** `purrr`**,** `furrr`**,** `future` -- for data
    manipulation and optional parallel processing (e.g., parallel
    downloads or extractions).

-   `lubridate`**,** `stringr`**,** `glue`**,** `rlang`**,** `magrittr`
    -- for date parsing, string handling, and programming utilities.

-   **Copernicus Data Space Account:** To download Sentinel‑1 data, you
    need a free account on the Copernicus Data Space Ecosystem (the
    replacement for the Copernicus SciHub/Open Access Hub). You can
    register on the [Copernicus Data Space
    portal](https://dataspace.copernicus.eu/). Ensure you have your
    **username** and **password** for the API. The S1OCN package uses
    these credentials to obtain an OAuth2 access token and download the
    files. No API key is needed -- just your login credentials.

-   **AWS CLI (optional):** If instead of using R to download data you
    prefer to use the S3 storage interface, you can install the AWS CLI
    and obtain S3 API keys for Copernicus Data Space. This involves
    generating **access keys** and configuring the AWS CLI with the
    Copernicus S3
    endpoint[\[5\]](https://documentation.dataspace.copernicus.eu/APIs/S3.html).
    However, this is not required to use S1OCN, as the package's
    `s1ocn_download_files()` function can download products directly via
    HTTPS using your Copernicus account. (For reference, see the
    Copernicus Data Space **S3 Access** documentation on how to generate
    secrets and configure
    access[\[5\]](https://documentation.dataspace.copernicus.eu/APIs/S3.html).)

**Note on System Dependencies:** If installing from source, make sure
external libraries needed by **sf** (GDAL, GEOS, PROJ) and **RNetCDF**
(NetCDF C library) are available on your system. On Debian/Ubuntu, for
example, you may need to install packages like `libgdal-dev`,
`libgeos-dev`, `libproj-dev`, and `libnetcdf-dev` before installing
S1OCN.

Installation
------------

You can install the development version of **S1OCN** directly from
GitHub using **remotes** or **devtools**:

    # Install remotes if not installed
    install.packages("remotes")

    # Install S1OCN package from GitHub
    remotes::install_github("GOFUVI/S1OCN")

This will download the package source and compile it along with all
dependencies. Alternatively, if you have downloaded a release archive
(for example, from Zenodo or a GitHub release), you can install it using
`R CMD INSTALL` or via `remotes::install_local("path/to/S1OCN.zip")`.

After installation, load the package as usual:

    library(S1OCN)

There is no additional configuration needed beyond having your
Copernicus Data Space credentials ready for downloading data.

Example Workflow
----------------

Below is an example workflow demonstrating how to use S1OCN to search
for Sentinel-1 OCN products, download them, and extract the wind data.
In this scenario, we will:

1.  **Search** for Sentinel-1 OCN files that meet certain criteria
    (e.g., a given area, time range, and orbit parameters).

2.  **Download** the matching OCN product files to a local directory.

3.  **Extract** the wind field data from the downloaded files and
    convert it into R data frames for analysis.

### 1. Searching for Sentinel‑1 OCN products

Use the `s1ocn_list_files()` function to query the catalog for OCN
products. You can filter the search by providing: - a geographic region
(polygon), - a date range (start and/or end date), - and specific
product attributes (like orbit direction, relative orbit number,
polarization, etc.).

**Example:** Search for OCN products in a region over the Western
Mediterranean, from January 2021 onward, on a descending orbit and a
specific relative orbit number, using IW mode (Interferometric Wide
swath):

    library(S1OCN)

    # Define a search polygon (e.g., a rectangular region) as a matrix of coordinates
    med_polygon <- matrix(c(-11, 41,   # lower-left corner (lon, lat)
                            -11, 44,   # upper-left
                             6,  44,   # upper-right
                             6,  41,   # lower-right
                            -11, 41),  # close polygon
                          ncol = 2, byrow = TRUE)

    # Search for Sentinel-1 OCN products with given filters
    files <- s1ocn_list_files(
      max_results     = 50,                # request up to 50 results 
      search_polygon  = med_polygon,       # area of interest (Mediterranean region)
      datetime_start  = "2021-01-01",      # start date (YYYY-MM-DD or any parseable date)
      # datetime_end  = "2021-12-31",     # (optional) end date
      attributes_search = list(
        orbitDirection      = "DESCENDING",  # only descending passes
        relativeOrbitNumber = 125,           # example orbit number of interest
        swathIdentifier     = "IW"           # only IW mode products (ensure OWI is present)
      )
    )

This will query the Copernicus Data Space catalog for Sentinel-1
products where: - **Collection** is Sentinel-1, - **Product type** is
OCN (the function enforces `productType = 'OCN'` internally), - The
acquisition **date** is after Jan 1, 2021 (and before the current date
or an optional end date), - The satellite's **orbit** is descending with
relative orbit 125, - The **mode** (swath identifier) is IW, within the
specified polygon (roughly bounding box given).

The result `files` is a data frame where each row is an OCN product that
matched the query. For example, `files$Name` contains the product Safe
file name (e.g., `"S1B_WV_OCN__2SSV_20211005T..."`), and `files$Id`
contains the unique identifier used for download. Other columns include
metadata like acquisition timestamps, footprint, file size, etc. If no
products match the criteria, the function returns an empty result
(signified by `rlang::zap()`).

You can examine the results or refine the search. For instance,
`nrow(files)` gives the number of products found. It's often helpful to
start with a broad search (e.g., one month or one region) and then
narrow down as needed. Keep in mind that **WV mode products do not
contain wind (OWI)
data**[\[4\]](https://creodias.eu/eodata/sentinel-1/sentinel-1-l2-ocn/#:~:text=OCN%20products%20are%20generated%20from,only%20contain%20OSW%20and%20RVL),
so filtering by `swathIdentifier = "IW"` or `"EW"` (or `"SM"`) is
advisable when you need wind fields.

### 2. Downloading OCN product files

Once you have a set of product metadata (as in the `files` data frame),
you can download the actual data files using `s1ocn_download_files()`.
This function will retrieve each product .ZIP from the Copernicus Data
Space. You need to provide your Copernicus Data Space **username** and
**password** for authentication. It's recommended not to hard-code
credentials in scripts; you can, for example, store them in environment
variables or a separate file. In this example, we'll assume you have
them in the environment (e.g., `CDSE_USER` and `CDSE_PASS`):

    # Specify a directory to save downloads
    dest_dir <- "~/data/s1_ocn_downloads"  # adjust path as needed
    dir.create(dest_dir, showWarnings = FALSE)

    # Set credentials (better to retrieve from env or prompt in a real use case)
    user <- Sys.getenv("CDSE_USER")       # your Copernicus Data Space username
    pass <- Sys.getenv("CDSE_PASS")       # your Copernicus Data Space password

    # Download the listed files (this will download .zip files to dest_dir)
    files <- s1ocn_download_files(
      files    = files,        # data frame from previous step
      dest     = dest_dir,     # destination directory for zip files
      username = user,
      passwd   = pass,
      workers  = 2             # download in parallel with 2 workers
    )

The `s1ocn_download_files()` function will handle authentication: it
contacts the Copernicus Data Space OAuth2 service to get an access token
(using your username/password), then uses that token to download each
product file via HTTPS. Downloads are done in parallel (here 2 at a
time, as specified by `workers=2`, to speed up the process). After
completion, the `files` data frame is returned with an additional column
`downloaded_file_path` giving the local path of each downloaded *.zip*
file.

Each downloaded file is a ZIP archive (in Sentinel SAFE format)
containing measurement data and metadata. For OCN products, the **wind
data** is typically found in a NetCDF file inside the `measurement/`
folder of the archive. We will extract that next.

**Note:** If you have many files (or very large files) to download,
ensure you have a stable internet connection. The function does not
automatically retry failed downloads; if a download fails, you may need
to rerun it for those files. Also, be mindful of disk space -- OCN
product files can be hundreds of MB each.

### 3. Extracting wind data from OCN products

After downloading, you can use the extraction functions to pull out the
wind field (OWI) data from the OCN files. There are two main functions
for this:

-   `s1ocn_extrat_wind_data(filepath)` -- reads a single OCN ZIP file
    and returns the wind data.

-   `s1ocn_extrat_wind_data_from_files(files_df, workers=1)` -- reads
    **multiple** downloaded files (using the `downloaded_file_path` in
    the `files` data frame) and returns a list of wind data objects.
    This can also run in parallel.

We'll use the latter for convenience, since we likely have multiple
files:

    # Extract wind data from all downloaded files
    wind_data_list <- s1ocn_extrat_wind_data_from_files(files, workers = 2)

This will unzip each file in `files$downloaded_file_path` (to a
temporary directory), locate the NetCDF within, and read the variables
pertaining to the wind field. It returns a list (with one element per
file) of **wind data**. Each wind data element is essentially a list of
arrays and metadata, containing: - **vars** -- a list of 2D arrays
(grids) for each wind-related variable, e.g. `owiLon`, `owiLat`,
`owiWindSpeed`, `owiWindDirection`, and others. These represent
longitude, latitude, wind speed (m/s), wind direction (degrees), etc.,
on a grid. - **dims** -- information about the dimensions of these grids
(e.g., number of points, grid spacing). - **global\_attributes** --
metadata attributes from the file (e.g., time of first/last measurement,
mission identifiers, etc.).

For most analyses, you may prefer to convert these wind data into a
regular R data frame (tabular format). The function
`s1ocn_new_S1OCN_wind_data_table()` takes one wind data list and
flattens it into a data frame (one row per wind vector cell), while
preserving some additional info as attributes. There is also a
convenience function `s1ocn_wind_data_list_to_tables()` that takes the
list output (from multiple files) and converts each to a data frame:

    # Convert each wind_data element to a data.frame
    wind_tables <- s1ocn_wind_data_list_to_tables(wind_data_list)

    # Example: inspect the first few rows of the first table
    wind_table1 <- wind_tables[[1]]
    head(wind_table1[, c("owiLon", "owiLat", "owiWindSpeed", "owiWindDirection")])

Each `wind_table` is a data frame where each row corresponds to a single
wind observation cell from the product. Key columns include: -
`owiLon`**,** `owiLat`**:** longitude and latitude of the cell (in
degrees).\
- `owiWindSpeed`**:** retrieved wind speed at that cell (m/s).\
- `owiWindDirection`**:** wind direction (degrees from North).\
- Additional columns like `owiMask`, `owiWindQuality`, etc., which
provide quality flags or ancillary info for each cell.\
- `firstMeasurementTime`**,** `lastMeasurementTime`**:** timestamps
(UTC) for the beginning and end of the data take (these will be constant
for all rows of a given product, added as columns for convenience).

The data frame also carries attributes (accessible via
`attributes(wind_table1)`) that include the full list of variables not
in the columns (for example, if there are other variables like cross-pol
wind information) and the original global attributes. The class of the
object is set to `"S1OCN_wind_data_table"` for easy method extension in
the future.

You can now analyze or visualize the wind data. For example, you might
plot the wind vectors on a map, compute statistics, or combine multiple
scenes. The wind speed and direction values represent 10-m above surface
winds[\[2\]](https://creodias.eu/eodata/sentinel-1/sentinel-1-l2-ocn/#:~:text=,The%20RVL%20component%20provides)
derived from the SAR, which can be compared to buoy data or model
outputs, etc.

Data Sources and References
---------------------------

S1OCN processes data from the **Copernicus Data Space Ecosystem**, which
is the platform hosting Sentinel-1 and other Copernicus mission data
since 2023. Here are useful links and references:

-   **Copernicus Data Space Catalogue (OData API):** The package queries
    the official Copernicus Data Space RESTful OData service for
    Sentinel-1 products. See the [OData API
    documentation](https://documentation.dataspace.copernicus.eu/APIs/OData.html)
    for details on query structure and available filters. The query
    construction in S1OCN ensures only Sentinel-1 OCN products are
    returned, using filters by collection and product type.

-   **Copernicus Data Space S3 API:** An alternative access method to
    Copernicus data is via an S3-compatible bucket. Users can generate
    access keys and use AWS S3 tools to download
    data[\[5\]](https://github.com/GOFUVI/S1OCN/blob/154b12f04a26bcc3f945c202231b5f3ee9d660c5/README.md#L20-L26).
    For more information on S3 access (optional, not used directly by
    this package), refer to the Copernicus Data Space documentation on
    generating secrets and configuring S3
    access[\[5\]](https://github.com/GOFUVI/S1OCN/blob/154b12f04a26bcc3f945c202231b5f3ee9d660c5/README.md#L20-L26).

-   **Sentinel-1 OCN Product Description:** For an overview of
    Sentinel-1 Level-2 Ocean products and their components (OWI, OSW,
    RVL), see the Copernicus knowledge
    base[\[6\]](https://creodias.eu/eodata/sentinel-1/sentinel-1-l2-ocn/#:~:text=There%20is%20only%20one%20standard,derived%20from%20the%20SAR%20data).
    OCN products are generated in all Sentinel-1 modes (SM, IW, EW, WV)
    with varying included
    components[\[4\]](https://creodias.eu/eodata/sentinel-1/sentinel-1-l2-ocn/#:~:text=OCN%20products%20are%20generated%20from,only%20contain%20OSW%20and%20RVL).
    The OWI component extracted by this package provides ocean surface
    wind vectors, which have been validated for use in meteorological
    and oceanographic
    research[\[7\]](https://sentiwiki.copernicus.eu/web/s1-processing#S1Processing-L2AlgorithmsS1-Processing-L2-Algorithms#:~:text=The%20Sentinel,NRCS)[\[8\]](https://sentiwiki.copernicus.eu/web/s1-processing#S1Processing-L2AlgorithmsS1-Processing-L2-Algorithms#:~:text=).

-   **Sentinel-1 Mission Information:** Sentinel-1 is a pair of C-band
    radar satellites (Sentinel-1A and 1B) launched in 2014 and 2016,
    respectively, as part of Copernicus. (Note: Sentinel-1B ceased
    operation in 2022; Sentinel-1A continues to collect
    data[\[9\]](https://documentation.dataspace.copernicus.eu/Data/SentinelMissions/Sentinel1.html#:~:text=The%20end%20of%20mission%20of,been%20declared%20in%20July%202022).)
    The mission provides all-weather, day-and-night radar imaging.
    General mission and data details can be found on the ESA Sentinel-1
    [official
    site](https://sentinels.copernicus.eu/web/sentinel/missions/sentinel-1)
    and the Copernicus
    documentation[\[10\]](https://documentation.dataspace.copernicus.eu/Data/SentinelMissions/Sentinel1.html#:~:text=The%20Sentinel,night%20under%20all%20weather%20conditions)[\[11\]](https://documentation.dataspace.copernicus.eu/Data/SentinelMissions/Sentinel1.html#:~:text=Sentinel%20data%20products%20are%20made,SM%2C%20IW%20and%20EW%20modes).

All Sentinel-1 data used by this package are **open and free** to use
under the Copernicus Open Data license. When using S1OCN and Sentinel-1
OCN data in your research, please credit \"Copernicus Sentinel-1 data\".

We hope S1OCN simplifies your workflow in accessing ocean wind data from
Sentinel-1. For any issues or support using the package, please refer to
the GitHub repository's issue tracker. Happy analyzing!

[\[1\]](https://documentation.dataspace.copernicus.eu/Data/SentinelMissions/Sentinel1.html#:~:text=The%20Sentinel,oil%20slicks%20or%20marine%20traffic)
[\[9\]](https://documentation.dataspace.copernicus.eu/Data/SentinelMissions/Sentinel1.html#:~:text=The%20end%20of%20mission%20of,been%20declared%20in%20July%202022)
[\[10\]](https://documentation.dataspace.copernicus.eu/Data/SentinelMissions/Sentinel1.html#:~:text=The%20Sentinel,night%20under%20all%20weather%20conditions)
[\[11\]](https://documentation.dataspace.copernicus.eu/Data/SentinelMissions/Sentinel1.html#:~:text=Sentinel%20data%20products%20are%20made,SM%2C%20IW%20and%20EW%20modes)
Sentinel-1 -- Documentation

<https://documentation.dataspace.copernicus.eu/Data/SentinelMissions/Sentinel1.html>

[\[2\]](https://creodias.eu/eodata/sentinel-1/sentinel-1-l2-ocn/#:~:text=,The%20RVL%20component%20provides)
[\[3\]](https://creodias.eu/eodata/sentinel-1/sentinel-1-l2-ocn/#:~:text=swell%20spectrum,of%20the%20ASAR%20Doppler%20grid)
[\[4\]](https://creodias.eu/eodata/sentinel-1/sentinel-1-l2-ocn/#:~:text=OCN%20products%20are%20generated%20from,only%20contain%20OSW%20and%20RVL)
[\[6\]](https://creodias.eu/eodata/sentinel-1/sentinel-1-l2-ocn/#:~:text=There%20is%20only%20one%20standard,derived%20from%20the%20SAR%20data)
Sentinel-1 L2 OCN Data on CREODIAS

<https://creodias.eu/eodata/sentinel-1/sentinel-1-l2-ocn/>

[\[5\]](https://github.com/GOFUVI/S1OCN/blob/154b12f04a26bcc3f945c202231b5f3ee9d660c5/README.md#L20-L26)
README.md

<https://github.com/GOFUVI/S1OCN/blob/154b12f04a26bcc3f945c202231b5f3ee9d660c5/README.md>

[\[7\]](https://sentiwiki.copernicus.eu/web/s1-processing#S1Processing-L2AlgorithmsS1-Processing-L2-Algorithms#:~:text=The%20Sentinel,NRCS)
[\[8\]](https://sentiwiki.copernicus.eu/web/s1-processing#S1Processing-L2AlgorithmsS1-Processing-L2-Algorithms#:~:text=)
S1 Processing

<https://sentiwiki.copernicus.eu/web/s1-processing>


## Acknowledgements

This work has been funded by the HF-EOLUS project (TED2021-129551B-I00), financed by MICIU/AEI /10.13039/501100011033 and by the European Union NextGenerationEU/PRTR - BDNS 598843 - Component 17 - Investment I3. Members of the Marine Research Centre (CIM) of the University of Vigo have participated in the development of this repository.

## Disclaimer
This software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, or in connection with the software or the use or other dealings in the software.

---
<p align="center">
  <a href="https://next-generation-eu.europa.eu/">
    <img src="logos/EN_Funded_by_the_European_Union_RGB_POS.png" alt="Funded by the European Union" height="80"/>
  </a>
  <a href="https://planderecuperacion.gob.es/">
    <img src="logos/LOGO%20COLOR.png" alt="Logo Color" height="80"/>
  </a>
  <a href="https://www.aei.gob.es/">
    <img src="logos/logo_aei.png" alt="AEI Logo" height="80"/>
  </a>
  <a href="https://www.ciencia.gob.es/">
    <img src="logos/MCIU_header.svg" alt="MCIU Header" height="80"/>
  </a>
  <a href="https://cim.uvigo.gal">
    <img src="logos/Logotipo_CIM_original.png" alt="CIM logo" height="80"/>
  </a>
  <a href="https://www.iim.csic.es/">
    <img src="logos/IIM.svg" alt="IIM logo" height="80"/>
  </a>
</p>
