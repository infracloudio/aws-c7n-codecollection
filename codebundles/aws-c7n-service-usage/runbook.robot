*** Settings ***
Metadata            Author   saurabh3460
Metadata            Supports    AWS    Tag    CloudCustodian
Metadata            Display Name    AWS network health
Documentation        List AWS Service Usage Exceeding defined threshold
Force Tags    Tag    AWS    usage

Library    RW.Core
Library    RW.CLI
Library    CloudCustodian.Core
Library    Util.py
Suite Setup    Suite Initialization


*** Tasks ***
List AWS Service Usage Exceeding defined threshold
    [Documentation]  List AWS services where usage exceeds a specified usage percentage
    [Tags]    aws    service    usage
    ${result}=    CloudCustodian.Core.Generate Policy   
    ...    ${CURDIR}/service-usage.j2
    ...    usage_percent=${USAGE_PERCENTAGE}
    ...    resource_providers=${AWS_RESOURCE_PROVIDERS}
    ${c7n_output}=    RW.CLI.Run Cli
    ...    cmd=custodian run -r ${AWS_REGION} --output-dir ${OUTPUT_DIR}/aws-c7n-service-usage ${CURDIR}/service-usage.yaml --cache-period 0 2> ${CURDIR}/service-usage.log
    ...    secret__aws_access_key_id=${AWS_ACCESS_KEY_ID}
    ...    secret__aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}

    ${report_data}=     PARSE CUSTODIAN LOG    ${CURDIR}/service-usage.log    0
    
    ${resource_list}    Set Variable    ${report_data['data']}

    Log    ${report_data['data']}
    RW.Core.Add Pre To Report    ${report_data['report_table']}

    IF    len(@{resource_list}) > 0
        FOR    ${item}    IN    @{resource_list}
            ${pretty_item}=    Evaluate    pprint.pformat(${item})    modules=pprint
            Log    ${item[3]}
            # RW.Core.Add Issue        
            # ...    severity=3
            # ...    expected=AWS Service `${item['Service']}` in AWS Account `${AWS_ACCOUNT_ID}` should not exceed usage threshold
            # ...    actual=AWS Service `${item['Service']}` in AWS Account `${AWS_ACCOUNT_ID}` exceeds usage threshold
            # ...    title=High usage detected for AWS Service `${item['Service']}` in AWS Account `${AWS_ACCOUNT_ID}`
            # ...    reproduce_hint=${c7n_output.cmd}
            # ...    details=${pretty_item}
            # ...    next_steps=Review and optimize usage for AWS Service `${item['Service']}` in AWS Account `${AWS_ACCOUNT_ID}`
        END
    END

** Keywords ***
Suite Initialization
    ${AWS_REGION}=    RW.Core.Import User Variable    AWS_REGION
    ...    type=string
    ...    description=AWS Region
    ...    pattern=\w*
    ${AWS_ACCOUNT_ID}=    RW.Core.Import User Variable   AWS_ACCOUNT_ID
    ...    type=string
    ...    description=AWS Account ID
    ...    pattern=\w*
    ${AWS_ACCESS_KEY_ID}=    RW.Core.Import Secret   AWS_ACCESS_KEY_ID
    ...    type=string
    ...    description=AWS Access Key ID
    ...    pattern=\w*
    ${AWS_SECRET_ACCESS_KEY}=    RW.Core.Import Secret   AWS_SECRET_ACCESS_KEY
    ...    type=string
    ...    description=AWS Access Key Secret
    ...    pattern=\w*
    ${AWS_RESOURCE_PROVIDERS}=    RW.Core.Import User Variable    AWS_RESOURCE_PROVIDERS
    ...    type=string
    ...    description=Comma-separated list of AWS Resource Providers
    ...    pattern=^[a-zA-Z0-9,]+$
    ...    example=ec2,firehose,lambda,logs,monitoring,rds,servicequotas,ssm,fargate,kms
    ...    default=ec2,firehose
    ${USAGE_PERCENTAGE}=    RW.Core.Import User Variable    USAGE_PERCENTAGE
    ...    type=number
    ...    description=Usage threshold percentage
    ...    pattern=\d*
    ...    example=80
    ...    default=20
    ${clean_workding_dir}=    RW.CLI.Run Cli    cmd=rm -rf ${OUTPUT_DIR}/aws-c7n-network-health         # Note: Clean out the cloud custoding report dir to ensure accurate data
    ${AWS_ENABLED_REGIONS}=    RW.CLI.Run Cli
    ...    cmd=aws ec2 describe-regions --region ${AWS_REGION} --query 'Regions[*].RegionName' --output json
    ...    secret__aws_access_key_id=${AWS_ACCESS_KEY_ID}
    ...    secret__aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
    ${AWS_ENABLED_REGIONS}=    Evaluate    json.loads(r'''${AWS_ENABLED_REGIONS.stdout}''')    json
    Set Suite Variable    ${AWS_ENABLED_REGIONS}    ${AWS_ENABLED_REGIONS}
    Set Suite Variable    ${AWS_REGION}    ${AWS_REGION}
    Set Suite Variable    ${AWS_ACCOUNT_ID}    ${AWS_ACCOUNT_ID}
    Set Suite Variable    ${AWS_ACCESS_KEY_ID}    ${AWS_ACCESS_KEY_ID}
    Set Suite Variable    ${AWS_SECRET_ACCESS_KEY}    ${AWS_SECRET_ACCESS_KEY}