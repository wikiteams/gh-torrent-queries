setwd("~/data/dyskusje/")

dialogues <- read.csv('discussions_clean.csv',
                      col.names = c('comment_id', 'user_id', 'body',
                                    'commit_id', 'pull_request_id',
                                    'created_at'),
                      sep = ';',
                      na.strings = "N/A",
                      fileEncoding = "UTF-8",
                      comment='', colClasses = "character",
                      quote = '\"', , encoding= "UTF-8")

users <- read.csv('users.csv',
                  col.names = c('id', 'login', 'name',
                                'company', 'location',
                                'created_at'),
                  sep = ';',
                  na.strings = "\\N",
                  fileEncoding = "UTF-8",
                  comment='', colClasses = "character",
                  quote = '\"', , encoding= "UTF-8")

typeof(dialogues)
sapply(dialogues, class)
names(dialogues)
dialogues$user_id <- as.numeric(dialogues$user_id)
dialogues$commit_id <- as.numeric(dialogues$commit_id)
dialogues$pull_request_id[dialogues$pull_request_id=='N'] <- NA
dialogues$pull_request_id <- as.numeric(dialogues$pull_request_id)
dialogues$created_at <- as.Date(dialogues$created_at)

typeof(users)
sapply(users, class)
names(users)
users$id <- as.numeric(users$id)
users$created_at <- as.Date(users$created_at)

library(igraph)
library(sqldf)

dialogues_n_users <- sqldf("select d.*, u.login from dialogues d
                           join users u on d.user_id = u.id");
aggregates <- sqldf("select commit_id, login, count(login) as n
                    from dialogues_n_users d group by commit_id, login");

typeof(dialogues_n_users)
typeof(aggregates)

activity_network <- sqldf("SELECT a1.login as login1, a2.login as login2,
                              a1.n as c1, a2.n as c2
                              FROM aggregates a1
                              LEFT JOIN aggregates a2
                              ON a1.commit_id = a2.commit_id
                              WHERE a1.login < a2.login;")

head(activity_network)

network <- sqldf("SELECT login1, login2, count(*) as weight
                 from activity_network group by login1, login2");

head(network)

sapply(network, class)

network_matrix <- as.matrix(network)

head(network_matrix)

g = graph.edgelist(network_matrix[,1:2],directed=FALSE)
E(g)$weight=as.numeric(network_matrix[,3])

# plot(g,layout=layout.fruchterman.reingold,edge.width=E(g)$weight)
# plotting in a reasonable time (less than 24h) is unreal, reduce first
