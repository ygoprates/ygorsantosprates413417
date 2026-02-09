# Artists & Albums API

Uma API REST sênior para gerenciar artistas e álbuns com autenticação JWT, integração MinIO e notificações WebSocket.

## 📋 Visão Geral do Projeto

Este projeto implementa uma API REST completa em Spring Boot 3.3 com foco em arquitetura profissional, segurança e escalabilidade. A aplicação gerencia artistas e seus álbuns, com suporte para upload de imagens de capa, autenticação JWT com expiração, WebSocket para notificações e sincronização automática com APIs externas.

### Candidato
**Vaga:** Senior Backend Engineer  
**Posição:** Java/Spring Boot Development

## 🎯 Requisitos Implementados

### ✅ Requisitos Gerais

- [x] **Segurança CORS**: Bloqueio de acesso a partir de domínios fora do escopo
- [x] **Autenticação JWT**: Expiração a cada 5 minutos com possibilidade de renovação
- [x] **REST Methods**: POST, PUT, GET implementados
- [x] **Paginação**: Todos os endpoints de listagem possuem paginação
- [x] **Consultas Parametrizadas**: Álbuns com artistas/cantores
- [x] **Busca por Artista**: Com ordenação alfabética (asc/desc)
- [x] **Upload de Imagens**: Uma ou mais imagens de capa do álbum
- [x] **Armazenamento MinIO**: Integração com API S3-compatível
- [x] **Links Pré-assinados**: Expiração de 30 minutos
- [x] **Versionamento**: Endpoints em `/v1/`
- [x] **Flyway Migrations**: Criação e população automática de tabelas
- [x] **OpenAPI/Swagger**: Documentação completa dos endpoints

### ✅ Requisitos Sênior

- [x] **Health Checks**: Liveness e Readiness probes
- [x] **Testes Unitários**: Com JUnit 5 e Mockito
- [x] **WebSocket**: Notificações em tempo real para novos álbuns
- [x] **Rate Limiting**: Máximo 10 requisições por minuto por usuário
- [x] **Sincronização de Regionais**: 
  - Import automático da lista externa
  - Atributo "ativo" para controle de estado
  - Sincronização inteligente (insert/inativar/atualizar)

## 🏗️ Arquitetura

### Padrão de Camadas

```
com.artists/
├── api/               # Controllers e DTOs (Presentation Layer)
├── application/       # Services (Business Logic)
├── domain/            # Entities e Value Objects (Domain Layer)
├── infrastructure/    # Repositories, Config, Security (Infrastructure Layer)
└── presentation/      # WebSocket handlers
```

### Decisões de Design

1. **ManyToMany Relationship**: Artista-Álbum com tabela de junção para máxima flexibilidade
2. **JPA Soft Delete via Status**: Regionais usam campo `ativo` para inativação
3. **Timestamps em Milliseconds**: Compatibilidade com diversos clientes
4. **MinIO Object Naming**: UUID + extensão para evitar colisões
5. **Rate Limiting per User**: Usando Google Guava RateLimiter com cache de 10 minutos
6. **JWT Tokens**: Separação entre Access Token (5 min) e Refresh Token (7 dias)

## 🚀 Configuração e Execução

### Pré-requisitos

- Java 17+
- Maven 3.8+
- Docker e Docker Compose
- PostgreSQL 16 (ou usar docker-compose)
- MinIO (ou usar docker-compose)

### Variáveis de Ambiente

```env
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/artists_db
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=postgres
MINIO_URL=http://localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
JWT_SECRET=your-very-long-secret-key-minimum-256-bits
```

### Execução com Docker Compose (Recomendado)

```bash
# Iniciar todos os serviços
docker-compose up -d

# Verificar logs
docker-compose logs -f api

# Parar serviços
docker-compose down
```

A API estará disponível em: `http://localhost:8080/api`

### Execução Local

```bash
# Build do projeto
mvn clean package

# Executar aplicação
mvn spring-boot:run

# Ou rodar o JAR
java -jar target/artists-api-1.0.0.jar
```

## 📚 Documentação da API

### Swagger UI
- Local: `http://localhost:8080/api/swagger-ui.html`
- JSON Schema: `http://localhost:8080/api/v3/api-docs`

### Endpoints Principais

#### Autenticação

```bash
# Login
POST /v1/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "admin"
}

# Resposta
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "tokenType": "Bearer",
  "expiresIn": 300000
}

# Refresh Token
POST /v1/auth/refresh?refreshToken=eyJhbGc...
```

