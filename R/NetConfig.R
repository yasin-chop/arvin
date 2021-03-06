#Author: Long Gao
#library("igraph")#igraph contains basic graph operations and some simple graph algorithms
#library("BiRewire")

####################################################################################################################
#This "makeNet" function was designed to generate a network object based on igraph library
#Following files are all tab delimited without headers
#Interaction_file, a string indicates the path of Interaction_file with 4 columns. 1st col is eSNP/gene 1, 2nd is target gene/gene 2, and 3rd is normalized weight. Last col denotes interaction type(EP/FI)
#Node_file, a string indicates the path of Node_file with 3 columns. 1st col is eSNP name/gene name, 2nd is normalized weight. Last col denotes node type (eSNP/Gene)
#rand, seed for generating random networks
#output is an igraph object as well as the real network, if "rand" is True then the output is a random network

#'Generate a graph object for input network 
#'
#'This function ...
#'
#'@param Interaction_file file path for edges in input network
#'@param Node_file file path for nodes in input network 
#'@param rand boolean value indicating if randomized network will be generated
#'@param seed seed for network randomization
#'@return a graph object
makeNet <- function(Interaction_file, Node_file, rand=FALSE, seed=1){
  #read edge and node information from corresponding files
  edge_set <- read.table(Interaction_file, sep="\t")
  node_set   <- read.table(Node_file, sep="\t")
  edge_set[,1] <- as.character(edge_set[,1])#in case the gene id is digits like
  edge_set[,2] <- as.character(edge_set[,2])
  #edge_set[,3] <- edge_set[,3] * 0#penalize edge weight
  node_set[,1] <- as.character(node_set[,1])
  
  if(rand==TRUE){
    #if this flag is True, edge weight and node weight will be shuffled first
    #in this way, the output graph is a random network
    node_set <- shuffleNode(node_set, seed)
    edge_set <- sfhuffleEdge(edge_set, seed)
  }
  
  ######################################################################################
  ######################################################################################
  #specify graph edge information
  interaction_set <- edge_set[,1:2]#get interaction informtion
  weight_set      <- edge_set[,3]#get corresponding edge weight
  graph <- make_graph(unlist(t(interaction_set)), directed=FALSE)#initialize a graph object by adding a set of edges
  graph <- set_edge_attr(graph, "weight", value=unlist(t(weight_set)))#add edge weight information to the graph	
  if(dim(edge_set)[2] > 3){
    #if the forth col was given
    #the edge "type" attribute will be specified 
    type_set <- edge_set[,4]
    graph <- set_edge_attr(graph, "type", value=as.character(type_set))#add edge weight information to the graph
  }
  
  ######################################################################################
  #some genes don't a node weight, so identify them and assign a zero weight
  all_nodes <- union(edge_set[,1],edge_set[,2])
  NonHit <- setdiff(all_nodes,node_set[,1])
  NonHit_data <- data.frame(NonHit, 0, "Gene")
  colnames(NonHit_data) <- colnames(node_set)
  node_set <- rbind(node_set, NonHit_data)
  
  #specify graph node information
  row.names(node_set) <- node_set[,1]#the vertex order might be different, so this step is to make the order consistent
  graph <- set_vertex_attr(graph, "weight",  value=node_set[V(graph)$name,2])#set the node weight
  if(dim(edge_set)[2] > 2){
    #if the third col was given
    #the node "type" attribute will be specified 
    graph <- set_vertex_attr(graph, "type", value=as.character(node_set[V(graph)$name,3]))#add edge weight information to the graph
  }
  
  print("The undirected-weighted eSNP-gene network has been constructed!")
  return(graph)
}

####################################################################################################################
#These two functions are used to shuffle node or edge weight to generate random networks
#The idea is to shuffle swap weight values based on origninal input matrix
shuffleNode <- function(node_set, seed=1){
  shuf_node_set <- NULL
  #shuffle node weight within the same node type eSNP/Gene
  eSNP_set <- subset(node_set, node_set[,3]=="eSNP")
  Gene_set <- subset(node_set, node_set[,3]=="Gene")
  set.seed(seed)
  eSNP_set[,2] <- sample(eSNP_set[,2])#shuffle node weight within eSNP nodes
  set.seed(seed)
  Gene_set[,2] <- sample(Gene_set[,2])#shuffle node weight within Gene nodes
  shuf_node_set <- rbind(eSNP_set, Gene_set)
  return(shuf_node_set)
}

sfhuffleEdge <- function(edge_set, seed=1){
  shuf_edge_set <- NULL
  #shuffle node weight within the same node type eSNP/Gene
  EP_set <- subset(edge_set, edge_set[,4]=="EP")
  FI_set <- subset(edge_set, edge_set[,4]=="FI")
  #set.seed(seed)
  EP_set[,3] <- sample(EP_set[,3])#shuffle edge weight within EP interactions
  EP_set[,2] <- sample(EP_set[,2])#shuffle snp-gene connections
  set.seed(seed)
  FI_set[,3] <- sample(FI_set[,3])#shuffle edge weight within functional interactions
  #temp_FI <- FI_set[,1:2]
  #temp_g <- make_graph(unlist(t(temp_FI)), directed=FALSE)
  #rewire_g <- birewire.rewire.undirected(temp_g,100*length(E(temp_g)))
  #rewire_edge <- as_edgelist(rewire_g)
  #new_FI_set <- as.data.frame(cbind(rewire_edge, FI_set[,3], rep("FI",dim(FI_set)[1])))
  #new_FI_set[,3] <- as.numeric(FI_set[,3])
  #print("Rewiring has been done!")
  #shuf_edge_set <- as.data.frame(rbind(EP_set, new_FI_set))
  #shuf_edge_set[,3] <- as.numeric(shuf_edge_set[,3])
  shuf_edge_set <- as.data.frame(rbind(EP_set, FI_set))#only shuffle the node weight
  shuf_edge_set[,3] <- as.numeric(shuf_edge_set[,3])#only shuffle the node weight
  return(shuf_edge_set)
}
