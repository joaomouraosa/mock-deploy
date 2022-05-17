## Contents
1. [Build the express-react app](#app)
  - [server side](#app-server)
  - [front side](#app-front)
  - [dockerize](#app-docker)
2. [Nginx proxy](#nginx)
  - [locally](#nginx-local)
  - [dockerize](#nginx-docker)
3. [Compose both services](#compose)
  - [build](#compose-build)
  - [push/pull to/from the github registry](#compose-push)
4. [GCP](#gcp)
  - [Start and access the instance](#gcp-start)
  - [Pull & run the images from the github registry](#gcp-run)
5. [SSL](#ssl)
  - [Locally](#ssl-local)
  - [GCP instance](#ssl-gcp)



## App 

### Express-react app  <a name="app"></a>

#### Express server (/server)  <a name="app-server"></a>
```bash 
cd server && npm init && git install express
```
```javascript
// server/package.json
"type": "module",
"scripts": {
  "start": "node index.js",
  "prod": "NODE_ENV=prod npm start"
}
```
```javascript
// server/index.js
import express from "express";
import path from "path";
import { fileURLToPath } from "url";

const [app, port] = [express(), 5000];
const __dirname = path.dirname(fileURLToPath(import.meta.url));

app.get("/api/connected", (req, res) => res.json({ message: "Connected!" }));
  if (process.env.NODE_ENV === "prod"){
    app.use(express.static(`${__dirname}/client/build`));
    app.get("*", (req, res) => res.sendFile(`${__dirname}/client/build/indehtml`));
  }
app.listen(port, () => console.log(`Listening on ${port}`));
```

#### React frontend  <a name="app-client"></a>

```bash 
#npx create-react-app client
```

```javascript
// server/client/package.json
{
  //...
  "proxy": "http://localhost:5000"
  //...
}
```

```bash 
#npm install pm2@latest -g
#pm2 list
pm2 delete nodeserver

npm install && npm install --prefix client
npm run build --prefix client

pm2 start "npm run prod" --name nodeserver  # or npm run prod

curl localhost:5000/api/connected
```

#### Dockerize <a name="app-docker"></a>

```yml
# server/Dockerfile
FROM node:alpine
WORKDIR /usr/src/app
COPY . .
RUN npm install
RUN npm install --prefix client
RUN npm run build --prefix client
EXPOSE 5000
#CMD ["pm2-runtime", "start", "\"npm run prod\"", "--name", "nodeserver"]
CMD ["npm", "run", "prod"]
```

```bash 
#docker build . && docker run express-react-deploy_nodeserver
#docker stop express-react-deploy_nodeserver
```


### Reverse proxy  <a name="nginx"></a>

#### Nginx (/nginx)  <a name="nginx-local"></a>

```javascript
# nginx/default.conf
server {
  listen 80 default_server;
        
  server_name fastfix.shop www.fastfix.shop;

  location / {
    proxy_pass http://nodeserver:5000;
    proxy_http_version 1.1;
    proxy_cache_bypass $http_upgrade;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
  }
}
```

```bash 
sudo apt install nginx && sudo systemctl stop nginx && killall nginx
#fuser 80/tcp && fuser 5000/tcp 
```
   
```bash 
sudo cp default.conf /etc/nginx/conf.d/
```
   
```bash 
sudo nginx -t
sudo systemctl start nginx
sudo systemctl status nginx
curl localhost:80
```
   

#### Dockerize  <a name="nginx-docker"></a>

```yml
# /nginx/Dockerfile
FROM nginx:1.20-alpine
RUN apk --no-cache add certbot certbot-nginx
COPY default.conf /etc/nginx/conf.d/default.conf
```

```bash
#sudo systemctl stop nginx && killall nginx
#docker build . && docker run express-react-deploy_nginx
#docker stop express-react-deploy_nginx
```


### Docker compose (dockerize both services) <a name="compose"></a>

#### Build the images locally  <a name="compose-local"></a>

```yml
# /docker-compose.yml
version: "3.3"
services:
    nodeserver:
       image: ghcr.io/joaomouraosa/mock_nodeserver
       restart: always
       build:
           context: ./server
       ports:
           - "5000:5000"
    nginx:
        image: ghcr.io/joaomouraosa/mock_nginx
        restart: always
        build:
            context: ./nginx
        ports:
            - "80:80"
            - "443:443"
```

```bash 
docker-compose up --build
```
#### Push the images to the github registry  <a name="compose-push"></a>
```bash 
docker push ghcr.io/joaomouraosa/mock_nodeserver:latest
docker push ghcr.io/joaomouraosa/mock_nginx:latest
```


#### Run the images from the Registry  <a name="compose-pull"></a>

```bash
docker pull ghcr.io/joaomouraosa/mock_nodeserver:latest
docker pull ghcr.io/joaomouraosa/mock_nginx:latest

docker-compose up --no-build
```

### GCP <a name='gcp'></a>

##### Prepare the instance
```bash 
gcloud compute instances start instance-2 --zone="europe-west1-b"

gcloud compute ssh instance-2 --zone="europe-west1-b" \
  --command="sudo systemctl stop nginx && killall nginx"

#gcloud compute ssh instance-2 --zone="europe-west1-b"  # access via SSH
```

##### Pull the data

```bash 

# Clone
gcloud compute ssh instance-2 --zone="europe-west1-b" \
  --command="git clone https://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/github.com/joaomouraosa/express-react-deploy.git"

# Pull the code
gcloud compute ssh instance-2 --zone="europe-west1-b" \
  --command="cd express-react-deploy && git pull"

# Pull the images    
gcloud compute ssh instance-2 --zone="europe-west1-b" --command="\
  sudo docker pull ghcr.io/joaomouraosa/online_shop_nodeserver:latest && \
  sudo docker pull ghcr.io/joaomouraosa/online_shop_nginx:latest"
```

##### Run

```bash
# Run
gcloud compute ssh instance-2 --zone="europe-west1-b"\ 
  --command="cd online_shop && sudo docker-compose up --no-build" 
```

##### Test

```bash
## SSL [ ] DNS [ ] Globally [ ]
gcloud compute ssh instance-2 --zone="europe-west1-b"\ 
  --command="curl localhost:80/api" 

## SSL [ ] DNS [ ] Globally [X]
IP=`gcloud compute ssh instance-2 --zone="europe-west1-b" --command="curl ifconfig.me"`
curl http://$IP/api

## SSL [ ] DNS [X] Globally [X]
curl http://fastfix.shop/api
curl http://www.fastfix.shop/api

## SSL [X] DNS [X] Globally [X]
curl https://fastfix.shop/api
curl https://www.fastfix.shop/api

#gcloud compute instances stop instance-2 --zone="europe-west1-b"
```

### SSL  <a name="ssl"></a>

##### GCP:

###### In the instance directly
```bash 
sudo certbot --nginx -d fastfix.shop -d www.fastfix.shop
```
###### In a container

```bash 
gcloud compute ssh instance-2 --zone="europe-west1-b"
```
```bash 
docker exec -it express-react-deploy_nginx_1 sh  # in the docker container
sudo certbot --nginx -d fastfix.shop -d www.fastfix.shop
exit
```
```bash 
docker push ghcr.io/joaomouraosa/online_shop_nginx:latest
```
##### Test
```bash 
curl https://fastfix.shop/api && curl https://www.fastfix.shop/api

# gcloud compute instances stop instance-2 --zone="europe-west1-b" 
```
