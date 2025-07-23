FROM hashicorp/terraform:1.12.1

# Install AWS CLI v1 from Alpine repos
RUN apk add --no-cache aws-cli

WORKDIR /workspace

CMD ["terraform", "--version"]