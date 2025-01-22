const z = @import("zframe");
const node = z.node;
const c = @import("components");
const Header = c.header.Header;
const Footer = c.footer.Footer;

pub fn Layout(page: node.Node) node.Node {
    const div = node.createNode(.div);
    const body = node.createNode(.body);
    return body.setClass("bg-white text-gray-900 font-sans dark:bg-gray-900 dark:text-gray-200 dark:font-sans").init(.{
        Header(),
        div.setClass("").init(.{
            page,
        }),
        div.setClass("mt-4").init(.{Footer()}),
    });
}
