pipeline.calcStatistics <- function()
{
  verbose = (output.paths["LPE"] != "")

  if (verbose)
  {
    write.table(preferences$error.model,
                file.path(output.paths["LPE"], "1_error_model.txt"),
                row.names=FALSE,
                col.names=FALSE)
  }

  util.info("Processing Single Genes")
  util.progress(0, 48)

  mean.e.g <- rowMeans(indata.original)
  e.g.m <- matrix(NA, nrow(indata), ncol(indata), dimnames=list(rownames(indata), colnames(indata)))
  delta.e.g.m <- matrix(NA, nrow(indata), ncol(indata), dimnames=list(rownames(indata), colnames(indata)))

  sd.g.m <<- matrix(NA, nrow(indata), ncol(indata), dimnames=list(rownames(indata), colnames(indata)))
  LPE.g.m <- matrix(NA, nrow(indata), ncol(indata), dimnames=list(rownames(indata), colnames(indata)))

  WAD.g.m <<- matrix(NA, nrow(indata), ncol(indata), dimnames=list(rownames(indata), colnames(indata)))

  t.g.m <<- matrix(NA, nrow(indata), ncol(indata), dimnames=list(rownames(indata), colnames(indata)))
  p.g.m <<- matrix(NA, nrow(indata), ncol(indata), dimnames=list(rownames(indata), colnames(indata)))

  n.0.m <<- rep(NA, ncol(indata))
  names(n.0.m) <<- colnames(indata)

  perc.DE.m <<- rep(NA, ncol(indata))
  names(perc.DE.m) <<- colnames(indata)

  fdr.g.m <<- matrix(NA, nrow(indata), ncol(indata), dimnames=list(rownames(indata), colnames(indata)))
  Fdr.g.m <<- matrix(NA, nrow(indata), ncol(indata), dimnames=list(rownames(indata), colnames(indata)))

  mean.LPE2 <- rep(NA, ncol(indata))
  names(mean.LPE2) <- colnames(indata)

  for (m in 1:ncol(indata))
  {
    if (preferences$error.model == "replicates")
    {
      e.r.g.m <- as.matrix(indata.original[,which(colnames(indata.original) == unique(colnames(indata))[m]), drop=FALSE])
    } else
    {
      e.r.g.m <- as.matrix(indata.original[,m])
    }

    e.g.m[,m] <- rowMeans(e.r.g.m)

    delta.e.r.g.m <- e.r.g.m - mean.e.g
    delta.e.g.m[,m] <- rowMeans(delta.e.r.g.m)

    w.g.m <- (delta.e.g.m[,m] - min(delta.e.g.m[,m])) / (max(delta.e.g.m[,m]) - min(delta.e.g.m[,m]))
    WAD.g.m[,m] <<- w.g.m * delta.e.g.m[,m]
  }

  # Track the progress
  progress.max <- ncol(indata)
  progress.current <- 0

  if (preferences$error.model == "replicates")      ##################################
  {
    R.m <- sapply(colnames(indata), function(colname)
    {
      return(length(which(colnames(indata.original) == colname)))
    })

    names(R.m) <- colnames(indata)

    sd.shrink.g.m <- matrix(NA, nrow(indata), ncol(indata), dimnames=list(rownames(indata), colnames(indata)))

    for (m in 1:ncol(indata))
    {
      if (R.m[m] > 1)
      {
        e.r.g.m <- as.matrix(indata.original[,which(colnames(indata.original) == unique(colnames(indata))[m]), drop=FALSE])

        o <- order(e.g.m[, m])

        sd.g.m[, m] <<- sapply(c(1:nrow(indata)), function(x)
        {
          sqrt(sum((e.r.g.m[x,] - e.g.m[x,m]) ^ 2) / R.m[m])
        })

        LPE.g.m[o, m] <- Get.Running.Average(sd.g.m[o, m], min(200, round(nrow(indata) * 0.02)))

        SD2 <- LPE.g.m[o, m]

        for (j in seq(length(SD2)-1, 1))
        {
          SD2[j] <- max(SD2[j], SD2[j+1])
        }
        LPE.g.m[o, m] <- SD2

        lambda <- 0.5
        sd.shrink.g.m[, m] <- sqrt(lambda * sd.g.m[,m] ^ 2 + (1 - lambda) * LPE.g.m[, m] ^ 2)
      }
      progress.current <- progress.current + 0.5
      util.progress(progress.current, progress.max)
    }


    no.sd.samples <- colnames(indata)[which(is.na(apply(sd.shrink.g.m, 2, mean)))]

    if (length(no.sd.samples) > 0)
    {
      for (i in 1:nrow(indata))
      {
        gene.expression.order <- colnames(indata)[order(indata[i,])]

        for (m in no.sd.samples)
        {
          position <- which(gene.expression.order == m)

          gene.expression.order.help <- gene.expression.order
          gene.expression.order.help[gene.expression.order.help %in% no.sd.samples] <- NA
          gene.expression.order.help[position] <- m
          gene.expression.order.help <- na.omit(gene.expression.order.help)

          position <- which(gene.expression.order.help == m)

          window <- position + c(-2, -1, 1, 2)
          window[which(window < 1)] <- NA
          window[which(window > length(gene.expression.order.help))] <- NA
          window <- na.omit(window)

          sd.g.m[i, m] <<- mean(sd.g.m[i, gene.expression.order.help[window]])
        }
      }

      for (m in no.sd.samples)
      {
        o <- order(e.g.m[, m])

        LPE.g.m[o, m] <- Get.Running.Average(sd.g.m[o, m], min(200, round(nrow(indata) * 0.02)))

        SD2 <- LPE.g.m[o, m]

        for (j in seq(length(SD2)-1, 1))
        {
          SD2[j] <- max(SD2[j], SD2[j+1])
        }
        LPE.g.m[o, m] <- SD2

        lambda <- 0.5
        sd.shrink.g.m[, m] <- sqrt(lambda * sd.g.m[, m] ^ 2 + (1 - lambda) * LPE.g.m[, m] ^ 2)
      }
    } # END no.sd.samples

    if (any(sd.shrink.g.m == 0))
    {
      sd.shrink.g.m[which(sd.shrink.g.m == 0)] <- max(sd.shrink.g.m[-which(sd.shrink.g.m == 0)])

      util.warn("Data contains constant genes")
      util.warn("Constant genes set to maximum variance")
    }

    for (m in 1:ncol(indata))
    {
      t.g.m[,m] <<- sqrt(R.m[m]) * (e.g.m[,m] - mean.e.g) / sd.shrink.g.m[,m]

      progress.current <- progress.current + 0.1
      util.progress(progress.current, progress.max)
    }
  } # END error.model "replicates"

  if (preferences$error.model == "all.samples")      ##################################
  {
    o <- order(apply(indata.original, 1, mean))
    sdo <- apply(indata.original, 1, sd)[o]
    col <- Get.Running.Average(sdo, min(200, round(nrow(indata) * 0.02)))
    col[which(is.nan(col))] <- 0.0000000001
    col[which(col == 0)] <- 0.0000000001

    for (i in seq(length(col)-1, 1))
    {
      col[i] <- max(col[i], col[i+1])
    }

    sd.g.m[o,] <<- col
    LPE.g.m <- sd.g.m

    t.g.m <<- apply(e.g.m, 2, function(e.g.m.col, root)
    {
      return(root * (e.g.m.col - mean.e.g) / sd.g.m[,1])
    }, sqrt(ncol(indata)))

    progress.current <- progress.current + (0.6 * ncol(indata))
    util.progress(progress.current, progress.max)
  } # END error.model "all.samples"


  if (preferences$error.model == "groups")      ##################################
  {
    R.m <- sapply(group.labels, function(label)
    {
      length(which(group.labels == label))
    })
    names(R.m) <- colnames(indata)

    sd.shrink.g.m <- matrix(NA, nrow(indata), ncol(indata),
                            dimnames=list(rownames(indata), colnames(indata)))

    for (m in 1:ncol(indata))
    {
      if (R.m[m] > 1)
      {
        e.r.g.m <- as.matrix(indata.original[,which(group.labels == group.labels[m]), drop=FALSE])

        o <- order(e.g.m[,m])

        sd.g.m[, m] <<- sapply(c(1:nrow(indata)), function(x)
        {
          sqrt(sum((e.r.g.m[x,] - e.g.m[x,m]) ^ 2) / R.m[m])
        })

        LPE.g.m[o, m] <- Get.Running.Average(sd.g.m[o,m], min(200, round(nrow(indata) * 0.02)))

        SD2 <- LPE.g.m[o, m]

        for (j in seq(length(SD2)-1, 1))
        {
          SD2[j] <- max(SD2[j], SD2[j+1])
        }
        LPE.g.m[o, m] <- SD2

        lambda <- 0.5
        sd.shrink.g.m[, m] <- sqrt(lambda * sd.g.m[, m] ^ 2 + (1 - lambda) * LPE.g.m[, m] ^ 2)
      }

      progress.current <- progress.current + 0.5
      util.progress(progress.current, progress.max)
    }

    no.sd.samples <- colnames(indata)[which(is.na(apply(sd.shrink.g.m, 2, mean)))]

    if (length(no.sd.samples) > 0)
    {
      for (i in 1:nrow(indata))
      {
        gene.expression.order <- colnames(indata)[order(indata[i,])]

        for (m in no.sd.samples)
        {
          position <- which(gene.expression.order == m)

          gene.expression.order.help <- gene.expression.order
          gene.expression.order.help[gene.expression.order.help %in% no.sd.samples] <- NA
          gene.expression.order.help[position] <- m
          gene.expression.order.help <- na.omit(gene.expression.order.help)

          position <- which(gene.expression.order.help == m)

          window <- position + c(-2, -1, 1, 2)
          window[which(window < 1)] <- NA
          window[which(window > length(gene.expression.order.help))] <- NA
          window <- na.omit(window)

          sd.g.m[i, m] <<- mean(sd.g.m[i, gene.expression.order.help[window]])
        }
      }

      for (m in no.sd.samples)
      {
        o <- order(e.g.m[,m])

        LPE.g.m[o, m] <- Get.Running.Average(sd.g.m[o,m], min(200, round(nrow(indata) * 0.02)))

        SD2 <- LPE.g.m[o, m]

        for (j in seq(length(SD2)-1, 1))
        {
          SD2[j] <- max(SD2[j], SD2[j+1])
        }
        LPE.g.m[o,m] <- SD2

        lambda <- 0.5
        sd.shrink.g.m[,m] <- sqrt(lambda * sd.g.m[,m] ^ 2 + (1 - lambda) * LPE.g.m[,m] ^ 2)
      }
    } # END no.sd.samples

    t.g.m <<- matrix(sapply(1:ncol(indata), function(i)
    {
      return(sqrt(R.m[i]) * (e.g.m[,i] - mean.e.g) / sd.shrink.g.m[,i])
    }), ncol=ncol(indata))
  } # END error.model "groups"


  ### calculate significances ###

  for (m in 1:ncol(indata))
  {
    suppressWarnings({
      try.res <- try({
        fdrtool.result <- fdrtool(t.g.m[,m], verbose=FALSE, plot=FALSE)
      }, silent=TRUE)
    })

    if (class(try.res) != "try-error")
    {
      p.g.m[,m] <<- fdrtool.result$pval
      fdr.g.m[,m] <<- fdrtool.result$lfdr
      Fdr.g.m[,m] <<- fdrtool.result$qval

      n.0.m[m] <<- fdrtool.result$param[1,"eta0"]
      perc.DE.m[m] <<- 1 - n.0.m[m]
    } else # happens for eg phenotype data
    {
      p.g.m[,m] <<- order(indata[,m]) / nrow(indata)
      fdr.g.m[,m] <<- p.g.m[,m]
      Fdr.g.m[,m] <<- p.g.m[,m]

      n.0.m[m] <<- 0.5
      perc.DE.m[m] <<- 1 - n.0.m[m]
    }

    mean.LPE2[m] <- sqrt(Get.Area(e.g.m[,m], LPE.g.m[,m] ^ 2) / (max(e.g.m[,m]) - min(e.g.m[,m])))

    progress.current <- progress.current + 0.4
    util.progress(progress.current, progress.max)
  }

  util.progress.terminate()


  ### LPE plots ###

  if (verbose)
  {
    if (preferences$error.model == "replicates")
    {
      for (m in 1:ncol(indata))
      {
        filename <- file.path(output.paths["LPE"], paste(colnames(indata)[m], ".bmp", sep=""))
        util.info("Writing:", filename)

        bmp(filename, 600, 600)
        par(mar=c(5, 6, 4, 5))

        plot(sd.g.m[,m] ~ e.g.m[,m],
             xlab="e",
             ylab="",
             main="Locally pooled error estimate (LPE)",
             xlim=c(min(e.g.m,na.rm=TRUE), max(e.g.m,na.rm=TRUE)),
             ylim=c(0,max(sd.g.m,na.rm=TRUE)),
             las=1,
             cex.main=1.5,
             cex.lab=2,
             cex.axis=2)

        title(main=colnames(indata)[m],line=0.5)
        mtext(expression(sigma), side=2, line=4, cex= 2, las=2)

        a <- round(mean.LPE2[colnames(indata)[m]], 2)
        expr <- paste("paste(\"<\", sigma[LPE] ,\"> = ", a, " \", sep=\"\")", sep="")
        mtext(eval(parse(text=paste("expression(", expr, ")", sep=""))), line=-1.7, cex=2)

        points(LPE.g.m[,m] ~ e.g.m[,m], col="green", pch=16)
        dev.off()
      }
    } else if (preferences$error.model == "all.samples")
    {
      filename <- file.path(output.paths["LPE"], "all_samples.bmp")
      util.info("Writing:", filename)

      bmp(filename, 600, 600)
      par(mar=c(5, 6, 4, 5))

      plot(apply(indata.original, 1, sd) ~ apply(indata.original, 1, mean),
           xlab=expression(e[g]),
           ylab="",
           main="Locally pooled error estimate (LPE)",
           las=1,
           cex.main=1.5,
           cex.lab=2,
           cex.axis=2)      
      
      mtext(expression(sigma[g]), side=2, line=4, cex= 2, las=2)
      points(LPE.g.m[,1] ~ apply(indata.original, 1, mean), col="green", pch=16)
      dev.off()
    } else if (preferences$error.model == "groups")
    {
      for (m in seq_along(unique(group.labels)))
      {
        plot.sample <- which(group.labels == unique(group.labels)[m])[1]

        filename <- file.path(output.paths["LPE"], paste(unique(group.labels)[m], ".bmp", sep=""))
        util.info("Writing:", filename)

        bmp(filename, 600, 600)
        par(mar=c(5, 6, 4, 5))

        plot(sd.g.m[,plot.sample] ~ e.g.m[,plot.sample],
             xlab="e",
             ylab="",
             main="Locally pooled error estimate (LPE)",
             xlim=c(min(e.g.m,na.rm=TRUE), max(e.g.m,na.rm=TRUE)),
             ylim=c(0,max(sd.g.m,na.rm=TRUE)),
             las=1,
             cex.main=1.5,
             cex.lab=2,
             cex.axis=2)

        title(main=unique(group.labels)[m],line=0.5)
        mtext(expression(sigma), side=2, line=4, cex= 2, las=2)
        points(LPE.g.m[,plot.sample] ~ e.g.m[,plot.sample], col="green", pch=16)
        dev.off()
      }
    }
  }


  ### Metagenes ###

  progress.current <- 0
  progress.max <- ncol(indata)

  util.info("Processing Metagenes")
  util.progress(progress.current, progress.max)

  t.m <<- p.m <<- fdr.m <<-
    matrix(NA, preferences$dim.1stLvlSom ^ 2, ncol(indata),
           dimnames=list(1:(preferences$dim.1stLvlSom ^ 2), colnames(indata)))

  t.m.help <- do.call(rbind, by(t.g.m, som.nodes, colMeans))
  t.m[rownames(t.m.help),] <<- t.m.help

  progress.current <- 0.4 * progress.max
  util.progress(progress.current, progress.max)

  for (m in 1:ncol(indata))
  {
    suppressWarnings({
      try.res <- try({
        fdrtool.result <- fdrtool(as.vector(na.omit(t.m[,m])), verbose=FALSE, plot=FALSE)
      }, silent=TRUE)
    })

    if (class(try.res) != "try-error")
    {
      p.m[which(!is.na(t.m[,m])),m] <<- fdrtool.result$pval
      fdr.m[which(!is.na(t.m[,m])),m] <<- fdrtool.result$lfdr
    } else # happens for eg phenotype data
    {
      p.m[which(!is.na(t.m[,m])),m] <<- t.m[which(!is.na(t.m[,m])),m] / max(t.m[,m], na.rm=TRUE)
      fdr.m[which(!is.na(t.m[,m])),m] <<- p.m[which(!is.na(t.m[,m])),m]
    }

    progress.current <- progress.current + 0.6
    util.progress(progress.current, progress.max)
  }

  util.progress.terminate()


  if (verbose)
  {
    filename <- file.path(output.paths["LPE"], "Sigma_LPE.pdf")
    util.info("Writing:", filename)

    pdf(filename, 8, 8)
    par(mar=c(10, 6, 4, 5))
    mean.LPE.string <- expression(paste("standard deviation derived from LPE model:  <", sigma[LPE], ">", sep=""))

    barplot(mean.LPE2,
            col=group.colors,
            main=mean.LPE.string,
            las=2,
            cex.main=1.5,
            cex.lab=1,
            cex.axis=1)

    box()

    if (length(unique(group.labels)) > 1)
    {
      mean.LPE2.boxes <- by(mean.LPE2, group.labels[names(mean.LPE2)], c)[unique(group.labels)]

      boxplot(mean.LPE2.boxes,
              col=unique(group.colors),
              main=mean.LPE.string,
              las=2,
              cex.main=1.5,
              cex.axis=1,
              xaxt="n")

      axis(1, seq_along(mean.LPE2.boxes), names(mean.LPE2.boxes), las=2)
    }

    dev.off()
  }
}
