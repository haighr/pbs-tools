\name{isThere}
\alias{isThere}
\title{
  Check Whether an Object Physically Exists
}
\description{
  Check to see whether objects physically exist in the specified environment.
  This differs from the function \code{exists} in that the latter sees objects across 
  environments.
}
\usage{
isThere(x, envir=parent.frame())
}
\arguments{
  \item{x}{a variable name (given as a character string).}
  \item{envir}{specify an environment to look in (e.g., \code{sys.frame(sys.nframe())}) }
}
\details{
  This function looks in the specified environment and the object must be physically
  present to elicit a \code{TRUE} response. This contrasts with the base function \code{exists}.
}
\value{
  A Boolean vector.
}
\author{
  Rowan Haigh, Pacific Biological Station, Nanaimo BC
}
\seealso{
  \code{\link{getFile}}
}
\examples{
pbsfun=function() {
  cat("Data object 'swiss' appears to exist in pos=0\n")
  cat(paste("   exists(\"swiss\",envir=sys.frame(0))",
    exists("swiss",envir=sys.frame(0))),"\n")
  cat("But it isn't really there...\n")
  cat(paste("   isThere(\"swiss\",envir=sys.frame(0))",
    isThere("swiss",envir=sys.frame(0))),"\n")
  invisible() }
pbsfun()
}
\keyword{logic}
