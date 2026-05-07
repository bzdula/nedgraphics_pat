# pat_format

Repository documenting efforts to reverse engineer *.pat* - image format used by textile CAD software made by Nedgraphics.
I've been asked to help recover a bunch (100GB+) of patterns, mostly carpet designs created by Nedgraphics Texcelle - textile CAD software since early 90s till early 2010s. I couldn't use the original software because of DRM issues - I was unable to move license to a different machine or VM because of fingerprinting and the licensing servers are dead for years (but they can send me an exciting quote for their new subscription service).

---

The .hexpat files is a pattern file (maybe I'll PR it upstream in the future) decoding that format (WIP).

Everything here is speculation however I've successfuly managed to extract some images with a fork of rust's [image-extras](https://github.com/bzdula/image-extras) crate.

---
So far what this is what I've found out (all values are big endian):

# Header

Starts from `0x0000` and goes (probably) to `0x0200` (since they seem to like to pad everything to nearest 512 byte block).

|Offset|Size|Type|Description|
|---|---|---|---|
|0x0000|2|u16|Width|
|0x0002|2|u16|Height|
|0x0004|4|u32|Some magic number (?) always `00 01 00 01` |
|0x0008|2|u16|Repeated width|
|0x000A|2|u16|Repeated height|
|0x000C|4|u32|Another magic number (?) always `00 00 00 02` |
|0x0010|4|u32|Resolution (to be figured out)|
|0x0014|4|char|String `CoBr`|
|0x0018|1|u8|Unknown - seems to be either `1F` or `1B`; possibly has something to do with color encoding|
|0x0019|1|u8|Possibly padding - always `00`|
|0x001A|2|u8|Unknown either `00` or `01`|
|0x01B+|485|?|Unknown

# Color encoding 

This format can encode color in two different ways: 
* "Palette encoding" - Either there is color data present at address `0x200` (and possibly there is relation with byte `0x0018`) meaning that it's akin of bmp with color palette or
* If there is no color palette data color is encoded inline

## Palette encoding

In this mode palette is encoded as 256 values from address `0x200` in planar fashion as **GRB** so for example second color of the palette is encoded under bytes `[0x301, 0x201, 0x401]` and so on.

## Inline encoding

In inline encoding color is encoded as **RGB** also in planar fashion where one image row consists of three planes for channels: 
```
R[0],R[1], ... ,R[rowlen - 2],R[rowlen - 1],
G[0],G[1], ... ,G[rowlen - 2],G[rowlen - 1],
B[0],B[1], ... ,B[rowlen - 2],B[rowlen - 1] 

then next row
```
so here if we want to get color of second pixel in an image we need to get `[0x601, 0x601 + rowlen, 0x601 + 2*rowlen]`.

> It is important that height encoded in header in this mode is multiplied by 3 (number of channels), it is important to remember about that when decoding.

# Data block

Data block always start at `0x600` and it's of size `width * height` (encoded height not "real height").

# Repeated header 

After data ends there is padding with zeros to the nearest 512 byte block and then there is the same header repeated 

# Unknown stuff

* What is going on between `0x20` and `0x200`, there are some (not much) values there but they doesn't seem to be important when recovering the image; perhaps some textile related information.
* If there are some other wacky modes of encoding 