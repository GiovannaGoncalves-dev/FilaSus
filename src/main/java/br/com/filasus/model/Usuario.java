package br.com.filasus.model;

import br.com.filasus.model.enums.PerfilUsuario;
import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Period;
import java.util.ArrayList;
import java.util.List;

/**
 * Entidade para todos os usuários do sistema (pacientes e equipe).
 * Tabela: Usuario — chave primária natural (cpf_usuario), sem id substituto.
 *
 * Perfis (Paciente/Atendente/Medico/Adm_unidade/Adm_geral) não são mais um
 * campo único: um usuário pode ter vários ao mesmo tempo (tabela
 * UsuarioPerfil). Aqui ficam carregados sob demanda em {@link #perfis}.
 * Da mesma forma, as unidades a que o usuário está vinculado (equipe) ficam
 * em {@link #unidadeIds}, carregadas sob demanda (tabela UsuarioUnidade).
 *
 * Implementa Serializable porque este objeto fica guardado na HttpSession
 * (login Model 2) — o Tomcat pode tentar persistir sessões entre restarts.
 */
public class Usuario implements Serializable {

    private String cpf; // PK
    private String email;
    private String senhaHash;
    private String nome;
    private String especialidade; // só MEDICO
    private String telefone;
    private LocalDate dataNascimento;
    private boolean ativo = true;
    private LocalDateTime criadoEm;

    private List<PerfilUsuario> perfis = new ArrayList<>();
    private List<Integer> unidadeIds = new ArrayList<>();

    public Usuario() {}

    // ─── Getters & Setters ────────────────────────────────────────────────────

    public String getCpf() { return cpf; }
    public void setCpf(String cpf) { this.cpf = cpf; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getSenhaHash() { return senhaHash; }
    public void setSenhaHash(String senhaHash) { this.senhaHash = senhaHash; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public String getEspecialidade() { return especialidade; }
    public void setEspecialidade(String especialidade) { this.especialidade = especialidade; }

    public String getTelefone() { return telefone; }
    public void setTelefone(String telefone) { this.telefone = telefone; }

    public LocalDate getDataNascimento() { return dataNascimento; }
    public void setDataNascimento(LocalDate dataNascimento) { this.dataNascimento = dataNascimento; }

    public boolean isAtivo() { return ativo; }
    public void setAtivo(boolean ativo) { this.ativo = ativo; }

    public LocalDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(LocalDateTime criadoEm) { this.criadoEm = criadoEm; }

    public List<PerfilUsuario> getPerfis() { return perfis; }
    public void setPerfis(List<PerfilUsuario> perfis) { this.perfis = perfis; }

    public boolean temPerfil(PerfilUsuario perfil) { return perfis.contains(perfil); }

    public List<Integer> getUnidadeIds() { return unidadeIds; }
    public void setUnidadeIds(List<Integer> unidadeIds) { this.unidadeIds = unidadeIds; }

    /**
     * Calcula a idade com base na data de nascimento (considera mês/dia, não só o ano).
     */
    public int getIdade() {
        if (dataNascimento == null) return 0;
        return Period.between(dataNascimento, LocalDate.now()).getYears();
    }

    // ─── Getters de exibição (uso direto em EL nas JSPs: ${usuario.cpfFormatado}) ─────

    public String getCpfFormatado() {
        if (cpf == null || cpf.length() != 11) return cpf;
        return cpf.substring(0, 3) + "." + cpf.substring(3, 6) + "." + cpf.substring(6, 9) + "-" + cpf.substring(9);
    }

    public String getTelefoneFormatado() {
        if (telefone == null) return null;
        String d = telefone.replaceAll("\\D", "");
        if (d.length() == 11) return "(" + d.substring(0, 2) + ") " + d.substring(2, 7) + "-" + d.substring(7);
        if (d.length() == 10) return "(" + d.substring(0, 2) + ") " + d.substring(2, 6) + "-" + d.substring(6);
        return telefone;
    }

    @Override
    public String toString() {
        return "Usuario{cpf='" + cpf + "', nome='" + nome + "', perfis=" + perfis + "}";
    }
}
