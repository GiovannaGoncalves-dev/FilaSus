<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="br.com.filasus.util.AuthUtil" %>
<%@ page import="br.com.filasus.util.NavigationUtil" %>
<%
  if (!AuthUtil.isLogado(request)) {
    response.sendRedirect(request.getContextPath() + "/login");
  } else {
    response.sendRedirect(request.getContextPath()
        + NavigationUtil.paginaInicial(AuthUtil.getPerfilAtivo(request)));
  }
%>
