#!/bin/bash
podman run --rm -it \
  -v "$(pwd)/terraform:/workspace" \
  -v "$HOME/.aws:/root/.aws" \
  -e AWS_PROFILE=my-personal \
  terraform-stripe-sync-srvice:latest "$@"