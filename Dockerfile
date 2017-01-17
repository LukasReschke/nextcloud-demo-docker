# Nextcloud - Demo Docker
#
# @copyright Copyright (c) 2017 Lukas Reschke (lukas@statuscode.ch)
# @copyright Copyright (c) 2016 Marcos Zuriaga Miguel (wolfi@wolfi.es)
# @copyright Copyright (c) 2016 Sander Brand (brantje@gmail.com)
# @license GNU AGPL version 3 or any later version
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

FROM ubuntu:16.04
RUN /bin/bash -c "export DEBIAN_FRONTEND=noninteractive" && \
	/bin/bash -c "debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password password PASS'" && \
	/bin/bash -c "debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password_again password PASS'" && \
	apt-get -y update && apt-get install -y \
	apache2 \
	cowsay \
	cowsay-off \
	git \
	curl \
	libapache2-mod-php7.0 \
	mariadb-server \ 
	php7.0 \
	php7.0-mysql \
	php-curl \
	php-dompdf \
	php-gd \
	php-mbstring \
	php-xml \
	php-xml-serializer \
	php-zip \
	php-apcu \
	php-ldap \
	wget \
	unzip \
	pwgen \
	sudo
RUN a2enmod ssl
RUN ln -s /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled

RUN service mysql restart && \
		mysql -uroot -pPASS -e "SET PASSWORD = PASSWORD('');" && \
		echo "echo hhvm" > /bin/phpenv && chmod +x /bin/phpenv && \
		cd /var/www/html && \
		mysql -e 'create database oc_autotest;' && \
		mysql -u root -e "CREATE USER 'oc_autotest'@'localhost' IDENTIFIED BY 'm464P455w0rd'" && \
		mysql -u root -e "grant all on oc_autotest.* to 'oc_autotest'@'localhost'" && \
		mysql -e "SELECT User FROM mysql.user;" && \
		cd /root/ && wget https://download.nextcloud.com/server/releases/nextcloud-11.0.1.zip && unzip /root/nextcloud-11.0.1.zip && \
		mv /root/nextcloud/* /var/www/html/ && \
		mv /root/nextcloud/.htaccess /var/www/html/.htaccess && \
		cd /var/www/html/ && \
		chmod +x occ && \
		service mysql restart && \
		mkdir -p /opt/nextcloud/ && \
		chown -R www-data /opt/nextcloud && \
		./occ maintenance:install --database-name oc_autotest --database-user oc_autotest --admin-user admin --admin-pass admin --database mysql --database-pass 'm464P455w0rd' --data-dir /opt/nextcloud && \
		chown -R www-data /opt/nextcloud && \
		./occ check && \
		./occ status && \
		./occ app:list && \
		./occ upgrade && \
		./occ config:system:set appstoreenabled --value=false && \
		./occ config:system:set trusted_domains 2 --value=172.17.0.2 && \
		./occ config:system:set trusted_domains 3 --value=demo.nextcloud.com && \
		./occ config:system:set trusted_domains 4 --value=demo.cloud.wtf && \
		./occ config:app:set --value="https://demo.nextcloud.com:9980" richdocuments wopi_url && \
		./occ config:system:set htaccess.RewriteBase --value="/" && \
		./occ maintenance:update:htaccess && \
		cd /var/www/html/apps/ && wget https://github.com/nextcloud/richdocuments/releases/download/1.1.25/richdocuments.tar.gz && tar -xf richdocuments.tar.gz && \
		rm -rf /var/www/html/apps/files_external && \
		rm -rf /var/www/html/apps/templateeditor && \
		rm -rf /var/www/html/apps/survey_client && \
		/var/www/html/occ app:enable richdocuments && \
		/var/www/html/occ config:system:set --value "\OC\Memcache\APCu" memcache.local && \
		chown -R www-data /var/www && \
		a2enmod headers && \
		a2enmod rewrite && \
		cat /etc/apache2/apache2.conf |awk '/<Directory \/var\/www\/>/,/AllowOverride None/{sub("None", "All",$0)}{print}' > /tmp/apache2.conf && \
		mv /tmp/apache2.conf /etc/apache2/apache2.conf && \
		sed -i '/SSLEngine on/a Header always set Strict-Transport-Security "max-age=63072000; includeSubdomains;"' /etc/apache2/sites-enabled/default-ssl.conf
EXPOSE 80
EXPOSE 443
ENTRYPOINT curl -L https://demo.nextcloud.com/startup.sh | bash && \
                        service mysql start && \
						service apache2 start && \
						sudo -u www-data /var/www/html/occ config:system:set instanceid --value $(pwgen -0 12 1) && \
						/usr/games/cowsay -f dragon.cow "you might now login using username:admin password:admin" && \
						bash -c "trap 'echo stopping services...; service apache2 stop && service mysql stop && exit 0' SIGTERM SIGKILL; \
						tail -f /var/www/html/index.php"
