CREATE OR REPLACE FUNCTION compete_from_use_cases(account_id VARCHAR)
RETURNS TABLE (
    use_cases VARCHAR,
    llm_competition VARIANT,
    llm_explanation VARCHAR,
    llm_sentiment VARCHAR
)
RETURNS NULL ON NULL INPUT
AS
$$
SELECT use_cases, 
try_parse_json(llm_competition):competitors llm_competition, 
try_parse_json(llm_competition):explanation::varchar llm_explanation,
try_parse_json(llm_competition):sentiment::varchar llm_sentiment
FROM (
SELECT trim(coalesce(use_cases, '')) as use_cases, 
SNOWFLAKE.CORTEX.COMPLETE(
    'mistral-large',
        CONCAT('You are an intelligent classification bot. You work for Snowflake Computing a data analytics company. Your task is to assess this list of use cases and categorize which competitor we may be up against after <<<>>> into one of the following predefined list of competitors:

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

Do not hallucinate, if a competitor is mentioned but it is not clearly competing then do not return it. 

####
Here are some examples:

Use Case ID: aI6VI00000xxxiDx0AI
Date: 2024-04-26
Stage: 2 - Scoping
Use Case Name: TD Migration use case
Description: Competing against databricks for a teradata migration
Competitor: Databricks

Use Case ID: aI6Do00xxx0fzQDKAY
Date: 2024-04-26
Stage: 8 - Use Case Lost
Use Case Name: Customer Data Platform
Description:  PoCs for several companies (Databricks, Snowflake) through partners.
Competitor: Databricks
###

<<<',  
     trim(coalesce(use_cases, ''))
    , '>>>'
        )
) llm_competition
FROM (SELECT listagg('Use Case ID: ' || u.use_case_id || '\n' ||
'Date: ' || u.ds || '\n' ||
'Stage: ' || u.new_stage ||  '\n' ||
'Use Case Name: ' || trim(coalesce(u.use_case_name, '') || '\n' ||
'Description: ' || coalesce(u.use_case_description, '')), '\n\n') as use_cases
FROM SALES.SALES_ENGINEERING.USECASE u
WHERE u.new_stage not in ('0 - Not in Pursuit')
--AND LENGTH(trim(u.use_case_id || u.ds || u.new_stage || coalesce(u.use_case_name, '') || coalesce(u.use_case_description, ''), '\n\n')) > 5
and u.account_id = account_id)
WHERE LENGTH(use_cases) > 5
)
$$;