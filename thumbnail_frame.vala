/*********************************************************************

 thumbnail_frame.vala

 Copyright (c) 2017 Chuhai

 This file is part of TexMag - Texture Magnifier.
 This software is released under the MIT License, see LICENSE.txt.

*********************************************************************/


////////////////////////////////////////////////////////////
//	クラス: サムネイルフレーム
////////////////////////////////////////////////////////////
public class ThumbnailFrame : Gtk.Frame {
	private const int FRAME_WIDTH = 128;

	private TexMagWindow		window;
	private Gtk.IconView		iconview;
	private Gtk.Button			btn_remove;
	private ImageDataLists		image_lists;
	private SupportedMimeTypes	mime_types;
	private AppSettings			settings;
	private ImageFileMonitor	file_monitor;

	public ThumbnailFrame(TexMagWindow window,
						  ImageDataLists image_lists,
						  SupportedMimeTypes mime_types,
						  AppSettings settings) {
		this.window      = window;
		this.image_lists = image_lists;
		this.mime_types  = mime_types;
		this.settings    = settings;

		// 子ウィジェットの設定
		var vbox_base = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		this.add(vbox_base);

		var hbox_footer = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		var hbox_footer_inner = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		hbox_footer.set_center_widget(hbox_footer_inner);
		hbox_footer.margin = 5;
		this.iconview = new Gtk.IconView.with_model(this.image_lists.model);
		this.iconview.item_width = FRAME_WIDTH - 32;
		this.iconview.columns = 1;
		this.iconview.pixbuf_column = 0;
		this.iconview.tooltip_column = 1;
		this.iconview.width_request = FRAME_WIDTH;
		this.iconview.selection_mode = Gtk.SelectionMode.BROWSE;
		var scroll = new Gtk.ScrolledWindow (null, null);
		scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
		scroll.add(this.iconview);

		vbox_base.pack_start(scroll, true, true, 0);
		vbox_base.pack_start(hbox_footer, false, false, 0);

		var btn_open    = new Gtk.Button.from_icon_name("document-open-symbolic", Gtk.IconSize.BUTTON);
		this.btn_remove = new Gtk.Button.from_icon_name("list-remove-symbolic", Gtk.IconSize.BUTTON);
		this.btn_remove.sensitive = false;
		hbox_footer_inner.get_style_context().add_class(Gtk.STYLE_CLASS_LINKED);
		hbox_footer_inner.pack_start(btn_open, false, false, 0);
		hbox_footer_inner.pack_start(this.btn_remove, false, false, 0);

		// シグナルハンドラの設定
		btn_open.clicked.connect(on_open_clicked);
		this.btn_remove.clicked.connect(on_remove_clicked);
		this.iconview.selection_changed.connect(on_selection_changed);

		// ファイル監視の設定
		this.file_monitor = new ImageFileMonitor();
		this.file_monitor.changed.connect(on_file_changed);
		this.file_monitor.removed.connect(on_file_removed);
	}

	public void select_item(Gtk.TreeIter? iter, bool force_update = false) {
		if (iter != null) {
			if ((this.image_lists.get_filepath(iter) == this.image_lists.selected_filepath)
			&&  (force_update == false)) {
				return;
			}
			if (this.image_lists.select(iter) == true) {
				Gtk.TreePath path = this.image_lists.model.get_path(iter);
				this.iconview.scroll_to_path(path, false, 0, 0);
				this.iconview.set_cursor(path, null, false);
				this.iconview.select_path(path);

				if (this.settings.auto_reload == true) {
					this.file_monitor.set_filemonitor(this.image_lists.selected_filepath);
				}
				else {
					this.file_monitor.reset_filemonitor();
				}
			}
		}
		else {
			this.file_monitor.reset_filemonitor();
		}

		this.window.update_magnified_area();

		if (this.image_lists.model.iter_n_children(null) == 0) {
			this.btn_remove.sensitive = false;
		}
		else {
			this.btn_remove.sensitive = true;
		}
	}

	public bool get_selected_iter(out Gtk.TreeIter? iter) {
		bool result = false;
		iter = null;
		Gtk.TreePath path = this.iconview.get_selected_items().nth_data(0);
		if (path != null) {
			result = this.image_lists.model.get_iter(out iter, path);
		}
		return result;
	}

	private void on_open_clicked() {
		var dialog = new ImageFileOpenDialog(this.window, this.mime_types);
		dialog.select_multiple = true;
		if (dialog.show() == Gtk.ResponseType.ACCEPT) {
			SList<string> files = dialog.get_filenames();
			Gtk.TreeIter? iter = null;
			foreach (string file in files) {
				if (iter == null) {
					iter = this.image_lists.load_image(file);
				}
				else {
					this.image_lists.load_image(file);
				}
			}
			select_item(iter);
		}
	}

	private void on_remove_clicked() {
		Gtk.TreeIter? iter;
		Gtk.TreeIter? after_iter;
		if (get_selected_iter(out iter) == true) {
			after_iter = iter;
			if (this.image_lists.model.iter_next(ref after_iter) == false) {
				after_iter = iter;
				if (this.image_lists.model.iter_previous(ref after_iter) == false) {
					after_iter = null;
				}
			}

			this.image_lists.remove(iter);
			select_item(after_iter);
		}
	}

	private void on_selection_changed() {
		Gtk.TreeIter? iter;
		if (get_selected_iter(out iter) == true) {
			select_item(iter);
		}
	}

	private void on_file_changed(string filepath) {
		if (this.image_lists.selected_filepath == filepath) {
			Gtk.TreeIter? iter;
			if (get_selected_iter(out iter) == true) {
				this.image_lists.refresh(iter);
				select_item(iter, true);
			}
		}
	}

	private void on_file_removed(string filepath) {
		if (this.image_lists.selected_filepath == filepath) {
			on_remove_clicked();
		}
	}
}


////////////////////////////////////////////////////////////
//	クラス: 画像ファイルオープンダイアログ
////////////////////////////////////////////////////////////
private class ImageFileOpenDialog : GLib.Object {
	private Gtk.FileChooserDialog	dialog;

	public bool select_multiple {
		set { this.dialog.select_multiple = value; }
		get { return this.dialog.select_multiple; }
	}

	public ImageFileOpenDialog(Gtk.Window parent, SupportedMimeTypes mime_types) {
		// ファイル選択ダイアログの設定
		this.dialog = new Gtk.FileChooserDialog("Open Image Files",
											    parent,
											    Gtk.FileChooserAction.OPEN,
											    "_Cancel", Gtk.ResponseType.CANCEL,
											    "_Open", Gtk.ResponseType.ACCEPT);
		this.dialog.local_only = true;

		// フィルタの設定
		var filter = new Gtk.FileFilter();
		filter.set_filter_name("Image Files");
		foreach (string mime_type in mime_types.get_all()) {
			filter.add_mime_type(mime_type);
		}
		this.dialog.set_filter(filter);
	}

	public int show() {
		var result = this.dialog.run();
		this.dialog.close();
		return result;
	}

	public SList<string> get_filenames() {
		return this.dialog.get_filenames();
	}
}