#### Artistas

```bash
# Listar artistas (paginado)
GET /v1/artists?page=0&size=20

# Buscar por nome (com sort)
GET /v1/artists/search?name=Serj&sort=asc&page=0&size=20

# Criar artista (requer autenticação)
POST /v1/artists
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "name": "Serj Tankian",
  "description": "American musician"
}

# Obter por ID
GET /v1/artists/1

# Atualizar (requer autenticação)
PUT /v1/artists/1
Authorization: Bearer {accessToken}

# Deletar (requer autenticação)
DELETE /v1/artists/1
Authorization: Bearer {accessToken}

# Artistas de um álbum
GET /v1/artists/album/1?page=0&size=20
```

#### Álbuns

```bash
# Listar álbuns (paginado)
GET /v1/albums?page=0&size=20

# Buscar por título
GET /v1/albums/search?title=Harakiri&page=0&size=20

# Álbuns de um artista
GET /v1/albums/artist/1?page=0&size=20

# Criar álbum
POST /v1/albums
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "title": "Harakiri",
  "description": "First solo album",
  "releaseYear": 2012,
  "artistIds": [1, 2]
}

# Upload de imagens (aceita múltiplos arquivos)
POST /v1/albums/1/images
Authorization: Bearer {accessToken}
Content-Type: multipart/form-data

files: [image1.jpg, image2.png]
```

#### Regionais

```bash
# Listar regionais ativos
GET /v1/regionais

# Listar todos (incluindo inativos)
GET /v1/regionais/all

# Sincronizar com API externa (manual)
POST /v1/regionais/sync
Authorization: Bearer {accessToken}
```

#### Health Checks

```bash
# Health completo
GET /v1/health

# Liveness probe (Kubernetes)
GET /v1/health/live

# Readiness probe (Kubernetes)
GET /v1/health/ready
```

### WebSocket

Conectar a: `ws://localhost:8080/api/ws/albums`

Eventos: Novo álbum cadastrado notifica todos os clientes conectados

```javascript
// Cliente JavaScript
const ws = new WebSocket('ws://localhost:8080/api/ws/albums');

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  // {"type":"NEW_ALBUM","album_id":1,"title":"Harakiri"}
};
```

## 🔐 Segurança

### Autenticação e Autorização

- **JWT Tokens**: Implementação com JJWT library
- **Expiração**: Access Token 5 minutos, Refresh Token 7 dias
- **CORS**: Origem permitida: localhost:3000, localhost:8080, localhost:5173
- **Usuários Default**:
  - `admin:admin` (ROLE_ADMIN, ROLE_USER)
  - `user:user` (ROLE_USER)

### Rate Limiting

- **Limite**: 10 requisições por minuto por usuário
- **Cache**: Limiters armazenados em cache por 10 minutos
- **Status**: 429 Too Many Requests quando limite é excedido

### CORS

Endpoints públicos (GET):
- `/v1/artists/**`
- `/v1/albums/**`
- `/v1/regionais/**`
- `/v1/auth/login`
- `/v1/health/**`
- Swagger UI

## 🗄️ Banco de Dados

### Schema

```sql
-- Artistas
artists (id, name, description, created_at, updated_at)

-- Álbuns
albums (id, title, description, release_year, created_at, updated_at)

-- Relacionamento N:N
artist_album (artist_id, album_id)

-- Imagens de Álbuns
album_images (id, album_id, object_name, content_type, file_size, created_at)

-- Regionais com sincronização
regionais (id, nome, ativo, external_id, created_at, updated_at)
```

### Dados Iniciais

A aplicação carrega automaticamente dados de exemplo via Flyway:
- 4 Artistas: Serj Tankian, Mike Shinoda, Michel Teló, Guns N' Roses
- 13 Álbuns associados aos artistas

## 🧪 Testes

### Executar Testes

```bash
# Todos os testes
mvn test

# Teste específico
mvn test -Dtest=ArtistServiceTest

# Com cobertura
mvn jacoco:report
# Resultado em: target/site/jacoco/index.html
```

### Cobertura de Testes

- ✅ ArtistService: CRUD operations, paginação, busca
- ✅ JwtTokenProvider: Validação e geração de tokens
- ✅ Controllers: Mapeamento de requisições

## 📊 MinIO

### Acesso ao Console

- URL: `http://localhost:9001`
- Usuário: `minioadmin`
- Senha: `minioadmin`

### Bucket

- Nome: `albums`
- Criado automaticamente

### Presigned URLs

