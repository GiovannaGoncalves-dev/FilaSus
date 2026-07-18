package br.com.filasus.dao;

import br.com.filasus.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO para o vínculo entre usuário e mutirão (organizador/participante).
 * Tabela: UsuarioMutirao.
 */
public class UsuarioMutiraoDAO {

    public void vincular(String cpfUsuario, int idMutirao, boolean criouMutirao) throws SQLException {
        String sql = "INSERT INTO UsuarioMutirao (cpf_usuario, id_mutirao, criou_mutirao) VALUES (?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpfUsuario);
            ps.setInt(2, idMutirao);
            ps.setBoolean(3, criouMutirao);
            ps.executeUpdate();
        }
    }

    public List<String> listarOrganizadores(int idMutirao) throws SQLException {
        String sql = "SELECT cpf_usuario FROM UsuarioMutirao WHERE id_mutirao = ? AND criou_mutirao = 1";
        List<String> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idMutirao);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(rs.getString("cpf_usuario"));
            }
        }
        return lista;
    }

    public List<Integer> listarMutiroesDoUsuario(String cpfUsuario) throws SQLException {
        String sql = "SELECT id_mutirao FROM UsuarioMutirao WHERE cpf_usuario = ?";
        List<Integer> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpfUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(rs.getInt("id_mutirao"));
            }
        }
        return lista;
    }
}
