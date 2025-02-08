# zframe Tutorial 🚀

Welcome to the world of **zframe**! In this tutorial, you'll learn how to create web applications using zframe.

## What is zframe?

zframe is an **experimental web frontend framework** developed in **Zig**. It leverages Web Components and allows seamless integration of WebAssembly while remaining lightweight and efficient!

Unlike other frameworks, zframe is developed entirely in **pure Zig**, meaning you can build it using just the Zig toolchain. However, to make development more convenient, there's also a [handy CLI tool](https://github.com/yamada031016/zframe-dev-utils) available.

### Want to Learn Zig?

Zig hasn't reached v1.0 yet and frequently undergoes breaking changes. Stay updated using these resources:

- [Official Zig Website](https://ziglang.org/ja-JP/)
- [Zig Language Repository](https://github.com/ziglang/zig)
- [Zig Language Reference](https://ziglang.org/documentation/master/)
- [Zig API Documentation](https://ziglang.org/documentation/master/std/#)
- [zig.guide](https://zig.guide/)
- [ziglings (Practice Exercises)](https://codeberg.org/ziglings/exercises/)

---

# 🚀 Setup

### 1. Install Zig
First, install Zig!

🔗 [Zig Getting Started Guide](https://ziglang.org/learn/getting-started/)

### 2. Set Up zframe CLI (Optional)

```sh
cd zframe/zframe-cli
zig build -Doptimize=ReleaseSmall
```

To make the CLI easier to use, set up an alias:
```sh
echo "alias zframe = <your dir>/zframe-dev-utils/zig-out/bin/zfc" >> ~/.bashrc
```

Verify that the CLI is working:
```sh
zfc help
```

### 3. Create a Project

```sh
zfc init zframe-tutorial
```

Or clone a sample project:

```sh
git clone https://github.com/yamada031016/zframe-hello-world
mv zframe-hello-world zframe-tutorial
cd zframe-tutorial
rm -rf .git
```

Now that your project is ready, let's build it!

```sh
zfc build serve
```

Alternatively:
```sh
zig build run
<your-webserver> <html dir path(zig-out/html)>
```

---

# 🎨 Creating a Website

## 📄 Adding a New Page

Place page components in the `src/pages` folder, and they will be automatically routed! For example, creating `pages/about.zig` will make it accessible at `localhost:port/about`.

### Let's Create an About Page!

```zig
const z = @import("zframe");
const c = @import("components");
const node = z.node;

fn about() node.Node {
    const h1 = node.createNode(.h1);
    return h1.init("about");
}

pub fn main() !void {
    try z.render.render(@src().file, about());
}
```

---

## 🎨 Styling

Currently, **only Tailwind (Play CDN)** is supported.
**CSS support is planned for the future**, so stay tuned!

---

# 🔥 Component System

In zframe, components are placed in `src/components` and registered in `components/components.zig` for reuse.

### 🔗 Adding Navigation

First, create a `NavList` component.

#### `components/navList.zig`
```zig
pub fn NavList() Node {
    const nav = n.createNode(.nav);
    const a = n.createNode(.a);

    return nav.init(.{
        a.init(.{.href="/", .template="index"}),
        a.init(.{.href="/about", .template="about"}),
    });
}
```

Don't forget to register it!

#### `components/components.zig`
```zig
pub const NavList = @import("navList.zig").NavList;
```

Now, let's add it to a page!

#### `pages/about.zig`
```zig
fn about() node.Node {
    const h1 = node.createNode(.h1);
    const div = node.createNode(.div);

    return div.init(.{
        c.NavList(),
        h1.init("about"),
    });
}
```

---

## 📌 Creating a Layout Component

To manage common structures across pages, let's create a **layout component**!

#### `components/layout.zig`
```zig
const z = @import("zframe");
const node = z.node;
const c = @import("components");

pub fn Layout(page: node.Node) node.Node {
    const div = node.createNode(.div);
    return div.init(.{
        c.NavList(),
        page,
    });
}
```

---

## 🌍 Web Components

zframe makes it easy to create **Web Components**!
Use `.custom` to generate a `Node` and `define` to assign it a unique name.

#### `allRed.zig`
```zig
fn allRed() node.Node {
    const custom = node.createNode(.custom);
    const all_red = custom.define("all-red");
    const h2 = node.createNode(.h2);

    return all_red.init(.{
        h2.setClass("text-xl text-red-500").init("Test"),
    });
}
```

---

<!--# 🛠 WebAssembly-->
<!---->
<!--zframe is perfect for leveraging WebAssembly!-->
<!--Stay tuned for more guides on advanced usage.-->
<!---->
<!--Now it's time to bring your ideas to life and build an awesome web app! 🚀-->
