# Element Module

## Overview
The `element.zig` module provides structures and functions for representing HTML elements in `zframe`. It defines a flexible abstraction over various HTML elements, enabling structured and type-safe manipulation of elements within the framework.

## API Reference

### `createElement`
```zig
pub fn createElement(comptime tagName: Tag) Element
```
Creates an `Element` instance corresponding to the given HTML tag.

- **Parameters**:
  - `tagName`: A `Tag` representing the HTML tag type.
- **Returns**:
  - An `Element` instance corresponding to the tag.

### `ElementType`
```zig
pub const ElementType = enum { ... };
```
An enumeration defining different types of HTML elements supported by `zframe`. Possible values include:
- `plane`
- `image`
- `hyperlink`
- `link`
- `meta`
- `form`
- `input`
- `tablecol`
- `th`
- `td`
- `custom`

### `Element`
```zig
pub const Element = union(ElementType) { ... };
```
A union representing an HTML element. It provides methods for retrieving tag names and templates.

#### Methods
- `getTagName(self: *const Element) []const u8`
  - Returns the tag name of the element.
- `getTemplate(self: *const Element) ElementError![]u8`
  - Returns the template string associated with the element.

### Specific Element Structures

#### `PlaneElement`
A generic HTML element such as `<h1>`, `<p>`, etc.

```zig
pub const PlaneElement = struct { ... };
```

#### `Image`
Represents the `<img>` tag without automatic optimization.

```zig
pub const Image = struct { ... };
```

#### `HyperLink`
Represents an `<a>` (anchor) tag.

```zig
pub const HyperLink = struct { ... };
```

#### `Meta`
Represents a `<meta>` tag.

```zig
pub const Meta = struct { ... };
```

#### `Link`
Represents a `<link>` tag.

```zig
pub const Link = struct { ... };
```

#### `Custom`
Represents a Web Components custom element.

```zig
pub const Custom = struct { ... };
```

#### `Form`
Represents a `<form>` element.

```zig
pub const Form = struct { ... };
```

#### `Input`
Represents an `<input>` element.

```zig
pub const Input = struct { ... };
```

#### `TableCol`
Represents a `<col>` or `<colgroup>` element.

```zig
pub const TableCol = struct { ... };
```

#### `TableHead`
Represents a `<th>` element.

```zig
pub const TableHead = struct { ... };
```

#### `TableData`
Represents a `<td>` element.

```zig
pub const TableData = struct { ... };
```

## Usage Example
```zig
const myElement = createElement(.img);
std.debug.print("Tag name: {}", .{myElement.getTagName()});
```

## See Also
- [HTML Module](html.md)

