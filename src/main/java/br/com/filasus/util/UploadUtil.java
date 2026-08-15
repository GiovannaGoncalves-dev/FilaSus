package br.com.filasus.util;

import javax.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

/** Armazena documentos enviados em diretório persistente configurável. */
public final class UploadUtil {
    private static final String DIRETORIO_UPLOAD = diretorioUpload();

    private UploadUtil() {}

    private static String diretorioUpload() {
        String configurado = System.getenv("FILASUS_UPLOAD_DIR");
        return configurado == null || configurado.isBlank()
                ? System.getProperty("user.home") + "/.filasus/uploads" : configurado;
    }

    public static String salvar(Part arquivo) throws IOException {
        Files.createDirectories(Paths.get(DIRETORIO_UPLOAD));
        String original = nomeOriginal(arquivo);
        String extensao = original != null && original.contains(".")
                ? original.substring(original.lastIndexOf('.')) : "";
        Path destino = Paths.get(DIRETORIO_UPLOAD, UUID.randomUUID() + extensao);
        try (InputStream input = arquivo.getInputStream()) {
            Files.copy(input, destino, StandardCopyOption.REPLACE_EXISTING);
        }
        return destino.toString();
    }

    private static String nomeOriginal(Part arquivo) {
        String disposition = arquivo.getHeader("content-disposition");
        if (disposition == null) return null;
        for (String trecho : disposition.split(";")) {
            String valor = trecho.trim();
            if (valor.startsWith("filename=")) {
                String nome = valor.substring("filename=".length()).replace("\"", "");
                return Paths.get(nome).getFileName().toString();
            }
        }
        return null;
    }
}
