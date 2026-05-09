function dcr-start --wraps='sudo systemctl start docker' --description 'alias dcr-start=sudo systemctl start docker'
    sudo systemctl start docker $argv
end
