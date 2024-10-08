const z = @import("zframe");
const node = z.node;
const c = @import("components");

pub fn Layout(page: node.Node) node.Node {
    const div = node.createNode(.div);
    const raw = node.createNode(.raw);
    return div.init(.{
        raw.init(.{
            \\ <script>
            \\ var con = new WebSocket("ws://localhost:5555")
            \\ con.onopen = function(event) {
            \\ con.onmessage = function(event) {
            \\ window.location.reload();
            \\ }
            \\ }
            \\ </script>
        }),
        div.setClass("").init(.{
            page,
        }),
    });
}
