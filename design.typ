#let backCard = rect( width: 210mm - 40mm, height: 297mm - 40mm, fill: rgb("#F652A0") )

#set page(
background: backCard,
foreground: [
#place(
  top + left,
  square(
    size: 100pt,
    fill:  rgb("#4C5270"),
  ),
),
#place(
  bottom + right,
  square(
    size: 100pt,
    fill:  rgb("#4C5270"),
  ),
)
]
)
#v(20%)
#h(10%)
#text(size: 32pt,weight: "bold",style: "italic", fill: white)[zFrame Design Doc]
#linebreak()
#h(80%)
#text(size: 20pt,style: "italic", fill: white)[ver1.0]
#linebreak()

#set page(numbering: "- 1 -", 
header: [
#set text(10pt,fill: rgb("#F652A0"))
#smallcaps[Design Doc]
#h(1fr) #smallcaps[SecHack365]
],
background: none,
foreground: none,
)
#pagebreak()
#outline()

#counter(page).update(1)
#pagebreak()
#set heading(numbering: "1.a")

= 目的
Zig言語とWebAssemblyを活用した高速で安全なWeb開発を支援する

= 背景
Webアプリケーションがますます普及し高度化が進む中、これらの要求に応じる開発手法の発展が望まれている。\
JavaScriptよりも速く安全な実行方法としてWebAssembly(Wasm)が登場したが、未だ一般に普及しているとは言えない。\
この原因として大きく2つが考えられる。\
- Wasmのサイズが大きいと読み込み時間が長くなり望まれた実行速度を達成できない
- Wasm開発の障壁が高い上、既存のWeb開発への統合が確立されていない
本フレームワークはこれらの解決を目指す。\
前者は"高速・省メモリ・省サイズ"の特徴を持つZig言語により読み込み時間を最小化することで解決する。\
後者はWasmとWebサイトを一括で開発する仕組みにより解決する。

= 構成
本フレームワークは3つの要素によって構成される。\
これらは内部的な区分であり、一般の使用では意識しないことに注意されたい。\
+ Frontend
+ Wasm
+ Web Server
FrontendはWebサイト開発を行うもので{後で名付けるライブラリ群}が該当する。\
WasmはWasm開発の統合を行うもので{後で名付けるライブラリ}が該当する。\
Web Serverは生成されたWebサイトの配信を行うものであり、{後で名付けるサーバー名}が該当する。

= Frontend
== 構成
= WebAssembly
== 構成
= Web Server
== 構成
= 参考文献
= 改定記録
