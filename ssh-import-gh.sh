#!/bin/bash

# Prompt for the GitHub username
read -p "Enter the GitHub username: " github_user

# Define the URL for the GitHub keys
github_url="https://github.com/$github_user.keys"

# Create the .ssh directory if it doesn't exist
mkdir -p ~/.ssh

# Fetch the SSH keys and append them to the authorized_keys file
curl -s $github_url >> ~/.ssh/authorized_keys

# Set the correct permissions on the .ssh directory and authorized_keys file
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Confirm completion
echo "SSH keys from $github_user have been added to ~/.ssh/authorized_keys"

# Check if SSH service is running, and restart it if necessary
if systemctl is-active --quiet ssh; then
    echo "SSH service is running."
else
    echo "SSH service is not running. Starting SSH service..."
    sudo systemctl start ssh
fi

echo "Done!"
