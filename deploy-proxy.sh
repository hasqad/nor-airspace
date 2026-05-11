#!/bin/bash
# Kjør i AWS CloudShell: https://console.aws.amazon.com/cloudshell
set -e

BUCKET="nor-airspace-hasqad"
FUNC="nor-airspace-proxy"
ROLE="nor-airspace-lambda-role"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "==> Lager Lambda-rolle"
aws iam create-role \
  --role-name "$ROLE" \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  --no-cli-pager 2>/dev/null || echo "   (rolle finnes allerede)"

aws iam attach-role-policy \
  --role-name "$ROLE" \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null || true

echo "   Venter på at rolle skal propagere..."
sleep 12

echo "==> Pakker Lambda-kode"
curl -s https://raw.githubusercontent.com/hasqad/nor-airspace/master/proxy/index.mjs \
  -o /tmp/index.mjs
cd /tmp && zip -q function.zip index.mjs

echo "==> Lager/oppdaterer Lambda-funksjon"
if aws lambda get-function --function-name "$FUNC" --no-cli-pager &>/dev/null; then
  aws lambda update-function-code \
    --function-name "$FUNC" \
    --zip-file fileb:///tmp/function.zip \
    --no-cli-pager
else
  aws lambda create-function \
    --function-name "$FUNC" \
    --runtime nodejs20.x \
    --role "arn:aws:iam::$ACCOUNT_ID:role/$ROLE" \
    --handler index.handler \
    --zip-file fileb:///tmp/function.zip \
    --timeout 15 \
    --memory-size 128 \
    --no-cli-pager

  echo "==> Aktiverer offentlig URL"
  aws lambda add-permission \
    --function-name "$FUNC" \
    --statement-id allow-public \
    --action lambda:InvokeFunctionUrl \
    --principal "*" \
    --function-url-auth-type NONE \
    --no-cli-pager

  aws lambda create-function-url-config \
    --function-name "$FUNC" \
    --auth-type NONE \
    --cors '{"AllowOrigins":["*"],"AllowMethods":["GET"],"AllowHeaders":["*"]}' \
    --no-cli-pager
fi

LAMBDA_URL=$(aws lambda get-function-url-config \
  --function-name "$FUNC" \
  --query FunctionUrl --output text)

echo "==> Lambda URL: $LAMBDA_URL"

echo "==> Laster ned og oppdaterer index.html"
curl -s https://raw.githubusercontent.com/hasqad/nor-airspace/master/index.html \
  -o /tmp/index.html

sed -i "s|REPLACE_WITH_LAMBDA_URL|${LAMBDA_URL}|g" /tmp/index.html

echo "==> Laster opp til S3"
aws s3 cp /tmp/index.html "s3://$BUCKET/index.html" \
  --content-type "text/html; charset=utf-8" \
  --cache-control "no-cache"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Ferdig! Refresh siden:"
echo "   http://$BUCKET.s3-website-us-east-1.amazonaws.com"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"