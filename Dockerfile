FROM devgeniem/base:ubuntu
MAINTAINER Ville Pietarinen - Geniem Oy <ville.pietarinen-nospam@geniem.com>

# Fix apt-get and show colors
ARG DEBIAN_FRONTEND=noninteractive
ARG TERM=xterm-color
ARG RESTY_OPENSSL_VERSION="1.0.2j"

ARG RESTY_CONFIG_OPTIONS="\
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-file-aio \
    --with-ipv6 \
    --with-pcre-jit \
    --with-threads \
    --without-http_autoindex_module \
    --without-http_browser_module \
    --without-http_userid_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --without-http_split_clients_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    --without-http_referer_module \
    --user=nginx \
    --group=nginx \
    --sbin-path=/usr/sbin \
    --prefix=/etc/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx/nginx.lock \
    --http-fastcgi-temp-path=/tmp/nginx/fastcgi \
    --http-proxy-temp-path=/tmp/nginx/proxy \
    --http-client-body-temp-path=/tmp/nginx/client_body \
    --add-module=/tmp/ngx_cache_purge-2.3 \
    --with-openssl=/tmp/openssl-${RESTY_OPENSSL_VERSION} \
    --with-jemalloc \
    --with-libatomic \
    "

RUN apt-get update
RUN apt-get install -y build-essential curl libreadline-dev libncurses5-dev libpcre3-dev libgeoip-dev zlib1g-dev ca-certificates git libjemalloc-dev libatomic-ops-dev

RUN \
    cd /tmp/ && \

    # Download Nginx cache purge module
    echo "Downloading Nginx cache purge module..." && \
    curl -L http://labs.frickle.com/files/ngx_cache_purge-2.3.tar.gz | tar -zx && \

    # Download OpenSSL
    echo "Downloading OpenSSL..." && \
    curl -L https://www.openssl.org/source/openssl-${RESTY_OPENSSL_VERSION}.tar.gz | tar -zx

RUN mkdir /tmp/nginx/

WORKDIR /tmp/nginx/

RUN \
    mkdir tengine

WORKDIR /tmp/nginx/engine/

RUN \
    git clone --branch tengine-2.2.2 https://github.com/alibaba/tengine ./ \
    && ./configure ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} \
    && make \
    && make install

RUN \
    # Create nginx group
    groupadd -g 8888 nginx \
    && useradd -u 8888 -g nginx nginx
