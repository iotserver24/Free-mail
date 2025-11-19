#!/bin/bash
# Bash script to setup database
# Run this from the project root

export PGPASSWORD="18751@Anish"
HOST="193.24.208.154"
DATABASE="chat"
USER="postgres"

echo "Setting up database tables..."

psql -h $HOST -U $USER -d $DATABASE -f db/init.sql

if [ $? -eq 0 ]; then
    echo "Database setup complete!"
else
    echo "Error setting up database. Please check your connection and credentials."
    exit 1
fi

