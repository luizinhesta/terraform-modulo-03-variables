// Lê config.json (gerado pelo Terraform a partir das variáveis) e monta a página.
// Usa textContent (nunca innerHTML) para evitar injeção de HTML pelos valores.
(function () {
  "use strict";

  function el(tag, className, text) {
    var e = document.createElement(tag);
    if (className) e.className = className;
    if (text !== undefined) e.textContent = text;
    return e;
  }

  // Aceita apenas links https:// ou mailto:
  function linkSeguro(url) {
    return /^(https:\/\/|mailto:)/i.test(url) ? url : "#";
  }

  function render(cfg) {
    document.title = cfg.profile.name + " | Portfólio";
    document.getElementById("env-badge").textContent = cfg.environment;
    document.getElementById("nome").textContent = cfg.profile.name;
    document.getElementById("headline").textContent = cfg.profile.headline;
    document.getElementById("bio").textContent = cfg.profile.bio;

    var projetos = document.getElementById("projetos");
    cfg.projects.forEach(function (p) {
      var card = el("article", "card");
      card.appendChild(el("h3", null, p.title));
      card.appendChild(el("p", null, p.description));
      p.services.forEach(function (s) { card.appendChild(el("span", "tag", s)); });
      projetos.appendChild(card);
    });

    var tech = document.getElementById("tecnologias");
    cfg.technologies.forEach(function (t) { tech.appendChild(el("li", null, t)); });

    var contatos = document.getElementById("contatos");
    Object.keys(cfg.contact_links).forEach(function (nome) {
      var li = el("li");
      var a = el("a", null, nome);
      a.href = linkSeguro(cfg.contact_links[nome]);
      a.rel = "noopener noreferrer";
      li.appendChild(a);
      contatos.appendChild(li);
    });
  }

  fetch("config.json", { cache: "no-cache" })
    .then(function (r) {
      if (!r.ok) throw new Error("HTTP " + r.status);
      return r.json();
    })
    .then(render)
    .catch(function (err) {
      var erro = document.getElementById("erro");
      erro.textContent = "Não foi possível carregar config.json (" + err.message + ").";
      erro.hidden = false;
    });
})();
