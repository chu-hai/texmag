/*********************************************************************

 image_file_monitor.vala

 Copyright (c) 2017 Chuhai

 This file is part of TexMag - Texture Magnifier.
 This software is released under the MIT License, see LICENSE.txt.

*********************************************************************/


////////////////////////////////////////////////////////////
//	クラス: ファイル監視
////////////////////////////////////////////////////////////
public class ImageFileMonitor : GLib.Object {

	private GLib.FileMonitor	file_monitor;
	private string filepath;

	public signal void changed(string changed_filepath);
	public signal void removed(string removed_filepath);

	public ImageFileMonitor() {
		this.file_monitor = null;
	}
	~ImageFileMonitor() {
		reset_filemonitor();
	}

	public void set_filemonitor(string filepath) {
		reset_filemonitor();
		this.filepath = filepath;
		try {
			this.file_monitor = GLib.File.new_for_path(this.filepath).monitor(GLib.FileMonitorFlags.SEND_MOVED, null);
			this.file_monitor.changed.connect(on_filemonitor_changed);
		} catch (Error e) {
			stderr.printf("Error: %s\n", e.message);
		}
	}

	public void reset_filemonitor() {
		if (this.file_monitor != null) {
			file_monitor.cancel();
			file_monitor.changed.disconnect(on_filemonitor_changed);
			this.file_monitor = null;
			this.filepath = null;
		}
	}

	private void on_filemonitor_changed(GLib.File file, GLib.File? other_file, GLib.FileMonitorEvent event_type) {
		if (FileUtils.test(this.filepath, GLib.FileTest.EXISTS) == true) {
			this.changed(this.filepath);
		}
		else {
			this.removed(this.filepath);
		}
	}
}
