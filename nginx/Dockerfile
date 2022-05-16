FROM nginx:1.20-alpine
RUN apk --no-cache add certbot certbot-nginx
COPY default.conf /etc/nginx/conf.d/default.conf

# docker exec -it express-react-deploy_nginx_1 sh