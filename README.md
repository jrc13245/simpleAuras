# simpleAuras


<img width="457" height="292" alt="image" src="https://github.com/user-attachments/assets/03f280cf-36ac-4139-ab03-1f26d70bf8ad" />


## Console Commands:
/sa or /sa show or /sa hide - Show/hide simpleAuras Settings

/sa refresh X - Set refresh rate. (1 to 100 updates per second. Default: 5)


## Settings (/sa)
<img width="825" height="545" alt="image" src="https://github.com/user-attachments/assets/5eebc24d-6924-4a5b-a83d-b9bde4a03c2f" />


### Overview
Shows all existing auras.

- [+] / Add Aura: Creates a new, blank aura.
- v / ^: Sort aura priority (higher in the list = will be shown over other auras below)


### Aura-Editor
Shows the currently edited aura only.

Aura Name:
- Name of the aura to track (has to be exactly the same name)


Icon/Texture:
- Color: Basecolor of the aura.
- Autodetect: Gets icon from buff.
- Browse: Choose a texture.
- Scale: Basescale of 1 is 48x48px.
- x/y pos: Position from center of the screen.
- Show Duration*/Stacks*: Shows Duration in the center of the icon/texture, stacks are under that.


Conditions:
- Unit: Which unit the aura is on.
- Type: is it a buff or a debuff.
- Low Duration Color: If the auracolor should change at or below "lowduration"
- Low Duration in secs: Allways active, changes durationcolor to red if at or below, also changes color if activated.


Other:
- [c] / Copy: Copies the aura.
- Invert: Activate to show aura if conditions aren't met (for example show if a buff is missing - currently only affects if found)
- Dual: Mirrors the aura (if xpos = -150, then it will show a mirrored icon/texture at xpos 150).
- Delete: Deletes the aura after confirmation.

\* = Target Duration/Stacks need SuperWoW and CleveRoidMacros' Testbranch!
