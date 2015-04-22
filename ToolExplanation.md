
---

### File Browser ###
  * **Open File** - To open a file, either Double Click it or Right Click it and press Open.
  * **Preview File** - To preview a file, right click a file and click Preview. The tool screen will now say Preview instead of Ready and ghosting of the preview will begin. To remove the preview, simply put the tool away and pull it back out.
  * **Save File** - To save a file, Right Click a folder and click Save, then enter a file name, (optional)enter a description, and click Save or press Enter.
  * **Create a New Folder** - Right Click a folder and enter a folder name then press Enter or the New Folder button.
  * **Delete File** - To delete a file Right Click it and press Delete, then confirm that you want to delete it by pressing the trash can. You can also delete a whole folder.
  * **Search for Files** - To search for files, Right Click a folder and click search. Then enter a file name and press enter. Files will appear matching the search criteria which can be opened.


---

### Paste ###
You first need to have something copied or a file opened and the press left click to paste it.

---

### Regular Copy ###
To copy something right click on a prop. Everything constrained to it will be copied with it(welded, roped, axis, etc..).

---

### Area Copy ###
First activate the Area Copy by holding shift and press Right Click. You should now see a green box. The size of the box can be changed by holding E and scrolling the mouse wheel or by dragging the Area Copy Size slider in the tool menu.

Props that are inside the area box will be highlighted green.

Once you're ready to copy, just right click. If you did not right click a prop, a head prop will be automatically selected for you.


---

### Addition Copy ###
You can add a single prop at a time by holding Alt and Right Clicking a prop.

---

### Clear the Duplicator ###
You can clear what is copied in the duplicator by holding Alt and Shift and pressing Right Click.

---

### Offsets ###
  * **Change Height** - To change the height of a paste, hold down E and scroll the mouse or change the Height slider in the Offsets category.
  * **Change Yaw** - To change the yaw of a paste, hold down E and drag the mouse left and right or change the Yaw slider in the Offsets category.
  * **Change Pitch and Roll** - To change the pitch and roll, change the Pitch and Yaw sliders in the Offsets category.
  * **Reset Offsets** - To reset the offsets press the Reset button in the Offsets category. Offsets will also be reset when you copy something or open a file.

---

### Contraption Spawner ###
The Contraption Spawner allows you to take a small duplication and create a spawner for it. You can constrain the spawner to something and spawn bombs or rockets for example.

A Contraption Spawner can be created by pressing R.

A key to spawn and a key to undo can be set in the Contraption Spawner category. It can also be done through wire.

The Spawn Delay can be used to prevent spawning from happening to quickly. If you press the spawn key before the interval, a timer will be set to spawn when the interval has been reached.

The Undo Delay can be set to how quickly a spawn should automatically be removed.

You can also press R on a Contraption Spawner to update the settings.

---

### Area Auto Save ###
The Area Auto Save will save an area or a contraption every set amount of minutes.

To auto save an area, first you need to select the directory to save the file to. Click the Browse button in the Area Auto Save category and left click on the folder you want to have the file saved to, then enter a file named and click save.

Now Area Copy should already be activated; if not, activate it with, (Shift + Right Click), then set the size of the area copy box you want, and then press R to begin the Area Auto Save.

You can save just a contraption by checking the "Contraption only" box in the Area Auto Save category and activating the Area Auto Save on a prop. This will copy the contraption no matter where it is located.

You can turn off the Area Auto Save by press the Turn Off button in the Area Auto Save category.

You can see where your Area Auto Save location is and the size of it by clicking the Show button.

---

### Map Save ###
You can preset props on a map and have them automatically loaded when the server starts. To save a map, you need to be an admin. Enter a file name for the file in the Map Save category and then click the Save button.

To have a file automatically loaded set the `ConVar` `AdvDupe2_LoadMap` to a value of 1, 2, or 3. 0 is disable, 1 will preserve the frozen state of the props when they were copied, 2 will unfreeze all, 3 will freeze all. You will then need to set the file name of the file to automatically be loaded by setting the `ConVar` `AdvDupe2_MapFileName`

For example `AdvDupe2_MapFileName` myfilename

---