### O processo
- Primeiros testes foram locais, criei o Dockerfile e o docker-compose para certificar que a api conseguiria rodar em um container. Após isso, subi o minikube e escrevi os manifestos, apliquei no cluster eee: Não rodou! :(
- Por que? Porque deu pau no minikube não conseguia se conectar ao meu driver local de docker para baixar a imagem da aplicação que eu havia criado com `docker build` :).
- Simplesmente rodei um `eval $(minikube docker-env)` comando que faz o minikube entender que o registry ou URL que queremos procurar a imagem é a minha própria maquina, ai funfou!
- Após tudo isso rodar comecei a configurar a monitoração com prometheus e grafana, pra ser rapido, facil e indolor, usei o helm padrao feito pela propria comunidade do prometheus, show! Sem problemas ele subiu ja e running 10/10.
- Facilitar tudo que precisa fazer criei os arquivos:
<br> - `setup.sh` que basicamente instala o minikube se voce nao tiver (so pra MAC M1, porque é o que eu uso)
<br> - `deploy.sh` instala o app e faz o processo descrito acima!
- Juntamente com todo o app que salva as coisas na memória eu adicionei no compose e um manifesto para o postgresql, caso a gente decida persistir os comentarios em um banco.

### Melhorias
- Poderiamos persistir os comentarios em um banco! (fazer o codigo mais profissional)
- Fazer metricas customnizadas na aplicacao e exportar para o prometheus, metricas como: http_request_duration_seconds, http_requests_total, http_response_status_total, comments_created_total.
- Implementar argocd para fazer o gitops da nossa app, entao cada vez que criassemos uma imagem docker nova e fizessemos o update da tag da imagem no monifesto o argocd veria a mudanca no repositorio e faria o cluster ficar no mesmo estado de versao do repo!

### Por que PostgreSQL?
* É um banco robusto, open-source e super usado em produção.
- Suporta consultas complexas, relacionamentos e tem boa performance. Fácil de rodar com Docker e já tem suporte nativo no SQLAlchemy (que podemos utilizar um ORM qualquer para facil integração).
Se um dia precisar escalar, ele aguenta bem (ex: usando read replicas).

### Por que nosso Service é do tipo NodePort?
* Como estamos rodando no Minikube, precisamos expor a API pra conseguir acessar de fora.
 - NodePort libera uma porta no próprio nó do cluster pra gente acessar via IP do Minikube.
 - No EKS ou GKE, a gente trocaria isso por um LoadBalancer ou Ingress.

### O que e por que Minikube?
- Ótimo pra testar aplicações Kubernetes localmente antes de jogar no EKS/GKE.
- Simula um cluster de verdade, então já testamos os manifests sem custo de cloud.
- É leve e fácil de subir/apagar, então agiliza os testes.

### O que? Docker Compose tambem?
- Antes de jogar no Kubernetes, a gente quer testar rápido se tudo funciona.
- `docker-compose` sobe banco e API juntos, sem precisar escrever um YAML gigante.
- Mantemos o mesmo PostgreSQL, variáveis de ambiente e estrutura que usaremos no cluster.
- Fácil de rodar (docker-compose up -d) e derrubar (docker-compose down).

### Ok legal, Mas Prometheus?
- Tool padrão pra monitorar métricas em Kubernetese open-source.
- Fácil de integrar com o alguns SDK para exportar metricas customizadas da aplicação, usando somente um path de metricas tipo: `/metrics`.
- Faz coleta e armazenamento de métricas direto do cluster, sem precisar de outro banco.
Junto com o Grafana, fica fácil pra visualizar consumo de CPU, latência de requisições, etc.

### Eu li Grafana? Whaat?
- Interface **bonita/linda** e flexível pra monitorar tudo.
- Conecta direto no Prometheus pra exibir métricas em dashboards.
- Dá pra criar alertas, visualizar logs e métricas de várias fontes (CloudWatch, Datadog, etc.).
- Já tem templates prontos pra Kubernetes, então dá pra subir um dashboard super rápido.