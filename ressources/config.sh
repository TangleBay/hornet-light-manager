#!/usr/bin/env bash

# Welcome to the Hornet leightweight installer!
# Please enter your desired values into the configuration accordingly. Afterwards please run the script again.
# If you have any questions about the individual steps, please have a look at the readme at https://github.com/TangleBay/hornet-light-installer.
# Have fun with your Hornet node!


############################################################################################################################################################
# CONFIG FOR THE HORNET INSTALLER
############################################################################################################################################################

# ARM = Raspberry PI3+/4 (DietPi 32bit) | ARM64 = Raspberry4 4GB (Ubuntu 64bit) | x86_64 = VPS/Root (64bit)
os=ARM

# You can specify a own username for the hornet node
user=iota


############################################################################################################################################################
# CONFIG FOR THE PROXY INSTALLER
############################################################################################################################################################

# Set your domain or your ddns name
domain=myhornetnode.ddns.net

# Set your prefered Trinity port (this port must be exposed in your router if you want to reach it from outside)
apiport=14266

# Set your prefered dashboard port (this port must be exposed in your router if you want to reach it from outside)
dashport=14267


############################################################################################################################################################
# CONFIG FOR THE TANGLE BAY INSTALLER
############################################################################################################################################################
# !!! IMPORTANT !!!
# You need first to set up the reverse proxy!!!

# Set your prefered shown node name
name="My Awesome Hornet Node"

# Set if your node should do proof of work in the pool
pow=false

# You can set a iota donation address if you want! Please keep in mind that you need to change it after spending from the address!!!
donationaddress=CP9LDJQPBNRBRWWNPI9XSUSLCTWZEBG9NMANXDWDJHMFSHSBVRIWGKVOCFWVETVBWBAKOZURNZE9NSCGDWEZXAXSFW

# Please let it empty! You will receive your password after adding your node to the Tangle Bay Dock
password=""

############################################################################################################################################################
############################################################################################################################################################
