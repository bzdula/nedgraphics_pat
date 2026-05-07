// Enter your pattern code here and click on the Play button
// below to execute your code. The results will then be visible
// in the Pattern Data view.
// 
// More information can be found in the documentation.
// 
// 
// Simple example:
// 
// import std.io;
// 
// struct Pattern {
//     u32 int;
//     float floating_point;
// };
// 
// Pattern my_pattern @ 0x00;
// std::print("0x{:08X}", my_pattern.int);

#include <std/sys.pat>
#include <std/core.pat>
#pragma array_limit 1000000
#pragma pattern_limit 10000000

struct Header {
    be u16 width;
    be u16 height; 
    be u32 magic1;
    
    if (magic1 != 0x00010001) {
        break;
    }
      
    be u16 width_repeat;
    be u16 height_repeat;
    be u32 magic2;
    
    be u32 resolution; 
    be char cogr[4];
};

bool palette_encoded = false;

for (u32 i = 0x200, i < 0x300, i += 1) {
    if (std::mem::read_unsigned(i, 1) != 0x00) {
        palette_encoded = true;
        break;
    }
}

std::print("PALETTE ENCODED {}", palette_encoded);



struct PixelColor {
    u8 g @ 0x200 + std::core::array_index();
    u8 r @ 0x300 + std::core::array_index();
    u8 b @ 0x400 + std::core::array_index();   
} [[color(std::format("FF{:02X}{:02X}{:02X}", r, g, b))]];

Header header @ 0x0;

u16 height = header.height;

if (!palette_encoded) {
    height = header.height / 3;
}

struct Row {
    u8 r[header.width];
    u8 g[header.width];
    u8 b[header.width];
};

struct RGBPixel {
    u64 row = std::core::array_index() / header.width; 
    u64 col = std::core::array_index() % header.width;
    u64 base = addressof(parent);
    
    u8 r @ base + row * (header.width * 3) + col;
    u8 g @ base + row * (header.width * 3) + header.width + col;
    u8 b @ base + row * (header.width * 3) + header.width * 2 + col;
} [[color(std::format("FF{:02X}{:02X}{:02X}", r, g, b))]];


u64 size = header.width * height;
u64 data_end = 0x600 + size; 
u64 header_repeat = (data_end + 0xff) & ~u64(0xff);

struct ColorPixel {
    u8 index;
} [[color(std::format("FF{:02X}{:02X}{:02X}", pixels[index].r, pixels[index].g, pixels[index].b))]];

std::print("width: {} height: {} size: {:X}", header.width, height, size);
std::print("expected RGB end: {:X}", 0x600 + size * 3);
std::print("file size: {:X}", std::mem::size());

struct Data {
    
    if (palette_encoded) {
        if (size < 10000000){
            ColorPixel data[size];
        } else {
            u8 data[size];   
        }
    } else {
        if (size < 10000000){
            RGBPixel pixels_rgb[size];
        } else {
            Row rows[height];
        }
    }
};

Data data @0x600;

Header header2 @ header_repeat;