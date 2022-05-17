#!/bin/bash

GREEN=$'\e[0;32m'
RED=$'\e[0;31m'
NC=$'\e[0m'

NODE_CONTAINER='mock-deploy_nodeserver_1'
NGINX_CONTAINER='mock-deploy_nginx_1'

NODE_REGISTRY='ghcr.io/joaomouraosa/mock_nodeserver:latest'
NGINX_REGISTRY='ghcr.io/joaomouraosa/mock_nginx:latest'

REPO="joaomouraosa/mock-deploy.git"
TOKEN="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"


test() {
    URLs=('http://localhost:5000' 'http://localhost:80' 'http://localhost' 'http://fastfix.shop' 'http://www.fastfix.shop' 'https://fastfix.shop' 'https://www.fastfix.shop')
    for URL in ${URLs[@]}; do
        result=`curl -s -o /dev/null -w "%{http_code}" --max-time 3 $URL`
        if [ $result == "200" ]; then
            echo $URL ${GREEN} 'Success' ${NC}
        else
            echo $URL ${RED} 'Failed' ${NC}
        fi
    done
}

# sudo docker container prune  # remove stopped containers
# sudo docker image ls | tr -s ' ' | cut -d " " -f 3 | sudo xargs docker image rm  # remove all images 


# sudo docker-compose down # stop the running containers (1)
# 


build() {
    echo 'Building locally...' && docker-compose up --build --no-start nodeserver
    echo 'Pushing locally...' &&  docker push $NODE_REGISTRY #&& docker push $NGINX_REGISTRY
}


run() {
    echo 'Pulling...'
    docker pull $NODE_REGISTRY
    docker pull $NGINX_REGISTRY

    echo 'Run...'
    docker-compose up --no-build 
}

deploy() {
    echo '== [1/6] Start the instance...' && gcloud compute instances start instance-2 --zone="europe-west1-b"
    echo '== [2/6] Killing nginx...' && gcloud compute ssh instance-2 --zone="europe-west1-b" --command="sudo systemctl stop nginx && sudo killall nginx"
    echo '== [3/6] Cloning/Pulling the repo...' && gcloud compute ssh instance-2 --zone="europe-west1-b" --command="git clone https://$TOKEN@$REPO; cd mock-deploy && git pull"
    echo '== [4/6] Stop running containers...' && gcloud compute ssh instance-2 --zone="europe-west1-b" --command="cd mock-deploy && sudo docker-compose down; sudo docker ps -q | xargs sudo docker kill"
    echo '== [5/6] Pulling the images...' && gcloud compute ssh instance-2 --zone="europe-west1-b" --command="sudo docker pull $NODE_REGISTRY && sudo docker pull $NGINX_REGISTRY"
    echo '== [6/6] Running...' && gcloud compute ssh instance-2 --zone="europe-west1-b" --command="cd mock-deploy && sudo docker-compose up --no-build"
}
34.140.60.175
ssl() {
    echo 'Not automated - steps:'
    echo '======================'
    echo '== [1/6] Start the instance...' && echo "$ gcloud compute instances start instance-2 --zone=\"europe-west1-b\""
    echo ''
    echo '== [2/6] Access the instance via SSH...' && echo "$ gcloud compute ssh instance-2 --zone=\"europe-west1-b\""
    echo ''
    echo '== [3/6] Access the docker container...' && echo "$ sudo docker exec -it mock-deploy_nginx_1 sh"
    echo ''
    echo '== [4/6] Update the SSL credentials...' && echo "$ certbot --nginx -d fastfix.shop -d www.fastfix.shop"
    echo ''
    echo '== [5/6] Close the container...' && echo "$ exit"
    echo ''
    echo '== [6/6] Push the updated image...' && echo "$ sudo docker push ghcr.io/joaomouraosa/mock_nginx:latest"
    echo ''
}


for arg; do 
    case "$arg" in
        -b|--build) build;;
        -d|--deploy) deploy;;
        -r|--run) run;;
        -s|--ssl) ssl;;
        -t|--test) test;;
        *) echo "Usage: (-s|--scan)";;
    esac
done




