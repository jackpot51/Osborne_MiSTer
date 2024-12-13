use std::{env, fs, io};

mod app;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let path = env::args().nth(1).expect("no file provided");

    let file = fs::File::open(&path)?;
    let mut bufreader = io::BufReader::new(file);
    let mut parser = vcd::Parser::new(&mut bufreader);
    let header = parser.parse_header()?;
    let vsync_code = header
        .find_var(&["testbench", "vsync"])
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "no vsync found"))?
        .code;
    let hsync_code = header
        .find_var(&["testbench", "hsync"])
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "no hsync found"))?
        .code;
    let clk_dot_code = header
        .find_var(&["testbench", "clk_dot"])
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "no clk_dot found"))?
        .code;
    let video_code = header
        .find_var(&["testbench", "video"])
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "no video found"))?
        .code;

    let width = 52 * 8;
    let height = 24 * 10;
    let mut pixels = vec![0u8; width * height * 4];
    let mut row = 0;
    let mut col = 0;
    let mut video = false;
    let mut images = Vec::new();
    for command_result in parser {
        //TODO: this ignores all parsing errors
        let Ok(command) = command_result else {
            continue;
        };
        match command {
            vcd::Command::ChangeScalar(code, value) => {
                if code == vsync_code {
                    if value == vcd::Value::V0 {
                        if col > 0 || row > 0 {
                            row = 0;
                            col = 0;
                            images.push(cosmic::widget::image::Handle::from_rgba(
                                width as _,
                                height as _,
                                pixels.clone(),
                            ));
                        }
                    }
                } else if code == hsync_code {
                    if value == vcd::Value::V1 {
                        if col > 0 {
                            col = 0;
                            row += 1;
                        }
                    }
                } else if code == clk_dot_code {
                    if row < height && col < width {
                        // Clear pixel to black
                        pixels[(row * width + col) * 4 + 0] = 0x00;
                        pixels[(row * width + col) * 4 + 1] = 0x00;
                        pixels[(row * width + col) * 4 + 2] = 0x00;
                        pixels[(row * width + col) * 4 + 3] = 0xFF;
                        if video {
                            // Set green channel
                            pixels[(row * width + col) * 4 + 1] = 0xFF;
                        }
                    }
                    col += 1;
                } else if code == video_code {
                    video = value == vcd::Value::V1;
                }
            }
            _ => {}
        }
    }
    images.push(cosmic::widget::image::Handle::from_rgba(
        width as _,
        height as _,
        pixels.clone(),
    ));

    cosmic::app::run::<app::App>(Default::default(), images)?;

    Ok(())
}
