// loaded on every page through frontend.extra_module_url (see
// ../packages/dashboards.nix). Browsers keep files under /local for a month,
// so this file never changes; it imports the cards with the version of the
// current deploy appended, which it never takes from the cache. A new loader
// needs a new file name
const base = new URL(".", import.meta.url);
const version = await fetch(new URL("version", base), { cache: "no-store" })
  .then((response) => (response.ok ? response.text() : ""))
  .catch(() => "");

await import(new URL(`home-card.js?v=${version.trim()}`, base));
