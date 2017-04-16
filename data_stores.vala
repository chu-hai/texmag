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

	private Gtk.ListStore	_model;
	private Gdk.Pixbuf		_selected_pixbuf;
	private string			_selected_filepath;

	public Gtk.ListStore 	model 				{ get {return this._model;} }
	public Gdk.Pixbuf		selected_pixbuf		{ get {return this._selected_pixbuf;} }
	public string			selected_filepath	{ get {return this._selected_filepath;} }

	public ImageDataLists() {
		this._model = new Gtk.ListStore(2, typeof (Gdk.Pixbuf),	// アイコン用画像データ
										   typeof (string));	// 画像ファイルパス
	}

	public Gtk.TreeIter? load_image(string image_filepath) {
		Gtk.TreeIter? iter;
		if (is_exist(image_filepath, out iter)){
			return iter;
		}

		try {
			var pixbuf = get_scaled_pixbuf(new Gdk.Pixbuf.from_file(image_filepath), ICON_SIZE, ICON_SIZE);
			this._model.append(out iter);
			this._model.set(iter, 0, pixbuf, 1, image_filepath);
		} catch (Error e) {
			stderr.printf("%s\n", e.message);
			return null;
		}
		return iter;
	}

	public bool select(Gtk.TreeIter iter) {
		var filepath = get_filepath(iter);
		if (FileUtils.test(filepath, GLib.FileTest.EXISTS) == false) {
			stderr.printf("%s is not exists.\n", filepath);
			return false;
		}

		try {
			this._selected_pixbuf   = new Gdk.Pixbuf.from_file(filepath);
			this._selected_filepath = filepath;
		} catch (Error e) {
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
			var pixbuf = get_scaled_pixbuf(new Gdk.Pixbuf.from_file(filepath), ICON_SIZE, ICON_SIZE);
			this._model.set(iter, 0, pixbuf);
		} catch (Error e) {
			return false;
		}
		return true;
	}

	public string get_filepath(Gtk.TreeIter iter) {
		GLib.Value v_filepath;
		this._model.get_value(iter, 1, out v_filepath);

		return (string)v_filepath;
	}

	private bool is_exist(string filepath, out Gtk.TreeIter? iter = null) {
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
