#!/bin/bash

get_input() {
    local prompt="$1"
    local default_value="$2"
    
    if [ -n "$default_value" ]; then
        prompt="$prompt (default: $default_value): "
    else
        prompt="$prompt: "
    fi
    
    read -p "$prompt" input
    
    if [ -z "$input" ] && [ -n "$default_value" ]; then
        input="$default_value"
    fi
    
    echo "$input"
}

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    AWS_ACCESS_KEY_ID=$(get_input "AWS Access Key ID" "")
else
    AWS_ACCESS_KEY_ID=$(get_input "AWS Access Key ID" "$AWS_ACCESS_KEY_ID")
fi
echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> .env

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    AWS_SECRET_ACCESS_KEY=$(get_input "AWS Secret Access Key" "")
else
    AWS_SECRET_ACCESS_KEY=$(get_input "AWS Secret Access Key" "$AWS_SECRET_ACCESS_KEY")
fi
echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> .env

if [ -z "$AWS_ACCOUNT_ID" ]; then
    AWS_ACCOUNT_ID=$(get_input "AWS Account ID" "")
else
    AWS_ACCOUNT_ID=$(get_input "AWS Account ID" "$AWS_ACCOUNT_ID")
fi
echo "export AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID" >> .env

if [ -z "$AWS_SESSION_TOKEN" ]; then
    AWS_SESSION_TOKEN=$(get_input "AWS Session Token (leave blank if not needed)" "")
else
    AWS_SESSION_TOKEN=$(get_input "AWS Session Token" "$AWS_SESSION_TOKEN")
fi

if [ -n "$AWS_SESSION_TOKEN" ]; then
    echo "export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN" >> .env
fi

export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
export AWS_ACCOUNT_ID="$AWS_ACCOUNT_ID"
if [ -n "$AWS_SESSION_TOKEN" ]; then
    export AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN"
fi

mkdir -p ~/.aws
echo "[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" > ~/.aws/credentials

if [ -n "$AWS_SESSION_TOKEN" ]; then
    echo "aws_session_token = $AWS_SESSION_TOKEN" >> ~/.aws/credentials
fi

echo "[default]
region = us-west-2" > ~/.aws/config

echo "[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" > aws-creds.conf

if [ -n "$AWS_SESSION_TOKEN" ]; then
    echo "aws_session_token = $AWS_SESSION_TOKEN" >> aws-creds.conf
fi

kubectl --namespace default \
  create secret generic aws-creds \
  --from-file creds=./aws-creds.conf

cat <<EOF > aws-provider-config.yaml
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: default
      name: aws-creds
      key: creds
EOF

kubectl apply -f aws-provider-config.yaml

echo "AWS credentials have been set up, Kubernetes secret has been created, and AWS ProviderConfig has been applied."
