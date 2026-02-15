#!/usr/bin/env bash

# Color codes
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
RESET='\033[0m'

update_ollama_models(){
	echo -e "------------------${YELLOW}Updating Ollama Models${RESET}------------------"
	echo "Starting Ollama service..." && sudo systemctl start ollama
	ollama list | awk 'NR>1 {print $1}' | while read model; do
		model_name="${model%:*}"
		tag="${model#*:}"		
		local_digest=$(ollama list | grep "^$model" | awk '{print $2}')
		remote_digest=$(curl -s -I -L -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
			"https://registry.ollama.ai/v2/library/$model_name/manifests/$tag" \
			| grep -i "ollama-content-digest" | awk '{print $2}' | cut -c 1-12)
		if [[ -n "$remote_digest" ]]; then
			if [[ "$local_digest" != "$remote_digest" ]]; then
				echo -e "---------${CYAN}Updating $model${RESET}---------"
				ollama pull "$model"
			else
				echo -e "${GREEN}$model is already up to date.${RESET}"
			fi
		else
			echo -e "${RED}Could not fetch remote digest for $model${RESET}"
		fi
	done
}

update_ollama(){
	echo -e "------------------${YELLOW}Updating Ollama${RESET}-------------------------"
	if command -v ollama &> /dev/null; then
	    ollama_local_version=$(ollama --version | awk '{print $4}')
		ollama_latest_version=$(curl -s https://api.github.com/repos/ollama/ollama/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
		install_ollama='curl -fsSL https://ollama.com/install.sh | sh &'
		if [[ $ollama_local_version != $ollama_latest_version ]]; then
		    [ $(systemctl is-active ollama) = "active" ] && echo "Stopping Ollama service..." && sudo systemctl stop ollama
			echo -e "Updating Ollama from version ${RED}$ollama_local_version${RESET} to ${GREEN}$ollama_latest_version${RESET}..."
			eval $install_ollama
		else
			echo -e "${GREEN}Ollama is already up to date (v$ollama_local_version).${RESET}"
		fi
		wait
		update_ollama_models
	else
		echo -e "${RED}Ollama is not installed.${RESET}"
		echo "Installing Ollama..."
		eval $install_ollama
	fi
}

update_openwebui(){
	echo -e "------------------${YELLOW}Updating Open WebUI${RESET}---------------------"
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
		image_name=$(docker ps --format '{{.Image}}' | grep 'open-webui' | head -n1)
		start_container='docker run -d --network=host \
			-e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
			-v open-webui:/app/backend/data \
			--name open-webui \
			--restart always \
			'"$image_name"
		if docker image inspect $image_name 2>&1 | grep -q "No such image";then
			echo -e "${RED}Open WebUI is not installed.${RESET}"
			echo "Installing Open WebUI..."
			eval $start_container
		else
			local_image_digest=$(docker image inspect $image_name -f '{{.RepoDigests}}' | awk -F@ '{sub(/]/,"");print $2}')
			remote_image_digest=$(docker buildx imagetools inspect $image_name | awk '/Digest/ {print $2}')
			if [[ $local_image_digest != $remote_image_digest ]]; then
				if docker pull $image_name; then
				    echo "Stopping Open WebUI container..."
					docker stop $(docker ps -a -q --filter "ancestor=$image_name") &>/dev/null
					echo "Removing Open WebUI container..."
					docker rm $(docker ps -a -q --filter "ancestor=$image_name") &>/dev/null
					echo "Cleaning dangling images..."
					docker image prune -f &>/dev/null
					echo "Starting new Open WebUI container..."
					eval $start_container
					docker ps
				else
					echo -e "${RED}Failed to pull open-webui image.${RESET}"
					return 1
				fi
			else
				echo -e "${GREEN}Open WebUI is already up to date.${RESET}"
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
