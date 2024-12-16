#!/bin/bash

# Ujuzi STEMex Backend Setup Script
# Comprehensive setup for Strapi and PostgreSQL

# Exit on any error
set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Detect Linux distribution
detect_distribution() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo -e "${RED}Unsupported operating system${NC}"
        exit 1
    fi
}

# Install Node.js and npm
install_nodejs() {
    echo -e "${YELLOW}Installing Node.js and npm...${NC}"
    
    case $DISTRO in
        ubuntu|debian)
            # Add NodeSource repository for latest Node.js
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        
        fedora|centos|rhel)
            sudo dnf install -y nodejs npm
            ;;
        
        arch)
            sudo pacman -S --noconfirm nodejs npm
            ;;
        
        *)
            echo -e "${RED}Unsupported distribution. Please install Node.js manually.${NC}"
            exit 1
            ;;
    esac
}

# Install PostgreSQL based on distribution
install_postgresql() {
    echo -e "${YELLOW}Installing PostgreSQL...${NC}"
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y postgresql postgresql-contrib
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            ;;
        
        fedora|centos|rhel)
            sudo dnf install -y postgresql-server postgresql-contrib
            sudo postgresql-setup --initdb
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            
            # Configure PostgreSQL to allow password authentication
            sudo sed -i 's/ident/md5/g' /var/lib/pgsql/data/pg_hba.conf
            sudo systemctl restart postgresql
            ;;
        
        arch)
            sudo pacman -S --noconfirm postgresql
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            
            # Initialize PostgreSQL data directory if not already done
            if [ ! -d "/var/lib/postgres/data" ]; then
                sudo -u postgres initdb -D /var/lib/postgres/data
            fi
            ;;
        
        *)
            echo -e "${RED}Unsupported distribution. Please install PostgreSQL manually.${NC}"
            exit 1
            ;;
    esac
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Prerequisite checks
prereqs_check() {
    echo -e "${YELLOW}Checking and installing prerequisites...${NC}"
    
    # Detect distribution
    detect_distribution
    
    # Check and install Node.js
    if ! command_exists node; then
        echo -e "${YELLOW}Node.js not found. Installing...${NC}"
        install_nodejs
    fi

    # Check and install npm
    if ! command_exists npm; then
        echo -e "${YELLOW}npm not found. Installing...${NC}"
        case $DISTRO in
            ubuntu|debian)
                sudo apt-get install -y npm
                ;;
            fedora|centos|rhel)
                sudo dnf install -y npm
                ;;
            arch)
                sudo pacman -S --noconfirm npm
                ;;
        esac
    fi

    # Check and install PostgreSQL
    if ! command_exists psql; then
        echo -e "${YELLOW}PostgreSQL not found. Installing...${NC}"
        install_postgresql
    fi
}

# Database setup function
setup_database() {
    echo -e "${YELLOW}Setting up PostgreSQL database...${NC}"
    
    # Prompt for database details
    read -p "Enter database name: " DB_NAME
    read -p "Enter database user: " DB_USER
    read -sp "Enter database password: " DB_PASS
    echo ""

    # Determine PostgreSQL admin user
    PG_ADMIN_USER="postgres"

    # Create database
    sudo -u $PG_ADMIN_USER psql -c "DROP DATABASE IF EXISTS \"$DB_NAME\";"
    sudo -u $PG_ADMIN_USER psql -c "CREATE DATABASE \"$DB_NAME\";"

    # Create user with sudo
    sudo -u $PG_ADMIN_USER psql -c "CREATE USER \"$DB_USER\" WITH PASSWORD '$DB_PASS';"

    # Switch to the "ujuzi" database and grant privileges
    sudo -u $PG_ADMIN_USER psql -d $DB_NAME -c "GRANT ALL ON SCHEMA public TO \"$DB_USER\";"

    echo -e "${GREEN}Database $DB_NAME created and user $DB_USER granted privileges on the public schema.${NC}"
}

# Strapi project setup
create_strapi_project() {
    echo -e "${YELLOW}Setting up Strapi project...${NC}"
    
    # Prompt for project name
    read -p "Enter project name (used for project folder): " PROJECT_NAME

    # Check if project directory exists
    if [ -d "$PROJECT_NAME" ]; then
        echo -e "${YELLOW}Project directory '$PROJECT_NAME' already exists. Entering the directory and installing dependencies...${NC}"
        
        # Navigate to the project directory
        cd $PROJECT_NAME
        
        # Install or update dependencies
        npm install

        echo -e "${GREEN}Dependencies installed for existing project.${NC}"
    else
        # Create and navigate to project directory
        npx create-strapi-app@latest $PROJECT_NAME

        # Navigate to project directory
        cd $PROJECT_NAME

        echo -e "${GREEN}Strapi project created successfully!${NC}"
    fi

    # Update .env file with database configuration
    cat > .env << EOF
HOST=0.0.0.0
PORT=1337
APP_KEYS=$(openssl rand -base64 32),$(openssl rand -base64 32)
API_TOKEN_SALT=$(openssl rand -base64 16)
ADMIN_JWT_SECRET=$(openssl rand -base64 32)
TRANSFER_TOKEN_SALT=$(openssl rand -base64 16)

# Database Configuration
DATABASE_CLIENT=postgres
DATABASE_HOST=127.0.0.1
DATABASE_PORT=5432
DATABASE_NAME=$DB_NAME
DATABASE_USERNAME=$DB_USER
DATABASE_PASSWORD=$DB_PASS
DATABASE_SSL=false
EOF

    # Install PostgreSQL driver
    npm install pg
}

# Development environment setup
setup_dev_environment() {
    echo -e "${YELLOW}Setting up development environment...${NC}"
    
    # Install dependencies
    npm install
}

# Main script execution
main() {
    echo -e "${GREEN}Starting Ujuzi STEMex Backend Setup${NC}"
    
    # Check and install prerequisites
    prereqs_check
    
    # Setup database
    setup_database
    
    # Create Strapi project
    create_strapi_project
    
    # Setup development environment
    setup_dev_environment

    echo -e "${GREEN}Backend setup completed successfully!${NC}"
    echo -e "${YELLOW}To start the Strapi server, run: npm run develop${NC}"
}

# Run the main script
main
