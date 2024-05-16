CREATE OR REPLACE FUNCTION compete_from_opportunities(account_id VARCHAR)
RETURNS TABLE (
    account_id VARCHAR,
    opportunity_id VARCHAR,
    close_date DATE,
    notes VARCHAR,
    llm_competition VARCHAR,
    llm_explanation VARCHAR,
    llm_sentiment VARCHAR,
    primary_competitor VARCHAR
)
RETURNS NULL ON NULL INPUT
AS
$$
SELECT account_id, opportunity_id, close_date, notes, 
try_parse_json(llm_competition):competitors::varchar llm_competition, 
try_parse_json(llm_competition):explanation::varchar llm_explanation, 
try_parse_json(llm_competition):sentiment::varchar llm_sentiment, 
-- llm_competition,
primary_competitor_c primary_competitor
FROM (
SELECT o.account_id, o.id as opportunity_id, o.close_date, 
trim('Title: ' || coalesce(name, '') ||
' |\n\nDescription: ' || coalesce(description, '') ||
' |\n\nBusiness Pain: ' || coalesce(identify_pain_c, '') ||
' |\n\nSales Notes: ' || coalesce(next_steps_c, '') || 
' |\n\nSE Notes: ' || coalesce(se_comments_c, '')
) as notes, 
SNOWFLAKE.CORTEX.COMPLETE(
    'mistral-large',
        CONCAT('You are an intelligent classification bot. You work for Snowflake Computing a data analytics company. Your task is to assess sales opportunities using the title, description, business pain description and salesperson meeting notes and categorize which competitor we may be competing against after <<<>>> into one of the following predefined list of competitors:

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

"SF" refers to Snowflake. Terraform is not the same as Teradata. Teradata and SAS are 2 different companies, Teradata is a direct competitor, SAS is not. Do not include Snowflake as a competitor. 

####
Here are some examples:

Title: Redshift Compete |
Description: Company Cap 1 - currently on an on-prem TD.  Due to their current business with AWS, SWA has drifted toward a POC of Redshift by default (quote from them).  Working hard on reversing their course.  This opportunity is to take out a TD on-prem implementation leaning towards AWS Redshift |
Business Pain: Costs and distractions of data migration | 
Sales Notes: 2024-04-15[BB] |
SE Notes: none
Competitor: AWS, Teradata

Title: Public Utility District No. 1 of Chelan County-Cap-New Business |
Description: Looking to replace existing oracle data warehouse with cloud based tooling as apart of their data analytics strategic plan efforts. |
Business Pain: - on prem data warehouse cannot support growing AMI data 
- cannot support self service analytics vision with current tech stack |
Sales Notes: 
4/29/2022 (DR) Met with the team. Starting data modernization project, looking at both SF and Synapse |
SE Notes:
Competitor: Oracle, Microsoft

Title: Element Fleet Management Inc-PS&T | Description: Element Fleet is looking to reduce cost and complexity by migrating off of EMR and RDS onto Snowflake. EMR represents ~120K per year, RDS ~190K per year, in addition to Elastic and Kafka costs, and we need to provide guidance on how much this might cost within Snowflake. |
Business Pain: Expensive, inefficient and unable to scale |
Sales Notes: 2023-11-15-CW-CURRENT STATUS: Working with Gurvinder & team to review PS for January during EF new budget.
NEXT STEPS:
RISK: |
SE Notes:
Competitor: AWS

###

<<<',  
trim('Title: ' || coalesce(name, '') ||
' |\n\n Description: ' || coalesce(description, '') ||
' |\n\n Business Pain: ' || coalesce(identify_pain_c, '') ||
' |\n\n Sales Notes: ' || coalesce(next_steps_c, '') || 
' |\n\n SE Notes: ' || coalesce(se_comments_c, '')
)
    , '>>>'
        )
) llm_competition, 
primary_competitor_c
FROM fivetran.salesforce.opportunity o
WHERE o.account_id = account_id
AND is_deleted = FALSE
AND (name is not null OR description is not null OR identify_pain_c is not null OR se_comments_c is not null)
AND length(trim('Title: ' || coalesce(name, '') ||
' |\n\nDescription: ' || coalesce(description, '') ||
' |\n\nBusiness Pain: ' || coalesce(identify_pain_c, '') ||
' |\n\nSales Notes: ' || coalesce(next_steps_c, '') || 
' |\n\nSE Notes: ' || coalesce(se_comments_c, '')
)) > 5
ORDER BY close_date DESC
)
$$;