/*********************************************************************

 settings.vala

 Copyright (c) 2017 Chuhai

 This file is part of TexMag - Texture Magnifier.
 This software is released under the MIT License, see LICENSE.txt.

*********************************************************************/


////////////////////////////////////////////////////////////
//	クラス: 環境設定管理
////////////////////////////////////////////////////////////
public class AppSettings : GLib.Object {
	private	string			filepath;
	private GLib.KeyFile	keyfile;

	public bool set_titlebar 	{ get; set; }
	public bool auto_reload 	{ get; set; }
	public bool always_on_top 	{ get; set; }

	public class AppSettings() {
		this.set_titlebar	= false;
		this.auto_reload	= false;
		this.always_on_top	= false;

		this.filepath = GLib.Path.build_filename(
						GLib.Environment.get_user_config_dir(),
						"texmag",
						"texmag.conf");

		this.keyfile = new GLib.KeyFile();
		try {
			this.keyfile.load_from_file(this.filepath, KeyFileFlags.KEEP_COMMENTS);
		} catch (Error e) {
			warning("Could not load configuration file: %s", e.message);
			return;
		}

		this.set_titlebar  = get_boolean("settings", "set_titlebar",  this.set_titlebar);
		this.auto_reload   = get_boolean("settings", "auto_reload",	  this.auto_reload);
		this.always_on_top = get_boolean("settings", "always_on_top", this.always_on_top);
	}

	public void save_setting() {
		var dir_name = GLib.Path.get_dirname(this.filepath);
		if (DirUtils.create_with_parents(dir_name, 0777) != 0) {
			warning("Could not create directory: [%s] %s", dir_name, GLib.strerror(GLib.errno));
			return;
		}

		this.keyfile.set_boolean("settings", "set_titlebar",  this.set_titlebar);
		this.keyfile.set_boolean("settings", "auto_reload",	  this.auto_reload);
		this.keyfile.set_boolean("settings", "always_on_top", this.always_on_top);
		try {
			this.keyfile.save_to_file(this.filepath);
		} catch (Error e) {
			warning("Could not save configuration file: %s", e.message);
		}
	}


	private bool get_boolean(string group_name, string key_name, bool default_value) {
		bool val;
		try {
			val = this.keyfile.get_boolean(group_name, key_name);
		} catch (Error e) {
			val = default_value;
		}
		return val;
	}
}
