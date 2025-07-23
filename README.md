https://hoppscotch.io/realtime/websocket

./terraform.sh apply -var-file=secrets.tfvars

./terraform.sh force-unlock fa5eac21-75c6-5d63-8eff-6da62199b6c4

 curl ifconfig.me
 

 podman exec -it stripe-sync bash

WebSocket Clients
brew install websocat
websocat ws://stripe-sync-service-alb-637805745.us-west-2.elb.amazonaws.com/ws
 

if  you see this:
validating provider credentials: retrieving caller identity from STS: operation error STS: GetCallerIdentity
on macOS, Podman (or Docker) runs containers inside a Linux VM. If the VM's clock drifts (often after your Mac sleeps), new containers inherit the VM's incorrect time.
to fix this, restart Podman/Docker Desktop to resync the VM's clock with your Mac:
podman machine stop && podman machine start



podman machine stop
podman machine rm -f
podman machine init --cpus 4 --memory 12288
podman machine start

#Migration
alembic revision --autogenerate -m "your migration message"
alembic upgrade head


Connecting to Database in docker:
podman exec -it stripe-postgres bash
psql -h stripe-postgres -U postgres -d stripe_db -p 5432


alembic -x db_url=postgresql+psycopg2://postgres:postgres@stripe-sync-db.cdvkwvsdgtlm.us-west-2.rds.amazonaws.com:5432/stripe_db upgrade head