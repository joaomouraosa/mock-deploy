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
  1. > npm init && git install express
  2. > echo 'node_modules' >> .gitignore
  3. > package.json
      ```json
      "type": "module",
      "scripts": {
        "start": "node index.js",
        "production": "npm install --prefix client && npm run build --prefix client && npm install && NODE_ENV=production npm start"
      }
      ```

  4. > index.js

      ```javascript
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

#### React frontend (/server/client) <a name="app-client"></a>

  1. > npx create-react-app client
  2. > npm run build
  3. > /server/client/package.json
      ```json
      {
        "proxy": "http://localhost:5000"
      }
      ```

#### Dockerize <a name="app-docker"></a>

1. > .dockerignore
      ```
      node_modules
      .git
      .gitignore
      docker-compose*
      .vscode
      ```

2. > Dockerfile
      ```
      FROM node:alpine
      WORKDIR /usr/src/app
      COPY . .
      RUN npm install && npm install --prefix client && npm install pm2@latest -g
      EXPOSE 5000
      CMD ["pm2", "start", "\"npm run prod\"", "--name", "nodeserver"]
      ```

3. > #docker build . && docker run express-react-deploy_nodeserver


### Reverse proxy  <a name="nginx"></a>

#### Nginx (/nginx)  <a name="nginx-local"></a>

1. > default.conf
      ```
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
2. > sudo apt install nginx && sudo systemctl stop nginx
3. > cp default.conf /etc/nginx/conf.d/default.conf
4. > sudo nginx -t # Check if the configuration file is free of errors
5. > #sudo systemctl start nginx 

#### Dockerize  <a name="nginx-docker"></a>

1. > /nginx/Dockerfile
      ```
      FROM nginx
      COPY default.conf /etc/nginx/conf.d/default.conf
      ```

2. > #docker build . && docker run express-react-deploy_nginx


### Docker compose (dockerize both services) <a name="compose"></a>

#### Build the images locally  <a name="compose-local"></a>

1. > /docker-compose.yml
      ```yml
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

2. > sudo docker-compose up --build

#### Push the images to github registry  <a name="compose-push"></a>
> docker push ghcr.io/joaomouraosa/online_shop_nodeserver:latest
> docker push ghcr.io/joaomouraosa/online_shop_nginx:latest

#### Pull the images from the github registry  <a name="compose-pull"></a>
> docker pull ghcr.io/joaomouraosa/online_shop_nodeserver:latest
> docker pull ghcr.io/joaomouraosa/online_shop_nginx:latest

#### Run the images from the github registry  <a name="compose-pull"></a>

1. > compose-run.yml
      ```yml
      version: "3.3"
      services:
          nodeserver:
              image: ghcr.io/joaomouraosa/online_shop_nodeserver:latest
              ports:
                  - "5000:5000"
          nginx:
              restart: always  # Assures the server is always up and running, restarting the service in case of unexpected errors
              image: nginx:1.15-alpine
              ports:
                 - "80:80"
                 - "443:443"
      ```

2. > #docker-compose -f compose-run.yml up -d

### GCP <a name='gcp'></a>

#### Start and access the instance <a name='gcp-start'></a>

1. > gcloud compute instances start instance-2 --zone="europe-west1-b"

#### Pull & run the images from the registry <a name='gcp-run'></a>

1. > gcloud compute ssh instance-2 --zone="europe-west1-b" --command="cd online_shop && git pull && sudo systemctl stop nginx"
       
2. > gcloud compute ssh instance-2 --zone="europe-west1-b" --command="sudo docker pull ghcr.io/joaomouraosa/online_shop_nodeserver:latest"

3. > gcloud compute ssh instance-2 --zone="europe-west1-b" --command="sudo docker pull ghcr.io/joaomouraosa/online_shop_nginx:latest"
        
4. ```bash
    gcloud compute ssh instance-2 --zone="europe-west1-b" --command="cd online_shop && sudo docker-compose -f compose-run.yml up --build" 
    ```


### SSL  <a name="ssl"></a>
#### Locally <a name="ssl-local"></a>
1. > docker exec -it express-react-deploy_nginx_1 sh
2. > sudo certbot --nginx -d fastfix.shop -d www.fastfix.shop

#### GCP <a name="ssl-gcp"></a>