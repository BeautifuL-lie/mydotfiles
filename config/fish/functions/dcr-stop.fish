function dcr-stop --wraps='sudo systemctl stop docker.socket docker.service' --description 'alias dcr-stop=sudo systemctl stop docker.socket docker.service'
    sudo systemctl stop docker.socket docker.service $argv
end
