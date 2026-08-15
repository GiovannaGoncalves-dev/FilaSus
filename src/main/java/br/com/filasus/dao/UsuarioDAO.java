package br.com.filasus.dao;

import br.com.filasus.model.Usuario;
import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO responsável pelas operações de persistência de Usuario.
 * Tabela: Usuario — chave primária natural: cpf_usuario.
 *
 * Perfis e unidades vinculadas não são colunas desta tabela (ver
 * UsuarioPerfilDAO / UsuarioUnidadeDAO); este DAO carrega ambos ao montar o
 * objeto, para que o `Usuario` retornado já venha completo.
 */
public class UsuarioDAO {

    private final UsuarioPerfilDAO perfilDAO = new UsuarioPerfilDAO();
    private final UsuarioUnidadeDAO unidadeDAO = new UsuarioUnidadeDAO();

    // ─── CREATE ──────────────────────────────────────────────────────────────

    public void inserir(Usuario usuario) throws SQLException {
        String sql = "INSERT INTO Usuario "
                   + "(cpf_usuario, email_usuario, senha_usuario, nome_usuario, especialidade_usuario, "
                   + " telefone_usuario, data_nascimento_usuario, ativo_usuario, criado_em_usuario) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, usuario.getCpf());
            ps.setString(2, usuario.getEmail());
            ps.setString(3, usuario.getSenhaHash());
            ps.setString(4, usuario.getNome());
            ps.setString(5, usuario.getEspecialidade());
            ps.setString(6, usuario.getTelefone());
            ps.setDate(7, usuario.getDataNascimento() != null
                    ? Date.valueOf(usuario.getDataNascimento()) : null);
            ps.setBoolean(8, usuario.isAtivo());
            if (usuario.getCriadoEm() == null) usuario.setCriadoEm(java.time.LocalDateTime.now());
            ps.setTimestamp(9, Timestamp.valueOf(usuario.getCriadoEm()));

            ps.executeUpdate();
        }
    }

    // ─── READ ─────────────────────────────────────────────────────────────────

    public Usuario buscarPorCpf(String cpf) throws SQLException {
        String sql = "SELECT * FROM Usuario WHERE cpf_usuario = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpf);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        }
        return null;
    }

    /** Busca usuário ativo por e-mail, case-insensitive (login da equipe). */
    public Usuario buscarPorEmail(String email) throws SQLException {
        String sql = "SELECT * FROM Usuario WHERE LOWER(email_usuario) = LOWER(?) AND ativo_usuario = TRUE";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        }
        return null;
    }

    public boolean existeEmail(String email) throws SQLException {
        String sql = "SELECT 1 FROM Usuario WHERE LOWER(email_usuario) = LOWER(?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public boolean existeCpf(String cpf) throws SQLException {
        String sql = "SELECT 1 FROM Usuario WHERE cpf_usuario = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpf);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /** Usuários que têm o perfil informado (join com UsuarioPerfil). */
    public List<Usuario> listarPorPerfil(PerfilUsuario perfil) throws SQLException {
        String sql = "SELECT u.* FROM Usuario u "
                   + "INNER JOIN UsuarioPerfil up ON up.cpf_usuario = u.cpf_usuario "
                   + "WHERE up.tipo_perfil = ? ORDER BY u.nome_usuario";
        List<Usuario> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, perfil.name());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        }
        return lista;
    }

    public List<Usuario> listarPacientes() throws SQLException {
        return listarPorPerfil(PerfilUsuario.PACIENTE);
    }

    /** Busca pacientes por nome ou CPF (somente dígitos) — substring, case-insensitive. */
    public List<Usuario> buscarPacientes(String termo) throws SQLException {
        // sem esse cuidado, um termo só de letras vira LIKE '%%' no CPF e casa com todo mundo
        String digitos = termo.replaceAll("\\D", "");
        String sql = "SELECT u.* FROM Usuario u "
                   + "INNER JOIN UsuarioPerfil up ON up.cpf_usuario = u.cpf_usuario "
                   + "WHERE up.tipo_perfil = 'PACIENTE' "
                   + "AND (LOWER(u.nome_usuario) LIKE ?"
                   + (digitos.isEmpty() ? "" : " OR u.cpf_usuario LIKE ?")
                   + ") ORDER BY u.nome_usuario";
        List<Usuario> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, "%" + termo.toLowerCase() + "%");
            if (!digitos.isEmpty()) ps.setString(2, "%" + digitos + "%");
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        }
        return lista;
    }

    // ─── UPDATE ───────────────────────────────────────────────────────────────

    public void atualizar(Usuario usuario) throws SQLException {
        String sql = "UPDATE Usuario SET email_usuario=?, senha_usuario=?, nome_usuario=?, "
                   + "especialidade_usuario=?, telefone_usuario=?, data_nascimento_usuario=?, ativo_usuario=? "
                   + "WHERE cpf_usuario=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, usuario.getEmail());
            ps.setString(2, usuario.getSenhaHash());
            ps.setString(3, usuario.getNome());
            ps.setString(4, usuario.getEspecialidade());
            ps.setString(5, usuario.getTelefone());
            ps.setDate(6, usuario.getDataNascimento() != null
                    ? Date.valueOf(usuario.getDataNascimento()) : null);
            ps.setBoolean(7, usuario.isAtivo());
            ps.setString(8, usuario.getCpf());

            ps.executeUpdate();
        }
    }

    public void atualizarSenha(String cpf, String senhaHash) throws SQLException {
        String sql = "UPDATE Usuario SET senha_usuario = ? WHERE cpf_usuario = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, senhaHash);
            ps.setString(2, cpf);
            ps.executeUpdate();
        }
    }

    // ─── DELETE ───────────────────────────────────────────────────────────────

    public void deletar(String cpf) throws SQLException {
        String sql = "DELETE FROM Usuario WHERE cpf_usuario = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpf);
            ps.executeUpdate();
        }
    }

    // ─── Mapeamento ResultSet → Usuario ──────────────────────────────────────

    private Usuario mapear(ResultSet rs) throws SQLException {
        Usuario u = new Usuario();
        u.setCpf(rs.getString("cpf_usuario"));
        u.setEmail(rs.getString("email_usuario"));
        u.setSenhaHash(rs.getString("senha_usuario"));
        u.setNome(rs.getString("nome_usuario"));
        u.setEspecialidade(rs.getString("especialidade_usuario"));
        u.setTelefone(rs.getString("telefone_usuario"));

        Date dataNasc = rs.getDate("data_nascimento_usuario");
        if (dataNasc != null) u.setDataNascimento(dataNasc.toLocalDate());

        u.setAtivo(rs.getBoolean("ativo_usuario"));
        Timestamp criadoEm = rs.getTimestamp("criado_em_usuario");
        if (criadoEm != null) u.setCriadoEm(criadoEm.toLocalDateTime());

        u.setPerfis(perfilDAO.listarPerfis(u.getCpf()));
        u.setUnidadeIds(unidadeDAO.listarUnidadesDoUsuario(u.getCpf()));
        return u;
    }
}
