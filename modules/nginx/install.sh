#!/bin/bash

__namespace__() {

	apt-get update
	apt-get upgrade --show-upgraded

	require_packs 'nginx'
	install_packs

	ORIGIN_DIR=`pwd`

	rm -rf /tmp/nginx-install
	mkdir /tmp/nginx-install
	cd /tmp/nginx-install

	wget http://nginx.org/download/nginx-1.2.7.tar.gz

	tar -xzvf nginx-*.tar.gz
	rm nginx-*.tar.gz

	NGINX_HOME='/usr/local/nginx'

	local options="--prefix=$NGINX_HOME"

	[[ ${!NGINX_OPTS[@]} =~ 'with-auth-module' ]] && {
		wget https://github.com/samizdatco/nginx-http-auth-digest/tarball/master -O master.tar
		tar -xzvf master.tar
		rm master.tar
		options="$options --add-module=../samizdatco-nginx-http-auth-digest-*"
	}

	[[ ${!NGINX_OPTS[@]} =~ 'with-gzip-static-module' ]] && {
		options="$options --with-http_gzip_static_module"
	}

	cd nginx-*
	./configure $options
	make && checkinstall --install=yes --pkgname=nginx --default
	cd ../..
	cd $ORIGIN_DIR
	rm -rf /tmp/nginx-install

	mkdir -p $NGINX_HOME/logs

	# adduser --system --no-create-home --disabled-login --disabled-password --group nginx

	INIT_FILE="$MODULES_PATH/nginx/init-script.sh"
	check_file $INIT_FILE
	cp $INIT_FILE /etc/init.d/nginx
	chmod +x /etc/init.d/nginx
	/usr/sbin/update-rc.d -f nginx defaults

}; __namespace__