package br.com.filasus.dao;

import br.com.filasus.model.ItemFila;
import br.com.filasus.model.ItemFilaId;
import br.com.filasus.model.enums.StatusItemFila;
import br.com.filasus.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

/**
 * DAO responsável pelas operações de persistência de ItemFila.
 * Tabela: ItemFila — PK composta: (id_fila, sequencia_item_fila).
 */
public class ItemFilaDAO {

    // ─── CREATE ──────────────────────────────────────────────────────────────

    /**
     * Insere um paciente na fila. A sequência é calculada automaticamente
     * como MAX(sequencia_item_fila) + 1 para aquela fila.
     */
    public void inserir(ItemFila item) throws SQLException {
        String sqlSeq = "SELECT COALESCE(MAX(sequencia_item_fila), 0) + 1 FROM ItemFila WHERE id_fila = ?";
        String sqlIns = "INSERT INTO ItemFila (id_fila, cpf_usuario, sequencia_item_fila, status_itemfila, entrada_em_item_fila) "
                      + "VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int idFila = item.getIdFila();
                int proxSeq;

                try (PreparedStatement psSeq = conn.prepareStatement(sqlSeq)) {
                    psSeq.setInt(1, idFila);
                    try (ResultSet rs = psSeq.executeQuery()) {
                        rs.next();
                        proxSeq = rs.getInt(1);
                    }
                }

                item.setId(new ItemFilaId(idFila, proxSeq));
                if (item.getEntradaEm() == null) item.setEntradaEm(java.time.LocalDateTime.now());

                try (PreparedStatement psIns = conn.prepareStatement(sqlIns)) {
                    psIns.setInt(1, idFila);
                    psIns.setString(2, item.getCpfPaciente());
                    psIns.setInt(3, proxSeq);
                    psIns.setString(4, item.getStatus().name());
                    psIns.setTimestamp(5, Timestamp.valueOf(item.getEntradaEm()));
                    psIns.executeUpdate();
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

    // ─── READ ─────────────────────────────────────────────────────────────────

    public ItemFila buscarPorChave(int idFila, int sequencia) throws SQLException {
        String sql = "SELECT * FROM ItemFila WHERE id_fila = ? AND sequencia_item_fila = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idFila);
            ps.setInt(2, sequencia);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        }
        return null;
    }

    public List<ItemFila> listarPorFila(int idFila) throws SQLException {
        String sql = "SELECT * FROM ItemFila WHERE id_fila = ? ORDER BY sequencia_item_fila";
        List<ItemFila> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idFila);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        }
        return lista;
    }

    public List<ItemFila> listarPorFilaEStatus(int idFila, Collection<StatusItemFila> status) throws SQLException {
        if (status.isEmpty()) return new ArrayList<>();
        String placeholders = String.join(",", status.stream().map(s -> "?").toList());
        String sql = "SELECT * FROM ItemFila WHERE id_fila = ? AND status_itemfila IN (" + placeholders + ") "
                   + "ORDER BY sequencia_item_fila";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idFila);
            int idx = 2;
            for (StatusItemFila s : status) ps.setString(idx++, s.name());
            try (ResultSet rs = ps.executeQuery()) {
                List<ItemFila> lista = new ArrayList<>();
                while (rs.next()) lista.add(mapear(rs));
                return lista;
            }
        }
    }

    public List<ItemFila> listarPorPaciente(String cpfPaciente) throws SQLException {
        String sql = "SELECT * FROM ItemFila WHERE cpf_usuario = ? ORDER BY entrada_em_item_fila DESC";
        List<ItemFila> lista = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cpfPaciente);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        }
        return lista;
    }

    public int calcularPosicao(ItemFila item) throws SQLException {
        if (item == null || item.getStatus() != StatusItemFila.AGUARDANDO) return 0;
        String sql = "SELECT COUNT(*) + 1 AS posicao FROM ItemFila anterior "
                + "WHERE anterior.id_fila=? AND anterior.status_itemfila='aguardando' AND ("
                + "(EXISTS (SELECT 1 FROM Documento d WHERE d.id_fila_documento=anterior.id_fila "
                + "AND d.sequencia_item_fila_documento=anterior.sequencia_item_fila AND d.status_validacao_documento='aprovado') "
                + "AND NOT EXISTS (SELECT 1 FROM Documento atual WHERE atual.id_fila_documento=? "
                + "AND atual.sequencia_item_fila_documento=? AND atual.status_validacao_documento='aprovado')) "
                + "OR ((EXISTS (SELECT 1 FROM Documento d WHERE d.id_fila_documento=anterior.id_fila "
                + "AND d.sequencia_item_fila_documento=anterior.sequencia_item_fila AND d.status_validacao_documento='aprovado')) "
                + "= (EXISTS (SELECT 1 FROM Documento atual WHERE atual.id_fila_documento=? "
                + "AND atual.sequencia_item_fila_documento=? AND atual.status_validacao_documento='aprovado')) "
                + "AND anterior.sequencia_item_fila < ?))";
        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, item.getIdFila());
            ps.setInt(2, item.getIdFila());
            ps.setInt(3, item.getSequenciaItemFila());
            ps.setInt(4, item.getIdFila());
            ps.setInt(5, item.getSequenciaItemFila());
            ps.setInt(6, item.getSequenciaItemFila());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("posicao") : 0;
            }
        }
    }

    // ─── UPDATE ───────────────────────────────────────────────────────────────

    /** Atualiza o status do item (atualizado_em_item_fila é preenchido pelo próprio banco). */
    public void atualizarStatus(int idFila, int sequencia, StatusItemFila status) throws SQLException {
        String sql = "UPDATE ItemFila SET status_itemfila = ? WHERE id_fila = ? AND sequencia_item_fila = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status.name());
            ps.setInt(2, idFila);
            ps.setInt(3, sequencia);
            ps.executeUpdate();
        }
    }

    private ItemFila mapear(ResultSet rs) throws SQLException {
        ItemFila item = new ItemFila();
        item.setId(new ItemFilaId(rs.getInt("id_fila"), rs.getInt("sequencia_item_fila")));
        item.setCpfPaciente(rs.getString("cpf_usuario"));
        item.setStatus(StatusItemFila.fromJson(rs.getString("status_itemfila")));

        Timestamp entrada = rs.getTimestamp("entrada_em_item_fila");
        if (entrada != null) item.setEntradaEm(entrada.toLocalDateTime());

        Timestamp atualizado = rs.getTimestamp("atualizado_em_item_fila");
        if (atualizado != null) item.setAtualizadoEm(atualizado.toLocalDateTime());

        return item;
    }
}
