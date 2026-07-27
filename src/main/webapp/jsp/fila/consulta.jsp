<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="br.com.filasus.model.ItemFila" %>
<%@ page import="java.util.List" %>
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <title>Consultar fila - FilaSUS</title>
</head>
<body>
    <h1>Consultar posição na fila</h1>

    <% if (request.getAttribute("erro") != null) { %>
        <p style="color:red;"><%= request.getAttribute("erro") %></p>
    <% } %>

    <form method="get" action="${pageContext.request.contextPath}/fila/consulta">
        <label>CPF: <input type="text" name="cpfPaciente" maxlength="11" value="${cpfPaciente}" required></label>
        <button type="submit">Consultar</button>
    </form>

    <% List<ItemFila> itens = (List<ItemFila>) request.getAttribute("itens"); %>
    <% List<Integer> posicoes = (List<Integer>) request.getAttribute("posicoes"); %>
    <% if (itens != null) { %>
        <table border="1" cellpadding="6">
            <tr><th>Fila</th><th>Sequência</th><th>Status</th><th>Posição</th></tr>
            <% for (int i = 0; i < itens.size(); i++) {
                   ItemFila item = itens.get(i);
                   int posicao = posicoes.get(i); %>
            <tr>
                <td><%= item.getIdFila() %></td>
                <td><%= item.getSequenciaItemFila() %></td>
                <td><%= item.getStatus().getDescricao() %></td>
                <td><%= posicao > 0 ? String.valueOf(posicao) : "-" %></td>
            </tr>
            <% } %>
        </table>
        <% if (itens.isEmpty()) { %>
            <p>Nenhum registro de fila encontrado para este CPF.</p>
        <% } %>
    <% } %>
</body>
</html>
