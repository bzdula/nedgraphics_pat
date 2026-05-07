#include <std/sys.pat>
#include <std/core.pat>


struct Header {
    be u16 width;
    be u16 height; 
    be u32 magic1;

    be u16 width_repeat;
    be u16 height_repeat;
    be u32 magic2;
    
    be u32 resolution; 
    be char cogr[4];
    
    be u8 rest[488];
    
    if (magic1 != 0x00010001
        || magic1 != 0x00000002
        || cogr != "CoGr") {
        break;
    }
} [[comment("HEADER")]];

bool palette_encoded = false;

for (u32 i = 0x200, i < 0x300, i += 1) {
    if (std::mem::read_unsigned(i, 1) != 0x00) {
        palette_encoded = true;
        break;
    }
}



std::print("PALETTE ENCODED {}", palette_encoded);


/*

struct PixelColor {
    u8 g @ 0x200 + std::core::array_index();
    u8 r @ 0x300 + std::core::array_index();
    u8 b @ 0x400 + std::core::array_index();   
} [[color(std::format("FF{:02X}{:02X}{:02X}", r, g, b))]];

*/

struct ColorBlock {
    if (palette_encoded) {
        u8 green[256];
        u8 red[256];
        u8 blue[256];
    }
};

Header header @ 0x0;

ColorBlock colors @ 0x200;


if (!palette_encoded) {
    height = header.height / 3;
}

struct InlineRow {
    u8 [header.width];
    u8 g[header.width];
    u8 b[header.width];
} [[comment(std::format("ROW #{}", std::core::array_index()))]];


u64 size = header.width * header.height;
u64 data_end = 0x600 + size;  //Size + offset
u64 header_repeat = (data_end + 0xff) & ~u64(0xff);

struct Data {

    if (palette_encoded) {
        u8 data[size];
    } else {
        InlineRow rows[height];
    }
};

Data data @0x600;

Header header2 @ header_repeat;