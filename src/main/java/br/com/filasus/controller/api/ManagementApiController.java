package br.com.filasus.controller.api;

import br.com.filasus.dao.AtendimentoDAO;
import br.com.filasus.dao.DocumentoDAO;
import br.com.filasus.dao.ItemFilaDAO;
import br.com.filasus.dao.UsuarioDAO;
import br.com.filasus.dao.UsuarioPerfilDAO;
import br.com.filasus.dao.UsuarioUnidadeDAO;
import br.com.filasus.dao.UnidadeDAO;
import br.com.filasus.dao.FilaDAO;
import br.com.filasus.dao.MutiraoDAO;
import br.com.filasus.model.Atendimento;
import br.com.filasus.model.Documento;
import br.com.filasus.model.ItemFila;
import br.com.filasus.model.Usuario;
import br.com.filasus.model.Unidade;
import br.com.filasus.model.Fila;
import br.com.filasus.model.Mutirao;
import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.model.enums.StatusItemFila;
import br.com.filasus.model.enums.StatusValidacaoDocumento;
import br.com.filasus.model.enums.TipoDocumento;
import br.com.filasus.util.AuthUtil;
import br.com.filasus.util.PasswordUtil;
import br.com.filasus.util.UploadUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.Part;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/** APIs de usuários, atendimentos e validações de prioridade. */
@WebServlet(urlPatterns = {"/api/users", "/api/users/*", "/api/units", "/api/attendance", "/api/attendance/*",
        "/api/priority", "/api/priority/*"})
