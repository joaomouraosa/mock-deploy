#!/bin/bash

GREEN=$'\e[0;32m'
RED=$'\e[0;31m'
NC=$'\e[0m'
BOLD=$(tput bold)
REGULAR=$(tput sgr0)

## Git
REPO_HANDLER='mock-deploy'
GIT_USERNAME='joaomouraosa'
TOKEN="ghp_SECRET_TOKENabcdefghioj123"
REPO="$GIT_USERNAME/$REPO_HANDLER.git"

## docker-compose
NODE_SERVICE='nodeserver'
NGINX_SERVICE='nginx'

## docker registry
NODE_CONTAINER="${REPO_HANDLER}_${NODE_SERVICE}_1"
NGINX_CONTAINER="${REPO_HANDLER}_${NGINX_SERVICE}_1"

NODE_REGISTRY="ghcr.io/$GIT_USERNAME/${REPO_HANDLER}_${NODE_SERVICE}:latest"
NGINX_REGISTRY="ghcr.io/$GIT_USERNAME/${REPO_HANDLER}_${NGINX_SERVICE}:latest"

## VPS
INSTANCE="instance-2 --zone=europe-west1-b"


pp() {
    echo ${BOLD}$1${REGULAR}  $2
}


testURL() {
    result=`curl -s -o /dev/null -w "%{http_code}" --max-time 3 $1`
    if [ $result == "200" ]; then echo ${GREEN}${BOLD}'O'${REGULAR}${NC} $URL 
    else echo ${RED}${BOLD}'X'${REGULAR}${NC} $URL 
    fi
}


test() {
    pp 'Local' && URLs=('http://localhost:5000' 'http://localhost:80' 'http://localhost'); for URL in ${URLs[@]}; do testURL $URL; done
    pp 'VPS - DNS [ ] SSL [ ]' && URLs=($IP':80'); for URL in ${URLs[@]}; do testURL $URL; done
    pp 'VPS - DNS [X] SSL [ ]' && URLs=('http://fastfix.shop' 'http://www.fastfix.shop'); for URL in ${URLs[@]}; do testURL $URL; done
    pp 'VPS - DNS [X] SSL [X]' && URLs=('https://fastfix.shop' 'https://www.fastfix.shop'); for URL in ${URLs[@]}; do testURL $URL; done
}

# getIP() {
#     gcloud compute instances describe $INSTANCE --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
# }


build() {
    pp '== Build [1/3] Build'  && docker-compose up --build --no-start $NODE_SERVICE #nginx
    pp '== Build [2/3] Commit' && docker commit $NODE_CONTAINER $NODE_REGISTRY
    pp '== Build [3/3] Push'   && docker push $NODE_REGISTRY #&& docker push $NGINX_REGISTRY
}


run() {
    #pp '== Run locally  [1/2] Pull'  && docker pull $NODE_REGISTRY 
    docker pull $NGINX_REGISTRY
    pp '== Run locally  [2/2] Run'   && docker-compose up --no-build -d
}


clean() {
    pp '== Clean [1/2] Stop'   && docker-compose down #--rmi all
    pp '== Clean [2/2] Clean'  && docker system prune -f
    pp '== Clean [4/6] Clean instance'  && gcloud compute ssh $INSTANCE --command="cd mock-deploy && sudo docker-compose down; sudo docker system prune -f"
}


exit() {
    clean
    pp '== Exit [1/1] Close instance' && gcloud compute instances stop $INSTANCE
}


deploy() {
    pp '== Deploy [1/6] Start the instance...'       && gcloud compute instances start $INSTANCE
    pp '== Deploy [2/6] Kill nginx services...'      && gcloud compute ssh $INSTANCE --command="sudo systemctl stop nginx; sudo killall nginx; sudo systemctl disable nginx"
    pp '== Deploy [3/6] Cloning/Pulling the repo...' && gcloud compute ssh $INSTANCE --command="git clone https://$TOKEN@$REPO; cd mock-deploy && git pull"
    pp '== Deploy [4/6] Stop running containers...'  && gcloud compute ssh $INSTANCE --command="cd mock-deploy && sudo docker-compose down; sudo docker system prune -f"
    pp '== Deploy [5/6] Pulling the images...'       && gcloud compute ssh $INSTANCE --command="sudo docker pull $NODE_REGISTRY && sudo docker pull $NGINX_REGISTRY"
    pp '== Deploy [6/6] Run'                         && gcloud compute ssh $INSTANCE --command="cd mock-deploy && sudo docker-compose up --no-build -d"
}

ssl() {
    pp 'Not automated - steps:'
    pp '======================'
    pp '# Local [1/6] Start instance & access the instance, eg:' 
    echo "gcloud compute instances start $INSTANCE"
    echo "gcloud compute ssh $INSTANCE"
    echo ''
    pp '# Instance [2/6] Access container in instance' 
    echo "cd mock-deploy"
    echo "sudo docker-compose exec nginx sh"
    echo "#sudo docker exec -it $NGINX_CONTAINER sh  # (alternative)"  
    echo ''
    pp '# Container [4/6] Update the SSL credentials...' 
    echo "certbot --nginx -d fastfix.shop -d www.fastfix.shop"
    echo ''
    pp '# Container [5/6] Close the container...' 
    echo "# exit"
    echo ''
    pp '# Instance [5/6] Commit & Push the new image...' 
    echo "sudo docker commit $NGINX_CONTAINER $NGINX_REGISTRY"
    echo "sudo docker push $NGINX_REGISTRY"
    echo ''
}


help() {
    pp '=============== Help ==============='
    echo '-b | --build   Builds locally'
    echo '-r | --run     Runs locally'
    echo '-d | --deploy  Deploys to the VPS'
    echo '-t | --test    Connection tests'
    echo '-a | --all     i.e., -b -r -d -t'
    echo '-s | --ssl     SSL setup steps'
    echo '-e | --exit    Closes the instance'
    echo '-h | --help    Prompts this'
}


for arg; do     
    case "$arg" in
        -b|--build) build;;
        -d|--deploy) deploy;;
        -r|--run) run;;
        -s|--ssl) ssl;;
        -t|--test) test;;
        -a|--all|-brdt|--) build && deploy && sleep 6s && test;;
        -c|--clean) clean;;
        -e|--exit) exit && sleep 5s && test;;
        -h|--help|*) help;;
    esac
done




