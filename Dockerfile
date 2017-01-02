# Nextcloud - passman
#
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
	wget \
	unzip
RUN a2enmod ssl
RUN ln -s /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled

RUN service mysql restart && \
		mysql -uroot -pPASS -e "SET PASSWORD = PASSWORD('');" && \
		echo "echo hhvm" > /bin/phpenv && chmod +x /bin/phpenv && \
		cd /var/www/html && \
		mysql -e 'create database oc_autotest;' && \
		mysql -u root -e "CREATE USER 'oc_autotest'@'localhost' IDENTIFIED BY 'owncloud'" && \
		mysql -u root -e "grant all on oc_autotest.* to 'oc_autotest'@'localhost'" && \
		mysql -e "SELECT User FROM mysql.user;" && \
		cd /root/ && wget https://download.nextcloud.com/server/releases/nextcloud-11.0.0.zip && unzip /root/nextcloud-11.0.0.zip && \
		mv /root/nextcloud/* /var/www/html/ && \
		mv /root/nextcloud/.htaccess /var/www/html/.htaccess && \
		cd /var/www/html/ && \
		chmod +x occ && \
		service mysql restart && \
		mkdir -p /opt/nextcloud/ && \
		chown -R www-data /opt/nextcloud && \
		./occ maintenance:install --database-name oc_autotest --database-user oc_autotest --admin-user admin --admin-pass admin --database mysql --database-pass 'owncloud' --data-dir /opt/nextcloud && \
		chown -R www-data /opt/nextcloud && \
		./occ check && \
		./occ status && \
		./occ app:list && \
		./occ upgrade && \
		./occ config:system:set appstoreenabled --value=false && \
		./occ config:system:set trusted_domains 2 --value=172.17.0.2 && \
		./occ config:system:set trusted_domains 3 --value=demo.nextcloud.com && \
		./occ config:system:set trusted_domains 4 --value=demo.cloud.wtf && \
		chown -R www-data /var/www && \
		rm -rf /var/www/html/apps/files_external && \
		rm -rf /var/www/html/apps/templateeditor
EXPOSE 80
EXPOSE 443
ENTRYPOINT curl -L https://demo.cloud.wtf/startup.sh | bash && \
                        service mysql start && \
						service apache2 start && \
						/usr/games/cowsay -f dragon.cow "you might now login using username:admin password:admin" && \
						bash -c "trap 'echo stopping services...; service apache2 stop && service mysql stop && exit 0' SIGTERM SIGKILL; \
						tail -f /var/www/html/data/nextcloud.log"