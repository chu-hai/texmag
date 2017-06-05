/*********************************************************************

 small_magnified_area.vala

 Copyright (c) 2017 Chuhai

 This file is part of TexMag - Texture Magnifier.
 This software is released under the MIT License, see LICENSE.txt.

*********************************************************************/


////////////////////////////////////////////////////////////
//	クラス: 小型拡大エリア
////////////////////////////////////////////////////////////
public class SmallMagnifiedArea : Gtk.Frame {
	private const int FRAME_WIDTH = 128;
	private const int[] SCALED_SIZE = {16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96};

	private int current_size_index = 2;

	private TexMagWindow	window;
	private ImageDataLists	image_lists;
	private Gtk.Button		btn_zoom_in;
	private Gtk.Button		btn_zoom_out;
	private Gtk.DrawingArea	small_magnified_area;

	public SmallMagnifiedArea(TexMagWindow window,
							  ImageDataLists image_lists) {
		this.window      = window;
		this.image_lists = image_lists;

		// 子ウィジェットの設定
		var vbox_base = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		this.add(vbox_base);

		this.small_magnified_area = new Gtk.DrawingArea();
		this.small_magnified_area.width_request = FRAME_WIDTH;
		this.small_magnified_area.get_style_context().add_class("small_magnified_area");

		var hbox_footer = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		var hbox_footer_inner = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		hbox_footer.set_center_widget(hbox_footer_inner);
		hbox_footer.margin = 5;

		vbox_base.pack_start(small_magnified_area, true, true, 0);
		vbox_base.pack_start(hbox_footer, false, false, 0);

		this.btn_zoom_in  = new Gtk.Button.from_icon_name("zoom-in-symbolic", Gtk.IconSize.BUTTON);
		this.btn_zoom_out = new Gtk.Button.from_icon_name("zoom-out-symbolic", Gtk.IconSize.BUTTON);
		hbox_footer_inner.get_style_context().add_class(Gtk.STYLE_CLASS_LINKED);
		hbox_footer_inner.pack_start(this.btn_zoom_out, false, false, 0);
		hbox_footer_inner.pack_start(this.btn_zoom_in,  false, false, 0);
		update_button_sensitive();

		// シグナルハンドラの設定
		this.small_magnified_area.draw.connect(on_small_magnified_area_draw);
		this.btn_zoom_in.clicked.connect(on_zoom_in_clicked);
		this.btn_zoom_out.clicked.connect(on_zoom_out_clicked);
	}

	public void draw_small_image() {
		this.small_magnified_area.queue_draw();
		update_button_sensitive();
	}

	private void update_button_sensitive() {
		if (this.image_lists.selected_pixbuf == null) {
			this.btn_zoom_in.sensitive  = false;
			this.btn_zoom_out.sensitive = false;
		}
		else if (this.current_size_index == 0) {
			this.btn_zoom_in.sensitive  = true;
			this.btn_zoom_out.sensitive = false;
		}
		else if (this.current_size_index == SCALED_SIZE.length - 1) {
			this.btn_zoom_in.sensitive  = false;
			this.btn_zoom_out.sensitive = true;
		}
		else {
			this.btn_zoom_in.sensitive  = true;
			this.btn_zoom_out.sensitive = true;
		}
	}

	private bool on_small_magnified_area_draw(Cairo.Context context) {
		weak Gtk.StyleContext style_context = this.small_magnified_area.get_style_context();
		int area_height = this.small_magnified_area.get_allocated_height ();
		int area_width  = this.small_magnified_area.get_allocated_width ();
		style_context.render_background(context, 0, 0, (double)area_width, (double)area_height);

		if (this.image_lists.selected_pixbuf == null) {
			return true;
		}

		int size = SCALED_SIZE[this.current_size_index];
		int x = (area_width  - size) / 2;
		int y = (area_height - size) / 2;

		// 枠線の描画
		context.set_source_rgb(0.7, 0.7, 0.7);
		context.rectangle(x-1, y-1, size+2, size+2);
		context.stroke();

		// イメージの描画
		var scaled_pixbuf = Utils.get_scaled_pixbuf(this.image_lists.selected_pixbuf, size, size);
		var source = Gdk.cairo_surface_create_from_pixbuf(scaled_pixbuf, 0, null);
		var pattern = new Cairo.Pattern.for_surface(source);
		context.translate(x, y);
		context.set_source(pattern);
		context.paint();

		return true;
	}

	private void on_zoom_in_clicked() {
		this.current_size_index = int.min(this.current_size_index + 1, SCALED_SIZE.length - 1);
		update_button_sensitive();
		draw_small_image();
	}

	private void on_zoom_out_clicked() {
		this.current_size_index = int.max(this.current_size_index - 1, 0);
		update_button_sensitive();
		draw_small_image();
	}
}
