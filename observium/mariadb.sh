#!/bin/bash
start_mysql(){
    /usr/bin/mysqld_safe --datadir=/config/databases > /dev/null 2>&1 &
    RET=1
    while [[ RET -ne 0 ]]; do
        mysql -uroot -e "status" > /dev/null 2>&1
        RET=$?
        sleep 1
    done
}

# If databases do not exist, create them
if [ -f /config/databases/observium/users.ibd ]; then
  echo "Database exists."
else
  echo "Initializing Data Directory."
  /usr/bin/mysql_install_db --datadir=/config/databases >/dev/null 2>&1
  echo "Installation complete."
  start_mysql
  echo "Creating database."
  mysql -uroot -e "CREATE DATABASE IF NOT EXISTS observium DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
  PW=$(cat /config/config.php | grep -m 1 "'db_pass'" | sed -r 's/.*(.{34})/\1/;s/.{2}$//')
  echo "Creating database user."
  mysql -uroot -e "CREATE USER 'observium'@'localhost' IDENTIFIED BY '$PW'"
  echo "Granting database access to 'observium' user for localhost."
  mysql -uroot -e "GRANT ALL PRIVILEGES ON observium.* TO 'observium'@'localhost'"
  mysql -uroot -e "FLUSH PRIVILEGES"
  cd /opt/observium
  echo "Running Observium's discovery script."
  ./discovery.php -u
  echo "Adding the 'observium' user to the app."
  php adduser.php observium observium 10
  echo "Shutting down."
  mysqladmin -u root shutdown
  sleep 1
  echo "Initialization complete."
fi

echo "Fixing file permissions."
chown -R nobody:users /config/databases
chmod -R 755 /config/databases
sleep 3

echo "Starting MariaDB..."
/usr/bin/mysqld_safe --skip-syslog --datadir='/config/databases'
