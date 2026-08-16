package br.com.filasus.dao;

import br.com.filasus.model.Atendimento;
import br.com.filasus.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/** DAO responsável pelas operações de persistência de Atendimento. */
public class AtendimentoDAO {

    /** Inicia o atendimento e muda a senha na mesma transacao, com bloqueio da linha. */
    public void iniciarTransacional(Atendimento atendimento) throws SQLException {
        String lockItem = "SELECT status_itemfila FROM ItemFila WHERE id_fila=? AND sequencia_item_fila=? FOR UPDATE";
        String openMedic = "SELECT 1 FROM Atendimento WHERE cpf_usuario=? AND fim_atendimento IS NULL LIMIT 1 FOR UPDATE";
        String openItem = "SELECT 1 FROM Atendimento WHERE id_fila=? AND sequencia_item_fila=? AND fim_atendimento IS NULL LIMIT 1 FOR UPDATE";
        String insert = "INSERT INTO Atendimento (id_item_fila, cpf_usuario, inicio_atendimento, id_fila, sequencia_item_fila) VALUES (?, ?, ?, ?, ?)";
        String update = "UPDATE ItemFila SET status_itemfila='EM_ATENDIMENTO' WHERE id_fila=? AND sequencia_item_fila=? AND status_itemfila='CHAMADO'";
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(lockItem)) {
                    ps.setInt(1, atendimento.getIdFila()); ps.setInt(2, atendimento.getSequenciaItemFila());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next() || !"CHAMADO".equalsIgnoreCase(rs.getString(1)))
                            throw new SQLException("A senha nao esta disponivel para atendimento.");
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement(openMedic)) {
                    ps.setString(1, atendimento.getCpfMedico());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) throw new SQLException("Finalize o atendimento atual primeiro.");
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement(openItem)) {
                    ps.setInt(1, atendimento.getIdFila()); ps.setInt(2, atendimento.getSequenciaItemFila());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) throw new SQLException("A senha ja possui atendimento em andamento.");
                    }
                }
                if (atendimento.getInicio() == null) atendimento.setInicio(java.time.LocalDateTime.now());
                try (PreparedStatement ps = conn.prepareStatement(insert, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, atendimento.getIdItemFila()); ps.setString(2, atendimento.getCpfMedico());
                    ps.setTimestamp(3, Timestamp.valueOf(atendimento.getInicio()));
                    ps.setInt(4, atendimento.getIdFila()); ps.setInt(5, atendimento.getSequenciaItemFila());
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) { if (rs.next()) atendimento.setId(rs.getInt(1)); }
                }
                try (PreparedStatement ps = conn.prepareStatement(update)) {
                    ps.setInt(1, atendimento.getIdFila()); ps.setInt(2, atendimento.getSequenciaItemFila());
                    if (ps.executeUpdate() != 1) throw new SQLException("A senha mudou de estado durante a operacao.");
                }
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public void iniciar(Atendimento atendimento) throws SQLException {
        String sql = "INSERT INTO Atendimento (id_item_fila, cpf_usuario, inicio_atendimento, id_fila, sequencia_item_fila) "
                   + "VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            if (atendimento.getInicio() == null) atendimento.setInicio(java.time.LocalDateTime.now());
            ps.setInt(1, atendimento.getIdItemFila());
            ps.setString(2, atendimento.getCpfMedico());
            ps.setTimestamp(3, Timestamp.valueOf(atendimento.getInicio()));
            ps.setInt(4, atendimento.getIdFila());
            ps.setInt(5, atendimento.getSequenciaItemFila());
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) atendimento.setId(rs.getInt(1));
            }
        }
    }

    public void finalizar(int id, java.time.LocalDateTime fim) throws SQLException {
        String sql = "UPDATE Atendimento SET fim_atendimento = ? WHERE id_atendimento = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(fim));
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    public Atendimento buscarPorId(int id) throws SQLException {
        String sql = "SELECT * FROM Atendimento WHERE id_atendimento = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        }
        return null;
    }

    public Atendimento buscarPorItem(int idFila, int sequencia) throws SQLException {
        String sql = "SELECT * FROM Atendimento WHERE id_fila=? AND sequencia_item_fila=? "
                + "ORDER BY id_atendimento DESC LIMIT 1";
        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idFila);
            ps.setInt(2, sequencia);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapear(rs) : null;
            }
        }
    }

    /** Atendimento em andamento (fim ainda nulo) de um médico. */
    public Atendimento buscarEmAndamento(String cpfMedico) throws SQLException {
        String sql = "SELECT * FROM Atendimento WHERE cpf_usuario = ? AND fim_atendimento IS NULL LIMIT 1";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpfMedico);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        }
        return null;
    }

    public List<Atendimento> listarPorMedico(String cpfMedico) throws SQLException {
        String sql = "SELECT * FROM Atendimento WHERE cpf_usuario = ? ORDER BY inicio_atendimento DESC";
        List<Atendimento> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpfMedico);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        }
        return lista;
    }

    public List<Atendimento> listarFinalizadosHoje(String cpfMedico) throws SQLException {
        String sql = "SELECT * FROM Atendimento WHERE cpf_usuario = ? AND fim_atendimento IS NOT NULL "
                + "AND fim_atendimento >= CURRENT_DATE AND fim_atendimento < CURRENT_DATE + INTERVAL 1 DAY "
                + "ORDER BY fim_atendimento DESC";
        List<Atendimento> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpfMedico);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        }
        return lista;
    }

    private Atendimento mapear(ResultSet rs) throws SQLException {
        Atendimento a = new Atendimento();
        a.setId(rs.getInt("id_atendimento"));
        a.setIdItemFila(rs.getInt("id_item_fila"));
        a.setIdFila(rs.getInt("id_fila"));
        a.setSequenciaItemFila(rs.getInt("sequencia_item_fila"));
        a.setCpfMedico(rs.getString("cpf_usuario"));
        Timestamp inicio = rs.getTimestamp("inicio_atendimento");
        if (inicio != null) a.setInicio(inicio.toLocalDateTime());
        Timestamp fim = rs.getTimestamp("fim_atendimento");
        if (fim != null) a.setFim(fim.toLocalDateTime());
        return a;
    }
}
