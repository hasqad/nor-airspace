#!/bin/bash
# Kjør dette EN gang etter at du har gjort: aws configure
# Lager S3-bucket, CloudFront-distribusjon og IAM-bruker for GitHub Actions
set -e

BUCKET="nor-airspace-hasqad"
REGION="us-east-1"
USERNAME="nor-airspace-deploy"

echo "==> Lager S3-bucket: $BUCKET"
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION"

echo "==> Konfigurerer S3 for statisk nettsidehosting"
aws s3api put-bucket-website \
  --bucket "$BUCKET" \
  --website-configuration '{"IndexDocument":{"Suffix":"index.html"},"ErrorDocument":{"Key":"index.html"}}'

echo "==> Fjerner public-access-block"
aws s3api delete-public-access-block --bucket "$BUCKET"

echo "==> Setter bucket policy (public read)"
aws s3api put-bucket-policy \
  --bucket "$BUCKET" \
  --policy "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Effect\": \"Allow\",
      \"Principal\": \"*\",
      \"Action\": \"s3:GetObject\",
      \"Resource\": \"arn:aws:s3:::$BUCKET/*\"
    }]
  }"

echo "==> Lager CloudFront-distribusjon"
CF_OUTPUT=$(aws cloudfront create-distribution --distribution-config "{
  \"CallerReference\": \"nor-airspace-$(date +%s)\",
  \"Comment\": \"NOR AIRSPACE\",
  \"Enabled\": true,
  \"PriceClass\": \"PriceClass_100\",
  \"DefaultRootObject\": \"index.html\",
  \"Origins\": {
    \"Quantity\": 1,
    \"Items\": [{
      \"Id\": \"s3-origin\",
      \"DomainName\": \"$BUCKET.s3-website-$REGION.amazonaws.com\",
      \"CustomOriginConfig\": {
        \"HTTPPort\": 80,
        \"HTTPSPort\": 443,
        \"OriginProtocolPolicy\": \"http-only\"
      }
    }]
  },
  \"DefaultCacheBehavior\": {
    \"TargetOriginId\": \"s3-origin\",
    \"ViewerProtocolPolicy\": \"redirect-to-https\",
    \"CachePolicyId\": \"658327ea-f89d-4fab-a63d-7e88639e58f6\",
    \"Compress\": true
  }
}")

CF_ID=$(echo "$CF_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['Distribution']['Id'])")
CF_DOMAIN=$(echo "$CF_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['Distribution']['DomainName'])")

echo "==> Lager IAM-bruker: $USERNAME"
aws iam create-user --user-name "$USERNAME"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "==> Setter minimumsrettigheter for deploy"
aws iam put-user-policy \
  --user-name "$USERNAME" \
  --policy-name "nor-airspace-deploy-policy" \
  --policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Effect\": \"Allow\",
        \"Action\": [\"s3:PutObject\", \"s3:GetObject\", \"s3:ListBucket\"],
        \"Resource\": [
          \"arn:aws:s3:::$BUCKET\",
          \"arn:aws:s3:::$BUCKET/*\"
        ]
      },
      {
        \"Effect\": \"Allow\",
        \"Action\": \"cloudfront:CreateInvalidation\",
        \"Resource\": \"arn:aws:cloudfront::$ACCOUNT_ID:distribution/$CF_ID\"
      }
    ]
  }"

echo "==> Lager access keys"
KEYS=$(aws iam create-access-key --user-name "$USERNAME")
KEY_ID=$(echo "$KEYS" | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['AccessKeyId'])")
KEY_SECRET=$(echo "$KEYS" | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['SecretAccessKey'])")

echo ""
echo "✅ ALT KLART!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  S3 bucket:          $BUCKET"
echo "  CloudFront ID:      $CF_ID"
echo "  CloudFront URL:     https://$CF_DOMAIN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Legger secrets til GitHub automatisk..."

GH=/opt/homebrew/bin/gh
$GH secret set AWS_ACCESS_KEY_ID    --repo hasqad/nor-airspace --body "$KEY_ID"
$GH secret set AWS_SECRET_ACCESS_KEY --repo hasqad/nor-airspace --body "$KEY_SECRET"
$GH secret set S3_BUCKET            --repo hasqad/nor-airspace --body "$BUCKET"
$GH secret set CF_DISTRIBUTION_ID   --repo hasqad/nor-airspace --body "$CF_ID"

echo ""
echo "✅ GitHub secrets er satt!"
echo "✅ Push til master for å deploye."
echo ""
echo "🌍 Nettstedet ditt: https://$CF_DOMAIN"
echo "   (CloudFront tar ~10 min å starte opp første gang)"