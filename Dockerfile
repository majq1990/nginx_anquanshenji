FROM arm64v8/nginx:1.21.0

LABEL MAINTAINER majianquan@egova.com.cn
   # set -x \
   # just rebulid nginx and clean the nginx tmp file  
RUN  cd /opt \
    && curl -O http://nginx.org/download/nginx-1.21.0.tar.gz && tar -xzf nginx-1.21.0.tar.gz \
    && curl -O https://www.openssl.org/source/openssl-1.1.1k.tar.gz && tar -xzf openssl-1.1.1k.tar.gz \
  ## update the source list to the mirrors.163.com 
    && cd /etc/apt/ \mv sources.list sources.list.bak \
    && echo 'deb http://mirrors.163.com/debian/ buster main non-free contrib \
deb http://mirrors.163.com/debian/ buster-updates main non-free contrib \
deb http://mirrors.163.com/debian-security/ buster/updates main non-free contrib' > /etc/apt/sources.list\

    && apt update \
    && apt-get  install -y binutils  build-essential cmake gawk bison flex texinfo automake \
       libtool cvs libncurses5-dev libglib2.0-dev gettext intltool subversion  git-core \
## just update the openssl to the 1.1.1K
    && apt -y remove openssl && cd /opt/openssl-1.1.1k && ./config && make -j 2 && make install \
## fix the Incorrect OpenSSL dependency Library
   && mv /usr/lib/aarch64-linux-gnu/libssl.so.1.1 /usr/lib/aarch64-linux-gnu/libssl.so.1.1.bak \
   && mv /usr/lib/aarch64-linux-gnu/libcrypto.so.1.1 /usr/lib/aarch64-linux-gnu/libcrypto.so.1.1.bak \
   && ln -s /usr/local/lib/libssl.so.1.1 /usr/lib/aarch64-linux-gnu/libssl.so.1.1 \
   && ln -s /usr/local/lib/libcrypto.so.1.1 /usr/lib/aarch64-linux-gnu/libcrypto.so.1.1\
##  Generating OpenSSL self signed certificate and dhparam
   && mkdir /opt/cert/ && cd /opt/cert/ && openssl genrsa -out server.key 2048 \
   && openssl req -new -subj "/C=CN/ST=SiChuan/L=ChengDu/O=egova/OU=egova.com/CN=domain" -key server.key -out server.csr \
   && mv server.key server.origin.key && openssl rsa -in server.origin.key -out server.key \
   && openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt \
   && openssl dhparam -out server-dhparam.pem 4096 \
## just update the nginx ,remove the other modle ,Ensure only required modules are installed 
    && cd /opt/nginx-1.21.0 \
    && ./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules \
	 --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log \ 
	--pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp \
	--http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \ 
	--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx \
	 --group=nginx --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module  --with-http_v2_module \
	 --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module \
	--with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -pie'\
    &&  make && scp  objs/nginx /usr/sbin/nginx && rm -rf /usr/share/nginx/html/* 

EXPOSE 80
EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
