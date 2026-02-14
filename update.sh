#!/bin/bash

update_ollama_models(){
	[ $(systemctl is-active ollama) != "active" ] && sudo systemctl start ollama
	ollama list | awk 'NR>1 {print "----------\033[36mUpdating "$1"\033[0m----------";system("ollama pull "$1)}'
}

update_ollama(){
	[ $(systemctl is-active ollama) = "active" ] && sudo systemctl stop ollama
	curl -fsSL https://ollama.com/install.sh | sh &
}

update_openwebui(){
	docker ps -a | awk '/open-webui/ {print $1}' | xargs docker stop | xargs docker remove -f
	docker pull ghcr.io/open-webui/open-webui:latest &
	wait
	docker image prune -f
	docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:latest
	docker ps -a
}

update(){
	echo -e "------------------\e[32mUpdate Ollama Models\e[0m------------------"
	update_ollama_models
	echo -e "------------------\e[32mUpdate Ollama\e[0m-------------------------"
	[ $ollama_local_version != $ollama_latest_version ] && update_ollama || echo "No update available for Ollama"
	echo -e "------------------\e[32mUpdate Open WebUI\e[0m---------------------"
	[ $local_image_digest != $remote_image_digest ] && update_openwebui || echo "No update available for Open WebUI"
}

ollama_latest_version=$(curl -s https://api.github.com/repos/ollama/ollama/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
ollama_local_version=$(ollama --version | awk '{print $4}')

[ $(systemctl is-active docker) != "active" ] && sudo systemctl start docker
remote_image_digest=$(docker buildx imagetools inspect ghcr.io/open-webui/open-webui:latest | awk '/Digest/ {print $2}')
local_image_digest=$(docker image inspect ghcr.io/open-webui/open-webui:latest -f '{{.RepoDigests}}' | awk -F@ '{sub(/]/,"");print $2}')

update
