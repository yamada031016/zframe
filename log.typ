= Zig Web Frontend Frameworkの作業ログ

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

= Week 2
== Y
=== Server
- support hot-reload
- search advanced web server.
- learn about HTTP/1.1
=== Frontend
- solved a misterious error.
- searched a principle of Axios
- searched state management 
=== Wasm
- thinked good ways to use wasm 

= Week 3
== Y
=== Server
- implemented HTTP/1.1
- learn about HTTP/2
=== Frontend
- considerate state management 
- learned about page component and router
=== Wasm
- considerate about JS gloo code.

= Week 4
== Y
=== Server
- considerated HTTP/2 implements
=== Frontend
- implemented simple state management.
- considerated about page component and router
=== Wasm
- considerated about simple Wasm api structure

= Week 5
== Y
=== Server
- implemented a part of HTTP/2
=== Frontend
- implemented page component and simple router
- mkdir pages and targets
- considerated about http fetch library
- learned about template system
=== Wasm
- implmented simple Wasm api system

= SecHack365 event 2
== Server
- full HTTP/1.1
- parts of HTTP/2
- hot-reload
== Frontend
- page and router
- complete component structure
- simple state management
== Wasm
- simple Wasm api system

= Week 6
== Y
=== Server
- implemented HTTP/2
=== Frontend
- developed simple http fetch library
- considered about template system
=== Wasm
- implmented multiple Wasm api systems

= Week 7
== Y
=== Server
- created 404 page and other important error message.
=== Frontend
- integrated simple http fetch library
- implemented template system
=== Wasm
- learned about good ways to distribute Wasm

= Week 7
== Y
=== Server
- improved log system
- learned about user configuration
=== Frontend
- implemented template system
=== Wasm
- learned about good ways to distribute Wasm
