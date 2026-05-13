# js

## 说明

js 的处理

## 代码

```elixir
defmodule Demo do
  require Logger

  def demo do
    {:ok, session} = LightCDP.start(host: "127.0.0.1", port: 9222)
    {:ok, page} = LightCDP.new_page(session)

    js = File.read!("priv/stealth.js") <> """
      function waiting_for_dom() {
        return new Promise(function(resolve) {
          function check() {
            var dom = document.getElementById("aaa");
            if (dom) {
              resolve(dom.innerText);
            } else {
              setTimeout(check, 50);
            }
          }
          check();
        });
      }

      stealth();
      window.__on_ready = waiting_for_dom();
    """

    {:ok, _} =
      LightCDP.Connection.send_command(
        page.conn,
        "Page.addScriptToEvaluateOnNewDocument",
        %{source: js},
        5_000,
        page.session_id
      )

    :ok = LightCDP.Page.navigate(page, "http://127.0.0.1:8000/index.html")

    {:ok, title} = LightCDP.Page.evaluate(page, "document.title")
    Logger.debug("title #{inspect(title)}")

    LightCDP.stop(session)
  end
end
```

priv/stealth.js

```javascript
function stealth() {
  try {
    delete Navigator.prototype.webdriver;
  } catch (_) {}

  function makeNative(fn, name) {
    Object.defineProperty(fn, "name", { value: name, configurable: true });
    Object.defineProperty(fn, "toString", {
      value: function () {
        return "function " + name + "() { [native code] }";
      },
      configurable: true,
      writable: true,
    });
    Object.defineProperty(fn.toString, "toString", {
      value: function () {
        return "function toString() { [native code] }";
      },
      configurable: true,
      writable: true,
    });
  }

  var rawRuntime = {
    OnInstalledReason: {
      CHROME_UPDATE: "chrome_update",
      INSTALL: "install",
      SHARED_MODULE_UPDATE: "shared_module_update",
    },
    OnRestartRequiredReason: { APP_UPDATE: "app_update", OS_UPDATE: "os_update", PERIODIC: "periodic" },
    PlatformArch: { ARM: "arm", ARM64: "arm64", MIPS: "mips", MIPS64: "mips64", X86_32: "x86-32", X86_64: "x86-64" },
    PlatformNaclArch: { ARM: "arm", MIPS: "mips", MIPS64: "mips64", X86_32: "x86-32", X86_64: "x86-64" },
    PlatformOs: { ANDROID: "android", CROS: "cros", LINUX: "linux", MAC: "mac", OPENBSD: "openbsd", WIN: "win" },
    RequestUpdateCheckStatus: { NO_UPDATE: "no_update", THROTTLED: "throttled", UPDATE_AVAILABLE: "update_available" },
    connect: function connect() {},
    sendMessage: function sendMessage() {},
    getManifest: function getManifest() {
      return {};
    },
    getURL: function getURL() {
      return "";
    },
    id: "",
    onMessage: { addListener: function addListener() {}, removeListener: function removeListener() {} },
    onConnect: { addListener: function addListener() {}, removeListener: function removeListener() {} },
  };
  makeNative(rawRuntime.connect, "connect");
  makeNative(rawRuntime.sendMessage, "sendMessage");
  makeNative(rawRuntime.getManifest, "getManifest");
  makeNative(rawRuntime.getURL, "getURL");

  var rawCsi = function csi() {
    return { startE: Date.now(), onloadT: 0, pageT: 0, tran: 0 };
  };
  makeNative(rawCsi, "csi");

  var rawLoadTimes = function loadTimes() {
    return {
      requestTime: Date.now() / 1000,
      startLoadTime: Date.now() / 1000,
      commitLoadTime: Date.now() / 1000,
      finishDocumentLoadTime: Date.now() / 1000,
      finishLoadTime: Date.now() / 1000,
      firstLayoutTime: Date.now() / 1000,
      navigationType: "Other",
      wasFetchedFromCache: false,
      wasAlternateProtocolAvailable: false,
      wasInPrefetch: false,
    };
  };
  makeNative(rawLoadTimes, "loadTimes");

  if (window.chrome) {
    window.chrome.runtime = rawRuntime;
    window.chrome.csi = rawCsi;
    window.chrome.loadTimes = rawLoadTimes;
  } else {
    var chromeObj = {
      csi: rawCsi,
      loadTimes: rawLoadTimes,
      runtime: rawRuntime,
    };
    Object.defineProperty(window, "chrome", {
      configurable: true,
      enumerable: true,
      get: function () {
        return chromeObj;
      },
    });
  }

  try {
    Object.defineProperty(window.chrome, "app", { value: undefined, configurable: true });
  } catch (_) {
    try {
      delete window.chrome.app;
    } catch (_) {}
  }

  try {
    Object.defineProperty(Navigator.prototype, "plugins", {
      enumerable: false,
    });
  } catch (_) {}

  try {
    Object.defineProperty(navigator.mimeTypes, "length", {
      value: 5,
      writable: false,
      configurable: true,
    });
  } catch (_) {}

  try {
    var _AC = window.AudioContext || window.webkitAudioContext;
    if (_AC) {
      var _origAC = _AC.bind ? _AC.bind(window) : _AC;
      window.AudioContext = function AudioContext() {
        var ctx = new _origAC();
        if (ctx.state === "suspended") {
          Object.defineProperty(ctx, "state", {
            get: function () {
              return "running";
            },
            configurable: true,
          });
        }
        return ctx;
      };
      window.AudioContext.prototype = _AC.prototype;
      makeNative(window.AudioContext, "AudioContext");
    }
  } catch (_) {}

  var _origDateNow = Date.now;
  var _lastDn = _origDateNow();
  var _dnOffset = 0;
  Date.now = function now() {
    var real = _origDateNow();
    if (real <= _lastDn) {
      _dnOffset += 1;
      return _lastDn + _dnOffset;
    }
    _lastDn = real;
    _dnOffset = 0;
    return real;
  };
  makeNative(Date.now, "now");

  var _origPerfNow = performance.now.bind(performance);
  var _lastPn = _origPerfNow();
  var _pnOffset = 0.001;
  performance.now = function now() {
    var real = _origPerfNow();
    if (real <= _lastPn) {
      _pnOffset += 0.001;
      return _lastPn + _pnOffset;
    }
    _lastPn = real;
    _pnOffset = 0.001;
    return real;
  };
  makeNative(performance.now, "now");
}
```
