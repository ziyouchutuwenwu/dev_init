import { Player, getStreamConnectedState } from "./player";

export const StreamCard = {
  mounted() {
    const streamId = this.el.dataset.streamId;
    const streamUrl = this.el.dataset.streamUrl || "";
    let zoneConfig = null;
    if (this.el.dataset.zoneConfig) {
      try {
        zoneConfig = JSON.parse(this.el.dataset.zoneConfig);
      } catch (e) {
        zoneConfig = this.el.dataset.zoneConfig;
      }
    }

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
      if (zoneConfig && !player.hasUnsavedChanges) {
        player.zoneConfig = zoneConfig;
      }
      player.enabled = this.el.dataset.enabled !== "false";
      const shouldConnect = getStreamConnectedState(streamId);
      if (shouldConnect) {
        if (!player.isConnected) {
          player.connect();
        } else {
          player.wakeUp();
        }
      } else {
        if (player.isConnected) {
          player.disconnect(false);
        }
      }
    } else {
      player = new Player({ streamId, url: streamUrl, videoEl, canvasEl, connectBtnEl, statusEl, countEl, rateEl, zoneConfig });
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
    if (this.player && this.el.dataset.zoneConfig && !this.player.hasUnsavedChanges) {
      try {
        const cfg = JSON.parse(this.el.dataset.zoneConfig);
        if (cfg) {
          this.player.zoneConfig = cfg;
        }
      } catch (e) {}
    }
    if (this.player && this.el.dataset.enabled !== undefined) {
      const isEnabled = this.el.dataset.enabled !== "false";
      if (this.player.enabled !== isEnabled) {
        this.player.enabled = isEnabled;
        if (!isEnabled) {
          this.player.clearDetections();
        }
      }
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
