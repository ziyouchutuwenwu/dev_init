import { Player } from "./player";

export const StreamCard = {
  mounted() {
    const streamId = this.el.dataset.streamId;
    const streamUrl = this.el.dataset.streamUrl || "";

    const videoEl = this.el.querySelector(`#video-${streamId}`);
    const canvasEl = this.el.querySelector(`#overlay-${streamId}`);
    const connectBtnEl = this.el.querySelector(`#btn-connect-${streamId}`);
    const statusEl = this.el.querySelector(`#status-${streamId}`);
    const countEl = this.el.querySelector(`#count-${streamId}`);
    const rateEl = this.el.querySelector(`#rate-${streamId}`);

    window._players = window._players || new Map();
    const activeStreamIds = new Set(
      Array.from(document.querySelectorAll("[data-stream-id]")).map((el) => el.dataset.streamId)
    );
    window._players.forEach((p, id) => {
      if (!activeStreamIds.has(id)) {
        p.destroy();
        window._players.delete(id);
      }
    });

    let player = window._players.get(streamId);

    if (player) {
      player.bindElements({ videoEl, canvasEl, connectBtnEl, statusEl, countEl, rateEl });
    } else {
      player = new Player({ streamId, url: streamUrl, videoEl, canvasEl, connectBtnEl, statusEl, countEl, rateEl });
      window._players.set(streamId, player);
    }
    this.player = player;

    this.handleEvent(`zone_updated:${streamId}`, (payload) => {
      if (this.player) {
        this.player.zoneConfig = payload.zone_config;
      }
    });
  },

  updated() {
    const newUrl = this.el.dataset.streamUrl;
    if (this.player && newUrl && this.player.url !== newUrl) {
      this.player.updateUrl(newUrl);
    }
  },

  destroyed() {
    const streamId = this.el.dataset.streamId;
    if (this.player) {
      this.player.unbindElements();
      if (!this.el.dataset.keepAlive) {
        this.player.destroy();
        window._players.delete(streamId);
      }
    }
  }
};
