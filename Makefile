.PHONY: init plan apply destroy push-to-ecr restart-podman psql local-server create-migration apply-migration-local \
		apply-migration-prod websocket-client generate-jwt update-ecs force-unlock fmt

BASTION_IP=34.220.2.72
DB_HOST=stripe-sync-db.cdvkwvsdgtlm.us-west-2.rds.amazonaws.com
ALB_URL=stripe-sync-service-alb-394896623.us-west-2.elb.amazonaws.com
JWT_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0LXVzZXIiLCJleHAiOjE3NTMxMzE3OTB9.LjSCtX0uVrdDFbW5DmKh-j7Ng66jRMhuor0MYkUYMrE


# Terraform commands using the terraform.sh wrapper
init:
	./terraform.sh init -reconfigure

plan:
	./terraform.sh plan -var-file=secrets.tfvars

apply:
	./terraform.sh apply -var-file=secrets.tfvars -auto-approve

destroy:
	./terraform.sh destroy -var-file=secrets.tfvars -auto-approve

fmt:
	./terraform.sh fmt

force-unlock:
	./terraform.sh force-unlock 3d5e5710-fb01-4fd5-c6ca-81036567d712

# AWS CLI commands to update ECS service
update-ecs: push-to-ecr
	aws ecs update-service --cluster stripe-sync-cluster --service stripe-sync-service --force-new-deployment --profile my-personal   --query "service.events[?contains(message, 'has started')].message" --output text


# Push Docker image to ECR using the push-to-ecr.sh wrapper
push-to-ecr:
	./push-to-ecr.sh

# Restart Podman machine
restart-podman:
	podman machine stop && podman machine start

# Connect to Postgres using psql
psql:
	psql "host=$(DB_HOST) port=5432 dbname=stripe_db user=postgres password=postgres"

local-server:
	podman compose up

create-migration:
	podman exec -it stripe-sync sh -c 'alembic revision -m "migration" --rev-id $$(date +%Y%m%d%H%M%S)'

apply-migration-local:
	podman exec -it stripe-sync alembic upgrade head

apply-migration-prod:
	podman exec -it stripe-sync alembic -x db_url=postgresql+psycopg2://postgres:postgres@$(DB_HOST)/stripe_db upgrade head

websocket-client-broadcast:
	websocat "ws://$(ALB_URL)/ws?token=$(JWT_TOKEN)&broadcast=true"

websocket-client:
	websocat "ws://$(ALB_URL)/ws?token=$(JWT_TOKEN)"

generate-jwt:
	podman exec -it stripe-sync python utility/generate_jwt.py

build-terraform-image:
	cd terraform && podman build -t terraform-stripe-sync-srvice:latest .

ssh:
	ssh ubuntu@$(BASTION_IP)

