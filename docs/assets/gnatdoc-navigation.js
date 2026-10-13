/* Qualified native GNATdoc 26 shell. No generated filename is constructed. */
(() => {
  "use strict";
  const controls = document.getElementById("package-navigation");
  const heading = document.getElementById("compilation-units");
  const frame = document.querySelector('iframe[name="document-content"]');
  if (!controls || !heading || !frame || controls.dataset.ready) return;
  const list = heading.nextElementSibling;
  if (!list || list.tagName !== "UL") return;
  const links = Array.from(list.querySelectorAll("a"));
  const byName = new Map(), byPath = new Map();
  for (const link of links) {
    const name = link.textContent;
    const url = new URL(link.getAttribute("href"), location.href);
    if (link.target !== frame.name || url.origin !== location.origin ||
        url.search || url.hash || !/^[a-f0-9]{64}\.html$/.test(link.getAttribute("href")) ||
        byName.has(name.toLowerCase()) || byPath.has(url.pathname)) return;
    const item = {name, url, link};
    byName.set(name.toLowerCase(), item);
    byPath.set(url.pathname, item);
  }
  const fallback = byName.get("opencv.core");
  if (links.length !== 195 || !fallback) return;
  controls.dataset.ready = "true";
  const search = document.getElementById("package-search");
  const status = document.getElementById("package-results");
  let active = null;
  function mark(item) {
    for (const link of links) link.removeAttribute("aria-current");
    item.link.setAttribute("aria-current", "page");
    active = item;
  }
  function outer(item, method) {
    const url = new URL(location.href);
    if (url.searchParams.getAll("package").length === 1 &&
        url.searchParams.get("package") === item.name) return;
    url.searchParams.set("package", item.name);
    history[method]({package: item.name}, "", url);
  }
  function requested() {
    const values = new URL(location.href).searchParams.getAll("package");
    return values.length === 1 ? byName.get(values[0].toLowerCase()) || fallback : fallback;
  }
  function restore() {
    const item = requested();
    mark(item);
    outer(item, "replaceState");
    // Replace the frame's history entry: outer package history is authoritative.
    // Native declaration fragments are untouched when already on this package.
    if (frame.contentWindow.location.pathname !== item.url.pathname)
      frame.contentWindow.location.replace(item.url.href);
  }
  frame.addEventListener("load", () => {
    try {
      const url = new URL(frame.contentWindow.location.href);
      const item = url.origin === location.origin && byPath.get(url.pathname);
      if (!item) return;
      if (item !== active) { mark(item); outer(item, "pushState"); }
    } catch (_) { /* Unsupported foreign navigation is never selected. */ }
  });
  document.querySelector(".side-navigation").addEventListener("click", event => {
    const link = event.target.closest("a");
    if (!link || link.target !== frame.name || event.button !== 0 ||
        event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    const url = new URL(link.href);
    const item = url.origin === location.origin && byPath.get(url.pathname);
    if (!item) return;
    event.preventDefault();
    mark(item);
    outer(item, "pushState");
    frame.contentWindow.location.replace(url.href);
  });
  function filter() {
    const query = search.value.toLowerCase();
    let count = 0;
    for (const link of links) {
      const matches = link.textContent.toLowerCase().includes(query);
      link.parentElement.hidden = !matches;
      if (matches) count++;
    }
    status.textContent = count ? `${count} packages` : "No matching packages.";
  }
  search.addEventListener("input", filter);
  document.getElementById("package-clear").addEventListener("click", () => {
    search.value = "";
    filter();
    search.focus();
  });
  window.addEventListener("popstate", restore);
  filter();
  restore();
  controls.hidden = false;
})();