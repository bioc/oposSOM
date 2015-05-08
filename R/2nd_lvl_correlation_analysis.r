pipeline.2ndLvlCorrelationAnalysis <- function()
{
  groupwise.group.colors.stability.1 <- apply((col2rgb(groupwise.group.colors) + 0.7 *
           (255 - col2rgb(groupwise.group.colors))) / 255,
        2, function(x) rgb(x[1],x[2],x[3]))
  
  groupwise.group.colors.stability.2 <- apply((col2rgb(groupwise.group.colors) + 0.9 *
          (255 - col2rgb(groupwise.group.colors))) / 255,
       2, function(x) rgb(x[1],x[2],x[3]))  
  
  
  stability.colors <- group.colors
  stability.colors[which(group.silhouette.coef < 0.5)] <- groupwise.group.colors.stability.1[group.labels[names(which(group.silhouette.coef < 0.5))]]
  stability.colors[which(group.silhouette.coef < 0)] <- groupwise.group.colors.stability.2[group.labels[names(which(group.silhouette.coef < 0))]]
    
    
    
    

  filename <- file.path(paste(files.name, "- Results"), "2nd lvl Metagene Analysis", "Correlation Analysis.pdf")
  util.info("Writing:", filename)
  pdf(filename, 29.7/2.54, 21/2.54, useDingbats=FALSE)

  for (i in seq_along(metagene.filter.list))
  {
    s <- metadata[metagene.filter.list[[i]]$s ,]
    cor.s <- cor(s)
    par(mar=c(1, 1, 1, 1))

    # Maximum Correlation Tree
    adj.matrix <- cor.s * -1
    g <- graph.adjacency(adj.matrix, weighted=TRUE, mode="undirected")
    stg <- minimum.spanning.tree(g)
    layout <- layout.kamada.kawai(stg)

    plot(stg, layout=layout, vertex.size=5, vertex.label = rep("",ncol(indata)),
         vertex.label.cex=if (ncol(indata)<100) 1.2 else 0.6,
         vertex.color=group.colors, main=paste("Correlation Spanning Tree,",metagene.filter.list[[i]]$n))

    legend("bottomright", as.character(unique(group.labels)), cex=0.5,
           text.col=groupwise.group.colors, bg="white")

    box()


    if (ncol(metadata) < 1000)
    {
      plot(stg, layout=layout, vertex.size=5, vertex.label = colnames(indata),
           vertex.label.cex=if (ncol(indata)<100) 1.2 else 0.6,
           vertex.color=group.colors, main=paste("Correlation Spanning Tree,",metagene.filter.list[[i]]$n))
      
      legend("bottomright", as.character(unique(group.labels)), cex=0.5,
             text.col=groupwise.group.colors, bg="white")
      
      box()

      plot(stg, layout=layout, vertex.size=5, vertex.label = rep("",ncol(indata)),
           vertex.label.cex=if (ncol(indata)<100) 1.2 else 0.6,
           vertex.color=stability.colors, main=paste("Correlation Spanning Tree, silhouette scores,",metagene.filter.list[[i]]$n))

      legend("bottomright", rep(as.character(unique(group.labels)),3), cex=0.5,
             text.col=c(groupwise.group.colors,groupwise.group.colors.stability.1,groupwise.group.colors.stability.2), bg="white",ncol=3,
             title="0.5<S    0<S<0.5    S<0",title.col="black")

      box()
    }
    
    
    # Collelation Backbone
    adj.matrix <- cor.s
    diag(adj.matrix) <- 0

    adj.matrix <- apply(adj.matrix, 1, function(x)
    {
      x[order(x,decreasing=TRUE)[-c(1:2)]] <- 0
      return(x)
    })

    adj.matrix[which(adj.matrix < 0.5)] <- 0

    g <- graph.adjacency(adj.matrix, weighted=TRUE,  mode="undirected")
    layout <- layout.fruchterman.reingold(g)

    plot(g, layout=layout, vertex.size=5, vertex.label = rep("",ncol(indata)),
         vertex.label.cex=if (ncol(indata)<100) 1.2 else 0.6,
         vertex.color=group.colors, main=paste("Correlation backbone,",metagene.filter.list[[i]]$n))
    
    legend("bottomright", as.character(unique(group.labels)), cex=0.5,
           text.col=groupwise.group.colors, bg="white")
    
    box()
    
    if (ncol(metadata) < 1000)
    {
      plot(g, layout=layout, vertex.size=5, vertex.label = colnames(indata),
           vertex.label.cex=if (ncol(indata)<100) 1.2 else 0.6,
           vertex.color=group.colors, main=paste("Correlation backbone,",metagene.filter.list[[i]]$n))
  
      legend("bottomright", as.character(unique(group.labels)), cex=0.5,
             text.col=groupwise.group.colors, bg="white")
  
      box()
  
      plot(g, layout=layout, vertex.size=5, vertex.label = rep("",ncol(indata)),
           vertex.label.cex=if (ncol(indata)<100) 1.2 else 0.6,
           vertex.color=stability.colors, main=paste("Correlation backbone, silhouette scores,",metagene.filter.list[[i]]$n))
  
      legend("bottomright", rep(as.character(unique(group.labels)),3), cex=0.5,
             text.col=c(groupwise.group.colors,groupwise.group.colors.stability.1,groupwise.group.colors.stability.2), bg="white",ncol=3,
             title="0.5<S    0<S<0.5    S<0",title.col="black")
  
      box()
    }

    # Correlation Network
    adj.matrix <- cor.s
    diag(adj.matrix) <- 0
    adj.matrix[which(adj.matrix < 0.5)] <- 0

    if (max(adj.matrix) > 0)
    {
      g <- graph.adjacency(adj.matrix, weighted=TRUE,  mode="undirected")
      layout <- layout.fruchterman.reingold(g, start=matrix(1:(2*ncol(indata)),ncol=2), niter=1000)

      plot(g, layout=layout, vertex.size=ifelse(ncol(indata)<250, 5, 3),
           vertex.label = rep("",ncol(indata)),
           vertex.label.cex=if (ncol(indata) < 100) 1.2 else 0.6,
           vertex.color=group.colors, main=paste("Correlation network,",metagene.filter.list[[i]]$n))
      
      legend("bottomright", as.character(unique(group.labels)), cex=0.5,
             text.col=groupwise.group.colors, bg="white")
      
      box()
      
      if (ncol(metadata) < 1000)
      {      
        plot(g, layout=layout, vertex.size=ifelse(ncol(indata) < 250, 5, 3),
             vertex.label=colnames(indata),
             vertex.label.cex=if (ncol(indata)<100) 1.2 else 0.6,
             vertex.color=group.colors, main=paste("Correlation network,",metagene.filter.list[[i]]$n))
  
        legend("bottomright", as.character(unique(group.labels)), cex=0.5,
               text.col=groupwise.group.colors, bg="white")
  
        box()
  
        plot(g, layout=layout, vertex.size=ifelse(ncol(indata) < 250, 5, 3),
             vertex.label = rep("",ncol(indata)),
             vertex.label.cex=if (ncol(indata)<100) 1.2 else 0.6,
             vertex.color=stability.colors, main=paste("Correlation network, silhouette scores,",metagene.filter.list[[i]]$n))
  
        legend("bottomright", rep(as.character(unique(group.labels)),3), cex=0.5,
               text.col=c(groupwise.group.colors,groupwise.group.colors.stability.1,groupwise.group.colors.stability.2), bg="white",ncol=3,
               title="0.5<S    0<S<0.5    S<0",title.col="black")
  
        box()
      }
    }

    # PCM
    hcl <- hclust(dist(cor.s))

    heatmap.wrap(x=cor.s, Rowv=as.dendrogram(hcl), Colv=as.dendrogram(hcl),
                 col=colramp(1000), scale="n", main=paste("Pairwise correlation map,",metagene.filter.list[[i]]$n),
                 mar=c(8,8), ColSideColors=group.colors, RowSideColors=group.colors)

    par(new=TRUE)
    plot(0,type="n", axes=FALSE, xlab="", ylab="")
    legend("bottomright", as.character(unique(group.labels)), cex=0.5,
           text.col=groupwise.group.colors, bg="white")
    
    par(new=TRUE, mar = c(25, 55, 10.8, 2))
    image(matrix(1:100, 1, 100), col = colramp(1000), axes=FALSE)
    axis(2, c(round(range(cor.s),1),"r"), at=c(0, 1, 0.5), las=2, tick=FALSE, pos=0, cex.axis=1)


    if (ncol(metadata) < 1000 && i <= 2)
    {
      def.par <- par(no.readonly = TRUE)

      environment(pipeline.2ndLvlModuleCorrelation) <- environment()
      pipeline.2ndLvlModuleCorrelation(s, hcl)

      par(def.par)
    }

    if (ncol(metadata) < 1000)
    {
      par(mar=c(1, 1, 1, 1))
      heatmap.wrap(x=cor.s, Rowv=NA, Colv=NA, col=colramp(1000), scale="n",
                   main=paste("Pairwise correlation map,",metagene.filter.list[[i]]$n), mar=c(8,8),
                   ColSideColors=group.colors, RowSideColors=group.colors)
  
      par(new=TRUE)
      plot(0,type="n", axes=FALSE, xlab="", ylab="")
      legend("bottomright", as.character(unique(group.labels)), cex=0.5,
             text.col=groupwise.group.colors, bg="white")
  
      par(new=TRUE, mar = c(31.6, 55, 4.2, 2))
      image(matrix(1:100, 1, 100), col = colramp(1000), axes=FALSE)
      axis(2, c(round(range(cor.s),1),"r"), at=c(0, 1, 0.5), las=2, tick=FALSE, pos=0, cex.axis=1)
      
      
      o <- unlist(sapply(unique(group.labels), function(gr)
      {
        idx <- names(group.labels)[which(group.labels == gr)]
  
        if (length(idx) > 1)
        {
          hc <- hclust(dist(t(s[,idx])))
          return(hc$labels[hc$order])
        }
        return(idx)
      }))
  
      par(mar=c(1, 1, 1, 1))
      heatmap.wrap(x=cor.s[o,o], Rowv=NA, Colv=NA, col=colramp(1000),
                   scale="n", main=paste("Pairwise correlation map,",metagene.filter.list[[i]]$n), mar=c(8,8),
                   ColSideColors=group.colors[o], RowSideColors=group.colors[o])
  
      par(new=TRUE)
      plot(0,type="n", axes=FALSE, xlab="", ylab="")
      legend("bottomright", as.character(unique(group.labels)), cex=0.5,
             text.col=groupwise.group.colors, bg="white")
      
      par(new=TRUE, mar = c(31.6, 55, 4.2, 2))
      image(matrix(1:100, 1, 100), col = colramp(1000), axes=FALSE)
      axis(2, c(round(range(cor.s),1),"r"), at=c(0, 1, 0.5), las=2, tick=FALSE, pos=0, cex.axis=1)
    }
  }

  dev.off()
}
