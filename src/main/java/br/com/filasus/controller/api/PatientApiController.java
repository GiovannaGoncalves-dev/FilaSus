package br.com.filasus.controller.api;

import br.com.filasus.dao.DocumentoDAO;
import br.com.filasus.dao.UsuarioDAO;
import br.com.filasus.dao.UsuarioPerfilDAO;
import br.com.filasus.model.Documento;
import br.com.filasus.model.Usuario;
import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.util.AuthUtil;
import br.com.filasus.util.PasswordUtil;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;
import java.sql.SQLException;
import java.sql.SQLIntegrityConstraintViolationException;
import java.time.LocalDate;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Dados cadastrais do paciente autenticado consumidos pela tela Meus Dados. */
@WebServlet("/api/patients/*")
public class PatientApiController extends HttpServlet {
    private static final Pattern JSON_FIELD = Pattern.compile("\\\"([^\\\"]+)\\\"\\s*:\\s*\\\"((?:\\\\.|[^\\\"])*)\\\"");
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final UsuarioPerfilDAO perfilDAO = new UsuarioPerfilDAO();
    private final DocumentoDAO documentoDAO = new DocumentoDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Usuario autenticado = AuthUtil.getUsuarioLogado(request);
        PerfilUsuario perfil = AuthUtil.getPerfilAtivo(request);
        if (autenticado == null || perfil == null) {
            erro(response, HttpServletResponse.SC_UNAUTHORIZED, "Não autenticado.");
            return;
        }

        if (request.getPathInfo() == null || "/".equals(request.getPathInfo())) {
            if (perfil == PerfilUsuario.PACIENTE) {
                erro(response, HttpServletResponse.SC_FORBIDDEN, "Perfil sem permissão para listar pacientes.");
                return;
            }
            try {
                String search = request.getParameter("search");
                List<Usuario> pacientes = search == null || search.isBlank()
                        ? usuarioDAO.listarPacientes() : usuarioDAO.buscarPacientes(search);
                json(response, HttpServletResponse.SC_OK, pacientesJson(pacientes));
            } catch (SQLException e) {
                throw new IOException("Erro ao listar pacientes.", e);
            }
            return;
        }

        String cpfSolicitado = cpfDoCaminho(request.getPathInfo());
        if (cpfSolicitado == null || (perfil == PerfilUsuario.PACIENTE && !cpfSolicitado.equals(autenticado.getCpf()))) {
            erro(response, HttpServletResponse.SC_FORBIDDEN, "Acesso permitido somente aos próprios dados.");
            return;
        }

        try {
            Usuario paciente = usuarioDAO.buscarPorCpf(cpfSolicitado);
            if (paciente == null) {
                erro(response, HttpServletResponse.SC_NOT_FOUND, "Paciente não encontrado.");
                return;
            }
            List<Documento> documentos = documentoDAO.listarPorUsuario(cpfSolicitado);
            json(response, HttpServletResponse.SC_OK, "{\"patient\":" + pacienteJson(paciente, documentos) + "}");
        } catch (SQLException e) {
            throw new IOException("Erro ao consultar os dados do paciente.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        if (request.getPathInfo() != null && !"/".equals(request.getPathInfo())) {
            erro(response, HttpServletResponse.SC_NOT_FOUND, "Rota não encontrada.");
            return;
        }
        String body = request.getReader().lines().reduce("", (left, right) -> left + right);
        String cpf = field(body, "cpf").replaceAll("\\D", "");
        String nome = field(body, "name").trim();
        String email = field(body, "email").trim();
        String senha = field(body, "password");
        String nascimento = field(body, "birthDate");
        String telefone = field(body, "phone").replaceAll("\\D", "");
        if (cpf.length() != 11 || nome.length() < 3 || !email.contains("@") || senha.length() < 8
                || nascimento.isBlank() || telefone.length() < 10) {
            erro(response, HttpServletResponse.SC_BAD_REQUEST, "Preencha CPF, nome, e-mail, senha, nascimento e telefone corretamente.");
            return;
        }
        Usuario paciente = new Usuario();
        paciente.setCpf(cpf);
        paciente.setNome(nome);
        paciente.setEmail(email);
        paciente.setSenhaHash(PasswordUtil.hash(senha));
        paciente.setTelefone(telefone);
        paciente.setAtivo(true);
        try {
            paciente.setDataNascimento(LocalDate.parse(nascimento));
            if (usuarioDAO.existeCpf(cpf) || usuarioDAO.existeEmail(email)) {
                erro(response, HttpServletResponse.SC_CONFLICT, "CPF ou e-mail já cadastrado.");
                return;
            }
            usuarioDAO.inserir(paciente);
            try {
                perfilDAO.adicionar(cpf, PerfilUsuario.PACIENTE);
            } catch (SQLException e) {
                usuarioDAO.deletar(cpf);
                throw e;
            }
            json(response, HttpServletResponse.SC_CREATED, "{\"patient\":" + pacienteJson(paciente, List.of()) + "}");
        } catch (IllegalArgumentException e) {
            erro(response, HttpServletResponse.SC_BAD_REQUEST, "Data de nascimento inválida.");
        } catch (SQLIntegrityConstraintViolationException e) {
            erro(response, HttpServletResponse.SC_CONFLICT, "CPF ou e-mail já cadastrado.");
        } catch (SQLException e) {
            throw new IOException("Erro ao cadastrar paciente.", e);
        }
    }

