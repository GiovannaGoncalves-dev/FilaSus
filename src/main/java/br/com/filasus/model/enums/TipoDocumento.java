package br.com.filasus.model.enums;

public enum TipoDocumento {
    RELATORIO("Relatório"),
    EXAME("Exame"),
    OUTRO("Outro");

    private final String descricao;

    TipoDocumento(String descricao) {
        this.descricao = descricao;
    }

    public String getDescricao() {
        return descricao;
    }

    public String toJson() {
        return name().toLowerCase();
    }

    public static TipoDocumento fromJson(String valor) {
        if (valor == null) return null;
        return TipoDocumento.valueOf(valor.trim().toUpperCase());
    }
}
