desc dev_project_commits;
select count(*) from dev_project_commits; -- 140290

SELECT 
    *
FROM
    dev_project_commits 
    INTO OUTFILE '/tmp/user2user-by-commits.csv' 
    FIELDS OPTIONALLY ENCLOSED BY '"' 
    TERMINATED BY ',' 
    ESCAPED BY '"' 
    LINES TERMINATED BY '\r\n';
    -- 140290 row(s) affected