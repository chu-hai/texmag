/*********************************************************************

 main.vala

 Copyright (c) 2017 Chuhai

 This file is part of TexMag - Texture Magnifier.
 This software is released under the MIT License, see LICENSE.txt.

*********************************************************************/


////////////////////////////////////////////////////////////
//	クラス: メインウィンドウ
////////////////////////////////////////////////////////////
public class TexMagWindow : Gtk.ApplicationWindow {
	private const int WINDOW_WIDTH = 640;
	private const int WINDOW_HEIGHT = 480;
	private const string DEFAULT_TITLE = "TexMag - Texture Magnifier";

	private Gtk.HeaderBar		header;
	private ThumbnailFrame		frame_thumb;
	private SmallMagnifiedArea	small_area;
	private Gtk.DrawingArea		magnified_area;
	private ImageDataLists		image_lists;
	private SupportedMimeTypes	mime_types;
	private AppSettings			settings;
	private ImageFileMonitor	file_monitor;

	public TexMagWindow(Gtk.Application app,
						ImageDataLists image_lists,
						SupportedMimeTypes mime_types,
						AppSettings settings) {
		Object(application: app);
		this.image_lists = image_lists;
		this.mime_types  = mime_types;
		this.settings    = settings;

		this.title = DEFAULT_TITLE;
		this.window_position = Gtk.WindowPosition.CENTER;
		this.set_default_size(WINDOW_WIDTH, WINDOW_HEIGHT);
		this.set_keep_above(this.settings.always_on_top);

		try {
			this.icon = new Gdk.Pixbuf.from_resource(app.resource_base_path + "/resources/appli_icon.png");
			this.image_lists.set_unavailable_icon(new Gdk.Pixbuf.from_resource(app.resource_base_path + "/resources/unavailable_image.png"));
		} catch (Error e) {
			warning("Could not load icon file: %s", e.message);
		}

		// ファイル監視の設定
		this.file_monitor = new ImageFileMonitor();
		this.file_monitor.created.connect(on_file_changed);
		this.file_monitor.changed.connect(on_file_changed);
		this.file_monitor.removed.connect(on_file_changed);
	}

	public void create_widgets() {
		// コンテナの設定
		var vbox_header = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		this.add(vbox_header);
		var hbox_base = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		hbox_base.margin = 5;
		vbox_header.pack_end(hbox_base, true, true, 0);

		var hbox_main = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		var revealer_info = new MessageArea();
		var overlay = new Gtk.Overlay();
		overlay.add(hbox_main);
		overlay.add_overlay(revealer_info);
		hbox_base.pack_end(overlay, true, true, 0);

		// HeaderBarの設定
		this.header = new Gtk.HeaderBar();
		this.header.decoration_layout = ":close";
		if (this.settings.set_titlebar) {
			this.header.set_show_close_button(true);
			this.header.title = this.title;
			this.set_titlebar(this.header);
		}
		else {
			this.header.title = "";
			vbox_header.pack_start(this.header, false, false, 0);
		}

		// HeaderBarへボタンを登録
		var btn_show_thumb = new Gtk.ToggleButton();
		btn_show_thumb.image = new Gtk.Image.from_icon_name("view-list-symbolic", Gtk.IconSize.MENU);
		btn_show_thumb.active = true;
		this.header.pack_start(btn_show_thumb);
		var btn_show_small = new Gtk.ToggleButton();
		btn_show_small.image = new Gtk.Image.from_icon_name("view-paged-symbolic", Gtk.IconSize.MENU);
		btn_show_small.active = true;
		this.header.pack_start(btn_show_small);
		var btn_option_menu = new Gtk.MenuButton();
		btn_option_menu.image = new Gtk.Image.from_icon_name("emblem-system-symbolic", Gtk.IconSize.MENU);
		this.header.pack_end(btn_option_menu);
		var btn_show_info = new Gtk.ToggleButton();
		btn_show_info.image = new Gtk.Image.from_icon_name("emblem-important-symbolic", Gtk.IconSize.MENU);
		this.header.pack_end(btn_show_info);

		// オプションメニューの設定
		set_option_menu_widgets(btn_option_menu);

		// メッセージエリアの設定
		revealer_info.set_reveal_child(false);
		revealer_info.set_transition_type(Gtk.RevealerTransitionType.SLIDE_UP);
		revealer_info.halign = Gtk.Align.FILL;
		revealer_info.valign = Gtk.Align.START;

		// サムネイルフレームの設定
		this.frame_thumb = new ThumbnailFrame(this, image_lists, mime_types, settings);
		var revealer_thumb = new Gtk.Revealer();
		revealer_thumb.set_reveal_child(true);
		revealer_thumb.set_transition_type(Gtk.RevealerTransitionType.SLIDE_LEFT);
		revealer_thumb.add(this.frame_thumb);
		hbox_base.pack_start(revealer_thumb, false, false, 0);

		// 小型拡大エリアの設定
		this.small_area = new SmallMagnifiedArea(this, image_lists);
		var revealer_small = new Gtk.Revealer();
		revealer_small.set_reveal_child(true);
		revealer_small.set_transition_type(Gtk.RevealerTransitionType.SLIDE_LEFT);
		revealer_small.add(this.small_area);
		hbox_base.pack_start(revealer_small, false, false, 0);

		// 拡大エリアの設定
		this.magnified_area = new Gtk.DrawingArea();
		this.magnified_area.margin = 10;
		this.magnified_area.can_focus = true;
		this.magnified_area.add_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		var frame_magnified_area = new Gtk.Frame(null);
		frame_magnified_area.add(this.magnified_area);
		hbox_main.pack_start(frame_magnified_area, true, true, 0);

		// シグナルハンドラの設定
		this.magnified_area.draw.connect(on_magnified_area_draw);
		this.magnified_area.button_press_event.connect((event) => {
			this.magnified_area.has_focus = true;
			return false;
		});
		this.magnified_area.key_press_event.connect((event) => {
			return this.frame_thumb.iconview_key_press_event(event);
		});

		btn_show_thumb.toggled.connect(() => {
			revealer_thumb.set_reveal_child(btn_show_thumb.active);
		});

		btn_show_small.toggled.connect(() => {
			revealer_small.set_reveal_child(btn_show_small.active);
		});

		btn_show_info.toggled.connect(() => {
			revealer_info.set_reveal_child(btn_show_info.active);
		});
	}

