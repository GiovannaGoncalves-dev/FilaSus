package br.com.filasus.dao;

import br.com.filasus.model.Documento;
import br.com.filasus.model.enums.StatusValidacaoDocumento;
import br.com.filasus.model.enums.TipoDocumento;
import br.com.filasus.util.DBConnection;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO responsável pelas operações de persistência de Documento (anexos
 * sujeitos a validação: comprovante de prioridade, exame, relatório etc.).
 */
public class DocumentoDAO {

    public void inserir(Documento doc) throws SQLException {
        String sql = "INSERT INTO Documento (cpf_usuario, tipo_documento, arquivo_url_documento, "
                   + "status_validacao_documento, enviado_em_documento) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, doc.getCpfUsuario());
            ps.setString(2, doc.getTipo() != null ? doc.getTipo().name() : null);
            ps.setString(3, doc.getArquivoUrl());
            ps.setString(4, doc.getStatusValidacao().name());
            if (doc.getEnviadoEm() == null) doc.setEnviadoEm(LocalDateTime.now());
            ps.setTimestamp(5, Timestamp.valueOf(doc.getEnviadoEm()));
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) doc.setId(rs.getInt(1));
            }
        }
    }

    public Documento buscarPorId(int id) throws SQLException {
        String sql = "SELECT * FROM Documento WHERE id_documento = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        }
        return null;
    }

    public List<Documento> listarPorUsuario(String cpfUsuario) throws SQLException {
        String sql = "SELECT * FROM Documento WHERE cpf_usuario = ? ORDER BY enviado_em_documento DESC";
        List<Documento> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpfUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        }
        return lista;
    }

    public List<Documento> listarPorStatus(StatusValidacaoDocumento status) throws SQLException {
        String sql = "SELECT * FROM Documento WHERE status_validacao_documento = ? ORDER BY enviado_em_documento";
        List<Documento> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status.name());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        }
        return lista;
    }

    public void validar(int id, StatusValidacaoDocumento status, String cpfValidador) throws SQLException {
        String sql = "UPDATE Documento SET status_validacao_documento=?, validado_por_usuario=?, validado_em_documento=? "
                   + "WHERE id_documento=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status.name());
            ps.setString(2, cpfValidador);
            ps.setTimestamp(3, Timestamp.valueOf(LocalDateTime.now()));
            ps.setInt(4, id);
            ps.executeUpdate();
        }
    }

    private Documento mapear(ResultSet rs) throws SQLException {
        Documento d = new Documento();
        d.setId(rs.getInt("id_documento"));
        d.setCpfUsuario(rs.getString("cpf_usuario"));
        String tipo = rs.getString("tipo_documento");
        if (tipo != null) d.setTipo(TipoDocumento.valueOf(tipo));
        d.setArquivoUrl(rs.getString("arquivo_url_documento"));
        d.setStatusValidacao(StatusValidacaoDocumento.valueOf(rs.getString("status_validacao_documento")));
        d.setCpfValidador(rs.getString("validado_por_usuario"));
        Timestamp validadoEm = rs.getTimestamp("validado_em_documento");
        if (validadoEm != null) d.setValidadoEm(validadoEm.toLocalDateTime());
        Timestamp enviadoEm = rs.getTimestamp("enviado_em_documento");
        if (enviadoEm != null) d.setEnviadoEm(enviadoEm.toLocalDateTime());
        return d;
    }
}
