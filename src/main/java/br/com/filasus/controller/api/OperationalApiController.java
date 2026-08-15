package br.com.filasus.controller.api;

import br.com.filasus.dao.FilaDAO;
import br.com.filasus.dao.DocumentoDAO;
import br.com.filasus.dao.ItemFilaDAO;
import br.com.filasus.dao.MutiraoDAO;
import br.com.filasus.dao.UsuarioDAO;
import br.com.filasus.model.Fila;
import br.com.filasus.model.ItemFila;
import br.com.filasus.model.ItemFilaId;
import br.com.filasus.model.Mutirao;
import br.com.filasus.model.Usuario;
import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.model.enums.StatusItemFila;
import br.com.filasus.model.enums.StatusMutirao;
import br.com.filasus.model.enums.TipoFila;
import br.com.filasus.util.AuthUtil;
import br.com.filasus.util.DBConnection;
import br.com.filasus.service.ChamarProximoService;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/** API operacional de mutirões, filas e painel da unidade. */
@WebServlet(urlPatterns = {"/api/sessions", "/api/sessions/*", "/api/queues", "/api/queues/*",
        "/api/queue", "/api/queue/*", "/api/display"})
public class OperationalApiController extends HttpServlet {
    private final MutiraoDAO mutiraoDAO = new MutiraoDAO();
    private final FilaDAO filaDAO = new FilaDAO();
    private final DocumentoDAO documentoDAO = new DocumentoDAO();
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final ChamarProximoService chamarProximoService = new ChamarProximoService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            String path = route(request);
            if (path.startsWith("/api/sessions")) sessions(request, response);
            else if ("/api/queues".equals(path)) queues(request, response);
            else if ("/api/queue".equals(path)) queue(request, response);
            else if ("/api/display".equals(path)) display(request, response);
            else ApiSupport.error(response, 404, "Rota não encontrada.");
        } catch (SecurityException e) {
            ApiSupport.error(response, 403, e.getMessage());
        } catch (SQLException e) {
            throw new IOException("Erro ao consultar dados operacionais.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            String path = route(request);
            if ("/api/sessions".equals(path)) createSession(request, response);
            else if ("/api/queues".equals(path)) createQueue(request, response);
            else if ("/api/queue".equals(path)) enqueue(request, response);
            else if ("/api/queue/call-next".equals(path)) callNext(request, response);
            else ApiSupport.error(response, 404, "Rota não encontrada.");
        } catch (SecurityException e) {
            ApiSupport.error(response, 403, e.getMessage());
        } catch (IllegalArgumentException e) {
            ApiSupport.error(response, 400, e.getMessage());
        } catch (SQLException e) {
            throw new IOException("Erro ao gravar dados operacionais.", e);
        }
    }

    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response) throws IOException, javax.servlet.ServletException {
        if ("PATCH".equalsIgnoreCase(request.getMethod())) {
            doPatch(request, response);
            return;
        }
        super.service(request, response);
    }

    protected void doPatch(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            String path = route(request);
            if (path.startsWith("/api/sessions/")) updateSession(request, response);
            else if (path.startsWith("/api/queues/")) updateQueue(request, response);
            else if (path.startsWith("/api/queue/")) updateItem(request, response);
            else ApiSupport.error(response, 404, "Rota não encontrada.");
        } catch (SecurityException e) {
            ApiSupport.error(response, 403, e.getMessage());
        } catch (IllegalArgumentException e) {
            ApiSupport.error(response, 400, e.getMessage());
        } catch (SQLException e) {
            throw new IOException("Erro ao atualizar dados operacionais.", e);
        }
    }

    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            if (route(request).startsWith("/api/queues/")) {
                requireRole(request, PerfilUsuario.ADM_UNIDADE, PerfilUsuario.ADM_GERAL);
                int id = ApiSupport.id(request.getPathInfo());
                exigirFilaDaUnidade(request, id);
                filaDAO.deletar(id);
                ApiSupport.json(response, 200, "{\"ok\":true}");
            } else ApiSupport.error(response, 404, "Rota não encontrada.");
        } catch (SecurityException e) {
            ApiSupport.error(response, 403, e.getMessage());
        } catch (IllegalArgumentException e) {
            ApiSupport.error(response, 400, e.getMessage());
        } catch (SQLException e) {
            throw new IOException("Erro ao excluir fila.", e);
        }
    }

    private void sessions(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        List<Mutirao> daUnidade = mutiroesDaUnidade(request);
        if ("/active".equals(request.getPathInfo())) {
            Mutirao ativo = null;
            for (Mutirao m : daUnidade) {
                if (m.getStatus() == StatusMutirao.ABERTO) { ativo = m; break; }
            }
            ApiSupport.json(response, 200, "{\"session\":" + (ativo == null ? "null" : sessionJson(ativo)) + "}");
            return;
        }
        List<Mutirao> sessions = daUnidade;
        StringBuilder json = new StringBuilder("{\"sessions\":[");
        for (int i = 0; i < sessions.size(); i++) {
            if (i > 0) json.append(',');
            json.append(sessionJson(sessions.get(i)));
        }
        ApiSupport.json(response, 200, json.append("]}").toString());
    }

    private String sessionJson(Mutirao m) throws SQLException {
        List<Fila> filas = filaDAO.listarPorMutirao(m.getId());
        StringBuilder json = new StringBuilder("{\"id\":\"").append(m.getId()).append("\"")
                .append(",\"name\":").append(ApiSupport.quote(m.getTipo()))
                .append(",\"location\":").append(ApiSupport.quote(m.getLocal()))
                .append(",\"date\":").append(ApiSupport.quote(m.getData() == null ? null : m.getData().toString()))
                .append(",\"startTime\":\"08:00\",\"endTime\":\"17:00\"")
                .append(",\"status\":").append(ApiSupport.quote(m.getStatus().toJson()))
                .append(",\"queues\":[");
        for (int i = 0; i < filas.size(); i++) {
            if (i > 0) json.append(',');
            json.append(queueJson(filas.get(i)));
        }
        return json.append("]}").toString();
    }

    private void queues(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        List<Fila> filas = new ArrayList<>();
        for (Mutirao m : mutiroesDaUnidade(request)) filas.addAll(filaDAO.listarPorMutirao(m.getId()));
        StringBuilder json = new StringBuilder("{\"queues\":[");
        for (int i = 0; i < filas.size(); i++) {
            if (i > 0) json.append(',');
            json.append(queueJson(filas.get(i)));
        }
        ApiSupport.json(response, 200, json.append("]}").toString());
    }

    private String queueJson(Fila f) {
        return "{\"id\":\"" + f.getId() + "\",\"sessionId\":\"" + f.getIdMutirao()
                + "\",\"name\":" + ApiSupport.quote(f.getNome()) + ",\"sequencePrefix\":\"F" + f.getId()
                + "\",\"avgServiceMinutes\":15,\"priority\":\"" + f.getTipo().toJson() + "\"}";
    }

    private void queue(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        // só mutirões da unidade do usuário: sem isso a fila da unidade errada seria listada
        List<Mutirao> daUnidade = mutiroesDaUnidade(request);
        int sessionId = ApiSupport.id(request.getParameter("sessionId"));
        if (sessionId == 0) {
            for (Mutirao m : daUnidade) {
                if (m.getStatus() == StatusMutirao.ABERTO) { sessionId = m.getId(); break; }
            }
        } else {
            boolean daMinhaUnidade = false;
            for (Mutirao m : daUnidade) if (m.getId() == sessionId) daMinhaUnidade = true;
            if (!daMinhaUnidade) throw new SecurityException("Mutirão de outra unidade.");
        }
        int queueId = ApiSupport.id(request.getParameter("queueId"));
        String status = request.getParameter("status");
        List<ItemFila> result = new ArrayList<>();
        if (sessionId != 0) {
            for (Fila fila : filaDAO.listarPorMutirao(sessionId)) {
                if (queueId != 0 && fila.getId() != queueId) continue;
                for (ItemFila item : itemFilaDAO.listarPorFila(fila.getId())) {
                    if (status == null || item.getStatus().toJson().equals(status)) result.add(item);
                }
            }
        }
        StringBuilder json = new StringBuilder("{\"items\":[");
        for (int i = 0; i < result.size(); i++) {
            if (i > 0) json.append(',');
            json.append(itemJson(result.get(i)));
        }
        json.append("],\"metrics\":").append(metricsJson(result)).append('}');
        ApiSupport.json(response, 200, json.toString());
    }

    private String itemJson(ItemFila item) throws SQLException {
        Fila fila = filaDAO.buscarPorId(item.getIdFila());
        Usuario patient = usuarioDAO.buscarPorCpf(item.getCpfPaciente());
        boolean approvedPriority = documentoDAO.temPrioridadeAprovada(item.getIdFila(), item.getSequenciaItemFila());
        String priority = fila != null && (fila.getTipo() == TipoFila.PRIORITARIO || approvedPriority)
                ? "prioritario" : "comum";
        return "{\"id\":\"" + item.getIdFila() + "_" + item.getSequenciaItemFila()
                + "\",\"sessionId\":\"" + (fila == null ? 0 : fila.getIdMutirao())
                + "\",\"queueId\":\"" + item.getIdFila() + "\",\"sequence\":" + item.getSequenciaItemFila()
                + ",\"password\":\"F" + item.getIdFila() + "-" + String.format("%03d", item.getSequenciaItemFila())
                + "\",\"patientId\":" + ApiSupport.quote(item.getCpfPaciente())
                + ",\"patientName\":" + ApiSupport.quote(patient == null ? "" : patient.getNome())
                + ",\"patientCpf\":" + ApiSupport.quote(patient == null ? "" : patient.getCpfFormatado())
                + ",\"patientAge\":" + (patient == null ? 0 : patient.getIdade())
                + ",\"queueName\":" + ApiSupport.quote(fila == null ? "" : fila.getNome())
                + ",\"priority\":\"" + priority + "\",\"status\":\"" + item.getStatus().toJson()
                + "\",\"position\":" + itemFilaDAO.calcularPosicao(item)
                + ",\"estimatedWaitMinutes\":" + Math.max(0, item.getTempoEsperaMinutos())
                + ",\"enteredAt\":" + ApiSupport.quote(item.getEntradaEm() == null ? null : item.getEntradaEm().toString())
                + ",\"calledAt\":" + (item.getStatus() == StatusItemFila.CHAMADO ? ApiSupport.quote(item.getAtualizadoEm() == null ? null : item.getAtualizadoEm().toString()) : "null") + "}";
    }

    private String metricsJson(List<ItemFila> items) throws SQLException {
        long waiting = 0;
        long priority = 0;
        for (ItemFila item : items) {
            if (item.getStatus() != StatusItemFila.AGUARDANDO) continue;
            waiting++;
            Fila queue = filaDAO.buscarPorId(item.getIdFila());
            if (documentoDAO.temPrioridadeAprovada(item.getIdFila(), item.getSequenciaItemFila())
                    || queue != null && queue.getTipo() == TipoFila.PRIORITARIO) priority++;
        }
        long called = items.stream().filter(i -> i.getStatus() == StatusItemFila.CHAMADO || i.getStatus() == StatusItemFila.EM_ATENDIMENTO).count();
        long attended = items.stream().filter(i -> i.getStatus() == StatusItemFila.ATENDIDO).count();
        long absent = items.stream().filter(i -> i.getStatus() == StatusItemFila.AUSENTE).count();
        return "{\"totalWaiting\":" + waiting + ",\"totalPriority\":" + priority
                + ",\"totalCommon\":" + Math.max(0, waiting - priority)
                + ",\"totalCalled\":" + called + ",\"totalAttended\":" + attended + ",\"totalAbsent\":" + absent
                + ",\"avgWaitMinutes\":0,\"avgServiceMinutes\":0}";
    }

    private void enqueue(HttpServletRequest request, HttpServletResponse response) throws IOException, SQLException {
        requireRole(request, PerfilUsuario.ATENDENTE);
        String body = ApiSupport.body(request);
        int queueId = ApiSupport.id(ApiSupport.string(body, "queueId"));
        String patientId = ApiSupport.string(body, "patientId").replaceAll("\\D", "");
        Fila fila = exigirFilaDaUnidade(request, queueId);
        if (usuarioDAO.buscarPorCpf(patientId) == null) throw new IllegalArgumentException("Paciente não encontrado.");
        ItemFila item = new ItemFila(new ItemFilaId(queueId, 0), patientId, StatusItemFila.AGUARDANDO, null);
        itemFilaDAO.inserir(item);
        ApiSupport.json(response, 201, "{\"item\":" + itemJson(item) + "}");
    }

    private void callNext(HttpServletRequest request, HttpServletResponse response) throws IOException, SQLException {
        requireRole(request, PerfilUsuario.ATENDENTE);
        String body = ApiSupport.body(request);
        int queueId = ApiSupport.id(ApiSupport.string(body, "queueId"));
        Fila selectedQueue = exigirFilaDaUnidade(request, queueId);
        ItemFila next = chamarProximoService.chamarProximoDaFila(selectedQueue.getId());
        if (next == null) {
            ApiSupport.json(response, 200, "{\"item\":null,\"message\":\"Fila vazia.\"}");
            return;
        }
        next.setStatus(StatusItemFila.CHAMADO);
        ApiSupport.json(response, 200, "{\"item\":" + itemJson(next) + "}");
    }

    private void updateItem(HttpServletRequest request, HttpServletResponse response) throws IOException, SQLException {
        requireRole(request, PerfilUsuario.ATENDENTE, PerfilUsuario.MEDICO);
        int[] id = ApiSupport.itemId(request.getPathInfo());
        exigirFilaDaUnidade(request, id[0]);
        ItemFila item = itemFilaDAO.buscarPorChave(id[0], id[1]);
        if (item == null) throw new IllegalArgumentException("Item não encontrado.");
        String status = ApiSupport.string(ApiSupport.body(request), "status");
        if ("remarcado".equals(status)) {
            itemFilaDAO.atualizarStatus(id[0], id[1], StatusItemFila.AUSENTE);
            ItemFila novo = new ItemFila(new ItemFilaId(id[0], 0), item.getCpfPaciente(), StatusItemFila.AGUARDANDO, null);
            itemFilaDAO.inserir(novo);
            ApiSupport.json(response, 200, "{\"item\":{\"status\":\"remarcado\"},\"newItem\":" + itemJson(novo) + "}");
            return;
        }
        StatusItemFila target = StatusItemFila.fromJson(status);
        itemFilaDAO.atualizarStatus(id[0], id[1], target);
        item.setStatus(target);
        ApiSupport.json(response, 200, "{\"item\":" + itemJson(item) + "}");
    }

    private void createSession(HttpServletRequest request, HttpServletResponse response) throws IOException, SQLException {
        requireRole(request, PerfilUsuario.ADM_UNIDADE, PerfilUsuario.ADM_GERAL);
        String body = ApiSupport.body(request);
        Mutirao m = new Mutirao();
        Integer unidade = AuthUtil.getUnidadeAtiva(request);
        m.setIdUnidade(unidade == null ? 1 : unidade);
        m.setTipo(ApiSupport.string(body, "name"));
        m.setLocal(ApiSupport.string(body, "location"));
        String date = ApiSupport.string(body, "date");
        m.setData(date.isBlank() ? LocalDate.now() : LocalDate.parse(date));
        m.setDuracaoMinutos(540);
        m.setStatus(StatusMutirao.AGENDADO);
        mutiraoDAO.inserir(m);
        List<Integer> queueIds = ApiSupport.integers(body, "queueIds");
        for (Integer queueId : queueIds) {
            Fila template = filaDAO.buscarPorId(queueId);
            if (template == null) continue;
            Fila queue = new Fila();
            queue.setIdMutirao(m.getId());
            queue.setNome(template.getNome());
            queue.setTipo(template.getTipo());
            filaDAO.inserir(queue);
        }
        ApiSupport.json(response, 201, "{\"session\":" + sessionJson(m) + "}");
    }

    private void updateSession(HttpServletRequest request, HttpServletResponse response) throws IOException, SQLException {
        requireRole(request, PerfilUsuario.ADM_UNIDADE, PerfilUsuario.ADM_GERAL);
        int id = ApiSupport.id(request.getPathInfo());
        exigirMutiraoDaUnidade(request, id);
        Mutirao m = mutiraoDAO.buscarPorId(id);
        if (m == null) throw new IllegalArgumentException("Mutirão não encontrado.");
        String status = ApiSupport.string(ApiSupport.body(request), "status");
        m.setStatus(StatusMutirao.fromJson(status));
        mutiraoDAO.atualizarStatus(id, m.getStatus());
        ApiSupport.json(response, 200, "{\"session\":" + sessionJson(m) + "}");
    }

    private void createQueue(HttpServletRequest request, HttpServletResponse response) throws IOException, SQLException {
        requireRole(request, PerfilUsuario.ADM_UNIDADE, PerfilUsuario.ADM_GERAL);
        String body = ApiSupport.body(request);
        List<Mutirao> active = mutiraoDAO.listarPorStatus(StatusMutirao.ABERTO);
        if (active.isEmpty()) throw new IllegalArgumentException("Crie ou abra um mutirão antes de criar filas.");
        Fila f = new Fila();
        f.setIdMutirao(active.get(0).getId());
        f.setNome(ApiSupport.string(body, "name"));
        f.setTipo("prioritario".equalsIgnoreCase(ApiSupport.string(body, "priority")) ? TipoFila.PRIORITARIO : TipoFila.COMUM);
        if (f.getNome().isBlank()) throw new IllegalArgumentException("Nome da fila é obrigatório.");
        filaDAO.inserir(f);
        ApiSupport.json(response, 201, "{\"queue\":" + queueJson(f) + "}");
    }

    private void updateQueue(HttpServletRequest request, HttpServletResponse response) throws IOException, SQLException {
        requireRole(request, PerfilUsuario.ADM_UNIDADE, PerfilUsuario.ADM_GERAL);
        int id = ApiSupport.id(request.getPathInfo());
        Fila f = exigirFilaDaUnidade(request, id);
        String name = ApiSupport.string(ApiSupport.body(request), "name");
        if (!name.isBlank()) f.setNome(name);
        filaDAO.atualizar(f);
        ApiSupport.json(response, 200, "{\"queue\":" + queueJson(f) + "}");
    }

    // ponytail: a tela de configuracoes foi removida; o painel usa valores fixos
    private static final String PAINEL_SETTINGS =
            "{\"clinicName\":\"FilaSUS\",\"enableAutoCall\":false,\"absenceThreshold\":3,\"displayPanelTheme\":\"light\"}";

    private void display(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        // ponytail: um painel por unidade; com mais de um mutirão aberto na mesma unidade mostra o primeiro
        List<Mutirao> active = new ArrayList<>();
        for (Mutirao m : mutiroesDaUnidade(request)) {
            if (m.getStatus() == StatusMutirao.ABERTO) active.add(m);
        }
        if (active.isEmpty()) {
            ApiSupport.json(response, 200, "{\"session\":null,\"settings\":" + PAINEL_SETTINGS + ",\"lastCalled\":[],\"waiting\":[],\"perQueue\":[]}");
            return;
        }
        Mutirao m = active.get(0);
        List<Fila> filas = filaDAO.listarPorMutirao(m.getId());
        StringBuilder perQueue = new StringBuilder("[");
        StringBuilder last = new StringBuilder("[");
        boolean firstQueue = true, firstLast = true;
        for (Fila f : filas) {
            List<ItemFila> items = itemFilaDAO.listarPorFila(f.getId());
            ItemFila current = items.stream().filter(i -> i.getStatus() == StatusItemFila.CHAMADO || i.getStatus() == StatusItemFila.EM_ATENDIMENTO).findFirst().orElse(null);
            long waiting = items.stream().filter(i -> i.getStatus() == StatusItemFila.AGUARDANDO).count();
            if (!firstQueue) perQueue.append(',');
            perQueue.append("{\"queue\":").append(queueJson(f)).append(",\"waitingCount\":").append(waiting)
                    .append(",\"current\":").append(current == null ? "null" : itemJson(current)).append('}');
            firstQueue = false;
            if (current != null) {
                if (!firstLast) last.append(',');
                last.append(itemJson(current));
                firstLast = false;
            }
        }
        ApiSupport.json(response, 200, "{\"session\":" + sessionJson(m) + ",\"settings\":" + PAINEL_SETTINGS + ",\"lastCalled\":"
                + last.append(']') + ",\"waiting\":[],\"perQueue\":" + perQueue.append(']') + "}");
    }

    /** Recusa mutirão de outra unidade. Mesmo critério das leituras: vale para todos os perfis,
     *  inclusive adm geral — se ele precisar operar a rede toda, entra um seletor de unidade. */
    private void exigirMutiraoDaUnidade(HttpServletRequest request, int idMutirao) throws SQLException {
        Mutirao m = mutiraoDAO.buscarPorId(idMutirao);
        Integer unidade = AuthUtil.getUnidadeAtiva(request);
        if (m == null || unidade == null || m.getIdUnidade() != unidade) {
            throw new SecurityException("Recurso de outra unidade.");
        }
    }

    /** Mesma checagem a partir da fila. */
    private Fila exigirFilaDaUnidade(HttpServletRequest request, int idFila) throws SQLException {
        Fila fila = filaDAO.buscarPorId(idFila);
        if (fila == null) throw new IllegalArgumentException("Fila não encontrada.");
        exigirMutiraoDaUnidade(request, fila.getIdMutirao());
        return fila;
    }

    /** Mutirões visíveis ao usuário logado: só os da unidade dele. */
    private List<Mutirao> mutiroesDaUnidade(HttpServletRequest request) throws SQLException {
        Integer unidade = unidadeDoUsuario(request);
        return unidade == null ? new ArrayList<>() : mutiraoDAO.listarPorUnidade(unidade);
    }

    /** Unidade do usuário: a da sessão para perfis operacionais, ou a do mutirão em que o paciente tem senha ativa. */
    private Integer unidadeDoUsuario(HttpServletRequest request) throws SQLException {
        Integer unidade = AuthUtil.getUnidadeAtiva(request);
        if (unidade != null) return unidade;
        Usuario usuario = AuthUtil.getUsuarioLogado(request);
        if (usuario == null) return null;
        String sql = "SELECT m.id_unidade FROM ItemFila i"
                + " JOIN Fila f ON f.id_fila = i.id_fila"
                + " JOIN Mutirao m ON m.id_mutirao = f.id_mutirao"
                + " WHERE i.cpf_usuario = ? AND i.status_itemfila IN ('aguardando','chamado','em_atendimento')"
                + " ORDER BY i.entrada_em_item_fila DESC LIMIT 1";
        try (Connection connection = DBConnection.getConnection();
             PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, usuario.getCpf());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : null;
            }
        }
    }

    private void requireRole(HttpServletRequest request, PerfilUsuario... roles) {
        if (!AuthUtil.checarPerfil(request, roles)) throw new SecurityException("Perfil sem permissão.");
    }

    private String route(HttpServletRequest request) {
        return request.getServletPath() + (request.getPathInfo() == null ? "" : request.getPathInfo());
    }
}
