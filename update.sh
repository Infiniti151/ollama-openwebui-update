#!/usr/bin/env bash

# Color codes
RED='\033[31m'
GREEN='\033[32m'
CYAN='\033[36m'
RESET='\033[0m'

update_ollama_models(){
	echo -e "------------------${GREEN}Updating Ollama Models${RESET}------------------"
	sudo systemctl start ollama
	ollama list | awk 'NR>1 {print "----------'${CYAN}'Updating "$1"'${RESET}'----------";system("ollama pull "$1)}'
}

update_ollama(){
	echo -e "------------------${GREEN}Updating Ollama${RESET}-------------------------"
	if command -v ollama &> /dev/null; then
	    ollama_local_version=$(ollama --version | awk '{print $4}')
		ollama_latest_version=$(curl -s https://api.github.com/repos/ollama/ollama/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
		if [[ $ollama_local_version != $ollama_latest_version ]]; then
			echo "Updating Ollama from version $ollama_local_version to $ollama_latest_version..."
			[ $(systemctl is-active ollama) = "active" ] && sudo systemctl stop ollama
			curl -fsSL https://ollama.com/install.sh | sh &
		else
			echo "Ollama is already up to date (v$ollama_local_version)."
		fi
		update_ollama_models
	else
		echo -e "${RED}Ollama is not installed${RESET}"
	fi
}

update_openwebui(){
	echo -e "------------------${GREEN}Updating Open WebUI${RESET}---------------------"
	if command -v docker &> /dev/null; then
		if ! docker ps &> /dev/null; then
			docker_endpoint=$(docker context inspect -f '{{.Endpoints.docker.Host}}')
			echo "Docker is not running. Attempting to start Docker..."
			if [[ $docker_endpoint == "unix:///var/run/docker.sock" ]]; then
				sudo systemctl start docker 2>/dev/null
			elif [[ $docker_endpoint == "unix:///run/user/$(id -u)/docker.sock" ]]; then
				systemctl --user start docker 2>/dev/null
			elif [[ $docker_endpoint == "unix://$HOME/.docker/desktop/docker.sock" ]]; then
				systemctl --user start docker-desktop 2>/dev/null
			fi
		fi
		if docker image inspect ghcr.io/open-webui/open-webui:latest 2>&1 | grep -q "No such image";then
			echo -e "${RED}Open WebUI is not installed.${RESET}"
		else
			local_image_digest=$(docker image inspect ghcr.io/open-webui/open-webui:latest -f '{{.RepoDigests}}' | awk -F@ '{sub(/]/,"");print $2}')
			remote_image_digest=$(docker buildx imagetools inspect ghcr.io/open-webui/open-webui:latest | awk '/Digest/ {print $2}')
			if [[ $local_image_digest != $remote_image_digest ]]; then
				docker ps -a | awk '/open-webui/ {print $1}' | xargs docker stop | xargs docker remove -f
				if docker pull ghcr.io/open-webui/open-webui:latest; then
					wait
					docker image prune -f
					docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:latest
					docker ps -a
				else
					echo -e "${RED}Failed to pull open-webui image.${RESET}"
					return 1
				fi
			else
				echo "Open WebUI is already up to date."
			fi
		fi
	else
		echo -e "${RED}Docker is not installed.${RESET}"
	fi
}

update(){
	update_ollama
	update_openwebui
}

update
