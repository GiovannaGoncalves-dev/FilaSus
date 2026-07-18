package br.com.filasus.dao;

import br.com.filasus.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO para o vínculo entre um usuário da equipe e uma unidade de saúde
 * (tabela UsuarioUnidade). Dá escopo ao perfil ADM_UNIDADE.
 */
public class UsuarioUnidadeDAO {

    public void vincular(String cpfUsuario, int idUnidade) throws SQLException {
        String sql = "INSERT IGNORE INTO UsuarioUnidade (cpf_usuario, id_unidade) VALUES (?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpfUsuario);
            ps.setInt(2, idUnidade);
            ps.executeUpdate();
        }
    }

    public void desvincular(String cpfUsuario, int idUnidade) throws SQLException {
        String sql = "DELETE FROM UsuarioUnidade WHERE cpf_usuario = ? AND id_unidade = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpfUsuario);
            ps.setInt(2, idUnidade);
            ps.executeUpdate();
        }
    }

    public List<Integer> listarUnidadesDoUsuario(String cpfUsuario) throws SQLException {
        String sql = "SELECT id_unidade FROM UsuarioUnidade WHERE cpf_usuario = ? ORDER BY id_unidade";
        List<Integer> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpfUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(rs.getInt("id_unidade"));
            }
        }
        return lista;
    }

    public List<String> listarUsuariosDaUnidade(int idUnidade) throws SQLException {
        String sql = "SELECT cpf_usuario FROM UsuarioUnidade WHERE id_unidade = ?";
        List<String> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idUnidade);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(rs.getString("cpf_usuario"));
            }
        }
        return lista;
    }
}
