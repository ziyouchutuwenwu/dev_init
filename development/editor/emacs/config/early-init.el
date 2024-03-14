;; 关闭启动画面
(setq inhibit-splash-screen t)

;; scrach 默认不显示任何东西
(setq  initial-scratch-message nil)

;; 隐藏菜单栏工具栏滚动条
(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)

;; 窗口位置和大小
(setq initial-frame-alist '(
  (top . 0.4)
  (left . 0.43)
  (width . 110)
  (height . 30)
))
