FROM node:alpine
WORKDIR /usr/src/app
COPY . .
RUN npm install
RUN npm install --prefix client
RUN npm run build --prefix client
EXPOSE 5000
#CMD ["pm2-runtime", "start", "\"npm run prod\"", "--name", "nodeserver"]
CMD ["npm", "run", "prod"]
