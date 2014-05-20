select u.login as who_is_followed, z.login as follower, f.created_at as date_when_followed from followers f, users u, users z where (f.user_id = u.id) and (f.follower_id = z.id) and (f.created_at between '2011-01-01 00:00:01' and '2011-12-31 23:59:59') order by date_when_followed asc