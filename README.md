# zframe
zframe is Web frontend framework for modern website with WebAssembly.
It has unique components system, modern useful features and interfaces integrating wasm on your app easily.

## Install
NOTE: zframe supports only zig v0.13.0, and I tested to build at Linux and Windows.
```sh
git clone https://github.com/yamada031016/zframe
# build cli tool
cd zframe/zframe-cli
zig build -Doptimize=ReleaseFast
```

## Get Started
You can initialize first website using zframe with a few minutes.
First, you execute below command to create and initialize your project.
NOTE: You should register your zfc path (zframe/zframe-cli/zig-out/bin/zfc)
```sh
zfc init zframe-demo
```
Then, you can find a directory named zframe-demo at current directory.
Let's move to this project directory, and built it!
```sh
cd zframe-demo
zfc build serve
```
You already have launched a browser, your website will open immediately.
Otherwise, you can open your website to click URL on the terminal.

Well done!
If you want to learn more, please try this tutorial.

## Examples
We have some examples at `examples/`, you can move to each project directory and build it.

## Features list
- own unique compornents system
- File system based routing
- development utils
  - project management
  - built-in web server
  - hot-reload ...
- SSG and CSR
- Web components
- partially JavaScript support (quite simple)
- Webassembly integration (quite simple)
