library(igraph)
library(sqldf)

setwd("C:/big data/siec-commits/")

commits <- read.csv('user2user-by-commits.csv',
                     col.names = c('user_id','user_login',
                                    'project_id','project_name',
                                    'commit_count'),
                     sep = ',',
                     na.strings = NA,
                     colClasses = c('integer', 'character',
                                    'integer', 'character', 'numeric'),
                     quote = '\"')

typeof(commits)
sapply(commits, class)
names(commits)

# commit_network <- sqldf("SELECT a1.user_login as login1,
#                            a2.user_login as login2,
#                            a1.commit_count as c1, a2.commit_count as c2,
#                            (select sum(t.commit_count) from commits t
#                               where t.project_id = a1.project_id
#                               group by t.project_id) as totalc
#                            FROM commits a1
#                            LEFT JOIN commits a2
#                            ON a1.project_id = a2.project_id
#                            WHERE a1.user_login < a2.user_login;")

commit_network <- sqldf("SELECT a1.user_login as login1,
                           a2.user_login as login2,
                           a1.commit_count as c1, a2.commit_count as c2,
                           a3.totalc as total
                           FROM commits a1
                           LEFT JOIN commits a2
                           ON a1.project_id = a2.project_id
                           LEFT JOIN (
                              select t.project_id as project_id,
                              sum(t.commit_count) as totalc
                              from commits t group by t.project_id
                           ) as a3
                           ON a1.project_id = a3.project_id
                           WHERE a1.user_login < a2.user_login;")

head(commit_network)
tail(commit_network)

network <- sqldf("SELECT login1, login2, count(*) as weight1,
                  (c1 + c2) as weight2, ((c1 + c2) / total) as weight3
                  from commit_network group by login1, login2");
''' weight1 - waga "ile wspolnych repo" maja uzytkownicy login1 oraz login2
      zauwaz ze zjoinowalismy wczesniej po project_id dlatego count(*)
      tutaj oznacza wlasnie ilosc wspolnych repozytorii

    weight2 - suma commit_count dla tych 2 uzytkownikow razem wzietych
      w obrębie danego repozytorium, wyliczone poprzez c1 + c2

    weight3 - "impact factor" - jaka czesc wszystkich commitów
      do danego repo stanowi ich wklad, weight3 przyjmuje wartosci od 0 do 1
'''

head(network)

sapply(network, class)

network_matrix <- as.matrix(network)  # zamiana na macierz

head(network_matrix)

g = graph.edgelist(network_matrix[,1:2],directed=FALSE)
E(g)$weight_common_repos = as.numeric(network_matrix[,3])
E(g)$weight_sum_commits = as.numeric(network_matrix[,4])
E(g)$weight_impact_factor = as.numeric(network_matrix[,5])

summary(g)

save.image(file = "workspace.RData")

write.graph(g, "user2user_by-commits.graphml", "graphml")
# write.graph(g, "user2user_commit-network.pajek", "pajek")
