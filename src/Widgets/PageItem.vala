/*
* Copyright (c) 2011-2016 Felipe Escoto (https://github.com/Philip-Scott/Notes-up)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
* Authored by: Felipe Escoto <felescoto95@hotmail.com>
*/

public class ENotes.PageItem : Gtk.ListBoxRow {
    public ENotes.Page page { get; construct set; }
    public bool can_drag { get; construct set; }

    private Gtk.Grid grid;
    private Gtk.Label title_label;
    private Gtk.Label preview_label;

    private const Gtk.TargetEntry[] drag_targets = {
        {"ENOTES_PAGESLIST_ROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public signal void index_changed ();

    public PageItem (ENotes.Page page, bool can_drag = false) {
        Object (page: page, can_drag: can_drag);
    }

    private static Trash trash_instance;

    static construct {
        trash_instance = Trash.get_instance ();
    }

    construct {
        set_activatable (true);

        grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;

        title_label = new Gtk.Label ("");
        title_label.use_markup = true;
        title_label.halign = Gtk.Align.START;
        title_label.get_style_context ().add_class ("h3");
        title_label.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) title_label).xalign = 0;
        title_label.margin_top = 9;
        title_label.margin_start = 10;
        title_label.margin_end = 10;
        title_label.margin_bottom = 9;

        preview_label = new Gtk.Label ("");
        preview_label.halign = Gtk.Align.START;
        preview_label.margin_top = 0;
        preview_label.margin_start = 10;
        preview_label.margin_end = 10;
        preview_label.margin_bottom = 9;
        preview_label.use_markup = true;
        preview_label.set_line_wrap (true);
        preview_label.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) preview_label).xalign = 0;
        preview_label.lines = 3;

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.hexpand = true;

        if (this.can_drag) {
            var dragBox = new Gtk.EventBox ();
            dragBox.drag_data_get.connect (this.on_drag_data_get);
            this.drag_data_received.connect (this.on_drag_data_received);
            Gtk.drag_source_set (dragBox, Gdk.ModifierType.BUTTON1_MASK, drag_targets, Gdk.DragAction.MOVE);
            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, drag_targets, Gdk.DragAction.MOVE);

            dragBox.add (grid);
            this.add (dragBox);
        } else {
            this.add (grid);
        }

        grid.add (title_label);
        grid.add (preview_label);
        grid.add (separator);

        load_data ();
        this.show_all ();
    }

    public void load_data () {
        preview_label.label = page.subtitle;
        title_label.label = "<b>" + page.name + "</b>";

        title_label.sensitive = !trash_instance.is_page_trashed (page);
        preview_label.sensitive = title_label.sensitive;
    }

    private void on_drag_data_get (Gdk.DragContext drag_context, Gtk.SelectionData selection_data,
        uint info, uint time ) {

        uint8[] data = {(uint8) this.get_index (), 0};
        selection_data.@set (selection_data.get_target (), 0, data);
    }

    private void on_drag_data_received (Gdk.DragContext drag_context, int x, int y,
        Gtk.SelectionData selection_data, uint info, uint time) {

        unowned uint8[] data = selection_data.get_data ();

        int source_pos = (int) data[0];
        int target_pos = this.get_index ();

        if (source_pos == target_pos) {
            Gtk.drag_finish (drag_context, true, true, time);
            return;
        }

        var parent = this.get_parent ();

        if (parent.get_type () == typeof (Gtk.ListBox)) {

            var listbox = (Gtk.ListBox) parent;
            var source = listbox.get_row_at_index (source_pos);

            source.ref ();
            listbox.remove (source);
            listbox.insert (source, target_pos);
            source.unref ();

            index_changed ();
        }

        Gtk.drag_finish (drag_context, true, true, time);
    }
}
