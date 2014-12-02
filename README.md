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
<ol>
<li>Title</li>
<li>Season</li>
<li>Episode (optional)</li>
<li>Filename</li>
<li>DVD-Title</li>
<li>DVD-Chapter (optional)</li>
</ol>

Check if you need to change defaults in selector.rb:
- Edit constant DB to set the path to csv file
- Edit constant MOUNTPOINT to set the directory where ripped media is going to be mounted for viewing.
- Edit constant CONFIG to set the path to the file where the latest settings will be saved on application exit.
