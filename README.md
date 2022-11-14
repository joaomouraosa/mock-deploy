## Contents
1. [Build the express-react app](#app)

2. [Nginx proxy](#nginx)

3. [Dockerize both services](#compose)

4. [GCP](#gcp)

5. [SSL](#ssl)


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
docker build . --tag ghcr.io/joaomouraosa/mock_nodeserver:latest
docker run -p 5000:5000 --name nodeserver ghcr.io/joaomouraosa/mock_nodeserver:latest &
curl localhost:5000/api/connected
#docker stop ghcr.io/joaomouraosa/mock_nodeserver:latest
```


### Reverse proxy  <a name="nginx"></a>

#### Nginx (/nginx)  <a name="nginx-local"></a>

```javascript
# nginx/default.conf
server {
  listen 80 default_server;
        
  server_name fastfix.shop www.fastfix.shop;

  location / {
    proxy_pass http://nodeserver:5000;  # if in localhost: http://localhost:5000; 
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
curl localhost:80/api
```
   

#### Dockerize  <a name="nginx-docker"></a>

```yml
# /nginx/Dockerfile
FROM nginx:1.20-alpine
RUN apk --no-cache add certbot certbot-nginx
COPY default.conf /etc/nginx/conf.d/default.conf
```

```bash
docker build . --tag ghcr.io/joaomouraosa/mock_nginx:latest
```

```bash 
curl localhost:5000/api/connected
#docker stop ghcr.io/joaomouraosa/mock_nodeserver:latest
```


### Docker compose (dockerize both services) <a name="compose"></a>

#### Build the images locally  <a name="compose"></a>

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
curl localhost:80/api

docker image prune

```
#### Push the images to the github registry  <a name="compose-push"></a>
```bash 
docker push ghcr.io/joaomouraosa/mock_nodeserver:latest
docker push ghcr.io/joaomouraosa/mock_nginx:latest
```


#### Run the images from the Registry  <a name="compose-run"></a>

```bash
docker pull ghcr.io/joaomouraosa/mock_nodeserver:latest
docker pull ghcr.io/joaomouraosa/mock_nginx:latest

docker-compose up --no-build
```

### GCP <a name='gcp'></a>

##### Prepare the instance <a name='gcp-start'></a>
```bash 
gcloud compute instances start instance-2 --zone="europe-west1-b"

gcloud compute ssh instance-2 --zone="europe-west1-b" \
 --command="sudo systemctl stop nginx && sudo killall nginx"

#gcloud compute ssh instance-2 --zone="europe-west1-b"  # access via SSH
```

##### Pull the data <a name='gcp-pull'></a>

```bash 

# Clone
gcloud compute ssh instance-2 --zone="europe-west1-b" \
 --command="git clone https://ghp_SECRET_TOKEN_12345@github.com/joaomouraosa/mock-deploy.git"

# Pull the code
gcloud compute ssh instance-2 --zone="europe-west1-b" \
 --command="cd mock-deploy && git pull"

# Pull the images    
gcloud compute ssh instance-2 --zone="europe-west1-b" --command="\
  sudo docker pull ghcr.io/joaomouraosa/mock_nodeserver:latest && \
  sudo docker pull ghcr.io/joaomouraosa/mock_nginx:latest"
```


##### Run <a name='gcp-run'></a>


```bash
# Stop running containers
gcloud compute ssh instance-2 --zone="europe-west1-b" --command="sudo docker kill $(sudo docker ps -q)" 
```


```bash
# Run
gcloud compute ssh instance-2 --zone="europe-west1-b" --command="cd mock-deploy && sudo docker-compose up --no-build" 
```

##### Test <a name='gcp-test'></a>

```bash
## SSL [ ] DNS [ ] Globally [ ]
res=`gcloud compute ssh instance-2 --zone="europe-west1-b" --command="curl localhost:80/api"`
echo $res

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

##### GCP

###### In the instance directly
```bash 
sudo certbot --nginx -d fastfix.shop -d www.fastfix.shop
```
###### In a container

```bash 
gcloud compute ssh instance-2 --zone="europe-west1-b"
```
```bash 
sudo docker exec -it mock-deploy_nginx_1 sh  # in the docker container
certbot --nginx -d fastfix.shop -d www.fastfix.shop
exit
```
```bash 
sudo docker push ghcr.io/joaomouraosa/mock_nginx:latest
sudo docker tag ghcr.io/joaomouraosa/mock_nginx:latest ghcr.io/joaomouraosa/mock_nginx:certified
sudo docker push ghcr.io/joaomouraosa/mock_nginx:certified
```
##### Test
```bash 
curl https://fastfix.shop/api && curl https://www.fastfix.shop/api

gcloud compute instances stop instance-2 --zone="europe-west1-b" 
```

##### Script

```bash 
sh script.sh -h
```
