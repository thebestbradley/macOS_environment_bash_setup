#!/bin/bash

# Ensure the script is not run as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root or with sudo."
   exit 1
fi

# Function to print error messages followed by an exit
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi

# Update Homebrew
echo "Updating Homebrew..."
brew update || error_exit "Failed to update Homebrew."

# Install gh CLI if not already installed
if ! command -v gh &> /dev/null; then
    echo "Installing gh CLI..."
    brew install gh || error_exit "Failed to install gh CLI."
else
    echo "gh CLI is already installed."
fi

# Install Git if not already installed
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    brew install git || error_exit "Failed to install Git."
else
    echo "Git is already installed."
fi

# Install SVN if not already installed
if ! command -v svn &> /dev/null; then
    echo "Installing SVN..."
    brew install svn || error_exit "Failed to install SVN."
else
    echo "SVN is already installed."
fi

# install coldfusion if not already installed
if ! command -v coldfusion &> /dev/null; then
    echo "Installing Adobe ColdFusion..."
    brew install coldfusion || error_exit "Failed to install Adobe ColdFusion."
else
    echo "Adobe ColdFusion is already installed."
fi

# Install MySQL if not already installed
if ! command -v mysql &> /dev/null; then
    echo "Installing MySQL..."
    brew install mysql || error_exit "Failed to install MySQL."
    echo "Starting MySQL..."
    brew services start mysql || error_exit "Failed to start MySQL."
else
    echo "MySQL is already installed."
    if ! brew services list | grep -q "mysql.*started"; then
        echo "Starting MySQL..."
        brew services start mysql || error_exit "Failed to start MySQL."
    else
        echo "MySQL is already running."
    fi
fi

# Install expect if not already installed
if ! command -v expect &> /dev/null; then
    echo "Installing expect..."
    brew install expect || error_exit "Failed to install expect."
else
    echo "Expect is already installed."
fi

# Install PHP if not already installed
if ! command -v php &> /dev/null; then
    echo "Installing PHP..."
    brew install php || error_exit "Failed to install PHP."
else
    echo "PHP is already installed."
fi

# Install Composer if not already installed
if ! command -v composer &> /dev/null; then
    echo "Installing Composer..."
    brew install composer || error_exit "Failed to install Composer."
else
    echo "Composer is already installed."
fi

# Install Node.js (comes with npm) if not already installed
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    brew install node || error_exit "Failed to install Node.js."
else
    echo "Node.js is already installed."
fi

# Install Apache if not already installed
if ! command -v httpd &> /dev/null; then
    echo "Installing Apache..."
    brew install httpd || error_exit "Failed to install Apache."
else
    echo "Apache is already installed."
fi

# Install phpMyAdmin if not already installed
if [ ! -d "/opt/homebrew/share/phpmyadmin" ]; then
    echo "Installing phpMyAdmin..."
    brew install phpmyadmin || error_exit "Failed to install phpMyAdmin."
else
    echo "phpMyAdmin is already installed."
fi

# Install Python if not already installed
if ! command -v python3 &> /dev/null; then
    echo "Installing Python..."
    brew install python || error_exit "Failed to install Python."
else
    echo "Python is already installed."
fi

echo "Installation of software complete."

#!/bin/bash

# Function to exit on error
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Function to prompt for MySQL root password
prompt_mysql_password() {
    echo "Please enter the new MySQL root password: "
    read -s root_password
    echo "Please confirm the new MySQL root password: "
    read -s root_password_confirm
    if [ "$root_password" != "$root_password_confirm" ]; then
        echo "Passwords do not match. Please run the script again."
        exit 1
    fi
}

# Ensure MySQL is running
if ! brew services list | grep -q "mysql.*started"; then
    echo "MySQL is not running. Starting MySQL..."
    brew services start mysql || error_exit "Failed to start MySQL."
fi

# Prompt for MySQL root password
prompt_mysql_password

