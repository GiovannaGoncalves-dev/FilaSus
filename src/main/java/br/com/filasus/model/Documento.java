package br.com.filasus.model;

import br.com.filasus.model.enums.StatusValidacaoDocumento;
import br.com.filasus.model.enums.TipoDocumento;
import java.time.LocalDateTime;

/**
 * Documento anexado por um usuário (comprovante de prioridade, exame,
 * relatório, etc.), sujeito a validação por outro usuário. Tabela: Documento.
 * Substitui o antigo DocumentoPaciente — não é mais exclusivo de prioridade.
 */
public class Documento {

    private int id;
    private String cpfUsuario;
    private TipoDocumento tipo;
    private String arquivoUrl;
    private String nomeOriginal;
    private Integer idFila;
    private Integer sequenciaItemFila;
    private String motivoPrioridade;
    private String descricao;
    private StatusValidacaoDocumento statusValidacao = StatusValidacaoDocumento.PENDENTE;
    private String cpfValidador;
    private LocalDateTime validadoEm;
    private LocalDateTime enviadoEm;

    public Documento() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getCpfUsuario() { return cpfUsuario; }
    public void setCpfUsuario(String cpfUsuario) { this.cpfUsuario = cpfUsuario; }

    public TipoDocumento getTipo() { return tipo; }
    public void setTipo(TipoDocumento tipo) { this.tipo = tipo; }

    public String getArquivoUrl() { return arquivoUrl; }
    public void setArquivoUrl(String arquivoUrl) { this.arquivoUrl = arquivoUrl; }

    public String getNomeOriginal() { return nomeOriginal; }
    public void setNomeOriginal(String nomeOriginal) { this.nomeOriginal = nomeOriginal; }

    public Integer getIdFila() { return idFila; }
    public void setIdFila(Integer idFila) { this.idFila = idFila; }

    public Integer getSequenciaItemFila() { return sequenciaItemFila; }
    public void setSequenciaItemFila(Integer sequenciaItemFila) { this.sequenciaItemFila = sequenciaItemFila; }

    public String getMotivoPrioridade() { return motivoPrioridade; }
    public void setMotivoPrioridade(String motivoPrioridade) { this.motivoPrioridade = motivoPrioridade; }

    public String getDescricao() { return descricao; }
    public void setDescricao(String descricao) { this.descricao = descricao; }

    public StatusValidacaoDocumento getStatusValidacao() { return statusValidacao; }
    public void setStatusValidacao(StatusValidacaoDocumento statusValidacao) { this.statusValidacao = statusValidacao; }

    public String getCpfValidador() { return cpfValidador; }
    public void setCpfValidador(String cpfValidador) { this.cpfValidador = cpfValidador; }

    public LocalDateTime getValidadoEm() { return validadoEm; }
    public void setValidadoEm(LocalDateTime validadoEm) { this.validadoEm = validadoEm; }

    public LocalDateTime getEnviadoEm() { return enviadoEm; }
    public void setEnviadoEm(LocalDateTime enviadoEm) { this.enviadoEm = enviadoEm; }

    @Override
    public String toString() {
        return "Documento{id=" + id + ", cpfUsuario='" + cpfUsuario + "', tipo=" + tipo
             + ", status=" + statusValidacao + "}";
    }
}
