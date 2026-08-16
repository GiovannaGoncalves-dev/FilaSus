# FilaSUS

Sistema web para organizar filas de atendimento em mutirões do SUS. A aplicação permite cadastrar pacientes, emitir e acompanhar senhas, solicitar prioridade, chamar o próximo paciente, registrar atendimentos e administrar unidades, mutirões, filas e usuários.

## Funcionalidades

O sistema possui acesso separado por perfil:

- **Paciente:** consulta a própria fila e o histórico, atualiza dados e envia solicitação de prioridade com documento.
- **Atendente:** cadastra e pesquisa pacientes, emite senhas e gerencia chamadas.
- **Médico:** inicia e finaliza atendimentos e valida solicitações de prioridade.
- **Administrador:** gerencia usuários, filas e mutirões e consulta relatórios.
- **Painel:** apresenta as chamadas da unidade para exibição pública.

Os dados operacionais são limitados à unidade ativa do usuário. Uma solicitação de prioridade é vinculada à senha e à fila específicas, evitando acesso ou aplicação de prioridade entre unidades diferentes.

## Tecnologias

- Java 17
- Jakarta/Java Servlet 4 e JSP
- HTML, CSS e JavaScript
- MySQL 8
- Apache Tomcat 9
- JDBC com MySQL Connector/J

## Pré-requisitos

Antes de executar o projeto, instale:

- JDK 17 ou superior;
- MySQL Server 8;
- MySQL Workbench;
- Apache Tomcat 9;
- Eclipse IDE for Enterprise Java and Web Developers.

## Executando localmente

### 1. Clone o repositório

```bash
git clone https://github.com/GiovannaGoncalves-dev/FilaSus.git
cd FilaSus
```

### 2. Configure o banco pelo MySQL Workbench

1. Inicie o MySQL Server.
2. Abra o MySQL Workbench e crie uma conexão com o servidor local.
3. Crie um banco de dados chamado `gerenciamento_fila2`.
4. No menu **File > Open SQL Script**, abra o arquivo `schema.sql` da raiz do projeto.
5. Selecione `gerenciamento_fila2` como schema padrão e execute todo o conteúdo do arquivo pelo botão de raio do Workbench.
6. Atualize a lista de schemas e confirme se as tabelas foram criadas.

Utilize o usuário e a senha da sua própria instalação do MySQL. Depois, informe essas credenciais na configuração da conexão da aplicação. A primeira conta de paciente pode ser criada pela tela pública de cadastro; usuários operacionais devem ser cadastrados por um administrador ou inseridos para o ambiente de desenvolvimento.

### 3. Importe o projeto no Eclipse

1. Abra **File > Import**.
2. Selecione **General > Existing Projects into Workspace**.
3. Escolha a pasta clonada do FilaSUS.
4. Confirme a importação.

O driver JDBC já está em `src/main/webapp/WEB-INF/lib/mysql-connector-j.jar`.

### 4. Configure o Tomcat

1. Abra a aba **Servers** no Eclipse.
2. Clique em **New > Server**.
3. Selecione **Apache Tomcat v9.0 Server** e informe a pasta de instalação.
4. Adicione o projeto `filasus` ao servidor.
5. Inicie o Tomcat pelo Eclipse.

Com a porta padrão do Tomcat, acesse:

```text
http://localhost:8080/filasus/
```

## Configuração da conexão

Por padrão, a classe `DBConnection` utiliza:

| Configuração | Valor padrão |
| --- | --- |
| Host | `localhost` |
| Porta | `3306` |
| Schema | `gerenciamento_fila2` |
| Usuário | `filasus` |
| Senha | `filasus123` |

Caso a conexão local tenha outros dados, configure as seguintes variáveis de ambiente no Tomcat:

| Variável | Valor padrão |
| --- | --- |
| `FILASUS_DB_URL` | `jdbc:mysql://localhost:3306/gerenciamento_fila2?useSSL=false&serverTimezone=America/Sao_Paulo&characterEncoding=UTF-8` |
| `FILASUS_DB_USER` | `filasus` |
| `FILASUS_DB_PASSWORD` | `filasus123` |

Essas credenciais são destinadas apenas ao desenvolvimento local. Use credenciais próprias e protegidas em outros ambientes.

## Arquivos enviados

Os comprovantes enviados nas solicitações de prioridade são armazenados, por padrão, em:

```text
$HOME/.filasus/uploads/
```

O banco guarda o caminho interno com UUID e também o nome original apresentado ao médico.

## Estrutura do projeto

```text
filasus/
├── schema.sql                          # Estrutura do banco
├── docs/                               # Documentação e relatórios de testes
└── src/main/
    ├── java/br/com/filasus/
    │   ├── controller/                 # Controllers Servlet tradicionais
    │   ├── controller/api/             # APIs JSON consumidas pelas telas
    │   ├── dao/                        # Acesso ao MySQL
    │   ├── filter/                     # Filtros HTTP e de autenticação
    │   ├── model/                      # Entidades e enumerações
    │   ├── service/                    # Regras de negócio
    │   └── util/                       # Banco, autenticação, senha e upload
    └── webapp/
        ├── css/                        # Estilos compartilhados
        ├── js/                         # Autenticação, componentes e utilitários
        ├── jsp/                        # Telas separadas por perfil
        └── WEB-INF/                    # Configuração e dependências web
```

## Autores

- Giovanna Gonçalves
- Matheus Souza Rosa
