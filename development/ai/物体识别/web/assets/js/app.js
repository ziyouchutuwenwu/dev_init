import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

import { StreamCard } from "./stream_card_hook";

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let hooks = { StreamCard }

const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: hooks
})

topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

document.addEventListener("click", (e) => {
  if (e.target.closest("#btn-connect-all")) {
    window._players?.forEach((p) => {
      p.connect();
    });
  } else if (e.target.closest("#btn-disconnect-all")) {
    window._players?.forEach((p) => {
      p.disconnect(true);
    });
  }
})

liveSocket.connect()