# ARCHITECTURE.md

## 🏗️ Arquitetura da Aplicação

### Visão Geral

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENT APPLICATIONS                      │
│           (Web Browser, Mobile, Third-party API)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ HTTP/HTTPS + JWT
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   SPRING BOOT 3.3 API                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         REST Controllers (Presentation Layer)        │   │
│  │  - AuthController, ArtistController, AlbumController│   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │          Security & Filters                          │   │
│  │  - JwtAuthenticationFilter, RateLimitingFilter      │   │
│  │  - CORS Configuration, SecurityConfig               │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │    Application Services (Business Logic Layer)      │   │
│  │  - ArtistService, AlbumService, AuthService         │   │
│  │  - MinIOService, RegionalService                    │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │    Infrastructure Layer                             │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │ Repositories (Data Access)                   │   │   │
│  │  │ - ArtistRepository, AlbumRepository, etc.    │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  │                                                      │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │ Configuration                                │   │   │
│  │  │ - JwtTokenProvider, SecurityConfig           │   │   │
│  │  │ - MinIOConfig, WebSocketConfig               │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         │                    │                    │
    PostgreSQL            MinIO S3          WebSocket
    Database              Storage           Notifications
     (Flyway)           (Images)             (Clients)
```

## 📦 Camadas e Componentes

### 1. Presentation Layer (API)

Responsabilidades:
- Receber requisições HTTP
- Validar entrada de dados
- Formatar respostas JSON
- Mapear entre DTOs e entidades

```java
// Exemplo: AuthController
@RestController
@RequestMapping("/v1/auth")
public class AuthController {
    @PostMapping("/login")
    public ResponseEntity<LoginResponseDTO> login(@RequestBody LoginRequestDTO request)
}
```

### 2. Security Layer

Responsabilidades:
- Autenticação JWT
- Rate Limiting
- CORS
- Autorização

```
Request → JwtAuthenticationFilter → RateLimitingFilter → Controller
           ↓                         ↓
       Token Validation        Requests/min Check
```

### 3. Application/Service Layer

Responsabilidades:
- Lógica de negócio
- Transações
- Orquestração entre repositórios
- Validações complexas

```java
@Service
@Transactional
public class ArtistService {
    public ArtistDTO createArtist(ArtistDTO dto) {
        // Validar entrada
        // Persistir no banco
        // Notificar listeners
        // Retornar resultado
    }
}
```

### 4. Domain Layer

Responsabilidades:
- Definir entidades
- Mapeamento ORM
- Relacionamentos

```java
@Entity
public class Artist {
    @ManyToMany(mappedBy = "artists")
    private Set<Album> albums;
}
```

### 5. Infrastructure Layer

Responsabilidades:
- Acesso a dados (Repositories)
- Integração com serviços externos
- Configurações técnicas

```java
// Repository
public interface ArtistRepository extends JpaRepository<Artist, Long>

// MinIO Service
public class MinIOService {
    public String uploadImage(MultipartFile file)
}

// JWT Provider
public class JwtTokenProvider {
    public String generateAccessToken(Authentication auth)
}
```

## 🗄️ Modelo de Dados (ER Diagram)

```
┌──────────────────┐
│    ARTISTS       │
├──────────────────┤
│ id (PK)          │
│ name (UNIQUE)    │
│ description      │
│ created_at       │
│ updated_at       │
└──────────────────┘
         │
         │ N:M (through artist_album)
         │
┌──────────────────┐
│    ALBUMS        │
├──────────────────┤
│ id (PK)          │
│ title            │
│ description      │
│ release_year     │
│ created_at       │
│ updated_at       │
└──────────────────┘
         │
         │ 1:N
         │
┌──────────────────────┐
│   ALBUM_IMAGES       │
├──────────────────────┤
│ id (PK)              │
│ album_id (FK)        │
│ object_name (MinIO)  │
│ content_type         │
│ file_size            │
│ created_at           │
└──────────────────────┘


┌──────────────────────┐
│    REGIONAIS         │
├──────────────────────┤
│ id (PK)              │
│ nome                 │
│ ativo (soft delete)  │
│ external_id (Sync)   │
│ created_at           │
│ updated_at           │
└──────────────────────┘
```

## 🔄 Fluxos Principais

### 1. Fluxo de Login

```
Client
   │
   ├─→ POST /auth/login {username, password}
   │
Server
   │
   ├─→ AuthController.login()
   │
   ├─→ AuthenticationManager.authenticate()
   │
   ├─→ JwtTokenProvider.generateAccessToken()
   │
   ├─→ JwtTokenProvider.generateRefreshToken()
   │
   └─→ LoginResponseDTO {accessToken, refreshToken}
   
Client recebe token e o inclui em requests subsequentes
```

### 2. Fluxo de Requisição Autenticada

```
Client
   │
   ├─→ GET /albums {Authorization: Bearer {token}}
   │
