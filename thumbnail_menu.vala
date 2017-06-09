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
	}
}
