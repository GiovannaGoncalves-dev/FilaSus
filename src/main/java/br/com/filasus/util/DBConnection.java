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

    private static final String URL = configuracao("FILASUS_DB_URL",
            "jdbc:mysql://localhost:3307/gerenciamento_fila2"
                    + "?useSSL=false&serverTimezone=America/Sao_Paulo"
                    + "&characterEncoding=UTF-8");
    private static final String USUARIO = configuracao("FILASUS_DB_USER", "filasus");
    private static final String SENHA = configuracao("FILASUS_DB_PASSWORD", "filasus123");

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new ExceptionInInitializerError(
                "Driver MySQL não encontrado. Certifique-se de que o JAR do conector está em WEB-INF/lib.\n" + e);
        }
    }

    private DBConnection() {}

    private static String configuracao(String nome, String padrao) {
        String valor = System.getenv(nome);
        return valor == null || valor.isBlank() ? padrao : valor;
    }

    /**
     * Retorna uma nova conexão com o banco de dados.
     * O chamador é responsável por fechar a conexão.
     */
    public static Connection getConnection() throws SQLException {
        Connection connection = DriverManager.getConnection(URL, USUARIO, SENHA);
        try (java.sql.Statement statement = connection.createStatement()) {
            statement.execute("SET time_zone = '-03:00'");
        } catch (SQLException e) {
            connection.close();
            throw e;
        }
        return connection;
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
