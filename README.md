* ## App

  1. ### Express server
    1. > npm init && git install express
    2. > .gitignore
    ```
    node_modules
    ```
    3. > package.json
    ```json
    {
      "type": "module",
      "scripts": {
        "start": "node index.js",
        "production": "npm install --prefix client && npm run build --prefix client && npm install && NODE_ENV=production npm start"
      }
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
        app.get("*", (req, res) =>
        res.sendFile(`${__dirname}/client/build/index.html`)
      );
    }
    app.listen(port, () => console.log(`Listening on ${port}`));
  ```



### React frontend

1. > npx create-react-app client
2. > npm run build
3. > /server/client/package.json
```json
{
  "proxy": "http://localhost:5000"
}
```

### Dockerize

1. > .dockerignore
```
node_modules
npm-debug.log
.git
.gitignore
npm-debug.log
docker-compose*
README.md
LICENSE
.vscode
```

2. > Dockerfile
```
FROM node:alpine
WORKDIR /usr/src/app
COPY . .
RUN npm install
RUN npm install --prefix client
RUN npm install pm2@latest -g
EXPOSE 5000
CMD ["pm2", "start", "\"npm run prod\"", "--name", "nodeserver"]
```


## Reverse proxy

### /nginx

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

#### Dockerize

1. > /nginx/Dockerfile
```
FROM nginx
COPY default.conf /etc/nginx/conf.d/default.conf
```

> sudo nginx -t # Check if the configuration file is free of errors
> sudo systemctl restart nginx # Restart nginx


### Dockerize the whole thing

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

    version: '3'

  webserver:
    image: nginx:latest
    ports:
      - 80:80
      - 443:443
    restart: always
    volumes:
      - ./nginx/conf/:/etc/nginx/conf.d/:ro
      - ./certbot/www:/var/www/certbot/:ro
  certbot:
    image: certbot/certbot:latest
    volumes:
      - ./certbot/www/:/var/www/certbot/:rw
```

2. > sudo docker-compose up --build


### SSL
1. > docker exec -it express-react-deploy_nginx_1 sh
2. > sudo certbot --nginx -d fastfix.shop -d www.fastfix.shop

