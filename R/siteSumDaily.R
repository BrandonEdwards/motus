#' Summarize daily detections of all tags by site
#'
#' Creates a summary of the first and last daily detection at a site, the length of time between first and last detection,
#' the number of tags, and the total number of detections at a site for each day. Same as siteSum, but daily by site.
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for motusTagID, sig, recvDeployName, ts
#' @param units units to display time difference, defaults to "hours", options include "secs", "mins", "hours", "days", "weeks"
#'
#' @return a data.frame with these columns:
#' \itemize{
#' \item recvDeployName: site name of deployment
#' \item date: date that is being summarised
#' \item first_ts: time of first detection on specified "date" at "recvDeployName"
#' \item last_ts: time of last detection on specified "date" at "recvDeployName"
#' \item tot_ts: total amount of time between first and last detection at "recvDeployName" on "date, output in specified unit (defaults to "hours")
#' \item num.tags: total number of unique tags detected at "recvDeployName", on "date"
#' \item num.det: total number of detections at "recvDeployName", on "date"
#' }
#'
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' You can use either a selected tbl from .motus eg. "alltags", or a data.frame, instructions to convert a .motus file to all formats are below.
#' sql.motus <- tagme(176, new = TRUE, update = TRUE) # download and access data from project 176 in sql format
#' tbl.alltags <- tbl(sql.motus, "alltags") # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#' df.alltags <- tbl.alltags %>% collect %>% as.data.frame() ## convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' 
#' Create site summaries for all sites within detection data with time in minutes using tbl file tbl.alltags
#' daily_site_summary <- siteSumDaily(tbl.alltags, units = "mins")
#' 
#' Create site summaries for only select sites with time in minutes using tbl file tbl.alltags
#' daily_site_summary <- siteSumDaily(filter(tbl.alltags, recvDeployName %in% c("Niapiskau", "Netitishi", "Old Cut", "Washkaugou")), units = "mins")
#'
#' Create site summaries for only a select species, Red Knot, with default time in hours using data.frame df.alltags
#' daily_site_summary <- siteSumDaily(filter(df.alltags, speciesEN == "Red Knot"))

siteSumDaily <- function(data, units = "hours"){
  data <- select(data, motusTagID, sig, recvDeployName, recvDeployLat, 
                 recvDeployLon, gpsLat, gpsLon, ts) %>% distinct %>% collect %>% as.data.frame
  data <- mutate(data,
                 recvLat = if_else((is.na(gpsLat)|gpsLat == 0|gpsLat ==999),
                                   recvDeployLat,
                                   gpsLat),
                 recvLon = if_else((is.na(gpsLon)|gpsLon == 0|gpsLon == 999),
                                   recvDeployLon,
                                   gpsLon),
                 recvDeployName = paste(recvDeployName, 
                                        round(recvLat, digits = 1), sep = "\n" ),
                 recvDeployName = paste(recvDeployName,
                                        round(recvLon, digits = 1), sep = ", "),
                 ts = lubridate::as_datetime(ts, tz = "UTC"),
                 date = as.Date(ts))
  #data$date <- as.Date(data$ts)
  grouped <- dplyr::group_by(data, recvDeployName, date)
  site_sum <- dplyr::summarise(grouped,
                        first_ts=min(ts),
                        last_ts=max(ts),
                        tot_ts = difftime(max(ts), min(ts), units = units),
                        num_tags = length(unique(motusTagID)),
                        num_det = length(ts))
  site_sum <- as.data.frame(site_sum)
  return(site_sum)
}
