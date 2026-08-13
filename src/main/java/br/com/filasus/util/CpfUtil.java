package br.com.filasus.util;

/**
 * Utilitário para validação e formatação de CPF (Cadastro de Pessoas Físicas).
 */
public class CpfUtil {

    private CpfUtil() {
        // Construtor privado para classe utilitária
    }

    /**
     * Remove todos os caracteres não numéricos de uma string de CPF.
     *
     * @param cpf String contendo CPF formatado ou não.
     * @return String contendo apenas os 11 dígitos do CPF ou null se o parâmetro for null.
     */
    public static String desformatar(String cpf) {
        if (cpf == null) return null;
        return cpf.replaceAll("\\D", "");
    }

    /**
     * Valida se a string representa um CPF válido no formato com ou sem pontuação.
     *
     * @param cpf String do CPF a ser validado.
     * @return true se o CPF for válido, false caso contrário.
     */
    public static boolean isValido(String cpf) {
        if (cpf == null) return false;

        String cleanCpf = desformatar(cpf);
        if (cleanCpf == null || cleanCpf.length() != 11) {
            return false;
        }

        // Rejeita CPFs com todos os dígitos iguais (ex: 000.000.000-00, 111.111.111-11, etc.)
        if (cleanCpf.matches("(\\d)\\1{10}")) {
            return false;
        }

        try {
            // Cálculo do primeiro dígito verificador
            int soma1 = 0;
            for (int i = 0; i < 9; i++) {
                soma1 += (cleanCpf.charAt(i) - '0') * (10 - i);
            }
            int digito1 = (soma1 * 10) % 11;
            if (digito1 == 10 || digito1 == 11) {
                digito1 = 0;
            }
            if (digito1 != (cleanCpf.charAt(9) - '0')) {
                return false;
            }

            // Cálculo do segundo dígito verificador
            int soma2 = 0;
            for (int i = 0; i < 10; i++) {
                soma2 += (cleanCpf.charAt(i) - '0') * (11 - i);
            }
            int digito2 = (soma2 * 10) % 11;
            if (digito2 == 10 || digito2 == 11) {
                digito2 = 0;
            }
            if (digito2 != (cleanCpf.charAt(10) - '0')) {
                return false;
            }

            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Formata um CPF numérico de 11 dígitos no padrão XXX.XXX.XXX-XX.
     *
     * @param cpf String do CPF.
     * @return CPF formatado ou a própria string original se não tiver 11 dígitos.
     */
    public static String formatar(String cpf) {
        if (cpf == null) return null;
        String clean = desformatar(cpf);
        if (clean.length() != 11) return cpf;
        return clean.substring(0, 3) + "."
             + clean.substring(3, 6) + "."
             + clean.substring(6, 9) + "-"
             + clean.substring(9);
    }
}
