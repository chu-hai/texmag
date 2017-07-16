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
	private TexMagWindow		window;
	private ThumbnailFrame		frame_thumb;
	private ImageDataLists		image_lists;
	private SupportedMimeTypes	mime_types;
	private Gtk.ModelButton		btn_refresh;
	private Gtk.ModelButton		btn_clear;
	private Gtk.ModelButton		btn_open_folder;

	public ThumbnailMenu(TexMagWindow window,
						 ThumbnailFrame frame_thumb,
						 Gtk.MenuButton parent,
						 ImageDataLists image_lists,
						 SupportedMimeTypes mime_types) {
		this.window      = window;
		this.frame_thumb = frame_thumb;
		this.image_lists = image_lists;
		this.mime_types  = mime_types;

		// コンテナの設定
		var vbox_menu = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		vbox_menu.margin_top    = 10;
		vbox_menu.margin_bottom = 10;
		vbox_menu.margin_start  = 20;
		vbox_menu.margin_end    = 20;
		this.shadow_type = Gtk.ShadowType.NONE;
		this.add(vbox_menu);

		// 各種メニュー項目の生成
		this.btn_refresh = new Gtk.ModelButton();
		btn_refresh.text = "Refresh";
		this.btn_clear = new Gtk.ModelButton();
		btn_clear.text = "Clear";
		var separator_1 = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
		this.btn_open_folder = new Gtk.ModelButton();
		btn_open_folder.text = "Open folder...";

		vbox_menu.pack_start(this.btn_refresh,		false, false, 3);
		vbox_menu.pack_start(this.btn_clear,		false, false, 3);
		vbox_menu.pack_start(separator_1,			false, false, 3);
		vbox_menu.pack_start(this.btn_open_folder,	false, false, 3);

		// シグナルハンドラの設定
		parent.toggled.connect(update_menu_sensitive);
		this.btn_refresh.clicked.connect(on_refresh_clicked);
		this.btn_clear.clicked.connect(on_clear_clicked);
		this.btn_open_folder.clicked.connect(on_open_folder_clicked);
	}

	private void update_menu_sensitive() {
		var sensitive = true;
		if (this.image_lists.model.iter_n_children(null) == 0) {
			sensitive = false;
		}
		this.btn_refresh.sensitive	= sensitive;
		this.btn_clear.sensitive	= sensitive;
	}

	private void on_refresh_clicked() {
		this.frame_thumb.iconview_refresh();
	}

	private void on_clear_clicked() {
		this.frame_thumb.iconview_clear();
		this.window.select_listitem(null);
	}

	private void on_open_folder_clicked() {
		var dialog = new FolderOpenDialog(this.window);
		dialog.select_multiple = false;
		if (dialog.show() == Gtk.ResponseType.ACCEPT) {
			int	success = 0;
			int	failure = 0;
			Gtk.TreeIter? first_iter = null;
			string dirname = dialog.foldername;

			try {
				var dir = Dir.open(dirname, 0);
				string? filename = null;
				while ((filename = dir.read_name()) != null){
					string filepath = GLib.Path.build_filename(dirname, filename);

					if (GLib.FileUtils.test(filepath, GLib.FileTest.IS_REGULAR) == false) {
						continue;
					}

					Gtk.TreeIter? temp_iter = null;
					if (mime_types.is_supported(Utils.get_mime_type(filepath)) == false) {
						failure++;
						continue;
					}

					temp_iter = this.image_lists.load_image(filepath);
					if (temp_iter != null) {
						if (first_iter == null) {
							first_iter = temp_iter;
						}
						success++;
					}
					else {
						failure++;
					}
				}
			} catch (GLib.FileError e) {
				Utils.show_message("%s".printf(e.message), MessageType.ERROR);
				return;
			}

			if (success > 0) {
				Utils.show_message("%d file(s) loaded.".printf(success));
			}
			if (failure > 0) {
				Utils.show_message("Failed to load %d file(s).".printf(failure), MessageType.WARNING);
			}

			this.window.select_listitem(first_iter, true);
		}
	}
}
