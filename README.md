# ollama-openwebui-update

Bash script to easily update Ollama, Ollama models, and Open WebUI (installed via Docker) in Linux

## What does the script do?
1. Updates Ollama via the official script if there is an update in the GitHub repo
2. Updates all downloaded Ollama models if they have an update in the Ollama registry
3. Updates Open WebUI via Docker if there is an update in the registry

**Note:** If Ollama and Open WebUI are not already installed, they are installed by this script. This script doesn't update Open WebUI installed via Pip/Kubernetes(Helm)/Portainer/Umbrel/CasaOS.

## How to use?
```
git clone https://github.com/Infiniti151/ollama-openwebui-update.git
cd ollama-openwebui-update
chmod +x ./update.sh
bash ./update.sh
```

## Output
![alt text](image.png)
