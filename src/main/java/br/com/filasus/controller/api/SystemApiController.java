package br.com.filasus.controller.api;

import br.com.filasus.dao.MutiraoDAO;
import br.com.filasus.model.Mutirao;
import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.util.AuthUtil;
import br.com.filasus.util.DBConnection;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/** Relatórios agregados. */
@WebServlet("/api/reports")
public class SystemApiController extends HttpServlet {
    private final MutiraoDAO mutiraoDAO = new MutiraoDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            requireAdmin(request);
            reports(request, response);
        } catch (SecurityException e) {
            ApiSupport.error(response, 403, e.getMessage());
        } catch (SQLException e) {
            throw new IOException("Erro ao gerar relatório.", e);
        }
    }

    private void reports(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        int sessionId = ApiSupport.id(request.getParameter("sessionId"));
        int queueId = ApiSupport.id(request.getParameter("queueId"));
        String sql = "SELECT "
                + "SUM(i.status_itemfila='ATENDIDO') attended, SUM(i.status_itemfila='AUSENTE') absent, "
                + "SUM(i.status_itemfila='AGUARDANDO') waiting, "
                + "SUM(f.tipo_fila='PRIORITARIO' OR EXISTS (SELECT 1 FROM Documento d "
                + "WHERE d.cpf_usuario=i.cpf_usuario AND d.status_validacao_documento='aprovado')) priority_count, COUNT(*) total "
                + "FROM ItemFila i JOIN Fila f ON f.id_fila=i.id_fila WHERE (?=0 OR f.id_mutirao=?) AND (?=0 OR f.id_fila=?)";
        int attended = 0, absent = 0, waiting = 0, priority = 0, total = 0;
        try (Connection connection = DBConnection.getConnection(); PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, sessionId); ps.setInt(2, sessionId); ps.setInt(3, queueId); ps.setInt(4, queueId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) { attended=rs.getInt("attended"); absent=rs.getInt("absent"); waiting=rs.getInt("waiting"); priority=rs.getInt("priority_count"); total=rs.getInt("total"); }
            }
        }
        Mutirao session = sessionId == 0 ? null : mutiraoDAO.buscarPorId(sessionId);
        String sessionJson = session == null ? "null" : "{\"id\":\"" + session.getId() + "\",\"name\":" + ApiSupport.quote(session.getTipo()) + "}";
        String report = "{\"totalAttendances\":" + attended + ",\"totalAbsent\":" + absent
                + ",\"avgWaitMinutes\":0,\"avgServiceMinutes\":0,\"byPriority\":[{\"priority\":\"prioritario\",\"count\":" + priority
                + "},{\"priority\":\"comum\",\"count\":" + Math.max(0,total-priority) + "}],\"byStatus\":["
                + "{\"status\":\"aguardando\",\"count\":" + waiting + ",\"label\":\"Aguardando\"},"
                + "{\"status\":\"atendido\",\"count\":" + attended + ",\"label\":\"Atendido\"},"
                + "{\"status\":\"ausente\",\"count\":" + absent + ",\"label\":\"Ausente\"}],\"byMedic\":[]}";
        String metrics = "{\"totalWaiting\":" + waiting + ",\"totalAttended\":" + attended + ",\"totalAbsent\":" + absent + "}";
        ApiSupport.json(response, 200, "{\"report\":" + report + ",\"metrics\":" + metrics + ",\"session\":" + sessionJson + "}");
    }

    private void requireAdmin(HttpServletRequest request) {
        if (!AuthUtil.checarPerfil(request, PerfilUsuario.ADM_UNIDADE, PerfilUsuario.ADM_GERAL))
            throw new SecurityException("Perfil sem permissão.");
    }
}
