#!/usr/bin/ruby

require 'gtk2'

class Parser
  DB = '/musik/dvd/metadata.csv'
  HEADERS = [:title, :season, :episode, :filename, :dvd_title, :dvd_chapter, :player]

  attr_accessor :data

  def initialize
    csv = File.readlines(DB)
    csv.shift # skip header
    csv.delete_if {|line| line.strip == ""}
    csv.map! {|line| line.strip } # skip trailing whitespace
    csv.map! {|line| line.split(';').map {|item| item.strip } }
    @data = []
    csv.each do |entry|
      @data << Hash[HEADERS.zip(entry)]
    end
  end
end

class Ui
  CONFIG=`echo -n $HOME` + "/.dvdcollection"
  MOUNTPOINT="/musik/dvd/mount"

  def fill_node(node, entry)
    node[1] = entry[:filename]
    node[2] = entry[:dvd_title]
    node[3] = entry[:dvd_chapter]
    node[4] = entry[:player]
  end

  # returns :de, :en or nil
  def get_language(radio)
    radio.group.each do |r|
      if r.active? then
        if r.label =~ /DE/ then
          return :de
        elsif r.label =~ /EN/ then
          return :en
        else
          return nil
        end
      end
    end
  end

  def set_language(radio, language)
    radio.group.each do |r|
      if r.label =~ /DE/ then
        r.active = true if language == 'de'
      elsif r.label =~ /EN/ then
        r.active = true if language == 'en'
      else
        r.active = true if not language
      end
    end
  end

  def initialize
    if File.exists? CONFIG then
      config = File.read(CONFIG).strip.split(",")
    else
      config = []
    end

    treestore = Gtk::TreeStore.new(String, String, String, String, String, String, String)

    current_title = current_season = nil
    p = Parser.new
    p.data.each do
      |entry|

      title_changed = false
      if !current_title or current_title[0] != entry[:title] then
        current_title = treestore.append(nil)
        current_title[0] = entry[:title]
        fill_node(current_title, entry)
        title_changed = true
      end

      if !current_season or title_changed or current_season[0] != entry[:season] then
        current_season = treestore.append(current_title)
        current_season[0] = entry[:season]
        fill_node(current_season, entry)
      end
      
      if !entry[:episode].empty? then
        node = treestore.append(current_season)
        node[0] = entry[:episode]
        fill_node(node, entry)
      end
    end

    treeview = Gtk::TreeView.new(treestore)
    treeview.append_column(Gtk::TreeViewColumn.new("", Gtk::CellRendererText.new, :text => 0))
    treeview.set_headers_visible(false)
    treeview.selection.mode = Gtk::SELECTION_BROWSE

    if config[2] then
      # expand to previous path
      treeview.expand_to_path(Gtk::TreePath.new(config[2]))
	    treeview.selection.select_path(Gtk::TreePath.new(config[2]))
	    treeview.scroll_to_cell(Gtk::TreePath.new(config[2]), nil, false, 0, 0)
	  else
			# expand first level of nodes
		  iter = treestore.iter_first
		  begin
		    treeview.expand_row(iter.path, false)
		  end while iter.next!
	  end

    hbox = Gtk::HBox.new
    scroll_area = Gtk::ScrolledWindow.new
    scroll_area.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    scroll_area.add(treeview)
    hbox.pack_start(scroll_area, true, true)

    window = Gtk::Window.new("DVD Collection")
    window.set_default_size(600,600)

    vbox = Gtk::VBox.new
    audio_de = Gtk::RadioButton.new('Audio DE')
    audio_en = Gtk::RadioButton.new(audio_de, 'Audio EN')
    subtitle_off = Gtk::RadioButton.new('Keine Untertitel')
    subtitle_de = Gtk::RadioButton.new(subtitle_off, 'Untertitel DE')
    subtitle_en = Gtk::RadioButton.new(subtitle_off, 'Untertitel EN')
    vbox.pack_start(audio_de, false, false)
    vbox.pack_start(audio_en, false, false)
    vbox.pack_start(subtitle_off, false, false)
    vbox.pack_start(subtitle_de, false, false)
    vbox.pack_start(subtitle_en, false, false)

    set_language(audio_de, config[0])
    set_language(subtitle_off, config[1])

    play = Gtk::Button.new('Starten')
    play.signal_connect("clicked") do
      node = treeview.selection.selected

      audio_language = get_language(audio_de)

      subtitle_language = get_language(subtitle_off)

      case node[4]
        when 'vlc'
          cmd = "cvlc dvd://#{node[1]}\##{node[2]}"
          if node[3] and node[3] != "" then
            cmd += ":{node[3]}"
          end
        else
          cmd  = "fuseiso #{node[1]} #{MOUNTPOINT}"
          cmd += " && mplayer -dvd-device #{MOUNTPOINT} dvd://#{node[2]} -fs -alang #{audio_language.to_s}"
          if subtitle_language then
            cmd += " -slang #{subtitle_language.to_s}"
          else
            cmd += " -sid 999"
          end
          if node[3] and node[3] != "" then
            cmd += " -chapter #{node[3]}"
          end
          cmd += "; fusermount -u #{MOUNTPOINT}"
      end
      puts cmd
      system(cmd)
    end
    vbox.pack_end(play, false, false)

    hbox.pack_start(vbox, false, true, 10)

    window.add(hbox)

    window.signal_connect("destroy") do
      system("echo \"#{get_language(audio_de)},#{get_language(subtitle_off)},#{treeview.selection.selected.path}\" > #{CONFIG}")
      Gtk.main_quit
    end

    window.show_all
  end
end

Ui.new
Gtk.main
