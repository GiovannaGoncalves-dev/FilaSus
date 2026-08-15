package br.com.filasus.controller;

import br.com.filasus.dao.FilaDAO;
import br.com.filasus.dao.ItemFilaDAO;
import br.com.filasus.dao.MutiraoDAO;
import br.com.filasus.dao.UsuarioDAO;
import br.com.filasus.model.Fila;
import br.com.filasus.model.ItemFila;
import br.com.filasus.model.ItemFilaId;
import br.com.filasus.model.enums.StatusItemFila;
import br.com.filasus.util.AuthUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Emissão de senha: paciente entra numa fila (comum ou prioritária) de um
 * mutirão. A sequência do dia é calculada pela própria ItemFilaDAO.
 */
@WebServlet("/fila/emitir")
public class EmissaoSenhaController extends HttpServlet {

    private final FilaDAO filaDAO = new FilaDAO();
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();
    private final MutiraoDAO mutiraoDAO = new MutiraoDAO();
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/atendente/cadastrar-paciente");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String idFilaParam = request.getParameter("idFila");
        String cpfPaciente = request.getParameter("cpfPaciente");

        if (idFilaParam == null || idFilaParam.isBlank() || cpfPaciente == null || cpfPaciente.isBlank()) {
            request.setAttribute("erro", "Selecione a fila e informe o CPF do paciente.");
            doGet(request, response);
            return;
        }

        try {
            int idFila = Integer.parseInt(idFilaParam);
            Fila fila = filaDAO.buscarPorId(idFila);
            Integer unidade = AuthUtil.getUnidadeAtiva(request);
            if (fila == null || unidade == null || mutiraoDAO.buscarPorId(fila.getIdMutirao()).getIdUnidade() != unidade)
                throw new IllegalArgumentException("Fila não pertence à unidade ativa.");
            String cpf = cpfPaciente.replaceAll("\\D", "");
            br.com.filasus.model.Usuario paciente = usuarioDAO.buscarPorCpf(cpf);
            if (paciente == null || !paciente.isAtivo()
                    || !paciente.temPerfil(br.com.filasus.model.enums.PerfilUsuario.PACIENTE))
                throw new IllegalArgumentException("Paciente inexistente, inativo ou sem perfil de paciente.");
            ItemFila item = new ItemFila();
            item.setId(new ItemFilaId(idFila, 0));
            item.setCpfPaciente(cpf);
            item.setStatus(StatusItemFila.AGUARDANDO);
            itemFilaDAO.inserir(item);
            request.getSession().setAttribute("flash_sucesso", "Senha F" + idFila + "-"
                    + String.format("%03d", item.getSequenciaItemFila()) + " emitida com sucesso.");
        } catch (SQLException | IllegalArgumentException | NullPointerException e) {
            request.getSession().setAttribute("flash_erro", e.getMessage() == null ? "Erro ao emitir senha." : e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/atendente/cadastrar-paciente");
    }
}
