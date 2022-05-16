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
  1.  ```bash 
      cd server && npm init && git install express
      ```
  2. ```javascript
     // server/package.json
     "type": "module",
     "scripts": {
       "start": "node index.js",
       "production": "npm install --prefix client && npm run build --prefix client && npm install && NODE_ENV=production npm start"
     }
     ```

  3. ```javascript
      // server/index.js
      import express from "express";
      import path from "path";
      import { fileURLToPath } from "url";
      const [app, port] = [express(), 5000];
      const __dirname = path.dirname(fileURLToPath(import.meta.url));
      app.get("/api/connected", (req, res) => res.json({ message: "Connected!" }));

      if (process.env.NODE_ENV === "production") {
        app.use(express.static(`${__dirname}/client/build`));
        app.get("*", (req, res) => res.sendFile(`${__dirname}/client/build/index.html`));
      }
      app.listen(port, () => console.log(`Listening on ${port}`));
      ```
      

#### React frontend  <a name="app-client"></a>

```bash 
npx create-react-app client
cd client && npm run build
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
pm2 list
pm2 delete nodeserver
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
EXPOSE 5000
CMD ["npm", "run", "prod"]
```

```bash 
docker build . && docker run express-react-deploy_nodeserver
```


### Reverse proxy  <a name="nginx"></a>

#### Nginx (/nginx)  <a name="nginx-local"></a>

```yml
# nginx/default.conf
server {
  listen 80 default_server;
        
  server_name nodeserver;

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
sudo apt install nginx 
sudo systemctl stop nginx
#fuser 80/tcp 
```
   
```bash 
sudo cp default.conf /etc/nginx/conf.d/
```
   
```bash 
sudo nginx -t # Check if the configuration file is free of errors
#sudo systemctl start nginx
#sudo systemctl status nginx
#curl localhost:80
```
   

#### Dockerize  <a name="nginx-docker"></a>

```yml
# /nginx/Dockerfile
FROM nginx:1.20-alpine
RUN apk add python3 python3-dev py3-pip build-base libressl-dev musl-dev libffi-dev rust cargo
RUN pip3 install pip --upgrade
RUN pip3 install certbot-nginx
COPY default.conf /etc/nginx/conf.d/default.conf
```

```bash
docker build . 
#docker run express-react-deploy_nginx
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
```

```bash 
docker-compose up --build
```
#### Push/pull the images to/from github registry  <a name="compose-push"></a>
```bash 
docker push ghcr.io/joaomouraosa/mock_nodeserver:latest
docker push ghcr.io/joaomouraosa/mock_nginx:latest

docker pull ghcr.io/joaomouraosa/mock_nodeserver:latest
docker pull ghcr.io/joaomouraosa/mock_nginx:latest
```


#### Run the images from the github registry  <a name="compose-pull"></a>

```bash 
docker-compose up --no-build
```
### GCP <a name='gcp'></a>

```bash 
# start the instance
gcloud compute instances start instance-2 --zone="europe-west1-b"

#gcloud compute ssh instance-2 --zone="europe-west1-b"  # access via SSH

# pull from github

gcloud compute ssh instance-2 --zone="europe-west1-b" \
  --command="git clone https://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/github.com/joaomouraosa/express-react-deploy.git"


gcloud compute ssh instance-2 --zone="europe-west1-b" \
  --command="cd express-react-deploy && git pull && sudo systemctl stop nginx && killall nginx"

# pull the images from the registry    
gcloud compute ssh instance-2 --zone="europe-west1-b" --command="\
  sudo docker pull ghcr.io/joaomouraosa/online_shop_nodeserver:latest && \
  sudo docker pull ghcr.io/joaomouraosa/online_shop_nginx:latest"

# run the images
gcloud compute ssh instance-2 --zone="europe-west1-b" 
  --command="cd online_shop && sudo docker-compose -f compose-run.yml up --build" 

# gcloud compute instances stop instance-2 --zone="europe-west1-b"  
```


### SSL  <a name="ssl"></a>

* locally:
  - local machine:
    ```bash 
    sudo certbot --nginx -d fastfix.shop -d www.fastfix.shop
    ```
  - docker container:
    ```bash 
    docker exec -it express-react-deploy_nginx_1 sh  # in the docker container
    sudo certbot --nginx -d fastfix.shop -d www.fastfix.shop
    docker push ghcr.io/joaomouraosa/online_shop_nginx:latest
    ```

* GCP:
  ```bash 
  gcloud compute ssh instance-2 --zone="europe-west1-b"  # in the instance
  ```
  - instance:
    ```bash 
    sudo certbot --nginx -d fastfix.shop -d www.fastfix.shop
    ```
  - docker container:
    ```bash 
    docker exec -it express-react-deploy_nginx_1 sh  # in the docker container
    sudo certbot --nginx -d fastfix.shop -d www.fastfix.shop
    exit
    docker push ghcr.io/joaomouraosa/online_shop_nginx:latest
    ```
  ```bash 
  # gcloud compute instances stop instance-2 --zone="europe-west1-b" 
  ```