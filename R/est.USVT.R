#' Estimate graphons based via Universal Singular Value Thresholding
#'
#' \code{est.USVT} is a generic matrix estimation method first
#' proposed for the case where a noisy realization of the matrix is given.
#' Universal Singular Value Thresholding (USVT), as its name suggests,
#' utilizes singular value decomposition of observations in addition to
#' thresholding over singular values achieved from the decomposition.
#'
#' @examples
#' ## generate a graphon of type No.1 with 3 clusters
#' W = gmodel.preset(3,id=1)
#'
#' ## create a probability matrix for 100 nodes
#' graphW = gmodel.block(W,n=100)
#' P = graphW$P
#'
#' ## draw 5 observations from a given probability matrix
#' A = gmodel.P(P,rep=5,symmetric.out=TRUE)
#'
#' ## run USVT algorithm with different eta values (0.01,0.1)
#' res2 = est.USVT(A,eta=0.01)
#' res3 = est.USVT(A,eta=0.1)
#'
#' ## compare true probability matrix and estimated ones
#' opar <- par(mfrow=c(1,3), pty="s")
#' image(P,      main="original P matrix")
#' image(res2$P, main="USVT with eta=0.01")
#' image(res3$P, main="USVT with eta = 0.1")
#' par(opar)
#'
#' @param A either \describe{
#' \item{Case 1.}{an \eqn{(n\times n)} binary adjacency matrix, or}
#' \item{Case 2.}{a list containing multiple of \eqn{(n\times n)} binary adjacency matrices.}
#' }
#' @param eta a positive number in \eqn{(0,1)} to control the level of thresholding.
#'
#'
#' @return a named list containing
#' \describe{
#' \item{svs}{a vector of sorted singular values.}
#' \item{thr}{a threshold to disregard singular values.}
#' \item{P}{a matrix of estimated edge probabilities.}
#' }
#'
#' @references
#' \insertRef{Chatterjee2015}{graphon}
#'
#' @export
est.USVT <- function(A,eta=0.01){
  ## (1) Preprocessing
  # 1. check if A is adjacency
  if (is.matrix(A)){ # case 1. a single matrix is given.
    if (!is.binAdj(A)){
      stop("* est.usvt : input A is not a valid binary adjacency matrix.")
    }
    matA = A
  } else {
    cond1 = is.list(A)
    cond2 = (length(unique(unlist(lapply(A,nrow))))==1)
    cond3 = is.binAdjvec(A)

    if (!(cond1&&cond2&&cond3)){
      stop("* est.usvt : input vector A is not proper.")
    }
    sizem = dim(A[[1]])[1]

    matA = matrix(0,sizem,sizem)
    for (i in 1:length(A)){
      matA = matA + A[[i]]
    }
    matA = matA/length(A)
  }

  # 2. eta
  if ((length(eta)>1)||(!is.numeric(eta))||(eta<=0)||(eta>=1)){
    stop("* est.usvt : a parameter eta should be in (0,1).")
  }

  ## (2) main computation
  # 2-1. parameter
  thr = (2+eta)*sqrt(nrow(matA))
  eA = svd(matA);
  idxthr = which(eA$d>=thr)

  # 2-2. recon
  if (length(idxthr)==1){
    P = outer(eA$u[,idxthr],eA$v[,idxthr])*eA$d[idxthr]
  } else {
    P = (eA$u[,idxthr] %*% diag(eA$d[idxthr]) %*% t(eA$v[,idxthr]))
  }

  # 2-3. arrange for values
  P[which(P>=1)] = 1
  P[which(P<=0)] = 0

  ## (3) outputs
  res = vector("list")
  res$svs = sort(eA$d,decreasing=TRUE)
  res$thr = thr
  res$P   = P
  return(res)
}
