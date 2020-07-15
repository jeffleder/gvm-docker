# gvm-docker
GVM11 (OpenVAS) Docker Image

# Note:
This is a simplified version of https://github.com/immauss/openvas (which was sourced from https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker)

# Docker Hub
https://hub.docker.com/repository/docker/jleder/gvm-docker

## Deployment

**Install docker**

**Create a volume to store persistent data**
```shell
docker volume create openvas
```

**Run the container**
```shell
docker run --detach --publish 127.0.0.1:9392:9392 -e USERNAME="ENTER_USERNAME_HERE" -e PASSWORD="ENTER_PASSWORD_HERE" --volume openvas:/data --name openvas jleder/gvm-docker
```
You can use whatever `--name` you'd like but for the sake of this guide we're using openvas.

The `-p 127.0.0.1:9392:9392` switch will forward host port `9392` to container port `9392` (the GSA web interface port) in the docker container.
You can change the host port from `9392` to any available port that you'd like (e.g. `8080`).

Depending on your hardware, it can take anywhere from a few seconds to 10 minutes while the NVTs are scanned and the database is rebuilt. **The default admin user account is created after this process has completed. If you are unable to access the web interface, it means it is still loading (be patient).**

**Checking Deployment Progress**

There is no easy way to estimate the remaining NVT loading time, but you can check if the NVTs have finished loading by running:
```
docker logs openvas
```

If you see "Your GVM 11 container is now ready to use!" then, you guessed it, your container is ready to use.

## Accessing Web Interface

Access web interface using the IP address of the docker host on port 8080 - `http://<IP address>:8080`

Default credentials:
```
Username: admin
Password: admin
```

## Monitoring Scan Progress

This command will show you the GVM processes running inside the container:
```
docker top openvas
```

## Checking the GVM Logs

All the logs from /usr/local/var/log/gvm/* can be viewed by running:
```
docker logs openvas
```
Or you can follow the logs (like tail -f ) with:
```
docker logs -f openvas
```

## Updating NVT/SCAP/CERT Data
Autobuilds should bake this into the DockerHub image so that the latest builds have the most recent data
