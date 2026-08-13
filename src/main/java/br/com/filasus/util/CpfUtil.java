package br.com.filasus.util;

/**
 * Utilitário para validação e formatação de CPF (Cadastro de Pessoas Físicas).
 */
public class CpfUtil {

    private CpfUtil() {
        // Construtor privado para classe utilitária
    }

    public static String desformatar(String cpf) {
        if (cpf == null) return null;
        return cpf.replaceAll("\\D", "");
    }

    public static boolean isValido(String cpf) {
        if (cpf == null) return false;

        String cleanCpf = desformatar(cpf);
        if (cleanCpf == null || cleanCpf.length() != 11) {
            return false;
        }

        if (cleanCpf.matches("(\\d)\\1{10}")) {
            return false;
        }

        try {
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
