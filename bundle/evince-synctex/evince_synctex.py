#!/usr/bin/env python3

# Copyright (C) 2010 Jose Aliste <jose.aliste@gmail.com>
#               2011 Benjamin Kellermann <Benjamin.Kellermann@tu-dresden.de>
#               2018 Mathias Rav <m@git.strova.dk>
#               2019 Eric Förster <efoerster@users.noreply.github.com>
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public Licence as published by the Free Software
# Foundation; either version 2 of the Licence, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public Licence for more
# details.
#
# You should have received a copy of the GNU General Public Licence along with
# this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
# Street, Fifth Floor, Boston, MA  02110-1301, USA

"""Evince SyncTeX bridge for this Neovim configuration.

来源：
    上游仓库：https://github.com/latex-lsp/evince-synctex
    原始文件：evince_synctex.py
    基于提交：593b00c938d82786b8bbaf584ebe68744f9c8407
    原始版本：https://github.com/latex-lsp/evince-synctex/blob/593b00c938d82786b8bbaf584ebe68744f9c8407/evince_synctex.py
    texlab 配置文档：https://github.com/latex-lsp/texlab/wiki/Previewing#evince
    保留上游版权声明；许可证全文见同目录 LICENSE。

本地修改（2026-10-10）：
    1. 保留上游 Evince D-Bus 接口定义和 startEvinceDaemon，重写命令行入口、
       窗口连接和监听生命周期，不再使用上游 EvinceWindowProxy。
    2. 新增必需参数 -s/--source，正向搜索使用正在编辑的源文件，而不是根据
       PDF 名称推导同名 .tex，以支持主文档包含的子文件。
    3. 用必需参数 --texlab 指定 texlab 可执行文件，替代通用 EDITOR_COMMAND。
       反向搜索直接通过 subprocess.Popen 参数列表调用 texlab inverse-search，
       不使用 shell 或命令字符串占位符替换。
    4. 反向搜索使用 --line1 接收 Evince 从 1 开始的行号，避免本机 texlab 的
       -l（从 0 开始）导致行号偏移；由 texlab 通知 Neovim 跳转。
    5. 按 PDF URI 的 SHA-256 注册独占 D-Bus 名称，每份 PDF 只保留一个反向
       搜索监听进程。重复正向搜索只移动阅读器；已打开的 PDF 也能建立监听。
    6. 通过 GetWindowList 获取实际窗口，每 100 ms 重试，最多 50 次，等待
       Evince 创建窗口。监听其 D-Bus owner 消失事件后退出，不终止阅读器。
       窗口连接或同步失败时向 stderr 报错并以状态码 1 退出。
    7. 使用 Path.as_uri 和 URL 解码处理路径，支持中文、空格等特殊字符。

当前命令行（与上游不兼容）：
    python3 evince_synctex.py -f LINE -s SOURCE --texlab TEXLAB PDF
    LINE 从 1 开始；省略 -f 时只打开 PDF 并监听反向搜索。
"""

import argparse
import hashlib
from pathlib import Path
import subprocess
import sys
from urllib.parse import unquote, urlparse

import dbus
import dbus.mainloop.glib
import dbus.service
from gi.repository import GLib


EV_DAEMON_PATH = "/org/gnome/evince/Daemon"
EV_DAEMON_NAME = "org.gnome.evince.Daemon"
EV_DAEMON_IFACE = "org.gnome.evince.Daemon"

EVINCE_PATH = "/org/gnome/evince/Evince"
EVINCE_IFACE = "org.gnome.evince.Application"

EV_WINDOW_IFACE = "org.gnome.evince.Window"


def startEvinceDaemon():
    bus = dbus.SessionBus()
    daemon = bus.get_object(
        EV_DAEMON_NAME, EV_DAEMON_PATH, follow_name_owner_changes=True
    )
    return (bus, daemon)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-f", "--forward", type=int)
    parser.add_argument("-s", "--source", required=True)
    parser.add_argument("--texlab", required=True)
    parser.add_argument("pdf")
    args = parser.parse_args()
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus, daemon = startEvinceDaemon()
    uri = Path(args.pdf).resolve().as_uri()
    # One listener per PDF; subsequent searches only move the viewer.
    name = "org.texlab.EvinceSync.p" + hashlib.sha256(uri.encode()).hexdigest()
    try:
        listener = dbus.service.BusName(name, bus, do_not_queue=True)
    except dbus.exceptions.NameExistsException:
        listener = None

    owner = daemon.FindDocument(uri, True, dbus_interface=EV_DAEMON_IFACE)
    app = bus.get_object(owner, EVINCE_PATH)
    loop = GLib.MainLoop()
    attempts = 0
    failure = None

    def inverse_search(input_file, source_link, _timestamp):
        path = unquote(urlparse(str(input_file)).path)
        # Evince reports one-based lines; recent texlab's -l is zero-based.
        subprocess.Popen([
            args.texlab, "inverse-search", "--input", path,
            "--line1", str(source_link[0]),
        ])

    def owner_changed(changed_name, _old_owner, new_owner):
        if changed_name == owner and not new_owner:
            loop.quit()

    def connect_window():
        nonlocal attempts
        attempts += 1
        try:
            windows = app.GetWindowList(dbus_interface=EVINCE_IFACE)
            if windows:
                window = dbus.Interface(bus.get_object(owner, windows[0]), EV_WINDOW_IFACE)
                if listener is not None:
                    window.connect_to_signal("SyncSource", inverse_search)
                if args.forward is not None:
                    window.SyncView(str(Path(args.source).resolve()), (args.forward, 1), 0)
                if listener is None:
                    loop.quit()
                return False
        except dbus.DBusException:
            if attempts >= 50:
                raise
        if attempts >= 50:
            raise RuntimeError("Evince did not create a document window")
        return True

    bus.add_signal_receiver(owner_changed, signal_name="NameOwnerChanged",
                            dbus_interface="org.freedesktop.DBus", arg0=str(owner))
    # Evince may still be creating its first window after FindDocument.
    def poll_window():
        nonlocal failure
        try:
            return connect_window()
        except Exception as error:
            failure = error
            print(error, file=sys.stderr)
            loop.quit()
            return False

    GLib.timeout_add(100, poll_window)
    try:
        loop.run()
    except KeyboardInterrupt:
        pass
    if failure is not None:
        sys.exit(1)


if __name__ == "__main__":
    main()
