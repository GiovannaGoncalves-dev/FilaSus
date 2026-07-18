package br.com.filasus.model.enums;

public enum StatusItemFila {
    AGUARDANDO("Aguardando"),
    CHAMADO("Chamado"),
    EM_ATENDIMENTO("Em Atendimento"),
    ATENDIDO("Atendido"),
    AUSENTE("Ausente");

    private final String descricao;

    StatusItemFila(String descricao) {
        this.descricao = descricao;
    }

    public String getDescricao() {
        return descricao;
    }

    public String toJson() {
        return name().toLowerCase();
    }

    public static StatusItemFila fromJson(String valor) {
        if (valor == null) return null;
        return StatusItemFila.valueOf(valor.trim().toUpperCase());
    }
}
