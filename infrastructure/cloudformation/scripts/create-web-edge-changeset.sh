#!/usr/bin/env bash
set -euo pipefail

# with this script we're using CloudFormation to create the stack and the change set, but we're not executing it
# we're just creating the change set and we're gonna execute it later
# this is useful because we can review the changes before executing them
# and we can also execute them in a different time

# for each tool the state is store differently and this changes the way we work with the tools
# for example, with Terraform we can use the local state file to store the state of the infrastructure
# with CloudFormation we can use the AWS CloudFormation service to store the state of the infrastructure
# so, in a way, the state is stored in the tool itself
# of course when using Terraform and AWS/S3, we can store the state in a remote state file, but this is not the default behavior
# in that sense i guess it would be more a decision of the teams and their expertise. If the main cloud provider is AWS, of course 
# it can be a good idea to use the native tool for the job, but if the team is more comfortable with Terraform, it can be a good idea to use it.
# and if it's another provider Terraform is also a great choice and especially if it's multicloud.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template_file="${script_dir}/../web-edge.yaml"

set -a
source "${script_dir}/../../../.env"
set +a

profile="${AWS_PROFILE:-devops-curso}"
region="${AWS_REGION:-us-east-1}"
stack_name="${STACK_NAME:-web-edge-sandbox-2}"
domain_name="${DOMAIN_NAME:?set DOMAIN_NAME in .env}"
bucket_name="${BUCKET_NAME:?set BUCKET_NAME in .env}"
dns_name="${DNS_NAME:?set DNS_NAME in .env}"

cache_policy_id="$(
  aws cloudfront list-cache-policies \
    --type managed \
    --profile "${profile}" \
    --query "CachePolicyList.Items[?CachePolicy.CachePolicyConfig.Name=='Managed-CachingOptimized'].CachePolicy.Id | [0]" \
    --output text
)"

hosted_zone_id="$(
  aws route53 list-hosted-zones-by-name \
    --dns-name "${dns_name}" \
    --profile "${profile}" \
    --query "HostedZones[?Name=='${dns_name}.'].Id | [0]" \
    --output text
)"
hosted_zone_id="${hosted_zone_id#/hostedzone/}"

if [[ -z "${cache_policy_id}" || "${cache_policy_id}" == "None" ]]; then
  echo "Managed-CachingOptimized cache policy was not found." >&2
  exit 1
fi

if [[ -z "${hosted_zone_id}" || "${hosted_zone_id}" == "None" ]]; then
  echo "No hosted zone named ${dns_name}." >&2
  exit 1
fi

echo "CachePolicyId=${cache_policy_id}"
echo "HostedZoneId=${hosted_zone_id}"
echo "Creating change set ${stack_name} without executing it."

aws cloudformation deploy \
  --template-file "${template_file}" \
  --stack-name "${stack_name}" \
  --region "${region}" \
  --profile "${profile}" \
  --no-execute-changeset \
  --parameter-overrides \
    "DomainName=${domain_name}" \
    "HostedZoneId=${hosted_zone_id}" \
    "BucketName=${bucket_name}" \
    "CachePolicyId=${cache_policy_id}"