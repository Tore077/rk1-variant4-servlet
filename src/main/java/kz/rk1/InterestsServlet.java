package kz.rk1;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

// РК1, 4-нұсқа: «Қызығушылықтарыңыз» — таңдалған checkbox-тарды « • » белгісімен бөліп шығару.
@WebServlet("/interests")
public class InterestsServlet extends HttpServlet {

    // Рұқсат етілген мәндер (форма ретімен).
    private static final List<String> OPTIONS = Arrays.asList("Музыка", "Спорт", "Кітап", "Кино");

    // GET: бос форманы көрсетеді.
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        render(req, resp, null, new ArrayList<>());
    }

    // POST: таңдалған қызығушылықтарды оқып, нәтижені шығарады.
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        req.setCharacterEncoding("UTF-8");
        // Бірдей name-мен келген бірнеше мәнді getParameterValues() оқиды.
        // Ештеңе белгіленбесе, ол null қайтарады.
        String[] values = req.getParameterValues("interest");

        List<String> selected = new ArrayList<>();
        if (values != null) {
            for (String option : OPTIONS) {
                if (Arrays.asList(values).contains(option)) {
                    selected.add(option);
                }
            }
        }

        String message;
        if (selected.isEmpty()) {
            message = "қызығушылық таңдалмады";
        } else {
            message = "Таңдалды: " + selected.size() + " — " + String.join(" • ", selected);
        }
        render(req, resp, message, selected);
    }

    private void render(HttpServletRequest req, HttpServletResponse resp, String message, List<String> selected)
            throws IOException {
        resp.setContentType("text/html;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        String ctx = req.getContextPath();
        out.println("<!doctype html><html lang='kk'><head><meta charset='UTF-8'>"
                + "<meta name='viewport' content='width=device-width,initial-scale=1'>"
                + "<title>Қызығушылықтарыңыз</title><link rel='stylesheet' href='" + ctx + "/style.css'></head>");
        out.println("<body><main><nav><a href='" + ctx + "/'>Басты бет</a></nav>");
        out.println("<h1>Қызығушылықтарыңыз</h1>");
        out.println("<form action='" + ctx + "/interests' method='post'>");
        for (String option : OPTIONS) {
            out.println("<label class='check'><input type='checkbox' name='interest' value='" + option + "'"
                    + (selected.contains(option) ? " checked" : "") + "> " + option + "</label>");
        }
        out.println("<button>Жіберу</button></form>");
        if (message != null) {
            // Шығарылатын мәтін тек OPTIONS тізімінен құралады — пайдаланушы енгізген мәтін тікелей шықпайды (XSS жоқ).
            out.println("<div class='" + (selected.isEmpty() ? "error" : "result") + "'>" + message + "</div>");
        }
        out.println("</main></body></html>");
    }
}
