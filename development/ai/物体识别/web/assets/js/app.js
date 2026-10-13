let hooks = { StreamCard };

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: hooks,
});

// 。。。。。。。。。。。。。。。。。。。。。。。。


document.addEventListener("click", (e) => {
  if (e.target.closest("#btn-connect-all")) {
    window._players?.forEach((p) => p.connect());
  } else if (e.target.closest("#btn-disconnect-all")) {
    window._players?.forEach((p) => p.disconnect());
  }
})
