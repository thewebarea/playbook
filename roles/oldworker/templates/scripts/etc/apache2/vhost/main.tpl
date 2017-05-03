<VirtualHost *:80>
	Include /var/www/%project%/config/aliases.conf
	ServerAdmin webmaster@%project%
	
	DocumentRoot /var/www/%project%/web
	<Directory /var/www/%project%/>
	    Include /var/www/%project%/config/web.conf
	</Directory>
	
	ErrorLog ${APACHE_LOG_DIR}/error-%project%.log
	LogLevel warn
	CustomLog ${APACHE_LOG_DIR}/access-%project%.log combined
</VirtualHost>