# Secure MySQL using expect script
echo "Securing MySQL..."
expect <<EOF
spawn mysql_secure_installation
expect "Enter password for user root:"
send -- "\r"
expect {
    "New password:" {
        send -- "$root_password\r"
        expect "Re-enter new password:"
        send -- "$root_password\r"
        expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
    }
    "Set root password? \[Y/n\] :" {
        send -- "Y\r"
        expect "New password:"
        send -- "$root_password\r"
        expect "Re-enter new password:"
        send -- "$root_password\r"
        expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
    }
    "Enter current password for root (enter for none):" {
        send -- "\r"
        expect "Set root password? \[Y/n\] :"
        send -- "Y\r"
        expect "New password:"
        send -- "$root_password\r"
        expect "Re-enter new password:"
        send -- "$root_password\r"
        expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
    }
}
expect eof
EOF

# Check if mysql_secure_installation failed due to existing root password
if [ $? -ne 0 ]; then
    echo "MySQL secure installation failed. Attempting to reset root password..."

    # Stop MySQL service
    echo "Stopping MySQL service..."
    brew services stop mysql || error_exit "Failed to stop MySQL."

    # Start MySQL with skip-grant-tables
    echo "Starting MySQL without grant tables..."
    mysqld_safe --skip-grant-tables &> /dev/null &
    sleep 5 # Wait a bit for MySQL to start

    # Reset root password
    NEW_ROOT_PASSWORD="$root_password"
    echo "Resetting root password..."
    mysql -u root mysql <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '$NEW_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF

    if [ $? -eq 0 ]; then
        echo "Root password reset successfully."
    else
        error_exit "Failed to reset root password."
    fi

    # Stop MySQL service
    echo "Stopping MySQL service to revert to normal operation..."
    killall mysqld
    sleep 5 # Wait a bit for MySQL to stop

    # Start MySQL service normally
    echo "Starting MySQL service..."
    brew services start mysql || error_exit "Failed to start MySQL normally."

    echo "MySQL root password has been reset. New password: $NEW_ROOT_PASSWORD"

    # Secure MySQL using expect script again
    echo "Securing MySQL..."
    expect <<EOF
spawn mysql_secure_installation
expect "Enter password for user root:"
send -- "\r"
expect {
    "New password:" {
        send -- "$root_password\r"
        expect "Re-enter new password:"
        send -- "$root_password\r"
        expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
    }
    "Set root password? \[Y/n\] :" {
        send -- "Y\r"
        expect "New password:"
        send -- "$root_password\r"
        expect "Re-enter new password:"
        send -- "$root_password\r"
        expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
    }
    "Enter current password for root (enter for none):" {
        send -- "\r"
        expect "Set root password? \[Y/n\] :"
        send -- "Y\r"
        expect "New password:"
        send -- "$root_password\r"
        expect "Re-enter new password:"
        send -- "$root_password\r"
        expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
        expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
        send -- "y\r"
    }
}
expect eof
EOF

    if [ $? -eq 0 ]; then
        echo "MySQL secured successfully."
    else
        error_exit "Failed to secure MySQL after resetting root password."
    fi
else
    echo "MySQL secured successfully."
fi

# Define paths for Homebrew Apache
SITES_PATH="$HOME/Documents/Sites"
APACHE_DOC_ROOT="/opt/homebrew/var/www"
HTTPD_CONF="/opt/homebrew/etc/httpd/httpd.conf"
VHOSTS_CONF="/opt/homebrew/etc/httpd/extra/httpd-vhosts.conf"

# Backup configuration files (requires sudo)
echo "Backing up configuration files..."
if [ -f "$HTTPD_CONF" ]; then
    sudo cp "$HTTPD_CONF" "$HTTPD_CONF.bak" || error_exit "Error backing up httpd.conf."
else
    echo "httpd.conf not found, skipping backup."
fi
if [ -f "$VHOSTS_CONF" ]; then
    sudo cp "$VHOSTS_CONF" "$VHOSTS_CONF.bak" || error_exit "Error backing up httpd-vhosts.conf."
else
    echo "httpd-vhosts.conf not found, skipping backup."
fi

# Create a symbolic link for Sites directory, if it doesn't already exist
if [ ! -L "$APACHE_DOC_ROOT/Sites" ] && [ ! -d "$APACHE_DOC_ROOT/Sites" ]; then
    sudo ln -s "$SITES_PATH" "$APACHE_DOC_ROOT/Sites" && echo "Symbolic link created for Sites directory." || error_exit "Error creating symbolic link for Sites directory."
