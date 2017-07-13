/*********************************************************************

 dialogs.vala

 Copyright (c) 2017 Chuhai

 This file is part of TexMag - Texture Magnifier.
 This software is released under the MIT License, see LICENSE.txt.

*********************************************************************/


////////////////////////////////////////////////////////////
//	クラス: オープンダイアログ
////////////////////////////////////////////////////////////

//	基底クラス
public class OpenDialogBase : GLib.Object {
	protected Gtk.FileChooserDialog	dialog;

	public bool select_multiple {
		set { this.dialog.select_multiple = value; }
		get { return this.dialog.select_multiple; }
	}

	protected OpenDialogBase(string? title, Gtk.Window parent, Gtk.FileChooserAction action) {
		this.dialog = new Gtk.FileChooserDialog(title, parent, action,
												"_Cancel", Gtk.ResponseType.CANCEL,
												"_Open", Gtk.ResponseType.ACCEPT);
		this.dialog.local_only = true;
	}

	public int show() {
		var result = this.dialog.run();
		this.dialog.close();
		return result;
	}
}


//	画像ファイルオープンダイアログ
public class ImageFileOpenDialog : OpenDialogBase {
	private SList<string> _filenames;
	public SList<string> filenames {
		get { _filenames = this.dialog.get_filenames(); return _filenames; }
	}

	public ImageFileOpenDialog(Gtk.Window parent, SupportedMimeTypes mime_types) {
		// ファイル選択ダイアログの設定
		base("Open Image Files", parent, Gtk.FileChooserAction.OPEN);

		// フィルタの設定
		var filter = new Gtk.FileFilter();
		filter.set_filter_name("Image Files");
		foreach (string mime_type in mime_types.get_all()) {
			filter.add_mime_type(mime_type);
		}
		this.dialog.set_filter(filter);
	}
}
