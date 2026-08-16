package br.com.filasus.filter;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URI;

/** Bloqueia POSTs originados fora do proprio sistema. */
@WebFilter("/*")
public class CsrfFilter implements Filter {
    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        if (!"POST".equalsIgnoreCase(request.getMethod()) || mesmaOrigem(request)) {
            chain.doFilter(req, res);
            return;
        }
        response.sendError(HttpServletResponse.SC_FORBIDDEN, "Origem da requisicao nao autorizada.");
    }

    private boolean mesmaOrigem(HttpServletRequest request) {
        String source = request.getHeader("Origin");
        if (source == null || source.isBlank()) source = request.getHeader("Referer");
        if (source == null || source.isBlank()) return false;
        try {
            URI uri = URI.create(source);
            int sourcePort = uri.getPort() < 0 ? ("https".equalsIgnoreCase(uri.getScheme()) ? 443 : 80) : uri.getPort();
            boolean mesmoHost = request.getServerName().equalsIgnoreCase(uri.getHost());
            boolean mesmaPorta = request.getServerPort() == sourcePort;
            boolean monitorLocal = loopback(request.getServerName()) && loopback(uri.getHost());
            return request.getScheme().equalsIgnoreCase(uri.getScheme())
                    && mesmoHost
                    && (mesmaPorta || monitorLocal);
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    private boolean loopback(String host) {
        return host != null && ("localhost".equalsIgnoreCase(host)
                || "127.0.0.1".equals(host) || "::1".equals(host));
    }
}
