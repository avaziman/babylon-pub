#!/bin/bash

set -e

echo "Checking and installing Docker in Ubuntu (if needed)..."
if ! command -v docker &>/dev/null; then
    echo "Docker is not installed. Installing..."
    sudo apt-get update -y && sudo apt-get upgrade -y
    sudo apt-get install -y curl
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker "$USER"
    echo "Docker installed. You may need to log out and back in for Docker permissions to take effect."
else
    echo "Docker is already installed."
fi

echo "Checking and installing Docker Compose plugin (if needed)..."
if ! docker compose version &>/dev/null; then
    echo "Docker Compose plugin is not installed. Installing..."
    sudo apt-get update -y
    sudo apt-get install -y docker-compose-plugin
    echo "Docker Compose plugin installed."
else
    echo "Docker Compose plugin is already installed."
fi

echo "Checking for docker-compose.yml and launching containers..."
if [ -f docker-compose.yml ]; then
    echo "Found docker-compose.yml. Pulling and launching containers..."
    docker compose pull
    docker compose up
    echo "Containers are up and running."
else
    echo "docker-compose.yml not found in the current directory."
    exit 1
fi

echo "Ubuntu Setup complete."

cleanup() {
    echo "Stopping Docker Compose..."
    docker compose down
    echo "Docker Compose stopped."
}

trap cleanup EXIT
