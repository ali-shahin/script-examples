#!/bin/bash
set -e

# Function: print_color
# Description: Prints a message in a specified color.
# Parameters:
#   $1 - The color to print the message in. Supported values are "green" and "red".
#   $2 - The message to print.
# Usage:
#   print_color "green" "This is a green message"
#   print_color "red" "This is a red message"
function print_color(){
  NC='\033[0m' # No Color

  case $1 in
    "green") COLOR='\033[0;32m' ;;
    "red") COLOR='\033[0;31m' ;;
    "*") COLOR='\033[0m' ;;
  esac

  echo -e "${COLOR} $2 ${NC}"
}

### Deploy the ecommerce application
echo "---------------- Deploying the ecommerce application ------------------"

## Deploy Pre-Requisites
print_color "green" "---------------- Setup Firewall ------------------"

# 1.Install firewalld
echo "Installing firewalld..."
sudo yum install -y firewalld

# 2.Start and enable firewalld
echo "Starting firewalld..."
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo systemctl status firewalld

print_color "green" "---------------- Setup Firewall - Finished ------------------"

## Deploy and Configure Database
print_color "green" "---------------- Setup Database Server ------------------"

# 1.Install mariadb
echo "Installing mariadb..."
sudo yum install -y mariadb-server

echo "Starting mariadb..."
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl status mariadb

# 2.Configure firewall for database
echo "Configuring firewall for database..."
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --reload

# 3.Configure database
echo "Configuring database..."
cat > db-create-script.sql <<-EOF
CREATE DATABASE ecomdb;
CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
FLUSH PRIVILEGES;
EOF
sudo mysql < db-create-script.sql

# 4.Load Product Inventory Information to database
echo "Loading Product Inventory Information to database..."
cat > db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;
INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");
EOF
sudo mysql < db-load-script.sql

print_color "green" "---------------- Setup Database Server - Finished ------------------"

## Deploy and Configure Web Server
print_color "green" "---------------- Setup Web Server ------------------"

# 1.Install required packages
echo "Installing Web Server Packages..."
sudo yum install -y httpd php php-mysqlnd

echo "Configuring firewall for webserver..."
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload

# 2.Configure httpd
sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf

# 3.Start and enable httpd
echo "Starting webserver..."
sudo systemctl start httpd
sudo systemctl enable httpd

# 4.Download code
echo "Downloading code..."
sudo yum install -y git
sudo git clone https://github.com/kodekloudhub/learning-app-ecommerce.git /var/www/html/

# 5.Create and Configure the .env File
echo "Creating and Configuring the .env File..."
cat > .env <<-EOF
DB_HOST=localhost
DB_USER=ecomuser
DB_PASSWORD=ecompassword
DB_NAME=ecomdb
EOF
sudo mv .env /var/www/html/

# 6.Restart httpd
echo "Restarting webserver..."
sudo systemctl restart httpd

print_color "green" "---------------- Setup Web Server - Finished ------------------"

# 7.Test
curl http://localhost

echo "---------------- Ecommerce application deployed successfully! ------------------"
