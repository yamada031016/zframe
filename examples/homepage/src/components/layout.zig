const z = @import("zframe");
const node = z.node;
const c = @import("components");
const Header = c.header.Header;
const Footer = c.footer.Footer;

pub fn Layout(page: node.Node) node.Node {
    const div = node.createNode(.div);
    return div.init(.{
        div.setClass("").init(.{
            Header(),
            page,
        }),
        div.setClass("mt-4").init(.{Footer()}),
    });
}
