#!/bin/bash -
#Shouldnt need to be ran in axiom droplet
#this is for install and use on ubuntu 20.04 for testing
apt update && apt upgrade -y
apt install chromium

snap install amass
