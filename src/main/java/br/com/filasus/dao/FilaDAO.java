package br.com.filasus.dao;

import br.com.filasus.model.Fila;
import br.com.filasus.model.enums.TipoFila;
import br.com.filasus.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO responsável pelas operações de persistência de Fila.
 * Tabela: Fila
 */
public class FilaDAO {

    public void inserir(Fila fila) throws SQLException {
        String sql = "INSERT INTO Fila (id_mutirao, nome_fila, tipo_fila) VALUES (?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, fila.getIdMutirao());
            ps.setString(2, fila.getNome());
            ps.setString(3, fila.getTipo().name());
            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) fila.setId(rs.getInt(1));
            }
        }
    }

    public Fila buscarPorId(int id) throws SQLException {
        String sql = "SELECT * FROM Fila WHERE id_fila = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        }
        return null;
    }

    public List<Fila> listarPorMutirao(int idMutirao) throws SQLException {
        String sql = "SELECT * FROM Fila WHERE id_mutirao = ? ORDER BY nome_fila";
        List<Fila> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idMutirao);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        }
        return lista;
    }

    public void deletar(int id) throws SQLException {
        String sql = "DELETE FROM Fila WHERE id_fila = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    public void atualizar(Fila fila) throws SQLException {
        String sql = "UPDATE Fila SET nome_fila = ?, tipo_fila = ? WHERE id_fila = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, fila.getNome());
            ps.setString(2, fila.getTipo().name());
            ps.setInt(3, fila.getId());
            ps.executeUpdate();
        }
    }

    private Fila mapear(ResultSet rs) throws SQLException {
        Fila f = new Fila();
        f.setId(rs.getInt("id_fila"));
        f.setIdMutirao(rs.getInt("id_mutirao"));
        f.setNome(rs.getString("nome_fila"));
        f.setTipo(TipoFila.fromJson(rs.getString("tipo_fila")));
        return f;
    }
}
