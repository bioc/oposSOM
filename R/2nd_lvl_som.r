pipeline.2ndLvlSom <- function()
{
  secLvlSom.custom <<- som(t(metadata), xdim=preferences$dim.2ndLvlSom, ydim=preferences$dim.2ndLvlSom)

  if (preferences$dim.2ndLvlSom == 20)
  {
    secLvlSom.20.20 <<- secLvlSom.custom
  } else
  {
    secLvlSom.20.20 <<- som(t(metadata), xdim=20, ydim=20)
  }

  filename <- file.path(paste(files.name, "- Results"), "2nd lvl Metagene Analysis", "2nd lvl SOM.pdf")
  util.info("Writing:", filename)
  pdf(filename, 21/2.54, 21/2.54, useDingbats=FALSE)

  ##### Plot Supersom #####
  par(mar=c(1, 1, 1, 1))
  xl <- c(min(secLvlSom.custom$visual[,"x"])-1.2, max(secLvlSom.custom$visual[,"x"])+1.2)
  yl <- c(min(-secLvlSom.custom$visual[,"y"])-1.2, max(-secLvlSom.custom$visual[,"y"])+1.2)

  plot(secLvlSom.custom$visual[,"x"], -secLvlSom.custom$visual[,"y"], type="n",
       axes=FALSE, xlab="", ylab="", xlim=xl, ylim=yl, xaxs="i", yaxs="i",main="Second level SOM", cex.main=1)

  if (length(unique(group.labels)) > 1)
  {
    legend("topright", as.character(unique(group.labels)), cex=0.5,
           text.col=groupwise.group.colors, bg="white")
  }

  for (j in 1:nrow(secLvlSom.custom$code.sum))
  {

    which.samples <-
      intersect(which(secLvlSom.custom$visual[,"x"] == secLvlSom.custom$code.sum[j,"x"]),
                which(secLvlSom.custom$visual[,"y"] == secLvlSom.custom$code.sum[j,"y"]))

    if (!is.na(which.samples[1]))
    {

      which.samples <- which.samples[1:min(9, length(which.samples))]

      x.seq <- c(0,0.3,0,-0.3,0,-0.3,0.3,-0.3,0.3)[seq_along(which.samples)]
      y.seq <- c(0,0,0.3,0,-0.3,-0.3,-0.3,0.3,0.3)[seq_along(which.samples)]

      points(secLvlSom.custom$visual[which.samples[1], "x"]+x.seq,
             -secLvlSom.custom$visual[which.samples[1], "y"]+y.seq,
             pch=16, col=group.colors[which.samples], cex=1.5)

      points(secLvlSom.custom$visual[which.samples[1], "x"]+x.seq,
             -secLvlSom.custom$visual[which.samples[1], "y"]+y.seq,
             pch=1, col="gray20", cex=1.5, lwd=1)
    }
  }

  box()

  plot(secLvlSom.custom$visual[,"x"], -secLvlSom.custom$visual[,"y"], type="n",
       axes=FALSE, xlab="", ylab="", xlim=xl, ylim=yl, xaxs="i", yaxs="i",main="Second level SOM", cex.main=1)

  if (length(unique(group.labels)) > 1)
  {
    legend("topright", as.character(unique(group.labels)), cex=0.5,
           text.col=groupwise.group.colors, bg="white")
  }

  for (j in 1:nrow(secLvlSom.custom$code.sum))
  {

    which.samples <-
      intersect(which(secLvlSom.custom$visual[,"x"] == secLvlSom.custom$code.sum[j,"x"]),
                which(secLvlSom.custom$visual[,"y"] == secLvlSom.custom$code.sum[j,"y"]))

    if (!is.na(which.samples[1]))
    {

      which.samples <- which.samples[1:min(9, length(which.samples))]

      x.seq <- c(0,0.3,0,-0.3,0,-0.3,0.3,-0.3,0.3)[seq_along(which.samples)]
      y.seq <- c(0,0,0.3,0,-0.3,-0.3,-0.3,0.3,0.3)[seq_along(which.samples)]

      points(secLvlSom.custom$visual[which.samples[1], "x"]+x.seq,
             -secLvlSom.custom$visual[which.samples[1], "y"]+y.seq,
             pch=16, col=group.colors[which.samples], cex=1.5)

      points(secLvlSom.custom$visual[which.samples[1], "x"]+x.seq,
             -secLvlSom.custom$visual[which.samples[1], "y"]+y.seq,
             pch=1, col="gray20", cex=1.5, lwd=1)

      text(secLvlSom.custom$visual[which.samples[1], "x"]+x.seq,
           -secLvlSom.custom$visual[which.samples[1], "y"]+y.seq,
           colnames(indata)[which.samples], col="gray20", cex=0.6)
    }
  }

  box()

  ##### Polygone-2ndSOM #####
  if (length(unique(group.labels)) > 1)
  {
    transparent.group.colors <- sapply(groupwise.group.colors, function(x)
    {
      paste(substr(x, 1, 7) , "50", sep="")
    })

    names(transparent.group.colors) <- unique(group.labels)

    plot(secLvlSom.custom$visual[,"x"], -secLvlSom.custom$visual[,"y"],
         type="n", axes=FALSE, xlab="", ylab="", cex=4, col=group.colors, pch=16,
         xaxs="i", yaxs="i", xlim=xl, ylim=yl,main="Second level SOM, group outlines", cex.main=1)

    for (i in seq_along(unique(group.labels)))
    {
      group.member <- which(group.labels==unique(group.labels)[i])
      group.centroid <- colMeans(secLvlSom.custom$visual[group.member, 1:2])

      hull <- chull(secLvlSom.custom$visual[group.member, 1],
                    -secLvlSom.custom$visual[group.member, 2])

      polygon(secLvlSom.custom$visual[group.member[hull], 1],
              -secLvlSom.custom$visual[group.member[hull], 2],
              col=transparent.group.colors[i], lty=1,
              border=groupwise.group.colors[i])
    }

    legend("topright", as.character(unique(group.labels)), cex=0.5,
           text.col=groupwise.group.colors, bg="white")

    box()
  }


  ##### Plot Supersom with real expression profiles ######
  par(mar=c(1,1,1,1))
  xl <- c(min(secLvlSom.20.20$visual[,"x"])-1, max(secLvlSom.20.20$visual[,"x"])+1)
  yl <- c(min(-secLvlSom.20.20$visual[,"y"])-1, max(-secLvlSom.20.20$visual[,"y"])+1)

  plot(secLvlSom.20.20$visual[,"x"], -secLvlSom.20.20$visual[,"y"], type="p", axes=FALSE,
       xlab="", ylab="", xlim=xl, ylim=yl, xaxs="i", yaxs="i",main="Second level SOM with expresson portraits", cex.main=1)

  if (length(unique(group.labels)) > 1)
  {
    legend("topright", as.character(unique(group.labels)), cex=0.5,
           text.col=groupwise.group.colors, bg="white")
  }

  for (j in 1:nrow(secLvlSom.20.20$code.sum))
  {
    which.samples <-
      intersect(which(secLvlSom.20.20$visual[,"x"] == secLvlSom.20.20$code.sum[j,"x"]),
                which(secLvlSom.20.20$visual[,"y"] == secLvlSom.20.20$code.sum[j,"y"]))

    if (!is.na(which.samples[1]))
    {
      m <- matrix(metadata[, which.samples[1]], preferences$dim.1stLvlSom, preferences$dim.1stLvlSom)

      if (max(m) - min(m) != 0)
      {
        m <- (m - min(m)) / (max(m) - min(m)) * 999
      }

      m <- cbind(apply(m, 1, function(x){x}))[nrow(m):1,]
      x <- pixmapIndexed(m , col=color.palette.portraits(1000), cellres=10)

      addlogo(x,
              secLvlSom.20.20$visual[which.samples[1], "x"]+c(-0.45,0.455),
              -secLvlSom.20.20$visual[which.samples[1], "y"]+c(-0.45,0.45))

      which.samples <- which.samples[1:min(9, length(which.samples))]

      x.seq <- c(0,0.3,0,-0.3,0,-0.3,0.3,-0.3,0.3)[seq_along(which.samples)]
      y.seq <- c(0,0,0.3,0,-0.3,-0.3,-0.3,0.3,0.3)[seq_along(which.samples)]

      points(secLvlSom.20.20$visual[which.samples[1], "x"]+x.seq,
             -secLvlSom.20.20$visual[which.samples[1], "y"]+y.seq,
             pch=16, col=group.colors[which.samples], cex=1.5)

      points(secLvlSom.20.20$visual[which.samples[1], "x"]+x.seq,
             -secLvlSom.20.20$visual[which.samples[1], "y"]+y.seq,
             pch=1, col="gray20", cex=1.5, lwd=1)
    }
  }

  box()
  dev.off()
}
