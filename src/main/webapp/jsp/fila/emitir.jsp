<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="br.com.filasus.model.Fila" %>
<%@ page import="java.util.List" %>
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <title>Emitir senha - FilaSUS</title>
</head>
<body>
    <h1>Emitir senha</h1>

    <% if (request.getAttribute("erro") != null) { %>
        <p style="color:red;"><%= request.getAttribute("erro") %></p>
    <% } %>

    <% if (request.getAttribute("senhaGerada") != null) { %>
        <p style="color:green;">
            Senha gerada! Fila <%= request.getAttribute("idFila") %>,
            sequência <%= ((br.com.filasus.model.ItemFila) request.getAttribute("senhaGerada")).getSequenciaItemFila() %>.
        </p>
    <% } %>

    <form method="get" action="${pageContext.request.contextPath}/fila/emitir">
        <label>Id do mutirão: <input type="number" name="idMutirao" value="${idMutirao}" required></label>
        <button type="submit">Carregar filas</button>
    </form>

    <% List<Fila> filas = (List<Fila>) request.getAttribute("filas"); %>
    <% if (filas != null) { %>
        <form method="post" action="${pageContext.request.contextPath}/fila/emitir">
            <label>Fila:
                <select name="idFila" required>
                    <% for (Fila f : filas) { %>
                        <option value="<%= f.getId() %>"><%= f.getNome() %> (<%= f.getTipo().getDescricao() %>)</option>
                    <% } %>
                </select>
            </label>
            <label>CPF do paciente: <input type="text" name="cpfPaciente" maxlength="11" required></label>
            <button type="submit">Emitir senha</button>
        </form>
    <% } %>
</body>
</html>
