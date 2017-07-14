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

		var btn_menu    = new Gtk.MenuButton();
		btn_menu.image = new Gtk.Image.from_icon_name("open-menu-symbolic", Gtk.IconSize.MENU);
		hbox_footer.pack_end(btn_menu, false, false, 5);
		var menu = new ThumbnailMenu(window, this, btn_menu, image_lists);
		var popover = new Gtk.PopoverMenu();
		popover.add(menu);
		menu.show_all();
		btn_menu.set_popover(popover);

		// シグナルハンドラの設定
		btn_open.clicked.connect(on_open_clicked);
		this.btn_remove.clicked.connect(on_remove_clicked);
		this.iconview.selection_changed.connect(on_selection_changed);
	}

	public void iconview_select_path(Gtk.TreePath path) {
		this.iconview.scroll_to_path(path, false, 0, 0);
		this.iconview.set_cursor(path, null, false);
		this.iconview.select_path(path);
	}

	public void iconview_clear() {
		this.image_lists.clear();

		// スクロールバーをリセットするためにmodelを再設定する
		this.iconview.model = null;
		this.iconview.model = this.image_lists.model;
	}

	public void iconview_refresh() {
		Gtk.TreeIter? iter;
		this.image_lists.refresh_all();
		if (get_selected_iter(out iter) == true) {
			this.window.select_listitem(iter, true);
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

	public void update_button_sensitive() {
		if (this.image_lists.model.iter_n_children(null) == 0) {
			this.btn_remove.sensitive = false;
		}
		else {
			this.btn_remove.sensitive = true;
		}
	}

	public bool iconview_key_press_event(Gdk.EventKey event) {
		Gtk.Widget? focused = this.window.get_focus();

		this.iconview.has_focus = true;
		var result = this.iconview.key_press_event(event);
		if (focused != null) {
			focused.has_focus = true;
		}

		return result;
	}

	private void on_open_clicked() {
		var dialog = new ImageFileOpenDialog(this.window, this.mime_types);
		dialog.select_multiple = true;
		if (dialog.show() == Gtk.ResponseType.ACCEPT) {
			int	success = 0;
			int	failure = 0;
			Gtk.TreeIter? first_iter = null;
			foreach (string filepath in dialog.filenames) {
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
			if (success > 0) {
				Utils.show_message("%d file(s) loaded.".printf(success));
			}
			if (failure > 0) {
				Utils.show_message("Failed to load %d file(s).".printf(failure), MessageType.WARNING);
			}

			this.window.select_listitem(first_iter);
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

			this.image_lists.remove(ref iter);
			this.window.select_listitem(after_iter);
		}
	}

	private void on_selection_changed() {
		Gtk.TreeIter? iter;
		if (get_selected_iter(out iter) == true) {
			this.window.select_listitem(iter);
		}
	}
}
