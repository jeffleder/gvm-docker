# gvm-docker
GVM11 (OpenVAS) Docker Image

# Note
This is a simplified version of https://github.com/immauss/openvas intended for one-off scans

# Docker Hub
https://hub.docker.com/repository/docker/jeffleder/gvm-docker

# Deployment
1. Install Docker (see https://docs.docker.com/engine/install/debian/ for debian)
2. Create a volume to store persistent data
```shell
docker volume create openvas
```
3. Run the container
```shell
docker run --detach --publish 127.0.0.1:9392:9392 -e USERNAME="ENTER_USERNAME_HERE" -e PASSWORD="ENTER_PASSWORD_HERE" --volume openvas:/data --name openvas jleder/gvm-docker
```
# Deployment Notes
You can use whatever `--name` you want for container but in this guide we're using `openvas`.
The `-p 127.0.0.1:9392:9392` switch will forward host port `9392` to container port `9392` (the GSA web interface port) in the docker container.
You can change the host port from `9392` to any available port that you'd like (e.g. `8080`).

The `127.0.0.1` portion of the `-p 127.0.0.1:9392:9392` switch will force GSA to only listen for localhost connections.

# Deployment Status Checks

You can verify that the container has completed loading by running:
```
docker logs openvas
```
If you see `Your GVM 11 container is now ready to use!`, the container is ready to use.

# Accessing Web Interface

Access the web interface from the docker host via `http://127.0.0.1:9392`

Default Credentials:
```
Username: admin
Password: admin
```
# Monitoring Scan Progress

This command will show you the GVM processes running inside the container:
```
docker top openvas
```

# Checking the GVM Logs

All the logs from /usr/local/var/log/gvm/* can be viewed by running:
```
docker logs openvas
```
Or you can follow the logs (like tail -f ) with:
```
docker logs -f openvas
```

# Updating NVT/SCAP/CERT Data
Autobuilds should bake this into the DockerHub image so that the latest builds have the most recent data
