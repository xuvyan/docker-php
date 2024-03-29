FROM php:7.2-fpm
ENV SWOOLE_VERSION 4.2.5
# 更新安装依赖包和PHP核心拓展
RUN apt-get update && apt-get install -y \
       git \
       curl \
       wget \
       zip \
       libz-dev \
       libssl-dev \
       libnghttp2-dev \
       libpcre3-dev \
       libfreetype6-dev \
       libjpeg62-turbo-dev \
       libpng-dev \
       zlib1g-dev \
       libxml2-dev \
       libbz2-dev \
       supervisor \
   && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
   && docker-php-ext-install -j$(nproc) gd \
       && docker-php-ext-install zip \
       && docker-php-ext-install pdo_mysql \
       && docker-php-ext-install opcache \
       && docker-php-ext-install mysqli \
       && docker-php-ext-install mbstring \
       && docker-php-ext-install bz2 \
       && docker-php-ext-install soap \
       && rm -r /var/lib/apt/lists/*
# 安装 Composer
ENV COMPOSER_HOME /root/composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ENV PATH $COMPOSER_HOME/vendor/bin:$PATH
# Swoole extension
RUN wget https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz -O swoole.tar.gz \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && ( \
        cd swoole \
        && phpize \
        && ./configure  \
        --enable-openssl  \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r swoole \
    && docker-php-ext-enable swoole
# Zookeeper install
RUN wget http://us.mirrors.quenda.co/apache/zookeeper/zookeeper-3.4.14/zookeeper-3.4.14.tar.gz \
&& tar -zxvf zookeeper-3.4.14.tar.gz \
&& ( \
   cd zookeeper-3.4.14  \
   && ./zookeeper-client/zookeeper-client-c/configure -prefix=/usr/local/zookeeper \
   && make \
   && make install \
) \
&& rm zookeeper-3.4.14.tar.gz \
&& rm -rf zookeeper-3.4.14
# Zookeeper extension
RUN wget http://pecl.php.net/get/zookeeper-0.6.4.tgz -O  zookeeper.tgz \
 && mkdir -p zookeeper \
 && tar -zxvf zookeeper.tgz \
 && ( \
	cd zookeeper-0.6.4 \
	&& phpize \
	&& ./configure --with-libzookeeper-dir=/usr/local/zookeeper \
	&& make \
	&& make install \
  ) \
 && rm -r zookeeper-0.6.4  \
 && rm zookpeeper.tgz \
 && docker-php-ext-enable zookeeper
