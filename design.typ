#let backCard = rect( width: 210mm - 40mm, height: 297mm - 40mm, fill: rgb("#F652A0") )

#set document(title:[Zframe Design Doc])
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
#set text(10pt,fill: rgb("#4C5270"))
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
#set heading(numbering: "1.1")

= 目的
Zig言語の持つ型システムと表現力の高い言語仕様及び生成される効率的なバイナリとWebAssemblyを活用した高速で安全なWeb開発を支援する\
== 目的でないもの
動的なレンダリング(CSR, SSR)機能

= 背景
Webアプリケーションがますます普及し高度化が進む中、これらの要求に応じる開発手法の発展が望まれている。\
JavaScriptよりも速く安全な実行方法としてWebAssembly(Wasm)が登場したが、未だ一般に普及しているとは言えない。\
この原因として大きく2つが考えられる。\
- Wasmのサイズが大きいと読み込み時間が長くなり望まれた実行速度を達成できない
- Wasm開発の障壁が高い上、既存のWeb開発への統合が容易でない
本フレームワークはこれらの解決を目指す。\
前者は"高速・省メモリ・省サイズ"の特徴を持つZig言語により読み込み時間を最小化することで解決する。\
後者はWasmとWebサイトを一括で開発する仕組みにより解決する。

= 概要
Zig言語の型システムと言語機能を活用した静的サイトジェネレータ

= 構成
本フレームワークは4つの要素によって構成される。\
+ Frontend
+ Wasm
+ Web Server
+ Development Utilities
FrontendはWebサイト開発を行うもので{後で名付けるライブラリ群}が該当する。\
WasmはWasm開発の統合を行うもので{後で名付けるライブラリ}が該当する。\
Web Serverは生成されたWebサイトの配信を行うものであり、{後で名付けるサーバー名}が該当する。\
Development Utilitiesは開発を支援するツール群であり、自動ビルドとプレビュー機能などが含まれる.

= Frontend
関数型的にDOM構造体を記述してWebサイトを構築する.\
HTMLエレメントを表す構造体ElementまたはElementを返却する関数をコンポーネントと呼ぶ.\
== 構成
コンポーネントとなる構造体とそれを解釈してDOMを描画するレンダリングの2つからなる.
=== レンダリング
render()関数によってHTML/CSSを生成する.\
引数としてNode構造体を受け取り、規則に則りHTML/CSSを描画する.\
引数は柔軟なDOM構造のために匿名構造体として定義し、render()内で引数の型を識別して処理を分岐する.
=== コンポーネント
==== Node構造体
DOMノードを表す構造体でリストとして定義されている.\
子要素の管理を担い、HTML要素の表現はElement構造体が担っているので注意されたい.
データとしてElement構造体を構造体の要素として持ち、ポインタ要素としてElement構造体の子要素を持つ.\
==== Element構造体
HTMLエレメントの総称として定義された構造体である.\
divやpタグなど任意のエレメントは列挙型Enumのhtml.TagをcreateElement()に引数として渡すことで生成して使用する.\
普段ユーザーはNode構造体をDOM構築のインターフェイスとして使用するため、Element構造体を意識する必要はない.
= WebAssembly
実行に必要なJavaScriptのグルーコードを生成して適した箇所に挿入する.\
Web APIの代替等の用途を想定している.
== Wasm生成
あるフォルダー(/wasmなどを想定)内のzigファイルをwasmにコンパイルすることで生成する.
また、機能ごとにwasmファイルを生成するため、規則を導入予定.
例えば、機能ごとにファイルに分け、それらを個別にコンパイルするなど(hash.zig -> hash.wasm, hello.zig ->hello.wasm)
== グルーコード生成
コンパイル時に予め生成したWasmファイルを解析し、必要なモジュールをimportしたり、メモリを確保するなどを把握する.
== 構成
= Web Server
Webページ及びWasmを配信する.\
効率的なWasm配信に適したものを開発する.
== 構成
= 参考文献
= 改定記録
