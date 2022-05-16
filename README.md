## Contents
1. [Build the express-react app](#app)
  - [server side](#app/server)
  - [front side](#app/front)
  - [dockerize](#app/front)
2. [Nginx proxy](#app/front)
  - [locally](#app/front)
  - [dockerize](#app/front)
3. [Compose both services](#app/front)
  - [build](#app/front)
  - [push to github registry](#app/front)
  - [pull from the github registry](#app/front)
4. [GCP](#app/front)
  - [Start and access the instance](#app/front)
  - [Pull & run the images from the github registry](#app/front)
5. [SSL](#app/front)
  - [Certificate the site](#app/front)
    - [Locally](#app/front)
    - [GCP instance](#app/front)



## App  <a name="app"></a>

### Express-react app 

#### Express server (/server)
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

#### React frontend (/server/client)

  1. > npx create-react-app client
  2. > npm run build
  3. > /server/client/package.json
  ```json
  {
    "proxy": "http://localhost:5000"
  }
  ```

#### Dockerize

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


### Reverse proxy 

#### Nginx (/nginx)

1. > default.conf
```
server {
        listen 80 default_server;  # this server listens on port 80
        listen [::]:80 default_server;
        
        server_name nodeserver;  # name this server "nodeserver", but we can call it whatever we like

        location / {
                proxy_http_version 1.1;
                proxy_cache_bypass $http_upgrade;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection 'upgrade';
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_pass http://nodeserver:5000;
        }
}
```
2. > sudo apt install nginx
3. > sudo systemctl stop nginx
4. > cp default.conf /etc/nginx/conf.d/default.conf
5. > sudo nginx -t # Check if the configuration file is free of errors
6. > sudo systemctl start nginx 

#### Dockerize

1. > /nginx/Dockerfile
```
FROM nginx
COPY default.conf /etc/nginx/conf.d/default.conf
```

2. > #docker build . && docker run express-react-deploy_nginx


### Docker compose (dockerize both services)

#### Build the images locally

1. > /docker-compose.yml
```
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

#### Push the images to github registry



#### Pull the images from the github registry


### SSL
1. > docker exec -it express-react-deploy_nginx_1 sh
2. > sudo certbot --nginx -d fastfix.shop -d www.fastfix.shop

