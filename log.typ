= Work log in Zig Web Frontend Framework

== What to write this.
- Y
write about what I did.
- W
write about what I noticed and learned.
- T
write about what I will do next.

= Week 1
== Y
=== Server
- handle SIGINT
if catch SIGINT, a server kill it own process.\
-> we can start the server soon after we stoped the server.
=== Frontend
- introduce Node structure (multi-node tree)
Node has child node information and Element structure.
-> Separate responsiblity for managing child nodes and storing HTML elements
- Changed the single pointer of Element.child to std.ArrayList.
HTML element could have only one child element, but now it could have any number of them.
However, I faced a mysterious error: when I increased the number of child elements to a certain number, render() did not work at all.
=== Wasm
- Found a library to manipulate DOM structure libraries in Zig.
If I ever decide to implement SSR or CSR, this library will be very useful.
== W
- How to handle signal.
- The Importance of Separating Responsibility
== T
- Web server hot-reload support
- Investigating a Mysterious Bug
