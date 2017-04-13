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

	private ThumbnailFrame		frame_thumb;
	private Gtk.DrawingArea		magnified_area;
	private ImageDataLists		image_lists;
	private SupportedMimeTypes	mime_types;
	private AppSettings			settings;

	public TexMagWindow(Gtk.Application app,
						ImageDataLists image_lists,
						SupportedMimeTypes mime_types,
						AppSettings settings) {
		Object(application: app);
		this.image_lists = image_lists;
		this.mime_types  = mime_types;
		this.settings    = settings;

		this.title = "TexMag - Texture Magnifier";
		this.window_position = Gtk.WindowPosition.CENTER;
		this.set_default_size(WINDOW_WIDTH, WINDOW_HEIGHT);
		this.set_keep_above(settings.always_on_top);
	}

	public void create_widgets() {
		// コンテナの設定
		var vbox_header = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		this.add(vbox_header);
		var hbox_base = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		hbox_base.margin = 5;
		vbox_header.pack_end(hbox_base, true, true, 0);

		var hbox_main = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		var revealer_info = new Gtk.Revealer();
		var overlay = new Gtk.Overlay();
		overlay.add(hbox_main);
		overlay.add_overlay(revealer_info);
		hbox_base.pack_end(overlay, true, true, 0);

		// HeaderBarの設定
		var header = new Gtk.HeaderBar();
		header.decoration_layout = ":close";
		if (settings.set_titlebar) {
			header.set_show_close_button(true);
			header.title = this.title;
			this.set_titlebar(header);
		}
		else {
			header.title = "";
			vbox_header.pack_start(header, false, false, 0);
		}

		// 情報エリアの設定
		revealer_info.set_reveal_child(false);
		revealer_info.set_transition_type(Gtk.RevealerTransitionType.SLIDE_UP);
		revealer_info.halign = Gtk.Align.FILL;
		revealer_info.valign = Gtk.Align.START;
		var frame_info = new Gtk.Frame(null);
		frame_info.get_style_context().add_class("app-notification");
		revealer_info.add(frame_info);

		// サムネイルフレームの設定
		this.frame_thumb = new ThumbnailFrame(this, image_lists, mime_types);
		var revealer_thumb = new Gtk.Revealer();
		revealer_thumb.set_reveal_child(true);
		revealer_thumb.set_transition_type(Gtk.RevealerTransitionType.SLIDE_LEFT);
		revealer_thumb.add(this.frame_thumb);
		hbox_base.pack_start(revealer_thumb, false, false, 0);

		// 拡大エリアの設定
		magnified_area = new Gtk.DrawingArea();
		magnified_area.margin = 10;
		var frame_magnified_area = new Gtk.Frame(null);
		frame_magnified_area.add(magnified_area);
		hbox_main.pack_start(frame_magnified_area, true, true, 0);

		// シグナルハンドラの設定
		magnified_area.draw.connect(on_magnified_area_draw);
	}

	public void select_item(Gtk.TreeIter? iter) {
		this.frame_thumb.select_item(iter);
	}

	public void update_magnified_area() {
		magnified_area.queue_draw();
	}

	private bool on_magnified_area_draw(Cairo.Context context) {
		if (this.image_lists.selected_pixbuf == null) {
			return true;
		}
		int dest_height = magnified_area.get_allocated_height();
		int dest_width  = magnified_area.get_allocated_width();

		draw_scaled_image(context, this.image_lists.selected_pixbuf, dest_width, dest_height);
		return true;
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
		this.window.select_item(iter);
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
