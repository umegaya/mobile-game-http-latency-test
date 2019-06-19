FROM openresty/openresty:bionic
RUN echo "env REDIRECT_TO;" >> /usr/local/openresty/nginx/conf/nginx.conf
RUN rm /etc/nginx/conf.d/default.conf 
ADD ./config/*.conf /etc/nginx/conf.d