@MultipartConfig(maxFileSize = 10 * 1024 * 1024)
public class ManagementApiController extends HttpServlet {
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final UsuarioPerfilDAO perfilDAO = new UsuarioPerfilDAO();
    private final UsuarioUnidadeDAO unidadeDAO = new UsuarioUnidadeDAO();
    private final UnidadeDAO unidadeCadastroDAO = new UnidadeDAO();
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();
    private final AtendimentoDAO atendimentoDAO = new AtendimentoDAO();
    private final DocumentoDAO documentoDAO = new DocumentoDAO();
    private final FilaDAO filaDAO = new FilaDAO();
    private final MutiraoDAO mutiraoDAO = new MutiraoDAO();

    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
        if ("PATCH".equalsIgnoreCase(request.getMethod())) { doPatch(request, response); return; }
        super.service(request, response);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            String route = route(request);
            if ("/api/users".equals(route)) listUsers(request, response);
            else if ("/api/units".equals(route)) listUnits(request, response);
            else if ("/api/attendance".equals(route)) currentAttendance(request, response);
            else if ("/api/priority".equals(route)) priorities(request, response);
            else ApiSupport.error(response, 404, "Rota não encontrada.");
        } catch (SecurityException e) {
            ApiSupport.error(response, 403, e.getMessage());
        } catch (SQLException e) {
            throw new IOException("Erro ao consultar dados administrativos.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
        try {
            String route = route(request);
            if ("/api/users".equals(route)) createUser(request, response);
            else if ("/api/attendance".equals(route)) startAttendance(request, response);
            else if ("/api/priority".equals(route)) requestPriority(request, response);
            else ApiSupport.error(response, 404, "Rota não encontrada.");
        } catch (SecurityException e) {
            ApiSupport.error(response, 403, e.getMessage());
        } catch (IllegalArgumentException e) {
            ApiSupport.error(response, 400, e.getMessage());
        } catch (SQLException e) {
            throw new IOException("Erro ao gravar dados administrativos.", e);
        }
    }

    protected void doPatch(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            String route = route(request);
            if (route.startsWith("/api/users/")) updateUser(request, response);
            else if (route.startsWith("/api/attendance/")) finishAttendance(request, response);
            else if (route.startsWith("/api/priority/")) validatePriority(request, response);
            else ApiSupport.error(response, 404, "Rota não encontrada.");
        } catch (SecurityException e) {
            ApiSupport.error(response, 403, e.getMessage());
        } catch (IllegalArgumentException e) {
            ApiSupport.error(response, 400, e.getMessage());
        } catch (SQLException e) {
            throw new IOException("Erro ao atualizar dados administrativos.", e);
        }
    }

    private void listUsers(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        require(request, PerfilUsuario.ADM_UNIDADE, PerfilUsuario.ADM_GERAL);
        PerfilUsuario role = parseRole(request.getParameter("role"));
        List<Usuario> users = usuarioDAO.listarPorPerfil(role == null ? PerfilUsuario.PACIENTE : role);
        StringBuilder json = new StringBuilder("{\"users\":[");
        boolean primeiro = true;
        for (Usuario u : users) {
            if (!daMinhaUnidade(request, u)) continue; // usuário de outra unidade não aparece
            if (!primeiro) json.append(',');
            json.append(userJson(u, role));
            primeiro = false;
        }
        ApiSupport.json(response, 200, json.append("]}").toString());
    }

    /** Usuário sem vínculo (paciente) é visível a todos; com vínculo, só na própria unidade. */
    private boolean daMinhaUnidade(HttpServletRequest request, Usuario alvo) {
        if (alvo.getUnidadeIds() == null || alvo.getUnidadeIds().isEmpty()) return true;
        Integer minha = AuthUtil.getUnidadeAtiva(request);
        return minha != null && alvo.getUnidadeIds().contains(minha);
    }

    /** Recusa senha/fila de outra unidade nas operações de atendimento. */
    private void exigirFilaDaMinhaUnidade(HttpServletRequest request, int idFila) throws SQLException {
        Fila fila = filaDAO.buscarPorId(idFila);
        Mutirao mutirao = fila == null ? null : mutiraoDAO.buscarPorId(fila.getIdMutirao());
        Integer minha = AuthUtil.getUnidadeAtiva(request);
        if (mutirao == null || minha == null || mutirao.getIdUnidade() != minha) {
            throw new SecurityException("Senha de outra unidade.");
        }
    }

    /** Unidade em que o paciente tem senha (ativa ou a mais recente). */
    private Integer unidadeDoPaciente(String cpf) throws SQLException {
        for (ItemFila item : itemFilaDAO.listarPorPaciente(cpf)) {
            Fila fila = filaDAO.buscarPorId(item.getIdFila());
            Mutirao mutirao = fila == null ? null : mutiraoDAO.buscarPorId(fila.getIdMutirao());
            if (mutirao != null) return mutirao.getIdUnidade();
        }
        return null;
    }

    /** Resolve a unidade pela senha vinculada à solicitação, sem inferir pelo CPF. */
    private Integer unidadeDoDocumento(Documento doc) throws SQLException {
        if (doc.getIdFila() != null && doc.getSequenciaItemFila() != null) {
            Fila fila = filaDAO.buscarPorId(doc.getIdFila());
            Mutirao mutirao = fila == null ? null : mutiraoDAO.buscarPorId(fila.getIdMutirao());
            return mutirao == null ? null : mutirao.getIdUnidade();
        }
        return unidadeDoPaciente(doc.getCpfUsuario()); // compatibilidade com documentos anteriores à associação
    }

    private String userJson(Usuario u, PerfilUsuario role) throws SQLException {
        String frontendRole = role == null ? "paciente" : role.toJson();
        if (frontendRole.startsWith("adm_")) frontendRole = "admin_unidade";
        return "{\"id\":" + ApiSupport.quote(u.getCpf()) + ",\"cpf\":" + ApiSupport.quote(u.getCpfFormatado())
                + ",\"name\":" + ApiSupport.quote(u.getNome()) + ",\"email\":" + ApiSupport.quote(u.getEmail())
                + ",\"role\":" + ApiSupport.quote(frontendRole) + ",\"specialty\":" + ApiSupport.quote(u.getEspecialidade())
                + ",\"unitId\":" + (u.getUnidadeIds().isEmpty() ? "null" : u.getUnidadeIds().get(0))
                + ",\"unitName\":" + ApiSupport.quote(unitName(u))
                + ",\"active\":" + u.isAtivo() + ",\"createdAt\":" + ApiSupport.quote(u.getCriadoEm() == null ? null : u.getCriadoEm().toString()) + "}";
    }

    private String unitName(Usuario user) throws SQLException {
        if (user.getUnidadeIds().isEmpty()) return null;
        Unidade unit = unidadeCadastroDAO.buscarPorId(user.getUnidadeIds().get(0));
        return unit == null ? null : unit.getNome();
    }

    private void listUnits(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        require(request, PerfilUsuario.ADM_UNIDADE, PerfilUsuario.ADM_GERAL);
        List<Unidade> units = unidadeCadastroDAO.listarTodas();
        StringBuilder json = new StringBuilder("{\"units\":[");
        for (int i = 0; i < units.size(); i++) {
            if (i > 0) json.append(',');
            Unidade unit = units.get(i);
            json.append("{\"id\":").append(unit.getId())
                    .append(",\"name\":").append(ApiSupport.quote(unit.getNome()))
                    .append(",\"address\":").append(ApiSupport.quote(unit.getEndereco())).append('}');
        }
        ApiSupport.json(response, 200, json.append("]}").toString());
    }

    private void createUser(HttpServletRequest request, HttpServletResponse response) throws IOException, SQLException {
        require(request, PerfilUsuario.ADM_UNIDADE, PerfilUsuario.ADM_GERAL);
        String body = ApiSupport.body(request);
        String cpf = ApiSupport.string(body, "cpf").replaceAll("\\D", "");
        String email = ApiSupport.string(body, "email").trim();
        String password = ApiSupport.string(body, "password");
        String name = ApiSupport.string(body, "name").trim();
        PerfilUsuario role = parseRole(ApiSupport.string(body, "role"));
        if (cpf.length() != 11 || !email.contains("@") || password.length() < 8 || name.length() < 3 || role == null)
            throw new IllegalArgumentException("Informe CPF, nome, e-mail, senha e perfil válidos.");
        if (usuarioDAO.existeCpf(cpf) || usuarioDAO.existeEmail(email)) throw new IllegalArgumentException("CPF ou e-mail já cadastrado.");
        int unit = ApiSupport.integer(body, "unitId", 0);
        if (role != PerfilUsuario.PACIENTE && (unit <= 0 || unidadeCadastroDAO.buscarPorId(unit) == null))
            throw new IllegalArgumentException("Selecione uma unidade válida.");
        Integer minhaUnidade = AuthUtil.getUnidadeAtiva(request);
        if (role != PerfilUsuario.PACIENTE && (minhaUnidade == null || unit != minhaUnidade))
            throw new SecurityException("Só é possível cadastrar usuários na própria unidade.");
        // sem escalada: admin de unidade cria equipe, nunca outro administrador
        boolean admGeral = AuthUtil.getPerfilAtivo(request) == PerfilUsuario.ADM_GERAL;
        if (!admGeral && (role == PerfilUsuario.ADM_GERAL || role == PerfilUsuario.ADM_UNIDADE))
            throw new SecurityException("Somente o administrador geral cadastra administradores.");
        Usuario user = new Usuario();
        user.setCpf(cpf); user.setNome(name); user.setEmail(email); user.setSenhaHash(PasswordUtil.hash(password));
        user.setEspecialidade(ApiSupport.string(body, "specialty")); user.setAtivo(true);
        String birthDate = ApiSupport.string(body, "birthDate");
        if (!birthDate.isBlank()) user.setDataNascimento(LocalDate.parse(birthDate));
        usuarioDAO.inserir(user);
        try {
            perfilDAO.adicionar(cpf, role);
            if (role != PerfilUsuario.PACIENTE) {
                unidadeDAO.vincular(cpf, unit);
                user.setUnidadeIds(List.of(unit));
            }
        } catch (SQLException e) {
            usuarioDAO.deletar(cpf);
            throw e;
        }
        ApiSupport.json(response, 201, "{\"user\":" + userJson(user, role) + "}");
    }

    private void updateUser(HttpServletRequest request, HttpServletResponse response) throws IOException, SQLException {
        require(request, PerfilUsuario.ADM_UNIDADE, PerfilUsuario.ADM_GERAL);
        String cpf = request.getPathInfo().substring(1).replaceAll("\\D", "");
        Usuario user = usuarioDAO.buscarPorCpf(cpf);
        if (user == null) throw new IllegalArgumentException("Usuário não encontrado.");
        if (!daMinhaUnidade(request, user)) throw new SecurityException("Usuário de outra unidade.");
        user.setAtivo(ApiSupport.bool(ApiSupport.body(request), "active", user.isAtivo()));
        usuarioDAO.atualizar(user);
        ApiSupport.json(response, 200, "{\"user\":" + userJson(user, user.getPerfis().isEmpty() ? null : user.getPerfis().get(0)) + "}");
    }

    private void currentAttendance(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        require(request, PerfilUsuario.MEDICO);
        Usuario medic = AuthUtil.getUsuarioLogado(request);
        Atendimento attendance = atendimentoDAO.buscarEmAndamento(medic.getCpf());
        String metrics = attendanceMetricsJson(medic.getCpf());
        if (attendance == null) {
            ApiSupport.json(response, 200, "{\"attendance\":null,\"metrics\":" + metrics + "}");
            return;
        }
        ItemFila item = itemFilaDAO.buscarPorChave(attendance.getIdFila(), attendance.getSequenciaItemFila());
        ApiSupport.json(response, 200, "{\"attendance\":" + attendanceJson(attendance, item)
                + ",\"metrics\":" + metrics + "}");
    }

    private String attendanceMetricsJson(String cpfMedico) throws SQLException {
        List<Atendimento> today = atendimentoDAO.listarFinalizadosHoje(cpfMedico);
        long totalMinutes = today.stream()
                .mapToLong(a -> java.time.Duration.between(a.getInicio(), a.getFim()).toMinutes()).sum();
        long average = today.isEmpty() ? 0 : Math.round((double) totalMinutes / today.size());
        return "{\"attendedToday\":" + today.size() + ",\"avgMinutes\":" + average + "}";
    }

    private String attendanceJson(Atendimento a, ItemFila item) throws SQLException {
        Usuario patient = item == null ? null : usuarioDAO.buscarPorCpf(item.getCpfPaciente());
        Fila queue = item == null ? null : filaDAO.buscarPorId(item.getIdFila());
        Documento latestDocument = item == null ? null
                : documentoDAO.buscarPorItem(item.getIdFila(), item.getSequenciaItemFila());
        Documento priorityDocument = latestDocument != null
                && latestDocument.getStatusValidacao() == StatusValidacaoDocumento.APROVADO
                ? latestDocument : null;
        String priority = priorityDocument != null
                || queue != null && queue.getTipo() == br.com.filasus.model.enums.TipoFila.PRIORITARIO
                ? "prioritario" : "comum";
        return "{\"id\":\"" + a.getId() + "\",\"itemId\":\"" + a.getIdFila() + "_" + a.getSequenciaItemFila()
                + "\",\"queueId\":\"" + a.getIdFila()
                + "\",\"password\":\"F" + a.getIdFila() + "-" + String.format("%03d", a.getSequenciaItemFila())
                + "\",\"patientId\":" + ApiSupport.quote(item == null ? null : item.getCpfPaciente())
                + ",\"patientName\":" + ApiSupport.quote(patient == null ? "" : patient.getNome())
                + ",\"patientCpf\":" + ApiSupport.quote(patient == null ? "" : patient.getCpfFormatado())
                + ",\"patientAge\":" + (patient == null ? 0 : patient.getIdade())
                + ",\"priority\":" + ApiSupport.quote(priority)
                + ",\"priorityReason\":" + ApiSupport.quote(priorityDocument == null ? null : priorityDocument.getMotivoPrioridade())
                + ",\"priorityValidation\":" + ApiSupport.quote(latestDocument == null ? "nao_solicitada"
                        : statusFrontend(latestDocument.getStatusValidacao()))
                + ",\"status\":\"em_atendimento\""
                + ",\"attendedAt\":" + ApiSupport.quote(a.getInicio() == null ? null : a.getInicio().toString()) + "}";
    }

    private void startAttendance(HttpServletRequest request, HttpServletResponse response) throws IOException, SQLException {
        require(request, PerfilUsuario.MEDICO);
        int[] id = ApiSupport.itemId(ApiSupport.string(ApiSupport.body(request), "itemId"));
        ItemFila item = itemFilaDAO.buscarPorChave(id[0], id[1]);
        if (item == null || item.getStatus() != StatusItemFila.CHAMADO) throw new IllegalArgumentException("Senha não está disponível para atendimento.");
        exigirFilaDaMinhaUnidade(request, id[0]);
        Usuario medic = AuthUtil.getUsuarioLogado(request);
        if (atendimentoDAO.buscarEmAndamento(medic.getCpf()) != null) throw new IllegalArgumentException("Finalize o atendimento atual primeiro.");
        Atendimento a = new Atendimento();
        a.setIdItemFila(id[1]); a.setIdFila(id[0]); a.setSequenciaItemFila(id[1]); a.setCpfMedico(medic.getCpf());
        atendimentoDAO.iniciar(a);
        itemFilaDAO.atualizarStatus(id[0], id[1], StatusItemFila.EM_ATENDIMENTO);
        item.setStatus(StatusItemFila.EM_ATENDIMENTO);
        ApiSupport.json(response, 201, "{\"item\":" + attendanceJson(a, item) + "}");
    }

    private void finishAttendance(HttpServletRequest request, HttpServletResponse response) throws IOException, SQLException {
        require(request, PerfilUsuario.MEDICO);
        int attendanceId = ApiSupport.id(request.getPathInfo());
        Atendimento a = atendimentoDAO.buscarPorId(attendanceId);
        Usuario medic = AuthUtil.getUsuarioLogado(request);
        if (a == null || !medic.getCpf().equals(a.getCpfMedico())) throw new IllegalArgumentException("Atendimento não encontrado.");
        exigirFilaDaMinhaUnidade(request, a.getIdFila());
        atendimentoDAO.finalizar(attendanceId, LocalDateTime.now());
        itemFilaDAO.atualizarStatus(a.getIdFila(), a.getSequenciaItemFila(), StatusItemFila.ATENDIDO);
        ApiSupport.json(response, 200, "{\"ok\":true}");
    }

    private void priorities(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        require(request, PerfilUsuario.MEDICO);
        String requested = request.getParameter("status");
        StatusValidacaoDocumento status = "aprovada".equals(requested) ? StatusValidacaoDocumento.APROVADO
                : "rejeitada".equals(requested) ? StatusValidacaoDocumento.REJEITADO : StatusValidacaoDocumento.PENDENTE;
        List<Documento> docs = documentoDAO.listarPorStatus(status);
        Integer minhaUnidade = AuthUtil.getUnidadeAtiva(request);
        StringBuilder json = new StringBuilder("{\"items\":[");
        boolean primeiro = true;
        for (Documento doc : docs) {
            // solicitação de paciente de outra unidade não é do médico daqui
            Integer unidadePaciente = unidadeDoDocumento(doc);
            if (unidadePaciente != null && !unidadePaciente.equals(minhaUnidade)) continue;
            if (!primeiro) json.append(',');
            json.append(priorityJson(doc));
            primeiro = false;
        }
        ApiSupport.json(response, 200, json.append("]}").toString());
    }

    private String priorityJson(Documento doc) throws SQLException {
        Usuario patient = usuarioDAO.buscarPorCpf(doc.getCpfUsuario());
        ItemFila active = doc.getIdFila() == null || doc.getSequenciaItemFila() == null ? null
                : itemFilaDAO.buscarPorChave(doc.getIdFila(), doc.getSequenciaItemFila());
        if (active == null && doc.getIdFila() == null) {
            List<ItemFila> items = itemFilaDAO.listarPorPaciente(doc.getCpfUsuario());
            active = items.stream().filter(i -> i.getStatus() == StatusItemFila.AGUARDANDO
                    || i.getStatus() == StatusItemFila.CHAMADO).findFirst().orElse(null);
        }
        String id = active == null ? "doc_" + doc.getId() : active.getIdFila() + "_" + active.getSequenciaItemFila();
        Fila queue = active == null ? null : filaDAO.buscarPorId(active.getIdFila());
        Mutirao session = queue == null ? null : mutiraoDAO.buscarPorId(queue.getIdMutirao());
        return "{\"id\":" + ApiSupport.quote(id) + ",\"documentId\":" + doc.getId()
                + ",\"password\":" + ApiSupport.quote(active == null ? null
                        : "F" + active.getIdFila() + "-" + String.format("%03d", active.getSequenciaItemFila()))
                + ",\"queueName\":" + ApiSupport.quote(queue == null ? null : queue.getNome())
                + ",\"sessionName\":" + ApiSupport.quote(session == null ? null : session.getTipo())
                + ",\"enteredAt\":" + ApiSupport.quote(doc.getEnviadoEm() == null ? null : doc.getEnviadoEm().toString())
                + ",\"patientId\":" + ApiSupport.quote(doc.getCpfUsuario())
                + ",\"patientName\":" + ApiSupport.quote(patient == null ? "" : patient.getNome())
                + ",\"patientCpf\":" + ApiSupport.quote(patient == null ? "" : patient.getCpfFormatado())
                + ",\"patientAge\":" + (patient == null ? 0 : patient.getIdade())
                + ",\"priorityReason\":" + ApiSupport.quote(doc.getMotivoPrioridade())
                + ",\"priorityValidation\":" + ApiSupport.quote(statusFrontend(doc.getStatusValidacao()))
                + ",\"documents\":[{\"id\":" + doc.getId() + ",\"fileName\":" + ApiSupport.quote(doc.getNomeOriginal() == null
                        ? java.nio.file.Paths.get(doc.getArquivoUrl()).getFileName().toString() : doc.getNomeOriginal())
                + ",\"description\":" + ApiSupport.quote(doc.getDescricao())
                + ",\"uploadedAt\":" + ApiSupport.quote(doc.getEnviadoEm() == null ? null : doc.getEnviadoEm().toString()) + "}]}";
    }

    private void requestPriority(HttpServletRequest request, HttpServletResponse response)
            throws IOException, SQLException, ServletException {
        require(request, PerfilUsuario.PACIENTE);
        boolean multipart = request.getContentType() != null
                && request.getContentType().toLowerCase().startsWith("multipart/form-data");
        String body = multipart ? "" : ApiSupport.body(request);
        int[] id = ApiSupport.itemId(multipart ? request.getParameter("itemId") : ApiSupport.string(body, "itemId"));
        ItemFila item = itemFilaDAO.buscarPorChave(id[0], id[1]);
        Usuario patient = AuthUtil.getUsuarioLogado(request);
        if (item == null || !patient.getCpf().equals(item.getCpfPaciente())) throw new IllegalArgumentException("Senha não encontrada.");
        Documento doc = new Documento();
        doc.setCpfUsuario(patient.getCpf()); doc.setTipo(TipoDocumento.OUTRO);
        doc.setMotivoPrioridade(multipart ? request.getParameter("reason") : ApiSupport.string(body, "reason"));
        doc.setDescricao(multipart ? request.getParameter("description") : ApiSupport.string(body, "description"));
        Part uploaded = multipart ? request.getPart("file") : null;
        String file = multipart && uploaded != null ? uploaded.getSubmittedFileName() : ApiSupport.string(body, "fileName");
        if (doc.getMotivoPrioridade() == null || doc.getMotivoPrioridade().isBlank()
                || doc.getDescricao() == null || doc.getDescricao().isBlank() || file == null || file.isBlank())
            throw new IllegalArgumentException("Informe o motivo, a descrição e o documento.");
        doc.setArquivoUrl(multipart ? UploadUtil.salvar(uploaded)
                : java.nio.file.Paths.get(file).getFileName().toString());
        doc.setNomeOriginal(java.nio.file.Paths.get(file).getFileName().toString());
        doc.setIdFila(id[0]);
        doc.setSequenciaItemFila(id[1]);
        doc.setStatusValidacao(StatusValidacaoDocumento.PENDENTE);
        documentoDAO.inserir(doc);
        ApiSupport.json(response, 201, "{\"item\":" + priorityJson(doc) + "}");
    }

    private void validatePriority(HttpServletRequest request, HttpServletResponse response) throws IOException, SQLException {
        require(request, PerfilUsuario.MEDICO);
        int[] itemId = ApiSupport.itemId(request.getPathInfo());
        Documento doc = null;
        if (itemId[0] > 0) {
            ItemFila item = itemFilaDAO.buscarPorChave(itemId[0], itemId[1]);
            if (item != null) {
                doc = documentoDAO.buscarPorItem(itemId[0], itemId[1]);
            }
        } else {
            int docId = ApiSupport.id(request.getPathInfo());
            doc = documentoDAO.buscarPorId(docId);
        }
        if (doc == null || doc.getStatusValidacao() != StatusValidacaoDocumento.PENDENTE) throw new IllegalArgumentException("Solicitação não encontrada ou já processada.");
        Integer unidadePaciente = unidadeDoDocumento(doc);
        if (unidadePaciente != null && !unidadePaciente.equals(AuthUtil.getUnidadeAtiva(request))) {
            throw new SecurityException("Solicitação de outra unidade.");
        }
        String action = ApiSupport.string(ApiSupport.body(request), "action");
        StatusValidacaoDocumento status = "approve".equals(action) ? StatusValidacaoDocumento.APROVADO : StatusValidacaoDocumento.REJEITADO;
        documentoDAO.validar(doc.getId(), status, AuthUtil.getUsuarioLogado(request).getCpf());
        ApiSupport.json(response, 200, "{\"ok\":true}");
    }

    private String statusFrontend(StatusValidacaoDocumento status) {
        if (status == StatusValidacaoDocumento.APROVADO) return "aprovada";
        if (status == StatusValidacaoDocumento.REJEITADO) return "rejeitada";
        return "pendente";
    }

    private PerfilUsuario parseRole(String role) {
        if (role == null || role.isBlank()) return null;
        return switch (role.toLowerCase()) {
            case "paciente" -> PerfilUsuario.PACIENTE;
            case "atendente" -> PerfilUsuario.ATENDENTE;
            case "medico" -> PerfilUsuario.MEDICO;
            case "admin", "admin_unidade" -> PerfilUsuario.ADM_UNIDADE;
            case "admin_geral" -> PerfilUsuario.ADM_GERAL;
            default -> null;
        };
    }

    private void require(HttpServletRequest request, PerfilUsuario... roles) {
        if (!AuthUtil.checarPerfil(request, roles)) throw new SecurityException("Perfil sem permissão.");
    }

    private String route(HttpServletRequest request) {
        return request.getServletPath() + (request.getPathInfo() == null ? "" : request.getPathInfo());
    }
}
