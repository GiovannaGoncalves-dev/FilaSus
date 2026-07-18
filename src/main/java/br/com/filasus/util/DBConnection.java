package br.com.filasus.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Utilitário de conexão com o banco de dados MySQL.
 * Utiliza DriverManager diretamente (adequado para Tomcat 9 com Dynamic Web Project).
 *
 * Configuração esperada no banco (ver schema.sql na raiz do projeto):
 *   - Host   : localhost:3306
 *   - Banco  : gerenciamento_fila2
 *   - Usuário: filasus
 *   - Senha  : filasus123
 */
public class DBConnection {

    private static final String URL      = "jdbc:mysql://localhost:3306/gerenciamento_fila2"
                                         + "?useSSL=false&serverTimezone=America/Sao_Paulo"
                                         + "&characterEncoding=UTF-8";
    private static final String USUARIO  = "filasus";
    private static final String SENHA    = "filasus123";

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new ExceptionInInitializerError(
                "Driver MySQL não encontrado. Certifique-se de que o JAR do conector está em WEB-INF/lib.\n" + e);
        }
    }

    private DBConnection() {}

    /**
     * Retorna uma nova conexão com o banco de dados.
     * O chamador é responsável por fechar a conexão.
     */
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USUARIO, SENHA);
    }

    /**
     * Fecha a conexão silenciosamente (útil em blocos finally).
     */
    public static void fechar(Connection conn) {
        if (conn != null) {
            try { conn.close(); } catch (SQLException ignored) {}
        }
    }
}
