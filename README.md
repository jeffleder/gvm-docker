# GVM-Docker
This is a GVM11 (OpenVAS) Docker Image intended for one-off scans.
Inspiration for this repo comes from the following:
* https://github.com/immauss/openvas
* https://kifarunix.com/install-and-setup-gvm-11-on-ubuntu-20-04/

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
docker run -d -p 127.0.0.1:9392:9392 -e USERNAME="admin" -e PASSWORD="admin" --volume openvas:/opt/gvm --name openvas --restart unless-stopped jeffleder/gvm-docker
```
# Deployment Notes
* The `-d` switch will run the container in a detached state
* The `-p 127.0.0.1:9392:9392` switch will forward host port `9392` to container port `9392` (the GSA web GUI port)
   * You can change the host port from `9392` to any available port that you'd like (e.g. `8080`)
   * The `127.0.0.1` part of the `-p 127.0.0.1:9392:9392` switch will force GSA to only listen for localhost connections
* The `-e USERNAME="admin"` switch allows you to sepcify a username to log into the GSAD web GUI with
* The `-e PASSWORD="admin"` switch allows you to sepcify a password to log into the GSAD web GUI with
* The `-e PASSWORD="admin"` switch allows you to sepcify a password to log into the GSAD web GUI with
* The `--name` switch allows you to specify whatever freindly name you want for the container (this guide uses `openvas` throughout)
* The `--restart unless-stopped` switch daemonizes the container (so it will restart on crash and/or system reboots)
* The last `jeffleder/gvm-docker` item specifies the image to pull and run for the container

# Deployment Status Checks
You can verify that the container has completed loading by running:
```
docker logs openvas
```
If you see `Your GVM 11 container is now ready to use!`, the container is ready to use.

# Accessing the Web GUI
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
All the logs from /opt/gvm/var/log/gvm* can be viewed by running:
```
docker logs openvas
```

# Updating NVT/SCAP/CERT Data
Autobuilds should bake NVT/SCAP/CERT Data into the DockerHub image so that the latest builds have the most recent data
