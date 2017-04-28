/*********************************************************************

 utils.vala

 Copyright (c) 2017 Chuhai

 This file is part of TexMag - Texture Magnifier.
 This software is released under the MIT License, see LICENSE.txt.

*********************************************************************/

namespace Utils {

	public Gdk.Pixbuf get_scaled_pixbuf(Gdk.Pixbuf src, int dest_width, int dest_height) {
		var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, dest_width, dest_height);
		var context = new Cairo.Context(surface);

		draw_scaled_image(context, src, dest_width, dest_height);

		return Gdk.pixbuf_get_from_surface(surface, 0, 0, dest_width, dest_height);
	}

	public void draw_scaled_image(Cairo.Context context, Gdk.Pixbuf src_pixbuf, int dest_width, int dest_height) {
		int src_height = src_pixbuf.height;
		int src_width  = src_pixbuf.width;
		double ratio = double.min((double)dest_height / src_height, (double)dest_width / src_width);

		var source = Gdk.cairo_surface_create_from_pixbuf(src_pixbuf, 0, null);
		var pattern = new Cairo.Pattern.for_surface(source);

		if (ratio < 1) {
			pattern.set_filter(Cairo.Filter.BILINEAR);
		}
		else {
			pattern.set_filter(Cairo.Filter.NEAREST);
		}
		context.translate((dest_width - src_width * ratio) / 2, (dest_height - src_height * ratio) / 2);
		context.scale(ratio, ratio);
		context.set_source(pattern);
		context.paint();
	}

	public bool is_file_exists(string filepath) {
		return FileUtils.test(filepath, GLib.FileTest.EXISTS);
	}
}
