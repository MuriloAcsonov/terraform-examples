#!/bin/bash

set -e

echo "Caso voce nao tenha configurado o minikube no seu Mac (M1)..."
echo "Baixando o binario do minikube"
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-darwin-arm64
echo "Instalando o binario do minikube"
sudo install minikube-darwin-arm64 /usr/local/bin/minikube
rm -rf minikube-darwin-arm64

echo "Minikube instalado..."