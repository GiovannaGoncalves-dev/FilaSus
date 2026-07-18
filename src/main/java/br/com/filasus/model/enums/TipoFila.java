package br.com.filasus.model.enums;

/**
 * Classificação da fila (`Fila.tipo_fila`). No schema atual a prioridade é
 * uma propriedade da fila, não do item individual — substitui o antigo
 * `TipoSenha`, que vivia em `ItemFila`.
 */
public enum TipoFila {
    COMUM("Comum"),
    PRIORITARIO("Prioritário");

    private final String descricao;

    TipoFila(String descricao) {
        this.descricao = descricao;
    }

    public String getDescricao() {
        return descricao;
    }

    public String toJson() {
        return name().toLowerCase();
    }

    public static TipoFila fromJson(String valor) {
        if (valor == null) return null;
        return TipoFila.valueOf(valor.trim().toUpperCase());
    }
}
