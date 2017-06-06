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
		stop_filemonitor();
	}

	public void start_filemonitor(string filepath) {
		if (filepath == this.filepath) {
			return;
		}

		stop_filemonitor();
		this.filepath = filepath;
		try {
			this.file_monitor = GLib.File.new_for_path(this.filepath).monitor(GLib.FileMonitorFlags.NONE, null);
			this.file_monitor.changed.connect(on_filemonitor_changed);
		} catch (Error e) {
			warning("File monitoring failed to start: %s", e.message);
		}
	}

	public void stop_filemonitor() {
		if (this.file_monitor != null) {
			file_monitor.cancel();
			file_monitor.changed.disconnect(on_filemonitor_changed);
			this.file_monitor = null;
			this.filepath = "";
		}
	}

	private void on_filemonitor_changed(GLib.File file, GLib.File? other_file, GLib.FileMonitorEvent event_type) {
		string filepath = file.get_path();
		if (filepath != this.filepath) {
			return;
		}

		switch (event_type) {
		case GLib.FileMonitorEvent.CREATED:
			this.created(filepath);
			break;

		case GLib.FileMonitorEvent.CHANGED:
		case GLib.FileMonitorEvent.ATTRIBUTE_CHANGED:
		case GLib.FileMonitorEvent.CHANGES_DONE_HINT:
			this.changed(filepath);
			break;

		case GLib.FileMonitorEvent.DELETED:
			this.removed(filepath);
			break;
		}
	}
}
