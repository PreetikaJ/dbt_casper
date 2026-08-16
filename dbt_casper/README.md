Welcome to your new dbt project!

### Using the starter project

Try running the following commands:
- dbt run
- dbt test


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices

### dbt setup
git clone <your-repo-url>
cd dbt_casper

## Setup virtual environment
python -m venv venv or py -3.10 -m venv venv
venv\Scripts\activate

## Define dependencies
### Create requirement.txt file having all dependancies 
dbt-bigquery 

### run below command to set up the dependancies
pip install -r requirements.txt

## Bigquery Setup
1. Create BigQuery Service Account
- Go to Google Cloud Console
- IAM & Admin → Service Accounts
- Create new service account
- Grant roles:
    - BigQuery Data Editor
    - BigQuery Job User
    - Bigquery User
- Generate JSON key
- Download and save key file securely (not to be commited or shared publically)

## Create profiles.yml file
### Location
C:\Users\<your-user>\.dbt\profiles.yml

### profiles.yml code format
dbt_casper:
  outputs:
    dev:
      dataset: casper_data_raw
      job_execution_timeout_seconds: 300
      job_retries: 1
      keyfile: YOUR JSON KEY
      location: EU
      method: service-account
      priority: interactive
      project: casper-code-challenge
      threads: 10
      type: bigquery

- profiles.yml file stored here for download. Please add your json key.

### Note: location must match your BigQuery dataset location (EU or US).

## Run following commands to test the connection.
dbt debug

## Comands to compile a model
dbt compile
dbt compile --select model_name --target target_env

dbt compile --select patients_engagement_reporting --target prod

## Commands to run a model
dbt run (To run all the models - not recommended for large projects)

dbt run --select model_name --target target_env

dbt run --select patients_engagement_reporting --target prod

## Commands to run the dbt test
dbt test --select model_name --target target_env

dbt test --select patients_engagement_reporting --target prod

## Commands to generate dbt docs and the lineage
dbt docs generate
dbt docs serve

## Current dbt structure for the casper project
dbt_casper/
│
├── models/
│   ├── casper_data_curated/
│   └── casper_data_reporting/
│   
├── macros/
├── seeds/
├── tests/
├── target/
├── dbt_project.yml
├── requirements.txt
└── README.md


### Requirements
Python 3.9+
BigQuery project
Service account with correct roles
Json key file

Note: Please provide your generated JSON key in the code to run the queries.