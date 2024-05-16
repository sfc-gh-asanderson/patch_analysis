CREATE OR REPLACE FUNCTION compete_from_tasks(account_id VARCHAR)
RETURNS TABLE (
    account_id VARCHAR,
    task_id VARCHAR,
    created_date TIMESTAMP_TZ,
    notes VARCHAR,
    llm_competition VARIANT,
    llm_explanation VARCHAR,
    llm_sentiment VARCHAR
)
RETURNS NULL ON NULL INPUT
AS
$$
SELECT account_id, task_id, created_date, notes, 
try_parse_json(llm_competition):competitors llm_competition, 
try_parse_json(llm_competition):explanation::varchar llm_explanation,
try_parse_json(llm_competition):sentiment::varchar llm_sentiment 
FROM (
SELECT t.account_id, t.id as task_id, t.created_date,  
trim('Meeting Notes: ' || coalesce(t.before_state_c, '') || '\n\n' || coalesce(t.pain_points_c, '')) as notes, 
SNOWFLAKE.CORTEX.COMPLETE(
    'mistral-large',
        CONCAT('You are an intelligent classification bot. You work for Snowflake Computing a data analytics company. Your task is to assess salesperson meeting notes and categorize which competitor we may be up against after <<<>>> into one of the following predefined list of competitors:

Databricks
AWS
Microsoft
Google
Oracle
Hadoop
Teradata
SAP
Netezza
Yellowbrick
Dremio
Actian
Exasol
Palantir
Vertica
TileDB
MotherDuck
Firebolt
Greenplum
Starburst

If the text doesn\'t seem to reference any of the above competitors, classify it as:
Unknown

You will respond with your explanation labelled "explanation", a csv list of competitors labelled "competitors" and the sentiment value associated with each competitor in the sentance that mentions it labelled "sentiment" separately in JSON format. Do not respond with competitors not in the list. Do not include a summary of the notes. 

"SF" refers to Snowflake. Do not include Snowflake as a competitor.  

####
Here are some examples:

Meeting Notes: Customer is looking to migrate a data warehouse off of Teradata and are considering both Snowflake and Databricks.
Competitor: Databricks
Meeting Notes: CDO is currently using AWS Redshift but is running into performance and scalability challenges. 
Competitor: AWS
Meeting Notes: The data team is currently evaluating data platforms including Microsoft Fabric and Snowflake. 
Competitor: Microsoft
Meeting Notes: Right now the business is using Google BigQuery to run their analytic workloads. 
Competitor: Google
Meeting Notes: Prospect is frustrated with the amount of administration that is required while using their current solution on MSFT Azure Synapse. 
Competitor: Microsoft
Meeting Notes: The business is using Salesforce and currently also keeping their analytics in the SFDC. 
Competitor: Salesforce
Meeting Notes: AWS -using Databricks currently -time spent looking for data 
Competitor: AWS, Databricks
Meeting Notes: Pretty happy with DBX and Unity catalog, but interested in hearing more about Snowpark 
Competitor: Databricks
Meeting Notes: Moving from On prem to amz s3. Wants Snowflake to sit on top in order to pull SAP and Saleforces data in real-time.
Competitor: AWS, SAP, Salesforce
Meeting Notes: The Chief Data Officer tells us he is being forced to move to Vantage in the cloud.
Competitor: Teradata
Meeting Notes: Prospect seems to have a preference for implementing a data lakehouse.
Competitor: Databricks
###

<<<',  
     trim('Meeting Notes: ' || coalesce(t.before_state_c, '') || '\n\n' || coalesce(t.pain_points_c, ''))
    , '>>>'
        )
) llm_competition
FROM fivetran.salesforce.task t
WHERE t.account_id = account_id
AND t.account_id is not null
AND t.is_deleted = FALSE
AND (t.before_state_c is not null OR pain_points_c is not null)
AND length(trim(coalesce(t.before_state_c, '') || ' ' || coalesce(t.pain_points_c, ''))) > 5
AND t.created_date is not null
ORDER BY created_date DESC
)
$$;