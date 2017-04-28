/*********************************************************************

 data_stores.vala

 Copyright (c) 2017 Chuhai

 This file is part of TexMag - Texture Magnifier.
 This software is released under the MIT License, see LICENSE.txt.

*********************************************************************/


////////////////////////////////////////////////////////////
//	クラス: 画像データ管理
////////////////////////////////////////////////////////////
public class ImageDataLists : GLib.Object {
	private const int ICON_SIZE = 64;

	private Gdk.Pixbuf?		unavailable_icon = null;

	private Gtk.ListStore	_model;
	private Gdk.Pixbuf		_selected_pixbuf;
	private string			_selected_filepath;

	public Gtk.ListStore 	model 				{ get {return this._model;} }
	public Gdk.Pixbuf		selected_pixbuf		{ get {return this._selected_pixbuf;} }
	public string			selected_filepath	{ get {return this._selected_filepath;} }

	public ImageDataLists() {
		this._model = new Gtk.ListStore(4, typeof (Gdk.Pixbuf),	// アイコン用画像データ
										   typeof (string),		// 画像ファイルパス
										   typeof (string),		// 更新日時
										   typeof (bool));		// 有効フラグ
	}

	public void set_unavailable_icon(Gdk.Pixbuf icon) {
		unavailable_icon = icon;
	}

	public Gtk.TreeIter? load_image(string image_filepath) {
		Gtk.TreeIter? iter;
		if (is_exists(image_filepath, out iter)){
			return iter;
		}

		try {
			var pixbuf = Utils.get_scaled_pixbuf(new Gdk.Pixbuf.from_file(image_filepath), ICON_SIZE, ICON_SIZE);
			var stamp = get_timestamp(image_filepath);
			this._model.append(out iter);
			this._model.set(iter, 0, pixbuf, 1, image_filepath, 2, stamp, 3, true);
		} catch (Error e) {
			stderr.printf("%s\n", e.message);
			return null;
		}
		return iter;
	}

	public bool select(Gtk.TreeIter iter) {
		var filepath = get_filepath(iter);
		this._selected_pixbuf = null;
		this._selected_filepath = filepath;

		if (Utils.is_file_exists(filepath) == false) {
			disable(iter);
			return false;
		}

		try {
			this._selected_pixbuf = new Gdk.Pixbuf.from_file(filepath);

			var cur_stamp = get_timestamp(filepath);
			GLib.Value v_stamp;
			this._model.get_value(iter, 2, out v_stamp);
			if (cur_stamp != (string)v_stamp) {
				refresh(iter);
			}
		} catch (Error e) {
			disable(iter);
			return false;
		}
		return true;
	}

	public bool remove(Gtk.TreeIter iter) {
		this._selected_pixbuf   = null;
		this._selected_filepath = "";
		return this._model.remove(iter);
	}

	public bool refresh(Gtk.TreeIter iter) {
		try {
			string filepath = get_filepath(iter);
			if (Utils.is_file_exists(filepath) == true) {
				var pixbuf = Utils.get_scaled_pixbuf(new Gdk.Pixbuf.from_file(filepath), ICON_SIZE, ICON_SIZE);
				var stamp = get_timestamp(filepath);
				this._model.set(iter, 0, pixbuf, 2, stamp, 3, true);
			}
			else {
				disable(iter);
			}
		} catch (Error e) {
			return false;
		}
		return true;
	}

	public void disable(Gtk.TreeIter iter) {
		if ((unavailable_icon == null) || (is_available(iter) == false)) {
			return;
		}

		GLib.Value v_pixbuf;
		this._model.get_value(iter, 0, out v_pixbuf);
		var pixbuf = (Gdk.Pixbuf)v_pixbuf;

		int dest_width  = pixbuf.width;
		int dest_height = pixbuf.height;
		int dest_x = (dest_width  - unavailable_icon.width)  / 2;
		int dest_y = (dest_height - unavailable_icon.height) / 2;

		unavailable_icon.composite(pixbuf, 0, 0, dest_width, dest_height,
								   dest_x, dest_y, 1, 1, Gdk.InterpType.NEAREST, 255);
		this._model.set(iter, 0, pixbuf, 3, false);
	}

	public string get_filepath(Gtk.TreeIter iter) {
		GLib.Value v_filepath;
		this._model.get_value(iter, 1, out v_filepath);

		return (string)v_filepath;
	}

	public bool is_available(Gtk.TreeIter iter) {
		GLib.Value v_available;
		this._model.get_value(iter, 3, out v_available);

		return (bool)v_available;
	}

	private bool is_exists(string filepath, out Gtk.TreeIter? iter = null) {
		Gtk.TreeIter? result_iter = null;
		bool result = false;

		this._model.foreach((_model, _path, _iter) => {
			GLib.Value v_filepath;
			_model.get_value(_iter, 1, out v_filepath);
			if ((string)v_filepath == filepath) {
				result_iter = _iter;
				result = true;
				return true;
			}
			return false;
		});

		iter = result_iter;
		return result;
	}

	private string get_timestamp(string filepath) {
		string result = "n/a";
		try {
			var file = GLib.File.new_for_path(filepath);
			if (file.query_exists ()) {
				var info = file.query_info("standard::content-type,time::modified",
											GLib.FileQueryInfoFlags.NONE,
											null);
				var mod_time = info.get_modification_time();
				result = mod_time.to_iso8601();
			}
		} catch (Error e) {
			stderr.printf ("Error: %s\n", e.message);
		}
		return result;
	}
}


////////////////////////////////////////////////////////////
//	クラス: mime-type管理
////////////////////////////////////////////////////////////
public class SupportedMimeTypes: GLib.Object {
	private GLib.HashTable<string, Gdk.PixbufFormat> format_lists;

	public SupportedMimeTypes() {
		this.format_lists = new GLib.HashTable<string, Gdk.PixbufFormat> (GLib.str_hash, GLib.str_equal);

		foreach(var format in Gdk.Pixbuf.get_formats()) {
			foreach(var mime in format.get_mime_types()) {
				if (format.is_disabled() == false) {
					this.format_lists.insert(mime, format);
				}
			}
		}
	}

	public bool is_supported(string mine_type) {
		return this.format_lists.lookup(mine_type) != null;
	}

	public string[] get_all() {
		string[] result = {};
		foreach(string mime in this.format_lists.get_keys()) {
			result += mime;
		}
		return result;
	}
}