	private void set_option_menu_widgets(Gtk.MenuButton btn_option) {
		// 各種Widgetの生成
		var grid = new Gtk.Grid();
		grid.column_spacing = 15;
		grid.row_spacing = 15;
		grid.margin = 20;

		var lbl_always_on_top = new Gtk.Label("Always on Top:");
		lbl_always_on_top.halign = Gtk.Align.END;
		grid.attach(lbl_always_on_top, 0, 0);
		var sw_always_on_top = new Gtk.Switch();
		grid.attach(sw_always_on_top, 1, 0);

		var lbl_auto_reload = new Gtk.Label("Automatic Reload:");
		lbl_auto_reload.halign = Gtk.Align.END;
		grid.attach(lbl_auto_reload, 0, 1);
		var sw_auto_reload = new Gtk.Switch();
		grid.attach(sw_auto_reload, 1, 1);

		var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
		grid.attach(separator, 0, 2, 2);

		var lbl_set_titlebar = new Gtk.Label("Use HeaderBar as TitleBar:");
		lbl_set_titlebar.halign = Gtk.Align.END;
		grid.attach(lbl_set_titlebar, 0, 3);
		var sw_set_titlebar = new Gtk.Switch();
		grid.attach(sw_set_titlebar, 1, 3);

		var lbl_titlebar_warn = new Gtk.Label("<span font_weight=\"bold\">This changes take effect after restart.</span>");
		lbl_titlebar_warn.set_use_markup(true);
		grid.attach(lbl_titlebar_warn, 0, 4, 2);

		var popover = new Gtk.PopoverMenu();
		popover.add(grid);
		grid.show_all();
		btn_option.set_popover(popover);

		// シグナルハンドラの設定
 		btn_option.clicked.connect(() => {
			if (btn_option.active == true) {
				sw_always_on_top.active = this.settings.always_on_top;
				sw_auto_reload.active   = this.settings.auto_reload;
				sw_set_titlebar.active  = this.settings.set_titlebar;
			}
 		});
		sw_always_on_top.notify["active"].connect(() => {
			this.settings.always_on_top = sw_always_on_top.active;
			this.set_keep_above(this.settings.always_on_top);
 		});
		sw_auto_reload.notify["active"].connect(() => {
			this.settings.auto_reload = sw_auto_reload.active;
			Gtk.TreeIter? iter;
			if (this.frame_thumb.get_selected_iter(out iter) == true) {
				this.image_lists.refresh(iter);
				select_listitem(iter, true);
			}
 		});
		sw_set_titlebar.notify["active"].connect(() => {
			this.settings.set_titlebar = sw_set_titlebar.active;
 		});
	}

