package br.com.filasus.controller.api;

import br.com.filasus.dao.FilaDAO;
import br.com.filasus.dao.ItemFilaDAO;
import br.com.filasus.dao.MutiraoDAO;
import br.com.filasus.dao.DocumentoDAO;
import br.com.filasus.dao.UsuarioDAO;
import br.com.filasus.dao.AtendimentoDAO;
import br.com.filasus.model.Documento;
import br.com.filasus.model.Fila;
import br.com.filasus.model.ItemFila;
import br.com.filasus.model.Mutirao;
import br.com.filasus.model.Usuario;
import br.com.filasus.model.Atendimento;
import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.model.enums.StatusItemFila;
import br.com.filasus.util.AuthUtil;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.EnumSet;
import java.util.List;
import java.util.ArrayList;

/** Senhas ativas e histórico do paciente autenticado. */
@WebServlet(urlPatterns = {"/api/my-queue", "/api/history"})
public class PatientQueueApiController extends HttpServlet {
    private static final EnumSet<StatusItemFila> STATUS_ATIVOS = EnumSet.of(
            StatusItemFila.AGUARDANDO, StatusItemFila.CHAMADO, StatusItemFila.EM_ATENDIMENTO);
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();
    private final FilaDAO filaDAO = new FilaDAO();
    private final MutiraoDAO mutiraoDAO = new MutiraoDAO();
    private final DocumentoDAO documentoDAO = new DocumentoDAO();
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final AtendimentoDAO atendimentoDAO = new AtendimentoDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Usuario autenticado = AuthUtil.getUsuarioLogado(request);
        PerfilUsuario perfil = AuthUtil.getPerfilAtivo(request);
        if (autenticado == null || perfil == null) {
            erro(response, HttpServletResponse.SC_UNAUTHORIZED, "Não autenticado.");
            return;
        }

        String cpfInformado = request.getParameter("patientId");
        if (perfil == PerfilUsuario.PACIENTE && cpfInformado != null
                && !cpfInformado.replaceAll("\\D", "").equals(autenticado.getCpf())) {
            erro(response, HttpServletResponse.SC_FORBIDDEN, "Acesso permitido somente às próprias senhas.");
            return;
        }

        try {
            boolean somenteAtivos = "/api/my-queue".equals(request.getServletPath());
            if (somenteAtivos && perfil != PerfilUsuario.PACIENTE) {
                erro(response, HttpServletResponse.SC_FORBIDDEN, "Rota exclusiva do paciente.");
                return;
            }
            List<ItemFila> itens = carregarItens(request, autenticado, perfil);
            String chave = somenteAtivos ? "items" : "history";
            StringBuilder json = new StringBuilder("{\"").append(chave).append("\":[");
            boolean primeiro = true;
            for (ItemFila item : itens) {
                boolean ativo = STATUS_ATIVOS.contains(item.getStatus());
                if (somenteAtivos != ativo) continue;
                if (!primeiro) json.append(',');
                Usuario paciente = usuarioDAO.buscarPorCpf(item.getCpfPaciente());
                String validacao = statusPrioridade(
                        documentoDAO.buscarPorItem(item.getIdFila(), item.getSequenciaItemFila()));
                json.append(itemJson(item, paciente, validacao));
                primeiro = false;
            }
            json.append("]}");
            json(response, HttpServletResponse.SC_OK, json.toString());
        } catch (SQLException e) {
            throw new IOException("Erro ao consultar as senhas do paciente.", e);
        }
    }

    private List<ItemFila> carregarItens(HttpServletRequest request, Usuario autenticado, PerfilUsuario perfil)
            throws SQLException {
        String patientId = request.getParameter("patientId");
        if (perfil == PerfilUsuario.PACIENTE) return itemFilaDAO.listarPorPaciente(autenticado.getCpf());
        if (patientId != null && !patientId.isBlank()) return itemFilaDAO.listarPorPaciente(patientId.replaceAll("\\D", ""));
        int sessionId = ApiSupport.id(request.getParameter("sessionId"));
        if (sessionId == 0) {
            // só mutirões da unidade da sessão: o primeiro aberto global pode ser de outra unidade
            Integer unidade = AuthUtil.getUnidadeAtiva(request);
            for (Mutirao m : mutiraoDAO.listarPorStatus(br.com.filasus.model.enums.StatusMutirao.ABERTO)) {
                if (unidade != null && m.getIdUnidade() == unidade) { sessionId = m.getId(); break; }
            }
        }
        List<ItemFila> itens = new ArrayList<>();
        if (sessionId != 0) for (Fila fila : filaDAO.listarPorMutirao(sessionId)) itens.addAll(itemFilaDAO.listarPorFila(fila.getId()));
        return itens;
    }

    private String itemJson(ItemFila item, Usuario paciente, String validacaoPrioridade) throws SQLException {
        Fila fila = filaDAO.buscarPorId(item.getIdFila());
        Mutirao mutirao = fila == null ? null : mutiraoDAO.buscarPorId(fila.getIdMutirao());
        String codigo = "F" + item.getIdFila() + "-" + String.format("%03d", item.getSequenciaItemFila());
        String prioridade = documentoDAO.temPrioridadeAprovada(item.getIdFila(), item.getSequenciaItemFila())
                || fila != null && fila.getTipo() == br.com.filasus.model.enums.TipoFila.PRIORITARIO
                ? "prioritario" : "comum";
        Atendimento atendimento = atendimentoDAO.buscarPorItem(item.getIdFila(), item.getSequenciaItemFila());
        Usuario medico = atendimento == null ? null : usuarioDAO.buscarPorCpf(atendimento.getCpfMedico());
        return "{\"id\":\"" + item.getIdFila() + "_" + item.getSequenciaItemFila()
                + "\",\"password\":\"" + codigo
                + "\",\"patientId\":\"" + escapar(item.getCpfPaciente())
                + "\",\"patientName\":\"" + escapar(paciente == null ? "" : paciente.getNome())
                + "\",\"queueName\":\"" + escapar(fila == null ? "" : fila.getNome())
                + "\",\"sessionName\":\"" + escapar(mutirao == null ? "" : mutirao.getTipo())
                + "\",\"position\":" + itemFilaDAO.calcularPosicao(item)
                + ",\"estimatedWaitMinutes\":" + Math.max(0, item.getTempoEsperaMinutos())
                + ",\"priority\":\"" + prioridade
                + "\",\"priorityValidation\":\"" + validacaoPrioridade
                + "\",\"status\":\"" + item.getStatus().toJson()
                + "\",\"enteredAt\":" + (item.getEntradaEm() == null ? "null" : "\"" + item.getEntradaEm() + "\"")
                + ",\"calledAt\":" + (atendimento == null || atendimento.getInicio() == null ? "null" : "\"" + atendimento.getInicio() + "\"")
                + ",\"attendedAt\":" + (atendimento == null || atendimento.getInicio() == null ? "null" : "\"" + atendimento.getInicio() + "\"")
                + ",\"finishedAt\":" + (atendimento == null || atendimento.getFim() == null ? "null" : "\"" + atendimento.getFim() + "\"")
                + ",\"medicName\":\"" + escapar(medico == null ? "" : medico.getNome()) + "\"}";
    }

    private String statusPrioridade(Documento documento) {
        if (documento == null || documento.getStatusValidacao() == null) return "nao_solicitada";
        String status = documento.getStatusValidacao().name();
        if ("APROVADO".equals(status)) return "aprovada";
        if ("REJEITADO".equals(status)) return "rejeitada";
        return "pendente";
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
