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
  - [push to github registry](#compose-push)
  - [pull from the github registry](#compose-pull)
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
  2. ```json
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
```json 
// /server/client/package.json
{
  "proxy": "http://localhost:5000"
}
```  

#### Dockerize <a name="app-docker"></a>

```yml
# server/Dockerfile
FROM node:alpine
WORKDIR /usr/src/app
COPY . .
RUN npm install && npm install --prefix client && npm install pm2@latest -g
EXPOSE 5000
CMD ["pm2", "start", "\"npm run prod\"", "--name", "nodeserver"]
```

```bash 
docker build . && docker run express-react-deploy_nodeserver
```


### Reverse proxy  <a name="nginx"></a>

#### Nginx (/nginx)  <a name="nginx-local"></a>

```yml
# nginx/default.conf
server {
  listen 80 default_server;  # this server listens on port 80
  listen [::]:80 default_server;
        
  server_name nodeserver;  # name this server "nodeserver", but we can call it whatever we like

  location / {
    proxy_pass http://localhost:5000;
    proxy_http_version 1.1;
    proxy_cache_bypass $http_upgrade;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
  }
}
```

```bash 
sudo apt install nginx && sudo systemctl stop nginx
```
   
```bash 
cp default.conf /etc/nginx/conf.d/default.conf
```
   
```bash 
sudo nginx -t # Check if the configuration file is free of errors
#sudo systemctl start nginx
```
   

#### Dockerize  <a name="nginx-docker"></a>

```yml
# /nginx/Dockerfile
FROM nginx
COPY default.conf /etc/nginx/conf.d/default.conf
```

```bash
docker build . && docker run express-react-deploy_nginx
```


### Docker compose (dockerize both services) <a name="compose"></a>

#### Build the images locally  <a name="compose-local"></a>

```yml
# /docker-compose.yml
version: "3.8"
services:
  nodeserver:
    build:
      context: ./server
      ports:
        - "5000:5000"
  nginx:
      restart: always
      build:
        context: ./nginx
      ports:
        - "80:80"
        - "443:443"
```

```bash 
sudo docker-compose up --build
```
#### Push/pull the images to/from github registry  <a name="compose-push"></a>
```bash 
docker push ghcr.io/joaomouraosa/online_shop_nodeserver:latest
docker push ghcr.io/joaomouraosa/online_shop_nginx:latest

docker pull ghcr.io/joaomouraosa/online_shop_nodeserver:latest
docker pull ghcr.io/joaomouraosa/online_shop_nginx:latest
```


#### Run the images from the github registry  <a name="compose-pull"></a>

```yml
# compose-run.yml
version: "3.3"
services:
  nodeserver:
    image: ghcr.io/joaomouraosa/online_shop_nodeserver:latest
    ports:
      - "5000:5000"
  nginx:
    restart: always  
    image: nginx:1.15-alpine
    ports:
      - "80:80"
      - "443:443"
```

```bash 
docker-compose -f compose-run.yml up -d
```
### GCP <a name='gcp'></a>

#### Pull & run the images from the registry <a name='gcp-run'></a>

```bash 

# start the instance
gcloud compute instances start instance-2 --zone="europe-west1-b"

# pull from github
gcloud compute ssh instance-2 --zone="europe-west1-b" 
  --command="cd online_shop && git pull && sudo systemctl stop nginx"

# pull the images from the registry    
gcloud compute ssh instance-2 --zone="europe-west1-b" --command="
  sudo docker pull ghcr.io/joaomouraosa/online_shop_nodeserver:latest && \
  sudo docker pull ghcr.io/joaomouraosa/online_shop_nginx:latest"

# run the images
gcloud compute ssh instance-2 --zone="europe-west1-b" 
  --command="cd online_shop && sudo docker-compose -f compose-run.yml up --build" 

# gcloud compute instances stop instance-2 --zone="europe-west1-b"  
```


### SSL  <a name="ssl"></a>
#### Locally <a name="ssl-local"></a>
```bash 
docker exec -it express-react-deploy_nginx_1 sh
sudo certbot --nginx -d fastfix.shop -d www.fastfix.shop
```

#### GCP <a name="ssl-gcp"></a>