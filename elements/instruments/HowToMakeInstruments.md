# How to make a LemonJam instrument?

This little document explains, how a LemonJam instrument can be made using the V programming language.
An instrument in LemonJam is directly used and shared as a dynamic library (```.dll``` or ```.so```) file.
Therefore it must have a specific structure to properly work.


## Compiling

To compile the instrument to properly be able to use it, use the following command to export it as a .dll or .so file:

```v -shared -prod <path to instrument folder or file> ```

This exposes the functionality and logic of the instrument to LemonJam, but it's still missing some basic identification data.
To allow LemonJam to identify the instrument to assign a title, icon, etc. a small .json file has to be created too. This must contain the following data:

```json
{
    "type": "Instrument",
    "name": "<Instrument name>",
    "creator": "You",
    "description": "<Instrument description>",
    "file": "<File name without extension>"
}
```