else
    echo "Sites directory link already exists."
fi

# Enable .htaccess overrides, if not already set
if ! grep -q "<Directory \"$APACHE_DOC_ROOT\">" "$HTTPD_CONF"; then
    echo "Enabling .htaccess overrides..."
    echo "
<Directory \"$APACHE_DOC_ROOT\">
    AllowOverride All
</Directory>
" | sudo tee -a "$HTTPD_CONF" > /dev/null || error_exit "Error setting AllowOverride."
    echo "AllowOverride set to All for DocumentRoot."
else
    echo "AllowOverride already set for DocumentRoot."
fi

# Uncomment the line to include the httpd-vhosts.conf file, if it's not already
if ! grep -q "^Include /opt/homebrew/etc/httpd/extra/httpd-vhosts.conf" "$HTTPD_CONF"; then
    echo "Including httpd-vhosts.conf in httpd.conf..."
    sudo sed -i '' 's/#Include \/opt\/homebrew\/etc\/httpd\/extra\/httpd-vhosts.conf/Include \/opt\/homebrew\/etc\/httpd\/extra\/httpd-vhosts.conf/' "$HTTPD_CONF" || error_exit "Error including httpd-vhosts.conf."
    echo "Virtual hosts configuration included."
else
    echo "Virtual hosts configuration already included."
fi

# Fix DocumentRoot warnings and set ServerName directive
if ! grep -q "ServerName localhost" "$HTTPD_CONF"; then
    echo "Setting ServerName in httpd.conf..."
    echo "ServerName localhost" | sudo tee -a "$HTTPD_CONF" > /dev/null || error_exit "Error setting ServerName."
fi
sudo sed -i '' 's|DocumentRoot "/opt/homebrew/opt/httpd/docs/dummy-host.example.com"|DocumentRoot "'"$APACHE_DOC_ROOT"'/Sites"|g' "$VHOSTS_CONF" || error_exit "Error fixing DocumentRoot."

# Restart Apache (requires sudo)
echo "Restarting Apache..."
sudo apachectl restart || error_exit "Error restarting Apache."
echo "Apache restarted successfully. Access your sites at http://localhost/Sites/site_folder_name"

echo "Static sites setup complete. Access your sites at http://localhost/Sites/site_folder_name"

# Start Apache automatically if not already running
if ! brew services list | grep -q "httpd.*started"; then
    echo "Starting Apache..."
    brew services start httpd || echo "Failed to start Apache using brew services. Try starting manually or check configuration."
else
    echo "Apache is already running."
fi

# Configure Apache to serve phpMyAdmin
echo "Configuring Apache..."
if [ ! -L "/opt/homebrew/var/www/phpmyadmin" ]; then
    sudo ln -s /opt/homebrew/share/phpmyadmin /opt/homebrew/var/www/phpmyadmin
fi
if ! grep -q "/opt/homebrew/var/www/phpmyadmin" "$HTTPD_CONF"; then
    echo "
Alias /phpmyadmin /opt/homebrew/share/phpmyadmin
<Directory /opt/homebrew/share/phpmyadmin>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride All
    <IfModule mod_authz_core.c>
        Require all granted
    </IfModule>
    <IfModule !mod_authz_core.c>
        Order allow,deny
        Allow from all
    </IfModule>
</Directory>
" | sudo tee -a "$HTTPD_CONF"
else
    echo "phpMyAdmin is already configured in Apache."
fi

# Restart Apache to apply changes (requires sudo)
echo "Restarting Apache..."
sudo apachectl restart || error_exit "Error restarting Apache."
echo "Apache restarted successfully."

# Create a basic phpMyAdmin configuration
if [ ! -f "/opt/homebrew/share/phpmyadmin/config.inc.php" ]; then
    echo "Creating phpMyAdmin configuration..."
    sudo cp /opt/homebrew/share/phpmyadmin/config.sample.inc.php /opt/homebrew/share/phpmyadmin/config.inc.php
    sudo sed -i '' "s/localhost/127.0.0.1/" /opt/homebrew/share/phpmyadmin/config.inc.php
else
    echo "phpMyAdmin configuration already exists​⬤