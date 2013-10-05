#!/usr/bin/ruby

require 'gtk2'

class Parser
  DB = 'metadata.csv'
  HEADERS = [:title, :season, :episode, :filename, :chapter, :audio_de, :audio_en, :subtitle_de, :subtitle_en]

  attr_accessor :data

  def initialize
    csv = File.readlines(DB)
    csv.shift # skip header
    csv.delete_if {|line| line.strip == ""}
    csv.map! {|line| line.strip } # skip trailing whitespace
    csv.map! {|line| line.split(',').map {|item| item.strip } }
    @data = []
    csv.each do |entry|
      @data << Hash[HEADERS.zip(entry)]
    end
    puts @data.inspect
  end
end

class Ui
  CONFIG="/home/hjvm/.foo"

  def fill_node(node, entry)
    node[1] = entry[:filename]
    node[2] = entry[:chapter]
    node[3] = entry[:audio_de]
    node[4] = entry[:audio_en]
    node[5] = entry[:subtitle_de]
    node[6] = entry[:subtitle_en]
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
        r.active = true if language == :de
      elsif r.label =~ /EN/ then
        r.active = true if language == :en
      else
        r.active = true if not language
      end
    end
  end

  def initialize
#    treestore = Gtk::TreeStore.new(String, String, Integer, Integer, Integer, Integer, Integer)
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
          
      node = treestore.append(current_season)
      node[0] = entry[:episode]
      fill_node(node, entry)
    end

    treeview = Gtk::TreeView.new(treestore)
    treeview.append_column(Gtk::TreeViewColumn.new("", Gtk::CellRendererText.new, :text => 0))
    treeview.set_headers_visible(false)
    treeview.selection.mode = Gtk::SELECTION_BROWSE

    iter = treestore.iter_first
    begin
      treeview.expand_row(iter.path, false)
    end while iter.next!

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

    config = File.read(CONFIG).strip.split(",").map {|i| i.to_sym }
    puts config.inspect
    set_language(audio_de, config[0])
    set_language(subtitle_off, config[1])

    play = Gtk::Button.new('Starten')
    play.signal_connect("clicked") do
      node = treeview.selection.selected

      language = get_language(audio_de)
      if language == :de
        audio = node[3]
      elsif language == :en
        audio = node[4]
      end

      language = get_language(subtitle_off)
      if language == :de
        subtitle = node[5]
      elsif language == :en
        subtitle = node[6]
      else
        subtitle = nil
      end

      cmd = "mplayer #{node[1]} -chapter #{node[2]} -fs -aid #{audio}"
      if subtitle then
        cmd += " -sid #{subtitle}"
      end
      # vobsubid, slang, alang
      #system(cmd)
      puts cmd
    end
    vbox.pack_end(play, false, false)

    hbox.pack_start(vbox, false, true, 10)

    window.add(hbox)

    window.signal_connect("destroy") do
      system("echo \"#{get_language(audio_de)},#{get_language(subtitle_off)}\" > #{CONFIG}")
      Gtk.main_quit
    end

    window.show_all
  end
end

Ui.new
Gtk.main
