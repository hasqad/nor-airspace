#!/bin/bash
# Kjør dette i AWS CloudShell: https://console.aws.amazon.com/cloudshell
set -e

BUCKET="nor-airspace-hasqad"
REGION="us-east-1"
USERNAME="nor-airspace-deploy"

echo "==> Lager S3-bucket: $BUCKET"
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION"

echo "==> Konfigurerer statisk hosting"
aws s3api put-bucket-website \
  --bucket "$BUCKET" \
  --website-configuration '{"IndexDocument":{"Suffix":"index.html"},"ErrorDocument":{"Key":"index.html"}}'

echo "==> Åpner for public read"
aws s3api delete-public-access-block --bucket "$BUCKET"
aws s3api put-bucket-policy \
  --bucket "$BUCKET" \
  --policy "{
    \"Version\":\"2012-10-17\",
    \"Statement\":[{
      \"Effect\":\"Allow\",
      \"Principal\":\"*\",
      \"Action\":\"s3:GetObject\",
      \"Resource\":\"arn:aws:s3:::$BUCKET/*\"
    }]
  }"

echo "==> Lager CloudFront-distribusjon"
CF_OUTPUT=$(aws cloudfront create-distribution --distribution-config "{
  \"CallerReference\":\"nor-airspace-$(date +%s)\",
  \"Comment\":\"NOR AIRSPACE\",
  \"Enabled\":true,
  \"PriceClass\":\"PriceClass_100\",
  \"DefaultRootObject\":\"index.html\",
  \"Origins\":{
    \"Quantity\":1,
    \"Items\":[{
      \"Id\":\"s3-origin\",
      \"DomainName\":\"$BUCKET.s3-website-$REGION.amazonaws.com\",
      \"CustomOriginConfig\":{
        \"HTTPPort\":80,\"HTTPSPort\":443,
        \"OriginProtocolPolicy\":\"http-only\"
      }
    }]
  },
  \"DefaultCacheBehavior\":{
    \"TargetOriginId\":\"s3-origin\",
    \"ViewerProtocolPolicy\":\"redirect-to-https\",
    \"CachePolicyId\":\"658327ea-f89d-4fab-a63d-7e88639e58f6\",
    \"Compress\":true
  }
}")

CF_ID=$(echo "$CF_OUTPUT"     | python3 -c "import sys,json; print(json.load(sys.stdin)['Distribution']['Id'])")
CF_DOMAIN=$(echo "$CF_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['Distribution']['DomainName'])")

echo "==> Lager IAM-bruker med minimumsrettigheter"
aws iam create-user --user-name "$USERNAME"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws iam put-user-policy \
  --user-name "$USERNAME" \
  --policy-name "nor-airspace-deploy" \
  --policy-document "{
    \"Version\":\"2012-10-17\",
    \"Statement\":[
      {
        \"Effect\":\"Allow\",
        \"Action\":[\"s3:PutObject\",\"s3:GetObject\",\"s3:ListBucket\"],
        \"Resource\":[
          \"arn:aws:s3:::$BUCKET\",
          \"arn:aws:s3:::$BUCKET/*\"
        ]
      },
      {
        \"Effect\":\"Allow\",
        \"Action\":\"cloudfront:CreateInvalidation\",
        \"Resource\":\"arn:aws:cloudfront::$ACCOUNT_ID:distribution/$CF_ID\"
      }
    ]
  }"

echo "==> Lager access keys"
KEYS=$(aws iam create-access-key --user-name "$USERNAME")
KEY_ID=$(echo "$KEYS"     | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['AccessKeyId'])")
KEY_SECRET=$(echo "$KEYS" | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['SecretAccessKey'])")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ AWS-oppsett ferdig!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌍 URL: https://$CF_DOMAIN"
echo "   (CloudFront bruker ~10 min på å starte første gang)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Gå til: github.com/hasqad/nor-airspace/settings/secrets/actions"
echo "Legg til disse 4 secrets:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  AWS_ACCESS_KEY_ID       =  $KEY_ID"
echo "  AWS_SECRET_ACCESS_KEY   =  $KEY_SECRET"
echo "  S3_BUCKET               =  $BUCKET"
echo "  CF_DISTRIBUTION_ID      =  $CF_ID"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"