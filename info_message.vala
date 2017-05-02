/*********************************************************************

 info_message.vala

 Copyright (c) 2017 Chuhai

 This file is part of TexMag - Texture Magnifier.
 This software is released under the MIT License, see LICENSE.txt.

*********************************************************************/

public enum MessageType {
	INFO, WARNING, ERROR
}

////////////////////////////////////////////////////////////
//	クラス: メッセージ表示インタフェース
////////////////////////////////////////////////////////////
public class MessageInterface : GLib.Object {

	public signal void add(string message_text, MessageType message_type);

    private static MessageInterface? instance = null;

    private MessageInterface() {}

    public static MessageInterface get_instance() {
        if (instance == null) {
            instance = new MessageInterface();
        }
        return instance;
    }

	public void add_message(string message_text, MessageType message_type) {
		this.add(message_text, message_type);
	}
}


////////////////////////////////////////////////////////////
//	クラス: メッセージ表示エリア
////////////////////////////////////////////////////////////
public class MessageArea : Gtk.Revealer {
	private enum Direction {
		PREVIOUS, NEXT
	}

	private Gtk.Stack	stack;
	private Gtk.Button	btn_clear;
	private Gtk.Button	btn_prev;
	private Gtk.Button	btn_next;
	private Gtk.Label	counter;

	public MessageArea() {
		// 子ウィジェットの設定
		var vbox_infobase = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		vbox_infobase.get_style_context().add_class(Gtk.STYLE_CLASS_OSD);

		var toolbar = new Gtk.Toolbar();
		toolbar.opacity = 0.8;

		var ti_clear   = new Gtk.ToolItem();
		var ti_counter = new Gtk.ToolItem();
		var ti_navi    = new Gtk.ToolItem();
		this.btn_clear = new Gtk.Button.from_icon_name("user-trash-symbolic", Gtk.IconSize.BUTTON);
		this.btn_prev  = new Gtk.Button.from_icon_name("go-previous-symbolic", Gtk.IconSize.BUTTON);
		this.btn_next  = new Gtk.Button.from_icon_name("go-next-symbolic", Gtk.IconSize.BUTTON);
		this.counter   = new Gtk.Label("0/0");
		var sep_space  = new Gtk.SeparatorToolItem();
		var hbox_infonavi = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		this.btn_clear.sensitive = false;
		this.btn_prev.sensitive  = false;
		this.btn_next.sensitive  = false;
		hbox_infonavi.get_style_context().add_class(Gtk.STYLE_CLASS_LINKED);
		hbox_infonavi.pack_start(this.btn_prev, false, false, 0);
		hbox_infonavi.pack_start(this.btn_next, false, false, 0);
		counter.get_style_context().add_class("message_counter");
		counter.margin_end = 16;
		ti_clear.add(this.btn_clear);
		ti_navi.add(hbox_infonavi);
		ti_counter.add(this.counter);
		sep_space.set_draw(false);
		sep_space.set_expand(true);
		toolbar.add(ti_clear);
		toolbar.add(sep_space);
		toolbar.add(ti_counter);
		toolbar.add(ti_navi);

		this.stack = new Gtk.Stack();
		this.stack.height_request = 80;
		this.stack.halign = Gtk.Align.FILL;
		this.stack.margin = 5;
		this.stack.transition_duration = 500;
		this.stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;

		vbox_infobase.pack_start(toolbar, false, false, 0);
		vbox_infobase.pack_start(this.stack, true, true, 0);
		this.add(vbox_infobase);

		// シグナルハンドラの設定
		this.btn_clear.clicked.connect(on_clear_clicked);
		this.btn_prev.clicked.connect(on_prev_clicked);
		this.btn_next.clicked.connect(on_next_clicked);

		var message = MessageInterface.get_instance();
		message.add.connect(on_add_message);
	}

	private void on_add_message(string message_text, MessageType message_type) {
		var sheet = new MessageSheet(message_text);
		string class_string;

		switch (message_type) {
		case MessageType.ERROR:
			class_string= "error_frame";
			break;
		case MessageType.WARNING:
			class_string= "warning_frame";
			break;
		default:
			class_string= "info_frame";
			break;
		}

		sheet.get_style_context().add_class(class_string);
		stack.add(sheet);
		set_button_sensitivities();
		set_message_count();
	}

	private void change_message(MessageArea.Direction dir) {
		GLib.List<weak Gtk.Widget> children = this.stack.get_children();
		var visible_child = this.stack.visible_child;
		if (visible_child != null) {
			unowned GLib.List<weak Gtk.Widget> found_child = children.find(visible_child);
			if (dir == MessageArea.Direction.NEXT) {
				this.stack.visible_child = found_child.next.data;
			}
			else {
				this.stack.visible_child = found_child.prev.data;
			}
		}
	}

	private void set_button_sensitivities() {
		GLib.List<weak Gtk.Widget> children = this.stack.get_children();
		var empty = (children.length() == 0);

		this.btn_clear.sensitive = !empty;
		if (empty == false) {
			this.btn_prev.sensitive  = (this.stack.visible_child != children.first().data);
			this.btn_next.sensitive  = (this.stack.visible_child != children.last().data);
		}
		else {
			this.btn_prev.sensitive  = false;
			this.btn_next.sensitive  = false;
		}
	}

	private void set_message_count() {
		GLib.List<weak Gtk.Widget> children = this.stack.get_children();
		var total = (int)children.length();
		var current = children.index(stack.visible_child) + 1;
		this.counter.label = "%d/%d".printf(current, total);
	}

	private void on_clear_clicked() {
		foreach (Gtk.Widget child in this.stack.get_children()) {
			this.stack.remove(child);
		}
		set_button_sensitivities();
		set_message_count();
	}

	private void on_prev_clicked() {
		change_message(MessageArea.Direction.PREVIOUS);
		set_button_sensitivities();
		set_message_count();
	}

	private void on_next_clicked() {
		change_message(MessageArea.Direction.NEXT);
		set_button_sensitivities();
		set_message_count();
	}

	////////////////////////////////////////////////////////////
	//	内部クラス: メッセージシート用フレーム
	////////////////////////////////////////////////////////////
	private class MessageSheet : Gtk.Frame {
		private Gtk.Label 	message_text;

		public MessageSheet(string text) {
			this.message_text = new Gtk.Label(text);
			this.message_text.set_ellipsize(Pango.EllipsizeMode.END);
			this.message_text.tooltip_text = text;
			this.message_text.set_use_markup(true);
			this.message_text.halign = Gtk.Align.START;
			this.message_text.margin = 5;
			this.add(this.message_text);
			this.shadow_type = Gtk.ShadowType.NONE;
			this.show_all();
		}
	}
}