    private String pacientesJson(List<Usuario> pacientes) {
        StringBuilder json = new StringBuilder("{\"patients\":[");
        for (int i = 0; i < pacientes.size(); i++) {
            if (i > 0) json.append(',');
            json.append(pacienteJson(pacientes.get(i), List.of()));
        }
        return json.append("]}").toString();
    }

    private String field(String json, String name) {
        Matcher matcher = JSON_FIELD.matcher(json == null ? "" : json);
        while (matcher.find()) {
            if (name.equals(matcher.group(1))) return matcher.group(2).replace("\\\"", "\"").replace("\\\\", "\\");
        }
        return "";
    }

    private String cpfDoCaminho(String pathInfo) {
        if (pathInfo == null || pathInfo.length() <= 1) return null;
        return URLDecoder.decode(pathInfo.substring(1), StandardCharsets.UTF_8).replaceAll("\\D", "");
    }

    private String pacienteJson(Usuario paciente, List<Documento> documentos) {
        StringBuilder json = new StringBuilder();
        json.append("{\"id\":\"").append(escapar(paciente.getCpf())).append("\"")
                .append(",\"name\":\"").append(escapar(paciente.getNome())).append("\"")
                .append(",\"cpf\":\"").append(escapar(paciente.getCpfFormatado())).append("\"")
                .append(",\"email\":\"").append(escapar(paciente.getEmail())).append("\"")
                .append(",\"phone\":\"").append(escapar(paciente.getTelefoneFormatado())).append("\"")
                .append(",\"birthDate\":").append(paciente.getDataNascimento() == null ? "null" : "\"" + paciente.getDataNascimento() + "\"")
                .append(",\"age\":").append(paciente.getIdade())
                .append(",\"documents\":[");
        for (int i = 0; i < documentos.size(); i++) {
            if (i > 0) json.append(',');
            Documento documento = documentos.get(i);
            json.append("{\"id\":").append(documento.getId())
                    .append(",\"fileName\":\"").append(escapar(nomeExibido(documento))).append("\"")
                    .append(",\"description\":\"").append(escapar(descricaoExibida(documento))).append("\"")
                    .append(",\"uploadedAt\":").append(documento.getEnviadoEm() == null ? "null" : "\"" + documento.getEnviadoEm() + "\"")
                    .append('}');
        }
        return json.append("]}").toString();
    }

    /** Nome que o usuário enviou; documentos antigos caem no nome gerado em disco. */
    private String nomeExibido(Documento documento) {
        String original = documento.getNomeOriginal();
        return original == null || original.isBlank() ? nomeArquivo(documento.getArquivoUrl()) : original;
    }

    /** Descrição informada na solicitação; sem ela, o tipo do documento. */
    private String descricaoExibida(Documento documento) {
        String descricao = documento.getDescricao();
        if (descricao != null && !descricao.isBlank()) return descricao;
        return documento.getTipo() == null ? "" : documento.getTipo().getDescricao();
    }

    private String nomeArquivo(String caminho) {
        if (caminho == null || caminho.isBlank()) return "";
        return Paths.get(caminho).getFileName().toString();
    }

    private void erro(HttpServletResponse response, int status, String mensagem) throws IOException {
        json(response, status, "{\"error\":\"" + escapar(mensagem) + "\"}");
    }

    private void json(HttpServletResponse response, int status, String conteudo) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(conteudo);
    }

    private String escapar(String valor) {
        if (valor == null) return "";
        return valor.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }
}