Server
   │
   ├─→ JwtAuthenticationFilter
   │   ├─→ Extract token from header
   │   ├─→ JwtTokenProvider.validateToken()
   │   └─→ Set SecurityContext
   │
   ├─→ RateLimitingFilter
   │   └─→ Check if user exceeded limit (10 req/min)
   │
   ├─→ AlbumController.getAllAlbums()
   │
   ├─→ AlbumService.getAllAlbums()
   │
   ├─→ AlbumRepository.findAllWithArtists()
   │
   └─→ Page<AlbumDTO> {content, page info}
```

### 3. Fluxo de Sincronização Regional

```
Agendador (5 em 5 minutos)
   │
   ├─→ RegionalService.syncRegionais()
   │
   ├─→ RestTemplate.getForObject(EXTERNAL_API_URL)
   │
   ├─→ Para cada regional externo:
   │   ├─→ Existe localmente?
   │   │   ├─→ Sim: atributo mudou?
   │   │   │   ├─→ Sim: inativar antigo, inserir novo
   │   │   │   └─→ Não: fazer nada
   │   │   └─→ Não: inserir novo
   │
   ├─→ Para cada regional local não encontrado:
   │   └─→ Marcar como inativo
   │
   └─→ Done
```

### 4. Fluxo de Upload de Imagem

```
Client
   │
   ├─→ POST /albums/1/images {files: [file1, file2]}
   │
Server
   │
   ├─→ AlbumController.uploadImages()
   │
   ├─→ Para cada arquivo:
   │   ├─→ MinIOService.uploadImage()
   │   │   ├─→ Generate UUID filename
   │   │   └─→ Upload to MinIO bucket
   │   │
   │   └─→ AlbumImageRepository.save()
   │       └─→ Persiste metadados no banco
   │
   └─→ 201 Created
```

### 5. Fluxo WebSocket - Novo Álbum

```
Client 1
   │
   ├─→ POST /albums {título, artistas}
   │
Server
   │
   ├─→ AlbumService.createAlbum()
   │
   ├─→ AlbumRepository.save()
   │
   ├─→ AlbumWebSocketHandler.notifyAllClients()
   │   └─→ {type: "NEW_ALBUM", id: 123, title: "..."}
   │
Server
   └─→ Conecta a todos os clients via WebSocket
       │
       ├─→ Client 1 (também recebe)
       │
       ├─→ Client 2 (navegador)
       │
       └─→ Client 3 (mobile)
```

## ⚙️ Padrões de Design Utilizados

### 1. Repository Pattern
```java
// Abstrai acesso a dados
ArtistRepository extends JpaRepository<Artist, Long>
```

### 2. Service/Business Logic Pattern
```java
@Service
public class ArtistService {
    // Centraliza lógica de negócio
    // Coordena repositories
    // Encapsula validações
}
```

### 3. DTO (Data Transfer Object)
```java
// Desacopla API de entidades
ArtistDTO vs Artist entity
```

### 4. Dependency Injection
```java
@RequiredArgsConstructor  // Constructor injection
private final ArtistRepository repository;
```

### 5. Strategy Pattern (Rate Limiting)
```java
// RateLimiter é estratégia de controle
RateLimiter rateLimiter = RateLimiter.create(rps);
```

## 🔐 Segurança - Camadas

```
┌─────────────────────────────────────────┐
│ 1. Transport Security (HTTPS/TLS)       │
│    - Em produção, todos os dados criptografados
└─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────┐
│ 2. CORS Validation                      │
│    - Verifica origem da requisição      │
└─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────┐
│ 3. JWT Authentication                   │
│    - Valida token, extrai usuário       │
└─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────┐
│ 4. Authorization (RBAC)                 │
│    - Verifica permissões por role       │
└─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────┐
│ 5. Rate Limiting                        │
│    - Controla requisições por usuário   │
└─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────┐
│ 6. Input Validation                     │
│    - Valida dados de entrada            │
└─────────────────────────────────────────┘
```

## 🚀 Escalabilidade - Considerações Futuras

### Bancos de Dados
```
Atual: PostgreSQL único
Futuro: 
  - Read replicas para queries pesadas
  - Sharding por artist_id
  - Particionamento de tabelas grandes
```

### Cache
```
Futuro:
  - Redis para cache de artistas/álbuns
  - Cache de regionais
  - Presigned URLs cache
```

### Message Queue
```
Futuro:
  - RabbitMQ/Kafka para eventos
  - Async notifications
  - Regional sync decoupled
```

### Load Balancing
```
Futuro:
  - Multiple API instances
  - API Gateway (Kong, Traefik)
  - Session affinity para WebSocket
```

## 📊 Performance

### Índices Database
```sql
-- Criados automaticamente via Flyway
CREATE INDEX idx_artist_name ON artists(name);
CREATE INDEX idx_album_title ON albums(title);
CREATE INDEX idx_album_images_album_id ON album_images(album_id);
CREATE INDEX idx_regionais_ativo ON regionais(ativo);
```

### Paginação
```
- Padrão: 20 itens por página
- Máximo: 100 itens por página
- Offset-based pagination
```

### Connection Pool
```
- HikariCP: 20 conexões máximo
- Min idle: 5 conexões
- Timeout: 30 segundos
```

---

**Última atualização**: Janeiro 2026
