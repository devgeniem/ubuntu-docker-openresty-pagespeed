FROM devgeniem/base:noble

LABEL maintainer="Jussi Alanen - Hion Digital Oy <jussi.alanen@hiondigital.com>"

ARG NGINX_VERSION="1.22.0"
ARG OPENSSL_VERSION="1.1.1k"
ARG PAGESPEED_VERSION="1.13.35.2"
ARG MAKE_J=4

RUN apt-get update && apt-get install -y  \
    dpkg-dev \
    gnupg \
    perl \
    wget \
    git nano \
    g++ \
    gcc \
    curl \
    make \
    unzip \
    bzip2 \
    gperf \
    python-is-python3 \
    openssl \
    libuuid1 \
    apt-utils \
    pkg-config \
    icu-devtools \
    build-essential \
    ca-certificates \
    uuid-dev \
    zlib1g-dev \
    libicu-dev \
    libssl-dev \
    apache2-dev \
    libpcre3 \
    libpcre3-dev \
    libmaxminddb-dev \
    libpng-dev \
    libaprutil1-dev \
    libcurl4-openssl-dev

COPY entrypoint.sh /usr/local/bin

# Download Nginx
RUN mkdir -p /usr/local/src/nginx && \
    echo "Downloading Nginx..." && \
    cd /tmp && \
    wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && \
    tar -zxvf nginx-$NGINX_VERSION.tar.gz

# Download Pagespeed for Nginx
RUN cd /tmp && \
    echo "Downloading PageSpeed for Nginx..." && \
    git clone https://github.com/apache/incubator-pagespeed-ngx.git && \
    cd incubator-pagespeed-ngx/ && \
    git checkout latest-stable

# Download OpenSSL
RUN cd /tmp && \
    echo "Downloading OpenSSL..." && \
    curl -L https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz | tar -zx

# Download Pagespeed Incubator
RUN cd /tmp/incubator-pagespeed-ngx && \
    echo "Downloading Incubator Pagespeed for Nginx..." && \
    wget https://dl.google.com/dl/page-speed/psol/$PAGESPEED_VERSION-x64.tar.gz && \
    tar -xvzf $PAGESPEED_VERSION-x64.tar.gz

# Build in additional Nginx modules
RUN cd /tmp && \
    git clone https://github.com/vozlt/nginx-module-vts.git && \
    git clone https://github.com/FRiCKLE/ngx_cache_purge.git && \
    git clone https://github.com/simplresty/ngx_devel_kit.git && \
    git clone https://github.com/leev/ngx_http_geoip2_module.git && \
    git clone https://github.com/openresty/echo-nginx-module.git && \
    git clone https://github.com/onnimonni/redis-nginx-module.git && \
    git clone https://github.com/onnimonni/ngx_http_redis-0.3.7 && \
    git clone https://github.com/openresty/redis2-nginx-module.git && \
    git clone https://github.com/openresty/srcache-nginx-module.git && \
    git clone https://github.com/openresty/set-misc-nginx-module.git && \
    git clone https://github.com/openresty/headers-more-nginx-module.git && \
    git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git

RUN ls -la /tmp/
RUN ls -la /tmp/ngx_http_geoip2_module

# Build the Nginx, and modules
RUN cd /tmp/nginx-$NGINX_VERSION && \
    ./configure --with-compat \

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
    --with-stream \
    --with-stream_ssl_module \
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
    --modules-path=/usr/lib/nginx \

    --prefix=/etc/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx/nginx.lock \

    --http-fastcgi-temp-path=/tmp/nginx/fastcgi \
    --http-proxy-temp-path=/tmp/nginx/proxy \
    --http-client-body-temp-path=/tmp/nginx/client_body \

    --with-openssl=/tmp/openssl-${OPENSSL_VERSION} \
    --add-module=/tmp/ngx_devel_kit \
    --add-module=/tmp/ngx_cache_purge \
    --add-module=/tmp/nginx-module-vts \
    --add-module=/tmp/echo-nginx-module \
    --add-module=/tmp/redis-nginx-module \
    --add-module=/tmp/redis2-nginx-module \
    --add-module=/tmp/srcache-nginx-module \
    --add-module=/tmp/set-misc-nginx-module \
    --add-module=/tmp/ngx_http_geoip2_module \
    --add-module=/tmp/headers-more-nginx-module && \
    # --add-module=/tmp/incubator-pagespeed-ngx && \
    make -j${MAKE_J} && \
    make -j${MAKE_J} install && \

    mkdir -p /var/lib/nginx /var/log/nginx && \

    ## Cleanup
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* /var/log/apt/*

RUN \
    # Temp directory
    mkdir /tmp/nginx/ \
    mkdir -p /tmp/nginx/pagespeed/images/ \

    # Symlink modules path to config path for easier usage
    && ln -sf /usr/lib/nginx /etc/nginx/modules \

    # Create nginx group
    && groupadd -g 8888 nginx \
    && useradd -u 8888 -g nginx nginx \

    # Symlink nginx logs to system output
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log
