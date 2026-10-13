defmodule WebWeb.PlayerComponent do
  use Phoenix.Component

  attr :id, :string, required: true
  attr :title, :string, default: nil
  attr :default_url, :string, default: ""
  attr :removable, :boolean, default: true
  attr :zone_config, :string, default: nil

  def stream_card(assigns) do
    ~H"""
    <div
      id={"stream-card-" <> @id}
      phx-hook="StreamCard"
      class="stream-card flex flex-col rounded-xl border border-zinc-200 bg-white p-3 shadow-sm hover:shadow transition-shadow"
      data-stream-id={@id}
      data-stream-url={@default_url}
      data-zone-config={@zone_config}
      data-keep-alive="true"
    >
      <div class="flex flex-wrap items-center justify-between gap-2 pb-2 mb-2 border-b border-zinc-100">
        <div class="flex items-center gap-1.5 shrink-0">
          <label class="text-xs font-semibold text-zinc-600 whitespace-nowrap">流标识:</label>
          <input
            type="text"
            id={"url-input-" <> @id}
            value={@id}
            class="w-24 sm:w-28 rounded border border-zinc-300 px-2 py-1 text-xs font-mono font-semibold text-zinc-800 bg-zinc-50 shadow-inner focus:border-blue-500 focus:outline-none"
          />
          <button
            type="button"
            id={"btn-connect-" <> @id}
            class="rounded bg-blue-600 px-2.5 py-1 text-xs font-semibold text-white hover:bg-blue-700 transition-colors cursor-pointer shadow-sm whitespace-nowrap"
          >
            连接
          </button>
        </div>

        <div class="flex flex-1 items-center justify-between gap-2.5 text-xs w-full sm:w-auto min-w-[270px]">
          <span
            id={"status-" <> @id}
            class="rounded-full bg-zinc-200 px-2 py-0.5 font-medium text-zinc-700 transition-colors whitespace-nowrap"
          >
            未连接
          </span>
          <span class="text-zinc-500 whitespace-nowrap">
            实时目标: <b id={"count-" <> @id} class="font-mono text-green-600">0</b>
          </span>
          <button
            type="button"
            id={"btn-fs-" <> @id}
            class="rounded border border-zinc-200 px-1.5 py-0.5 text-zinc-600 hover:bg-zinc-100 cursor-pointer whitespace-nowrap"
            title="全屏"
          >
            全屏
          </button>
        </div>
      </div>

      <div class="flex flex-wrap items-center justify-between gap-1.5 py-1.5 px-2 mb-2 bg-zinc-50 rounded-lg border border-zinc-200 text-xs">
        <div class="flex items-center gap-1.5 flex-wrap">
          <button
            type="button"
            id={"btn-draw-roi-" <> @id}
            class="rounded bg-amber-500 text-white px-2.5 py-1 font-semibold hover:bg-amber-600 transition-colors cursor-pointer shadow-xs flex items-center gap-1"
            title="在画面上按住鼠标拖拽调整触发区域"
          >
            标定触发区域
          </button>
          <button
            type="button"
            id={"btn-reset-zone-" <> @id}
            class="rounded border border-zinc-300 bg-white text-zinc-600 px-2 py-1 hover:bg-zinc-100 cursor-pointer"
            title="恢复默认全画幅触发区域"
          >
            重置区域
          </button>
        </div>

        <div class="flex items-center gap-1.5">
          <button
            type="button"
            id={"btn-save-zone-" <> @id}
            class="rounded bg-emerald-600 text-white px-2.5 py-1 font-semibold hover:bg-emerald-700 transition-colors cursor-pointer shadow-xs whitespace-nowrap"
            title="保存标定并立即热更新生效"
          >
            保存
          </button>
        </div>
      </div>

      <div
        id={"video-wrap-" <> @id}
        class="relative w-full aspect-video overflow-hidden rounded-lg bg-black flex items-center justify-center select-none"
      >
        <video
          id={"video-" <> @id}
          autoplay
          playsinline
          muted
          class="w-full h-full object-contain block"
        >
        </video>
        <canvas
          id={"overlay-" <> @id}
          class="absolute inset-0 w-full h-full"
          style="z-index: 30; pointer-events: none;"
        >
        </canvas>
      </div>

      <details class="mt-2 text-xs text-zinc-600">
        <summary class="cursor-pointer font-medium text-zinc-500 hover:text-zinc-700 select-none">
          实时检测与目标状态
        </summary>
        <div class="mt-1.5 max-h-32 overflow-y-auto pr-1">
          <ul id={"det-list-" <> @id} class="space-y-1">
            <li class="text-zinc-400">暂无目标</li>
          </ul>
        </div>
      </details>
    </div>
    """
  end
end
