#!/bin/bash
# Script to remove all OpenStack role assignments for a user

# Display usage if no arguments provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <user_email>"
    echo "Example: $0 user@example.com"
    exit 1
fi

# Find openstack command in PATH
OS=$(command -v openstack)
if [ -z "$OS" ]; then
    echo "Error: OpenStack CLI not found in PATH."
    echo "Please install it or make sure it's in your PATH."
    exit 2
fi

# Set field separator to newline for proper parsing
IFS=$'\n'
USER="$1"

echo "Removing OpenStack role assignments for user: $USER"
echo "Using openstack CLI at: $OS"

# Get the list of role assignments
echo "Fetching role assignments..."
assignments=$($OS role assignment list --user "$USER" --names -f value -c Role -c Project 2>/dev/null)

# Check if the openstack command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve role assignments. Check if:"
    echo "  - User '$USER' exists"
    echo "  - You have proper OpenStack credentials loaded"
    echo "  - OpenStack services are available"
    exit 3
fi

# Check if there are any assignments
if [ -z "$assignments" ]; then
    echo "No role assignments found for user: $USER"
    exit 0
fi

echo "Found the following role assignments:"
echo "$assignments"
echo "Removing assignments..."

# Counter for tracking successful removals
count=0

# Loop through each line of the assignments
while IFS= read -r line; do
    # Extract the role and project from the line
    ROLE=$(echo "$line" | awk '{print $1}')
    PROJECT_WITH_SUFFIX=$(echo "$line" | awk '{print $2}')
    
    # Strip the @nz suffix from project names
    # OpenStack returns project names with @nz suffix in role list,
    # but expects project names without this suffix in commands
    PROJECT=$(echo "$PROJECT_WITH_SUFFIX" | sed 's/@nz$//')
    
    echo "Removing role '$ROLE' from project '$PROJECT' (was '$PROJECT_WITH_SUFFIX') for user '$USER'..."
    
    # Remove the role from the project for the user
    $OS role remove --user "$USER" --project "$PROJECT" "$ROLE"
    
    # Check if removal was successful
    if [ $? -eq 0 ]; then
        ((count++))
        echo "  Success!"
    else
        echo "  Failed to remove role assignment."
    fi
done <<< "$assignments"

echo "Completed. Removed $count role assignment(s) for user: $USER"
