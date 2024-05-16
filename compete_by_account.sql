CREATE OR REPLACE FUNCTION compete_by_account(account_id VARCHAR) 
RETURNS TABLE (
    account_id VARCHAR,
    machine VARCHAR,
    human VARCHAR,
    competition VARIANT
)
RETURNS NULL ON NULL INPUT
AS
$$
SELECT account_id, machine, human, 
try_parse_json(llm_competition):competitors llm_competition
FROM (
SELECT account_id, listagg(machine, ', ') as machine, listagg(human, ', ') as human, 
SNOWFLAKE.CORTEX.COMPLETE(
    'mistral-large',
        CONCAT('You are an intelligent classification bot. Your task is to assess 2 lists of competitors, one given by humans and one from machines and categorize which competitor we are competing against <<<>>> into one of the following predefined list of competitors:

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
Salesforce
Palantir
Vertica
TileDB
MotherDuck
Firebolt

If the text doesn\'t seem to reference any of the above competitors, classify it as:
Unknown

You will only respond with the competitors labelled "competitors" in JSON format. Do not respond with anything not in the list. Only list each competitor once. Do not include a summary or description. 

Do not provide any explanations or notes. Rank the list by which you think are most important giving more weight to the human list. Limit the list to the top three competitors.

Some of the human classifications have additional comments in parentheses, ignore these.

Do not hallucinate, if there is no references to competitors from the list, return "Unknown".

####
Here are some examples:

Machine: AWS, Microsoft, Microsoft
Human: Microsoft - Synapse
Competitor: Microsoft

Machine: AWS
Human: AWS
Competitor: AWS

Machine: Databricks, Databricks
Human: Databricks (including Azure, AWS and GCP)
Competitor: Databricks

###

<<<',  
     'Machine: ' || listagg(machine, ', ') 
     || ' Human: ' || listagg(human, ', ')
    , '>>>'
        )
) llm_competition
FROM (
select llm_competition as machine, primary_competitor as human
FROM TABLE(compete_from_opportunities(account_id))
UNION ALL
select llm_competition as machine, null as human
from TABLE(compete_from_tasks(account_id))
UNION ALL
select llm_competition as machine, null as human
from TABLE(compete_from_use_cases(account_id))
))
$$;