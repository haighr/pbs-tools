\name{plotBTMW}
\alias{plotBTMW}
\title{
  Plot Bottom and Midwater Trawl Catch
}
\description{
  Plot catch by gear type, primarily to see how much trawl catch is 
  taken by bottom trawl gear vs midwater trawl gear. The code detects
  other gear types (e.g., hook & line) but the user can choose which
  gear types to display.
}
\usage{
plotBTMW(dat, strSpp="417", years=1996:2018, major=3:9, gear, stocks, 
   png=FALSE, pngres=400, PIN=c(8,6), lang=c("e","f"))
}
\arguments{
  \item{dat}{\code{data.frame} -- catch data, usually from a call to the \code{GF_MERGED_CATCH} table in GFFOS.}
  \item{strSpp}{\code{character} -- species Hart code used in GFBioSQL.}
  \item{years}{\code{numeric} -- range of years to plot, usually starting in 1996 (start of the at-sea observer program).}
  \item{major}{\code{numeric} -- major PMFC area codes (3=3C, 4=3D, 5=5A, etc.).}
  \item{gear}{\code{numeric} -- specific gear types to display in the catch series.}
  \item{stocks}{\code{character} -- names of specific stocks (\emph{currently not used}).}
  \item{png}{\code{logical} -- if \code{TRUE}, send the plot results to a \code{'.png'} file.}
  \item{pngres}{\code{numeric} -- resolution for output file (pixesl/inch).}
  \item{PIN}{\code{numeric} -- vector of (width, height) in inches for output file.}
  \item{lang}{\code{character} -- a vector of letters that denote the language for output:
    currently only \code{"e"} (english) and \code{"f"} (french).}
}
\value{
  In addition to a plot, the code returns the results of a \code{crossTab}
  of catch by year and gear, as well as sending the table to a \code{'.csv'} file.
}
\author{
  \href{mailto:rowan.haigh@dfo-mpo.gc.ca}{Rowan Haigh}, Program Head -- Offshore Rockfish\cr
  Pacific Biological Station (PBS), Fisheries & Oceans Canada (DFO), Nanaimo BC\cr
  \emph{locus opus}: Institute of Ocean Sciences (IOS), Sidney BC\cr
  Last modified \code{Rd: 2019-09-30}
}
\seealso{
In package \pkg{PBStools}:\cr
  \code{\link[PBStools]{buildCatch}},
  \code{\link[PBStools]{crossTab}},
  \code{\link[PBStools]{formatCatch}},
  \code{\link[PBStools]{plotCatch}},
  \code{\link[PBStools]{plotRecon}}
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory (show via RShowDoc("KEYWORDS")):
\keyword{hplot}
% \keyword{ ~kwd2 }
% Use only one keyword per line.
% For non-standard keywords, use \concept instead of \keyword:
\concept{M06_Assessment}
\concept{appendix}
\concept{catch}
% Use only one concept per line.