package br.com.filasus.model.enums;

public enum StatusMutirao {
    AGENDADO("Agendado"),
    ABERTO("Aberto"),
    ENCERRADO("Encerrado"),
    CANCELADO("Cancelado");

    private final String descricao;

    StatusMutirao(String descricao) {
        this.descricao = descricao;
    }

    public String getDescricao() {
        return descricao;
    }

    /** Valor canônico armazenado no ENUM status_mutirao do MySQL. */
    public String toDatabaseValue() {
        return name().toLowerCase(java.util.Locale.ROOT);
    }

    public String toJson() {
        return switch (this) {
            case AGENDADO -> "agendada";
            case ABERTO -> "aberta";
            case ENCERRADO -> "encerrada";
            case CANCELADO -> "cancelada";
        };
    }

    public static StatusMutirao fromJson(String valor) {
        if (valor == null) return null;
        return switch (valor.trim().toLowerCase()) {
            case "agendada", "agendado" -> AGENDADO;
            case "aberta", "aberto" -> ABERTO;
            case "encerrada", "encerrado" -> ENCERRADO;
            case "cancelada", "cancelado" -> CANCELADO;
            default -> throw new IllegalArgumentException("Status de mutirão inválido: " + valor);
        };
    }
}
