package br.com.filasus.dao;

import br.com.filasus.model.Mutirao;
import br.com.filasus.model.enums.StatusMutirao;
import br.com.filasus.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO responsável pelas operações de persistência de Mutirao.
 * Tabela: Mutirao — sempre vinculado a uma Unidade.
 */
public class MutiraoDAO {

    public void inserir(Mutirao mutirao) throws SQLException {
        String sql = "INSERT INTO Mutirao "
                   + "(id_unidade, data_mutirao, tipo_mutirao, local_mutirao, duracao_min_mutirao, status_mutirao, criado_em_mutirao) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, mutirao.getIdUnidade());
            ps.setDate(2, Date.valueOf(mutirao.getData()));
            ps.setString(3, mutirao.getTipo());
            ps.setString(4, mutirao.getLocal());
            ps.setInt(5, mutirao.getDuracaoMinutos());
            ps.setString(6, mutirao.getStatus().name());
            if (mutirao.getCriadoEm() == null) mutirao.setCriadoEm(java.time.LocalDateTime.now());
            ps.setTimestamp(7, Timestamp.valueOf(mutirao.getCriadoEm()));

            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) mutirao.setId(rs.getInt(1));
            }
        }
    }

    public Mutirao buscarPorId(int id) throws SQLException {
        String sql = "SELECT * FROM Mutirao WHERE id_mutirao = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        }
        return null;
    }

    public List<Mutirao> listarPorUnidade(int idUnidade) throws SQLException {
        String sql = "SELECT * FROM Mutirao WHERE id_unidade = ? ORDER BY data_mutirao DESC, id_mutirao DESC";
        List<Mutirao> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idUnidade);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        }
        return lista;
    }

    public List<Mutirao> listarTodos() throws SQLException {
        String sql = "SELECT * FROM Mutirao ORDER BY data_mutirao DESC, id_mutirao DESC";
        List<Mutirao> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapear(rs));
        }
        return lista;
    }

    public List<Mutirao> listarPorStatus(StatusMutirao status) throws SQLException {
        String sql = "SELECT * FROM Mutirao WHERE status_mutirao = ? ORDER BY data_mutirao DESC, id_mutirao DESC";
        List<Mutirao> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status.name());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        }
        return lista;
    }

    public void atualizarStatus(int id, StatusMutirao status) throws SQLException {
        String sql = "UPDATE Mutirao SET status_mutirao = ? WHERE id_mutirao = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status.name());
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    public void deletar(int id) throws SQLException {
        String sql = "DELETE FROM Mutirao WHERE id_mutirao = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    private Mutirao mapear(ResultSet rs) throws SQLException {
        Mutirao m = new Mutirao();
        m.setId(rs.getInt("id_mutirao"));
        m.setIdUnidade(rs.getInt("id_unidade"));
        Date data = rs.getDate("data_mutirao");
        if (data != null) m.setData(data.toLocalDate());
        m.setTipo(rs.getString("tipo_mutirao"));
        m.setLocal(rs.getString("local_mutirao"));
        m.setDuracaoMinutos(rs.getInt("duracao_min_mutirao"));
        m.setStatus(StatusMutirao.valueOf(rs.getString("status_mutirao")));
        Timestamp criadoEm = rs.getTimestamp("criado_em_mutirao");
        if (criadoEm != null) m.setCriadoEm(criadoEm.toLocalDateTime());
        return m;
    }
}
