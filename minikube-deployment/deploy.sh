#!/bin/bash

set -e

echo "Iniciando o Minikube..."
minikube start --driver=docker

echo "Configurando Docker dentro do Minikube..."
eval $(minikube docker-env)

echo "Construindo a imagem Docker da API..."
docker build -t comments-api:latest .

echo "Criando namespace para monitoramento..."
kubectl create namespace monitoring || echo "Namespace já existe, continuando..."

echo "Adicionando repositórios do Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo "Instalando Prometheus e Grafana..."
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring || echo "Prometheus já instalado"

echo "Aguardando pods do Prometheus e Grafana iniciarem..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus-grafana -n monitoring || true

echo "Aplicando configurações do PostgreSQL..."
kubectl apply -f postgres.yaml

echo "Aplicando o deployment da API..."
kubectl apply -f api.yaml

echo "Aguardando pods da API iniciarem..."
kubectl wait --for=condition=available --timeout=120s deployment/comments-api

echo "Deploy finalizado com sucesso!"

echo "Acesse a API em: $(minikube service comments-api --url)"
echo "Para acessar o Grafana, rode: kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
echo "Login no Grafana: admin / prom-operator"
