package br.com.filasus.controller;

import br.com.filasus.dao.DocumentoDAO;
import br.com.filasus.model.Documento;
import br.com.filasus.model.enums.StatusValidacaoDocumento;
import br.com.filasus.model.enums.TipoDocumento;
import br.com.filasus.util.UploadUtil;
import br.com.filasus.model.Usuario;
import br.com.filasus.util.AuthUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Pedido de prioridade: paciente envia um documento (comprovante, exame,
 * relatório) que fica pendente de validação (feature-validar-prioridade).
 */
@WebServlet("/documento/solicitar")
@MultipartConfig(maxFileSize = 10 * 1024 * 1024) // 10 MB
public class SolicitarPrioridadeController extends HttpServlet {

    private final DocumentoDAO documentoDAO = new DocumentoDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.getRequestDispatcher("/jsp/paciente/solicitar-prioridade.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Usuario usuario = AuthUtil.getUsuarioLogado(request);
        String cpfUsuario = usuario == null ? null : usuario.getCpf();
        String tipoParam = request.getParameter("tipo");
        Part arquivo = request.getPart("arquivo");

        if (cpfUsuario == null || cpfUsuario.isBlank() || tipoParam == null
                || arquivo == null || arquivo.getSize() == 0) {
            request.setAttribute("erro", "Informe o CPF, o tipo de documento e selecione um arquivo.");
            doGet(request, response);
            return;
        }

        try {
            String caminhoArquivo = UploadUtil.salvar(arquivo);

            Documento documento = new Documento();
            documento.setCpfUsuario(cpfUsuario.trim());
            documento.setTipo(TipoDocumento.fromJson(tipoParam));
            documento.setArquivoUrl(caminhoArquivo);
            documento.setStatusValidacao(StatusValidacaoDocumento.PENDENTE);
            documentoDAO.inserir(documento);

            request.setAttribute("sucesso", "Documento enviado! Aguarde a validação.");
        } catch (IllegalArgumentException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            request.setAttribute("erro", "Tipo de documento inválido. Use relatório, exame ou outro.");
        } catch (IOException | SQLException e) {
            request.setAttribute("erro", "Erro ao enviar documento: " + e.getMessage());
        }
        doGet(request, response);
    }
}
