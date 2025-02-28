#!/bin/bash

function update_ollama_models(){
	[ $(systemctl is-active ollama) != "active" ] && sudo systemctl start ollama
	ollama list | awk 'NR>1 {print $1}' | xargs ollama pull
}

function ollama_update(){
	[ $(systemctl is-active ollama) = "active" ] && sudo systemctl stop ollama
	curl -fsSL https://ollama.com/install.sh | sh &
}

function openwebui_update(){
	[ $(systemctl is-active docker) != "active" ] && sudo systemctl start docker
	docker ps -a | awk '/open-webui/ {print $1}' | xargs docker stop | xargs docker remove -f
	docker pull ghcr.io/open-webui/open-webui:latest &
	wait
	docker image prune -f
	docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:latest
	docker ps -a
}

function update(){
	echo -e "------------------\e[32mUpdate Ollama Models\e[0m------------------"
	update_ollama_models
	echo -e "------------------\e[32mUpdate Ollama\e[0m-------------------------"
	if [ $ollama_local != $ollama_latest ];then
		ollama_update
	else
		echo "Ollama is the latest version"
	fi
	echo -e "------------------\e[32mUpdate Open WebUI\e[0m---------------------"
	if [ $local_image_digest != $remote_image_digest ];then
		openwebui_update
	else
		echo "Open WebUI is the latest version"
	fi
}

ollama_latest=$(git ls-remote -t https://github.com/ollama/ollama.git | awk -e '$2 !~ /rc|ci/ {sub(/refs\/tags\/v/,"");print $2}' | sort -V | awk 'END{print}')
ollama_local=$(ollama --version | awk '{print $4}')

remote_image_digest=$(regctl image digest ghcr.io/open-webui/open-webui:latest)
local_image_digest=$(docker image inspect ghcr.io/open-webui/open-webui:latest --format '{{.RepoDigests}}' | awk -F@ '{sub(/]/,"");print $2}')

update
