#!/usr/bin/env bash

[ -f ~/.profile ] && source ~/.profile
set -e

echo "Adding Erlang Solutions repo"
sudo wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
sudo dpkg -i erlang-solutions_1.0_all.deb

echo "Updating apt-get"
sudo apt-get update

echo "Installing git"
sudo apt-get install git

echo "Installing node and npm"
sudo apt-get -y install nodejs-legacy
sudo apt-get -y install npm

echo "Installing the Erlang/OTP platform and all of its applications"
sudo apt-get -y install esl-erlang

echo "Installing Elixir"
sudo apt-get install elixir

echo "Installing Elm"
sudo npm install -g elm

echo "Install and setup Postgresql"
sudo apt-get -y install postgresql postgresql-contrib
