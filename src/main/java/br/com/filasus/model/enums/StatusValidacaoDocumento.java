package br.com.filasus.model.enums;

/**
 * Estado de validação de um `Documento` (ex.: comprovante de prioridade,
 * exame, relatório). Substitui o antigo `PrioridadeValidacao` — a validação
 * agora vive na entidade `Documento`, não em colunas de `ItemFila`.
 */
public enum StatusValidacaoDocumento {
    PENDENTE("Pendente"),
    APROVADO("Aprovado"),
    REJEITADO("Rejeitado");

    private final String descricao;

    StatusValidacaoDocumento(String descricao) {
        this.descricao = descricao;
    }

    public String getDescricao() {
        return descricao;
    }

    public String toJson() {
        return name().toLowerCase();
    }

    public static StatusValidacaoDocumento fromJson(String valor) {
        if (valor == null) return PENDENTE;
        return StatusValidacaoDocumento.valueOf(valor.trim().toUpperCase());
    }
}
