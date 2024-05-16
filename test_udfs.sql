-- OPPORTUNITIES
-- Sportsdirect
SELECT *
FROM TABLE(compete_from_opportunities('0013r00002dOVsBAAW'));

-- Natwest
SELECT *
FROM TABLE(compete_from_opportunities('0010Z00002D47bLQAR'));

-- Kipu Health
SELECT *
FROM TABLE(compete_from_opportunities('0010Z00001wlQeBQAU'));

-- TASKS

-- Test with JLR
SELECT *
FROM TABLE(compete_from_tasks('0010Z00001tHhZkQAK'));

-- Test with Tesco Bank
SELECT *
FROM TABLE(compete_from_tasks('0013r00002dOVsBAAW'));

-- USE CASES
-- JLR
SELECT *
FROM TABLE(compete_from_use_cases('0010Z00001tHhZkQAK'));

-- Kipu Health
SELECT *
FROM TABLE(compete_from_use_cases('0010Z00001wlQeBQAU'));

-- Tesco Bank
SELECT *
FROM TABLE(compete_from_use_cases('0013r00002dOVsBAAW'));


-- ACCOUNT

-- Test with JLR
SELECT *
FROM TABLE(compete_by_account('0010Z00001tHhZkQAK'));

-- Test with Tesco Bank
SELECT *
FROM TABLE(compete_by_account('0013r00002dOVsBAAW'));

-- Test with Natwest
SELECT *
FROM TABLE(compete_by_account('0010Z00002D47bLQAR'));

-- Test with Sportsdirect
SELECT *
FROM TABLE(compete_by_account('0013100001rtRPvAAM'));

-- Test with Maersk
SELECT account_id, competition
FROM TABLE(compete_by_account('0010Z000024XBLUQA4'));