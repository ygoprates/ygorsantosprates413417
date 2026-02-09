# CONTRIBUTING.md

## Estrutura de Commits

Este projeto segue o padrão Conventional Commits para uma história clara e rastreável:

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### Tipos de Commit

- **feat**: Nova funcionalidade
- **fix**: Correção de bug
- **docs**: Alterações de documentação
- **style**: Formatação, sem mudança lógica
- **refactor**: Refatoração de código
- **perf**: Melhorias de performance
- **test**: Adição ou alteração de testes
- **chore**: Alterações build, deps, CI/CD
- **ci**: Alterações CI/CD

### Exemplos

```
feat(artists): adiciona busca por nome com ordenação

- Implementa endpoint GET /artists/search
- Adiciona suporte para sort asc/desc
- Adiciona testes unitários

Closes #123
```

```
fix(auth): corrige expiração do token JWT

Ajusta o cálculo de expiração que estava em segundos
para milissegundos.
```

## Como Adicionar Nova Funcionalidade

### 1. Criar Entity (Domain Layer)

```java
@Entity
@Table(name = "new_entities")
public class NewEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    // fields...
}
```

### 2. Criar Repository

```java
@Repository
public interface NewEntityRepository extends JpaRepository<NewEntity, Long> {
    // Query methods...
}
```

### 3. Criar DTO

```java
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NewEntityDTO {
    // fields with annotations...
}
```

### 4. Criar Service

```java
@Service
@Transactional
@RequiredArgsConstructor
public class NewEntityService {
    private final NewEntityRepository repository;
    
    // Business logic...
}
```

### 5. Criar Controller

```java
@RestController
@RequestMapping("/v1/new-entities")
@RequiredArgsConstructor
@Tag(name = "NewEntity", description = "NewEntity endpoints")
public class NewEntityController {
    private final NewEntityService service;
    
    @PostMapping
    @Operation(summary = "Create new entity")
    public ResponseEntity<NewEntityDTO> create(@RequestBody NewEntityDTO dto) {
        // implementation...
    }
    
    // other methods...
}
```

### 6. Criar Flyway Migration

```sql
-- V3__Add_new_entity_table.sql
CREATE TABLE new_entities (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

CREATE INDEX idx_new_entities_name ON new_entities(name);
```

### 7. Criar Testes

```java
@ExtendWith(MockitoExtension.class)
class NewEntityServiceTest {
    @Mock
    private NewEntityRepository repository;
    
    @InjectMocks
    private NewEntityService service;
    
    @Test
    void testCreateNewEntity() {
        // test implementation...
    }
}
```

## Guidelines de Código

### Nomenclatura

- Classes: PascalCase (e.g., `ArtistService`)
- Métodos: camelCase (e.g., `getArtistById`)
- Constantes: UPPER_SNAKE_CASE (e.g., `MAX_PAGE_SIZE`)
- Variáveis: camelCase (e.g., `artistName`)

### Anotações Obrigatórias

```java
// DTOs
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor

// Entities
@Entity
@Table(name = "table_name")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor

// Services
@Service
@Transactional
@RequiredArgsConstructor
@Slf4j

// Controllers
@RestController
@RequestMapping("/v1/resource")
@RequiredArgsConstructor
@Tag(name = "ResourceName", description = "...")
```

### Logging

Use SLF4J com Lombok:

```java
@Slf4j
public class MyService {
    public void myMethod() {
        log.info("Informação: {}", variable);
        log.debug("Debug: {}", variable);
        log.warn("Aviso: {}", variable);
        log.error("Erro: {}", exception);
    }
}
```

### Validação

```java
// Use anotações de validação
@NotNull(message = "Name cannot be null")
@Size(min = 1, max = 255, message = "Name must be between 1 and 255 characters")
private String name;

// No Controller
public void create(@Valid @RequestBody NewEntityDTO dto) {
    // Invalid data will return 400 Bad Request
}
```

## Testes

### Coverage Mínimo

- Services: 80%+
- Controllers: 70%+
- Repositories: 60%+

### Estrutura de Teste

```java
@Test
void testMethodName() {
    // Arrange
    SomeObject object = new SomeObject();
    
    // Act
    Object result = service.methodName(object);
    
    // Assert
    assertThat(result).isNotNull();
    assertThat(result.getValue()).isEqualTo(expectedValue);
}
```

### Executar com Coverage

```bash
mvn clean test jacoco:report
open target/site/jacoco/index.html
```

## Pull Request

### Checklist

- [ ] Código segue guidelines do projeto
- [ ] Testes adicionados/atualizados
- [ ] Documentação atualizada
- [ ] Nenhum breaking change
- [ ] Commits bem estruturados
- [ ] Build passa sem erros

### Template de PR

```markdown
## Descrição

Breve descrição da alteração

## Tipo de Alteração

- [ ] Bug fix
- [ ] Nova funcionalidade
- [ ] Breaking change
- [ ] Alteração de documentação

## Como Testar

Instruções para testar as alterações

## Screenshots (se aplicável)

Adicionar screenshots

## Checklist

- [ ] Código testado localmente
- [ ] Testes adicionados
- [ ] Documentação atualizada
- [ ] Nenhum erro de lint
```

## Versionamento

Este projeto segue [Semantic Versioning](https://semver.org/):

- MAJOR: Alterações incompatíveis
- MINOR: Nova funcionalidade compatível
- PATCH: Correção de bugs

Exemplo: `1.2.3`

## Release

```bash
# Criar nova versão
git tag -a v1.1.0 -m "Release version 1.1.0"

# Push tags
git push origin v1.1.0

# Docker build e push
docker build -t artists-api:1.1.0 .
docker tag artists-api:1.1.0 artists-api:latest
```

## Documentação de API

Toda nova funcionalidade deve incluir:

1. Anotação `@Operation` nos controllers
2. Anotações `@Parameter` para parâmetros
3. Exemplos de Request/Response
4. Códigos de status HTTP esperados

```java
@PostMapping
@Operation(
    summary = "Create new entity",
    description = "Create a new entity with the provided data",
    responses = {
        @ApiResponse(responseCode = "201", description = "Entity created successfully"),
        @ApiResponse(responseCode = "400", description = "Invalid input"),
        @ApiResponse(responseCode = "401", description = "Unauthorized")
    }
)
public ResponseEntity<NewEntityDTO> create(@RequestBody NewEntityDTO dto) {
    // implementation...
}
```

## Contato e Discussão

Para dúvidas, abra uma Issue ou Discussion no GitHub.

---

Obrigado por contribuir! 🎉
