state_trans <- c(AL='B', AK='A', AZ='D', AR='C', CA='E', CO='F', CT='G',
                 DE='H', DC='y', FL='I', GA='J', HI='K', ID='M', IL='N',
                 IN='O', IA='L', KS='P', KY='Q', LA='R', ME='U', MD='T',
                 MA='S', MI='V', MN='W', MS='Y', MO='X', MT='Z', NE='c',
                 NV='g', NH='d', NJ='e', NM='f', NY='h', NC='a', ND='b',
                 OH='i', OK='j', OR='k', PA='l', RI='m', SC='n', SD='o',
                 TN='p', TX='q', UT='r', VT='t', VA='s', WA='u', WV='w',
                 WI='v', WY='x', US='z')

state_tbl <- setNames(toupper(state.abb), tolower(state.name))

#' Show location of StateFace font
#'
#' Displays the path to the StateFace font. For the font to work
#' in the on-screen plot device for ggplot2, you need to install
#' the font on your system
#' @export
show_stateface <- function() {
  system.file("fonts/", package="ggalt")
}

#' Load stateface font
#'
#' @export
load_stateface <- function() {
  if (!any(grepl("StateFace", extrafont::fonts()))) {
    tmp <- capture.output(suppressWarnings(extrafont::ttf_import(
      system.file("fonts/", package="ggalt"),
      prompt=FALSE, pattern="*.ttf", recursive=FALSE)))
  }
  tmp <- capture.output(suppressWarnings(extrafont::loadfonts(quiet=TRUE)))
}

#' Use ProPublica's StateFace font in ggplot2 plots
#'
#' @inheritParams ggplot2::geom_text
#' @export
geom_stateface <- function(mapping = NULL, data = NULL, stat = "identity",
                           position = "identity", ..., parse = FALSE,
                           nudge_x = 0, nudge_y = 0, check_overlap = FALSE,
                           na.rm = FALSE, show.legend = NA, inherit.aes = TRUE) {

  if (!missing(nudge_x) || !missing(nudge_y)) {
    if (!missing(position)) {
      stop("Specify either `position` or `nudge_x`/`nudge_y`", call. = FALSE)
    }

    position <- position_nudge(nudge_x, nudge_y)
  }

  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomStateface,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      parse = parse,
      check_overlap = check_overlap,
      na.rm = na.rm,
      ...
    )
  )

}

#' @rdname ggalt-ggproto
#' @format NULL
#' @usage NULL
#' @export
GeomStateface <- ggproto("GeomStateface", Geom,
      required_aes = c("x", "y", "label"),

 default_aes = aes(
   colour = "black", size = 3.88, angle = 0, hjust = 0.5,
   vjust = 0.5, alpha = NA, family = "", fontface = 1, lineheight = 1.2
 ),

 draw_panel = function(data, panel_scales, coord, parse = FALSE,
                       na.rm = FALSE, check_overlap = FALSE) {
   lab <- data$label

   if (max(sapply(lab, nchar)) == 2) {
     lab <- unname(state_trans[toupper(lab)])
   } else {
     lab <- unname(state_trans[state_tbl[tolower(lab)]])
   }

   data <- coord$transform(data, panel_scales)
   if (is.character(data$vjust)) {
     data$vjust <- compute_just(data$vjust, data$y)
   }
   if (is.character(data$hjust)) {
     data$hjust <- compute_just(data$hjust, data$x)
   }

   textGrob(
     lab,
     data$x, data$y, default.units = "native",
     hjust = data$hjust, vjust = data$vjust,
     rot = data$angle,
     gp = gpar(
       col = alpha(data$colour, data$alpha),
       fontsize = data$size * .pt,
       fontfamily = "StateFace",
       fontface = data$fontface,
       lineheight = data$lineheight
     ),
     check.overlap = check_overlap
   )
 },

 draw_key = draw_key_text
)

compute_just <- function(just, x) {
  inward <- just == "inward"
  just[inward] <- c("left", "middle", "right")[just_dir(x[inward])]
  outward <- just == "outward"
  just[outward] <- c("right", "middle", "left")[just_dir(x[outward])]

  unname(c(left = 0, center = 0.5, right = 1,
           bottom = 0, middle = 0.5, top = 1)[just])
}

just_dir <- function(x, tol = 0.001) {
  out <- rep(2L, length(x))
  out[x < 0.5 - tol] <- 1L
  out[x > 0.5 + tol] <- 3L
  out
}