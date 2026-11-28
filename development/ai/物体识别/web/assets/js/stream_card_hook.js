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
    let player = window._players.get(streamId);

    if (player) {
      if (streamUrl && player.url !== streamUrl) {
        player.updateUrl(streamUrl);
      }
      player.bindElements({ videoEl, canvasEl, connectBtnEl, statusEl, countEl, rateEl });
      if (zoneConfig && !player.hasUnsavedChanges) {
        player.zoneConfig = zoneConfig;
      }
      player.enabled = this.el.dataset.enabled !== "false";
      if (player.isConnected) {
        player.wakeUp();
      } else if (getStreamConnectedState(streamId)) {
        player.connect();
      } else {
        player.setStatus("未连接", false);
      }
      if (!player.isDetectionActive) {
        player.clearDetections();
      }
    } else {
      player = new Player({ streamId, url: streamUrl, videoEl, canvasEl, connectBtnEl, statusEl, countEl, rateEl, zoneConfig });
      player.enabled = this.el.dataset.enabled !== "false";
      if (getStreamConnectedState(streamId)) {
        player.connect();
      } else {
        player.setStatus("未连接", false);
      }
      window._players.set(streamId, player);
    }

    player.onConnectionChange = (isConnected) => {
      this.pushEvent("stream_connected_state", { stream_id: streamId, connected: isConnected });
    };

    if (player.isConnected || getStreamConnectedState(streamId)) {
      this.pushEvent("stream_connected_state", { stream_id: streamId, connected: true });
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
    if (this.player) {
      this.player.unbindElements();
    }
  }
};
