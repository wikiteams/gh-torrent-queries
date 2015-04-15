library(igraph)
sim_g_dice <- similarity.dice(g)
sim_g_iw <- similarity.invlogweighted(g)
sim_g_jac <- similarity.jaccard(g)
el <- get.edgelist(g)
#now we assign similarity value to the edges 
E(g)$weight_1 <- sim_g_dice[el]
E(g)$weight_2 <- sim_g_iw[el]
E(g)$weight_3 <- sim_g_jac[el]
save(file="network_with_sim.RData")
E(g)$weight_avg <- rowMeans( E(g)[ , c("weight_1", "weight_2", "weight_3")] ) 
write.graph(g, "discussion_network_with_sim.graphml", "graphml")
# write.graph(g, "discussion_network.pajek", "pajek")