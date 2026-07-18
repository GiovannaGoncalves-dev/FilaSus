package br.com.filasus.dao;

import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO para os perfis de um usuário (tabela UsuarioPerfil, PK composta
 * id_perfil + cpf_usuario). Um usuário pode ter vários perfis.
 */
public class UsuarioPerfilDAO {

    /** Adiciona um perfil ao usuário. Não faz nada se ele já tiver esse perfil. */
    public void adicionar(String cpfUsuario, PerfilUsuario perfil) throws SQLException {
        if (temPerfil(cpfUsuario, perfil)) return;
        String sqlProxId = "SELECT COALESCE(MAX(id_perfil), 0) + 1 FROM UsuarioPerfil WHERE cpf_usuario = ?";
        String sqlIns = "INSERT INTO UsuarioPerfil (id_perfil, cpf_usuario, tipo_perfil) VALUES (?, ?, ?)";
        try (Connection conn = DBConnection.getConnection()) {
            int proxId;
            try (PreparedStatement ps = conn.prepareStatement(sqlProxId)) {
                ps.setString(1, cpfUsuario);
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    proxId = rs.getInt(1);
                }
            }
            try (PreparedStatement ps = conn.prepareStatement(sqlIns)) {
                ps.setInt(1, proxId);
                ps.setString(2, cpfUsuario);
                ps.setString(3, perfil.name());
                ps.executeUpdate();
            }
        }
    }

    public void remover(String cpfUsuario, PerfilUsuario perfil) throws SQLException {
        String sql = "DELETE FROM UsuarioPerfil WHERE cpf_usuario = ? AND tipo_perfil = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpfUsuario);
            ps.setString(2, perfil.name());
            ps.executeUpdate();
        }
    }

    public boolean temPerfil(String cpfUsuario, PerfilUsuario perfil) throws SQLException {
        String sql = "SELECT 1 FROM UsuarioPerfil WHERE cpf_usuario = ? AND tipo_perfil = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpfUsuario);
            ps.setString(2, perfil.name());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public List<PerfilUsuario> listarPerfis(String cpfUsuario) throws SQLException {
        String sql = "SELECT tipo_perfil FROM UsuarioPerfil WHERE cpf_usuario = ? ORDER BY id_perfil";
        List<PerfilUsuario> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpfUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(PerfilUsuario.valueOf(rs.getString("tipo_perfil")));
            }
        }
        return lista;
    }
}
