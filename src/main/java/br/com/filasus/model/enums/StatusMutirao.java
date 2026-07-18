package br.com.filasus.model.enums;

public enum StatusMutirao {
    ABERTO("Aberto"),
    ENCERRADO("Encerrado");

    private final String descricao;

    StatusMutirao(String descricao) {
        this.descricao = descricao;
    }

    public String getDescricao() {
        return descricao;
    }

    public String toJson() {
        return name().toLowerCase();
    }

    public static StatusMutirao fromJson(String valor) {
        if (valor == null) return null;
        return StatusMutirao.valueOf(valor.trim().toUpperCase());
    }
}
