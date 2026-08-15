package br.com.filasus.util;

import javax.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

/**
 * Salva arquivos enviados via formulário multipart (usado por
 * feature-solicitar-prioridade para gravar o Documento.arquivoUrl).
 *
 * ponytail: grava em disco local (diretório temporário do sistema); trocar
 * por um storage externo (S3, disco compartilhado etc.) se a aplicação
 * passar a rodar em mais de uma instância.
 */
public class UploadUtil {

    private static final String DIRETORIO_UPLOAD = System.getProperty("java.io.tmpdir") + "/filasus-uploads";

    private UploadUtil() {}

    /** Salva o arquivo enviado e devolve o caminho onde ficou gravado. */
    public static String salvar(Part arquivo) throws IOException {
        Files.createDirectories(Paths.get(DIRETORIO_UPLOAD));

        String nomeOriginal = arquivo.getSubmittedFileName();
        String extensao = (nomeOriginal != null && nomeOriginal.contains("."))
                ? nomeOriginal.substring(nomeOriginal.lastIndexOf('.'))
                : "";
        String nomeArquivo = UUID.randomUUID() + extensao;
        Path destino = Paths.get(DIRETORIO_UPLOAD, nomeArquivo);

        try (InputStream in = arquivo.getInputStream()) {
            Files.copy(in, destino, StandardCopyOption.REPLACE_EXISTING);
        }
        return destino.toString();
    }
}
