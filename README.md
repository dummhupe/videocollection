videocollection
===============
Show ripped media collection and play them using mplayer. You can also select audio track (DE, EN) and subtitle (DE,EN). 

Dependencies
===============
- Ruby
- Gtk2
- mplayer
- fuseiso
- fusermount
Additionally this probably only works with Linux.

Installation
===============
Copy ruby script to anywhere you like. Create a csv file that will contain all metadata with these columns:
1. Title
2. Season
3. Episode (optional)
4. Filename
5. DVD-Title
6. DVD-Chapter (optional)

Check if you need to change defaults in selector.rb:
1. Edit constant DB to set the path to csv file
2. Edit constant MOUNTPOINT to set the directory where ripped media is going to be mounted for viewing.
3. Edit constant CONFIG to set the path to the file where the latest settings will be saved on application exit.
