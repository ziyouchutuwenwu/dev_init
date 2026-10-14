import { StreamCard } from "./stream_card_hook";

let hooks = { StreamCard }
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: hooks
})

// 这两个为新增代码

import { setStreamConnectedState } from "./player";

document.addEventListener("click", (e) => {
  if (e.target.closest("#btn-connect-all")) {
    window._players?.forEach((p) => {
      setStreamConnectedState(p.streamId, true);
      p.connect();
    });
  } else if (e.target.closest("#btn-disconnect-all")) {
    window._players?.forEach((p) => {
      setStreamConnectedState(p.streamId, false);
      p.disconnect(true);
    });
  }
})

liveSocket.connect()