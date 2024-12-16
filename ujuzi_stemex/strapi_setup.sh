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

# Database setup
setup_database() {
    echo -e "${YELLOW}Setting up PostgreSQL database...${NC}"
    
    # Prompt for database details
    read -p "Enter project name (used for database and project folder): " PROJECT_NAME
    read -p "Enter database user: " DB_USER
    read -sp "Enter database password: " DB_PASS
    echo ""

    # Determine PostgreSQL admin user
    PG_ADMIN_USER="postgres"

    # Create database
    sudo -u $PG_ADMIN_USER psql -c "CREATE DATABASE ${PROJECT_NAME}_db;"
    sudo -u $PG_ADMIN_USER psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
    sudo -u $PG_ADMIN_USER psql -c "GRANT ALL PRIVILEGES ON DATABASE ${PROJECT_NAME}_db TO $DB_USER;"

    # Export variables for later use
    export PROJECT_NAME
    export DB_NAME="${PROJECT_NAME}_db"
    export DB_USER
    export DB_PASS
}

# Strapi project setup
create_strapi_project() {
    echo -e "${YELLOW}Creating new Strapi project...${NC}"

    # Create and navigate to project directory
    npx create-strapi-app@latest $PROJECT_NAME --database postgres

    # Navigate to project directory
    cd $PROJECT_NAME

    # Configure database connection
    cat << EOF > config/database.js
module.exports = ({ env }) => ({
  connection: {
    client: 'postgres',
    connection: {
      host: env('DATABASE_HOST', '127.0.0.1'),
      port: env('DATABASE_PORT', 5432),
      database: env('DATABASE_NAME', '$DB_NAME'),
      user: env('DATABASE_USERNAME', '$DB_USER'),
      password: env('DATABASE_PASSWORD', '$DB_PASS'),
      ssl: env.bool('DATABASE_SSL', false),
    },
    debug: false,
  },
});
EOF

    # Create .env file with secure random secrets
    cat << EOF > .env
HOST=0.0.0.0
PORT=1337
APP_KEYS=$(openssl rand -base64 32),$(openssl rand -base64 32)
API_TOKEN_SALT=$(openssl rand -base64 16)
ADMIN_JWT_SECRET=$(openssl rand -base64 32)
TRANSFER_TOKEN_SALT=$(openssl rand -base64 16)
DATABASE_HOST=127.0.0.1
DATABASE_PORT=5432
DATABASE_NAME=$DB_NAME
DATABASE_USERNAME=$DB_USER
DATABASE_PASSWORD=$DB_PASS
EOF

    echo -e "${GREEN}Strapi project created successfully!${NC}"
}

# Development environment setup
setup_dev_environment() {
    echo -e "${YELLOW}Setting up development environment...${NC}"
    
    # Install dependencies
    npm install

    # Run database migrations
    npm run strapi db:migrate

    # Provide option to create admin user
    read -p "Do you want to create an admin user now? (y/n): " create_admin
    if [[ $create_admin == "y" || $create_admin == "Y" ]]; then
        npm run strapi admin:create-user
    fi
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
