/*********************************************************************

 thumbnail_menu.vala

 Copyright (c) 2017 Chuhai

 This file is part of TexMag - Texture Magnifier.
 This software is released under the MIT License, see LICENSE.txt.

*********************************************************************/


////////////////////////////////////////////////////////////
//	クラス: サムネイルフレーム・メニュー
////////////////////////////////////////////////////////////
public class ThumbnailMenu : Gtk.Frame {
	private TexMagWindow	window;
	private ThumbnailFrame	frame_thumb;
	private ImageDataLists	image_lists;
	private Gtk.ModelButton	btn_clear;

	public ThumbnailMenu(TexMagWindow window,
						 ThumbnailFrame frame_thumb,
						 Gtk.MenuButton parent,
						 ImageDataLists image_lists) {
		this.window      = window;
		this.frame_thumb = frame_thumb;
		this.image_lists = image_lists;

		// コンテナの設定
		var vbox_menu = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		vbox_menu.margin_top    = 10;
		vbox_menu.margin_bottom = 10;
		vbox_menu.margin_start  = 20;
		vbox_menu.margin_end    = 20;
		this.shadow_type = Gtk.ShadowType.NONE;
		this.add(vbox_menu);

		// 各種メニュー項目の生成
		this.btn_clear = new Gtk.ModelButton();
		btn_clear.text = "Clear";

		vbox_menu.pack_start(this.btn_clear, false, false, 3);

		// シグナルハンドラの設定
		parent.toggled.connect(update_menu_sensitive);
		this.btn_clear.clicked.connect(on_clear_clicked);
	}

	private void update_menu_sensitive() {
		var sensitive = true;
		if (this.image_lists.model.iter_n_children(null) == 0) {
			sensitive = false;
		}
		this.btn_clear.sensitive = sensitive;
	}

	private void on_clear_clicked() {
		this.frame_thumb.iconview_clear();
		this.window.select_listitem(null);
	}
}