	public void select_listitem(Gtk.TreeIter? iter, bool force_update = false) {
		if (iter != null) {
			if ((this.image_lists.get_filepath(iter) == this.image_lists.selected_filepath)
			&&  (force_update == false)) {
				return;
			}
			if (this.image_lists.select(iter) == true) {
				Gtk.TreePath path = this.image_lists.model.get_path(iter);
				this.frame_thumb.iconview_select_path(path);
			}
		}

		if ((this.settings.auto_reload == true) && (iter != null)) {
			this.file_monitor.start_filemonitor(this.image_lists.selected_filepath);
		}
		else {
			this.file_monitor.stop_filemonitor();
		}

		update_magnified_area();
		update_title_string();
		this.frame_thumb.update_button_sensitive();
	}

	private void update_magnified_area() {
		this.magnified_area.queue_draw();
		this.small_area.draw_small_image();
	}

	private void update_title_string() {
		this.header.title    = DEFAULT_TITLE;
		this.header.subtitle = null;

		Gtk.TreeIter? iter;
		if (this.frame_thumb.get_selected_iter(out iter) == true) {
			string filepath = this.image_lists.selected_filepath;
			this.header.title    = GLib.Path.get_basename(filepath);
			this.header.subtitle = GLib.Path.get_dirname(filepath);
			if (this.image_lists.selected_pixbuf != null) {
				int width  = this.image_lists.selected_pixbuf.width;
				int height = this.image_lists.selected_pixbuf.height;
				this.header.title = "%s (%dx%d)".printf(GLib.Path.get_basename(filepath), width, height);
			}
		}
	}

	private bool on_magnified_area_draw(Cairo.Context context) {
		if (this.image_lists.selected_pixbuf == null) {
			return true;
		}
		int dest_height = this.magnified_area.get_allocated_height();
		int dest_width  = this.magnified_area.get_allocated_width();

		Utils.draw_scaled_image(context, this.image_lists.selected_pixbuf, dest_width, dest_height);
		return true;
	}

	private void on_file_changed(string filepath) {
		if (this.image_lists.selected_filepath == filepath) {
			Gtk.TreeIter? iter;
			if (this.frame_thumb.get_selected_iter(out iter) == true) {
				this.image_lists.refresh(iter);
				select_listitem(iter, true);
			}
		}
	}
}


////////////////////////////////////////////////////////////
//	クラス: アプリケーション
////////////////////////////////////////////////////////////
public class TexMagApplication : Gtk.Application {
	private TexMagWindow		window;
	private ImageDataLists		image_lists;
	private SupportedMimeTypes	mime_types;
	private AppSettings			settings;

	public TexMagApplication() {
		Object(application_id: "app.texmag.texturemagnifier",
			   flags: ApplicationFlags.HANDLES_OPEN);

		this.image_lists = new ImageDataLists();
		this.mime_types  = new SupportedMimeTypes();
		this.settings    = new AppSettings();
	}

	protected override void startup() {
		base.startup();
		var provider = new Gtk.CssProvider();
		provider.load_from_resource(this.resource_base_path + "/resources/styles.css");
		Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(),
												 provider,
												 Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

		this.window = new TexMagWindow(this, image_lists, mime_types, settings);
		this.window.create_widgets();
		this.window.show_all();
	}

	protected override void activate() {
		this.window.present();
	}

	protected override void open(File[] files, string hint) {
		Gtk.TreeIter? iter = null;
		foreach (GLib.File file in files) {
			if (iter == null) {
				iter = this.image_lists.load_image(file.get_path());
			}
			else {
				this.image_lists.load_image(file.get_path());
			}
		}
		this.window.select_listitem(iter);
		this.window.present();
	}

	protected override void shutdown() {
		base.shutdown();
		this.settings.save_setting();
	}
}


////////////////////////////////////////////////////////////
//	エントリーポイント
////////////////////////////////////////////////////////////
public static int main(string[] args) {
	var app = new TexMagApplication();
	return app.run(args);
}