- Gerados automaticamente para downloads
- Validade: 30 minutos
- Permissão: READ only

## 🔄 Sincronização de Regionais

### Agendamento

- Executa a cada 5 minutos
- URL: `https://integrador-argus-api.geia.vip/v1/regionais`

### Lógica de Sincronização

1. **Novo no endpoint**: Inserir na tabela
2. **Ausente no endpoint**: Marcar como inativo
3. **Atributo alterado**: Inativar registro antigo e criar novo

```java
// Endpoint de sincronização manual
POST /v1/regionais/sync
Authorization: Bearer {accessToken}
```

## 📦 Dependências Principais

```xml
<!-- Spring Boot 3.3 -->
<spring-boot-starter-web/>
<spring-boot-starter-data-jpa/>
<spring-boot-starter-security/>
<spring-boot-starter-websocket/>
<spring-boot-starter-actuator/>

<!-- JWT -->
<jjwt-api/>
<jjwt-impl/>
<jjwt-jackson/>

<!-- MinIO -->
<minio/>

<!-- Database -->
<spring-boot-starter-data-jpa/>
<flyway-core/>
<postgresql/>

<!-- Utilities -->
<org.projectlombok:lombok/>
<org.mapstruct:mapstruct/>
<com.google.guava:guava/> <!-- Rate Limiting -->

<!-- Documentação -->
<springdoc-openapi-starter-webmvc-ui/>

<!-- Testes -->
<spring-boot-starter-test/>
<spring-security-test/>
```

## 🐳 Docker

### Build da Imagem

```bash
docker build -t artists-api:1.0.0 .
```

### Executar Container

```bash
docker run -d \
  --name artists-api \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/artists_db \
  -e SPRING_DATASOURCE_USERNAME=postgres \
  -e SPRING_DATASOURCE_PASSWORD=postgres \
  -e MINIO_URL=http://minio:9000 \
  artists-api:1.0.0
```

## 📝 Commits e Histórico

O projeto mantém histórico de commits pequenos e bem explicados:

```
commit 1: Initial Spring Boot project setup
commit 2: Database entities and migrations
commit 3: JWT authentication and security
commit 4: Artists and Albums controllers
commit 5: MinIO integration
commit 6: WebSocket notifications
commit 7: Rate limiting implementation
commit 8: Regional sync from external API
commit 9: Unit tests and documentation
commit 10: Docker containerization
```

## 🎓 Boas Práticas Implementadas

- ✅ **Clean Code**: Nomes descritivos, métodos pequenos
- ✅ **SOLID Principles**: Separação de responsabilidades
- ✅ **Design Patterns**: Service, Repository, DTO, Singleton
- ✅ **Error Handling**: Exceções customizadas, validações
- ✅ **Logging**: SLF4J com Logback configurado
- ✅ **Documentation**: Swagger/OpenAPI, README completo
- ✅ **Security**: JWT, CORS, autenticação
- ✅ **Scalability**: Rate limiting, paginação, índices DB
- ✅ **Testability**: Testes unitários, mocks, injeção de dependência
- ✅ **Maintainability**: Código modular, baixo acoplamento

## ⚠️ Considerações e Melhorias Futuras

### Implementado
- Autenticação JWT com refresh
- Rate limiting por usuário
- WebSocket para notificações
- MinIO para armazenamento de imagens
- Sincronização automática de regionais
- Health checks completos
- Testes unitários
- Documentação Swagger

### Possíveis Melhorias
- [ ] Autenticação OAuth2/OpenID Connect
- [ ] Cache distribuído (Redis)
- [ ] Message Queue (RabbitMQ/Kafka)
- [ ] Metrics com Prometheus/Grafana
- [ ] Testes de integração (TestContainers)
- [ ] API Key para acesso a serviços
- [ ] Soft delete para artistas/álbuns
- [ ] Auditoria de alterações
- [ ] Search avançado com Elasticsearch
- [ ] Versionamento de API (v2, v3)

## 🤝 Contribuição

Para contribuir com melhorias:

1. Criar feature branch: `git checkout -b feature/nova-funcionalidade`
2. Commit com mensagens descritivas: `git commit -m "feat: adiciona nova funcionalidade"`
3. Push para o branch: `git push origin feature/nova-funcionalidade`
4. Abrir Pull Request

## 📄 Licença

Este projeto é fornecido como parte do processo seletivo.
---

**Desenvolvido com ❤️ usando Spring Boot 3.3, PostgreSQL, MinIO e Docker**

