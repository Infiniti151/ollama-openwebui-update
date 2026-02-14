#!/usr/bin/env bash

# Color codes
CYAN='\033[36m'
GREEN='\033[32m'
RESET='\033[0m'

update_ollama_models(){
	[ $(systemctl is-active ollama) != "active" ] && sudo systemctl start ollama
	ollama list | awk 'NR>1 {print "----------'${CYAN}'Updating "$1"'${RESET}'----------";system("ollama pull "$1)}'
}

update_ollama(){
	[ $(systemctl is-active ollama) = "active" ] && sudo systemctl stop ollama
	curl -fsSL https://ollama.com/install.sh | sh &
}

update_openwebui(){
	docker ps -a | awk '/open-webui/ {print $1}' | xargs docker stop | xargs docker remove -f
	if docker pull ghcr.io/open-webui/open-webui:latest; then
		wait
		docker image prune -f
		docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:latest
		docker ps -a
	else
		echo "Failed to pull open-webui image"
		return 1
	fi
}

update(){
	echo -e "------------------${GREEN}Update Ollama Models${RESET}------------------"
	if command -v ollama &> /dev/null; then
		update_ollama_models
	else
		echo "Ollama is not installed"
	fi
	echo -e "------------------${GREEN}Update Ollama${RESET}-------------------------"
	[ $ollama_local_version != $ollama_latest_version ] && update_ollama || echo "No update available"
	echo -e "------------------${GREEN}Update Open WebUI${RESET}---------------------"
	[ $local_image_digest != $remote_image_digest ] && update_openwebui || echo "No update available"
}

ollama_latest_version=$(curl -s https://api.github.com/repos/ollama/ollama/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
ollama_local_version=$(ollama --version | awk '{print $4}')

if ! docker ps &> /dev/null; then
	docker_endpoint=$(docker context inspect -f '{{.Endpoints.docker.Host}}')
	echo "Docker is not running. Attempting to start Docker..."
	if [[ $docker_endpoint == "unix:///var/run/docker.sock" ]]; then
		sudo systemctl start docker 2>/dev/null
	elif [[ $docker_endpoint == "unix:///run/user/"* ]]; then
		systemctl --user start docker 2>/dev/null
	fi
fi
remote_image_digest=$(docker buildx imagetools inspect ghcr.io/open-webui/open-webui:latest | awk '/Digest/ {print $2}')
local_image_digest=$(docker image inspect ghcr.io/open-webui/open-webui:latest -f '{{.RepoDigests}}' | awk -F@ '{sub(/]/,"");print $2}')

update
