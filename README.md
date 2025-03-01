# ollama-openwebui-update

Bash script to easily update Ollama models, Ollama, and Open WebUI in Linux

## What does the script do?
1. Updates all downloaded Ollama models
2. Checks if the latest version of Ollama is installed. If not, installs/updates Ollama through the official install/update script
3. Checks if the latest version of Open WebUI image (ghcr.io/open-webui/open-webui:latest) exists in Docker. If not, pulls the latest image and starts a container at localhost:8080

## How to use?
Make sure the dependencies are installed on your system.
1. git clone https://github.com/Infiniti151/ollama-openwebui-update.git && cd ollama-openwebui-update
2. chmod +x update.sh
3. ./update.sh

## Dependencies
1. [Docker](https://docs.docker.com/get-started/get-docker/): To update Open WebUI docker image
2. [Regctl](https://github.com/regclient/regclient/blob/main/docs/install.md): To get image digest of remote image

## Output
![alt text](image.png)
