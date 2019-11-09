#!/bin/bash

SERVER_PATH='Server/DNBC-Backend'

# ssh into EC2 instance on AWS
ssh -i "XXX.pem" ubuntu@ec2-XX-XXX-XX-XXX.us-east-2.compute.amazonaws.com << EOF

# Change into directory containing the server
cd $SERVER_PATH
    
# Stop the server
pm2 stop index

# Update the local server from master on github
git pull

# Restart the server
pm2 start index

# echo 'Server has been updated'
exit 

EOF
