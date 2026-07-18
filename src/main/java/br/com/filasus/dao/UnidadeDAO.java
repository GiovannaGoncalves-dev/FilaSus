package br.com.filasus.dao;

import br.com.filasus.model.Unidade;
import br.com.filasus.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/** DAO responsável pelas operações de persistência de Unidade. */
public class UnidadeDAO {

    public void inserir(Unidade unidade) throws SQLException {
        String sql = "INSERT INTO Unidade (nome_unidade, endereco_unidade) VALUES (?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, unidade.getNome());
            ps.setString(2, unidade.getEndereco());
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) unidade.setId(rs.getInt(1));
            }
        }
    }

    public Unidade buscarPorId(int id) throws SQLException {
        String sql = "SELECT * FROM Unidade WHERE id_unidade = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        }
        return null;
    }

    public List<Unidade> listarTodas() throws SQLException {
        String sql = "SELECT * FROM Unidade ORDER BY nome_unidade";
        List<Unidade> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapear(rs));
        }
        return lista;
    }

    public void atualizar(Unidade unidade) throws SQLException {
        String sql = "UPDATE Unidade SET nome_unidade=?, endereco_unidade=? WHERE id_unidade=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, unidade.getNome());
            ps.setString(2, unidade.getEndereco());
            ps.setInt(3, unidade.getId());
            ps.executeUpdate();
        }
    }

    public void deletar(int id) throws SQLException {
        String sql = "DELETE FROM Unidade WHERE id_unidade = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    private Unidade mapear(ResultSet rs) throws SQLException {
        Unidade u = new Unidade();
        u.setId(rs.getInt("id_unidade"));
        u.setNome(rs.getString("nome_unidade"));
        u.setEndereco(rs.getString("endereco_unidade"));
        return u;
    }
}
