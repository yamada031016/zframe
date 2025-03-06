# zframe Documentation

Welcome to the official documentation for **zframe**, a web frontend framework written in Zig. zframe enables seamless development of WebAssembly (WASM) and frontend components, leveraging Zig’s expressive syntax and functional programming-like state management.

## Features

- **Minimal WASM size**: Optimized for fast load times.
- **Seamless Zig integration**: Develop frontend and WASM components in a single framework.
- **Declarative HTML rendering**: Convert Zig structs into corresponding HTML elements.
- **High performance rendering**: Efficient update and diffing system.

## Installation

### Prerequisites
Ensure you have Zig installed:
```sh
zig version
```
Install dependencies:
- [wasm-binary-analyzer](https://github.com/yamada031016/wasm-binary-analyzer)
- [markdown-zig](https://github.com/yamada031016/markdown-zig)
```sh
zig fetch --save=wasm-binary-analyzer https://github.com/yamada031016/wasm-binary-analyzer
zig fetch --save=markdown https://github.com/yamada031016/markdown-zig
```

### Building zframe
Clone the repository and build:
```sh
git clone https://github.com/yamada031016/zframe.git
zig build run
```

## Usage

### Basic Example
Create a simple `main.zig` file:
```zig
const zframe = @import("zframe");
const std = @import("std");

pub fn main() void {
    const app = zframe.createApp();
    app.mount("#root");
}
```
Compile and run:
```sh
zig build run
```

## Project Structure
zframe consists of the following core modules:

- [element.zig](docs/element.md) - Defines UI components.
- [handler.zig](docs/handler.md) - Event handling system.
- [html.zig](docs/html.md) - HTML generation utilities.
- [main.zig](docs/main.md) - Entry point and application setup.
- [node.zig](docs/node.md) - Virtual DOM representation.
- [render.zig](docs/render.md) - Rendering and diffing engine.
- [zframe.zig](docs/zframe.md) - Core framework logic.

## API Reference
For a detailed API reference, see [API Documentation](docs/api.md).

## Contributing
Contributions are welcome! Please check out the [contributing guide](docs/contributing.md).

## License
This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
