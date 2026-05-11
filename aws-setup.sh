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

echo "==> Laster opp index.html"
aws s3 cp /dev/stdin "s3://$BUCKET/index.html" \
  --content-type "text/html; charset=utf-8" \
  --cache-control "max-age=300" < /dev/null || true

echo "==> Lager IAM-bruker med minimumsrettigheter"
aws iam create-user --user-name "$USERNAME"
aws iam put-user-policy \
  --user-name "$USERNAME" \
  --policy-name "nor-airspace-deploy" \
  --policy-document "{
    \"Version\":\"2012-10-17\",
    \"Statement\":[{
      \"Effect\":\"Allow\",
      \"Action\":[\"s3:PutObject\",\"s3:GetObject\",\"s3:ListBucket\"],
      \"Resource\":[
        \"arn:aws:s3:::$BUCKET\",
        \"arn:aws:s3:::$BUCKET/*\"
      ]
    }]
  }"

echo "==> Lager access keys"
KEYS=$(aws iam create-access-key --user-name "$USERNAME")
KEY_ID=$(echo "$KEYS"     | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['AccessKeyId'])")
KEY_SECRET=$(echo "$KEYS" | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['SecretAccessKey'])")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Ferdig!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌍 URL: http://$BUCKET.s3-website-$REGION.amazonaws.com"
echo ""
echo "Gå til: github.com/hasqad/nor-airspace/settings/secrets/actions"
echo "Legg til disse 3 secrets:"
echo ""
echo "  AWS_ACCESS_KEY_ID      =  $KEY_ID"
echo "  AWS_SECRET_ACCESS_KEY  =  $KEY_SECRET"
echo "  S3_BUCKET              =  $BUCKET"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"