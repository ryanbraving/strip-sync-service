#!/bin/bash
podman run --rm -it \
  -v "$(pwd):/workspace" \
  -v "$HOME/.aws:/root/.aws" \
  -v /etc/localtime:/etc/localtime:ro \
  -e AWS_PROFILE=my-personal \
  terraform-stripe-sync-srvice:latest "$@"