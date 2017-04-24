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

	public signal void created(string created_filepath);
	public signal void changed(string changed_filepath);
	public signal void removed(string removed_filepath);

	public ImageFileMonitor() {
		this.file_monitor = null;
		this.filepath = "";
	}

	~ImageFileMonitor() {
		reset_filemonitor();
	}

	public void set_filemonitor(string filepath) {
		if (filepath == this.filepath) {
			return;
		}

		reset_filemonitor();
		this.filepath = filepath;
		try {
			this.file_monitor = GLib.File.new_for_path(this.filepath).monitor(GLib.FileMonitorFlags.NONE, null);
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
			this.filepath = "";
		}
	}

	private void on_filemonitor_changed(GLib.File file, GLib.File? other_file, GLib.FileMonitorEvent event_type) {
		switch (event_type) {
		case GLib.FileMonitorEvent.CREATED:
			this.created(this.filepath);
			break;

		case GLib.FileMonitorEvent.CHANGED:
		case GLib.FileMonitorEvent.ATTRIBUTE_CHANGED:
		case GLib.FileMonitorEvent.CHANGES_DONE_HINT:
			this.changed(this.filepath);
			break;

		case GLib.FileMonitorEvent.DELETED:
			this.removed(this.filepath);
			break;
		}
	}
}
