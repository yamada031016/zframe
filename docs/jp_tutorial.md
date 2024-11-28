# zframe チュートリアル
このチュートリアルでは、zframeでWebアプリケーションを作成する方法を学びます。
zframeはZig言語による実験的なWebフロントエンドフレームワークです。Web Componentsを含む独自のコンポーネントシステムやビルドシステムを持ち、WebAssemblyを手軽に活用することができます。
zframeは純粋なZig言語で開発されているためzigツールチェインのみでビルドできますが、より利便性の高い[開発者支援CLIツール](https://github.com/yamada031016/zframe-dev-utils)が用意されています。

Zig言語については以下の資料が役に立つでしょう。
Zig言語はv1に達しておらず、破壊的変更を恐れていません。
資料の記述が最新でない可能性があるためご注意ください。
- [Zig言語公式サイト](https://ziglang.org/ja-JP/)
- [Zig言語リポジトリ](https://github.com/ziglang/zig)
- [Zig言語リファレンス](https://ziglang.org/documentation/master/)
- [Zig言語APIドキュメント](https://ziglang.org/documentation/master/std/#)
- [zig.guide](https://zig.guide/)
- [ziglings](https://codeberg.org/ziglings/exercises/)

## セットアップ
### インストール
zigのインストールは以下を参照してください。
[Geting Started](https://ziglang.org/learn/getting-started/)

zframe CLIのビルド（任意）
```sh
git clone https://github.com/yamada031016/zframe-dev-utils.git
cd zframe-dev-utils
zig build -Doptimize=ReleaseSmall
```
zframe CLIのaliasを設定（任意）
```sh
echo "alias zframe = <your dir>/zframe-dev-utils/zig-out/bin/zframe > ~/.bashrc
```
zframe CLIの動作確認（任意）
```sh
zframe help
```
### プロジェクト作成
```sh
zframe init zframe-tutorial
```
または
```sh
git clone https://github.com/yamada031016/zframe-hello-world
mv zframe-hello-world zframe-tutorial
cd zframe-tutorial
rm -rf .git
```
プロジェクトが作成できたので、ビルドをしてみましょう！
```sh
zframe build serve
```
または
```sh
zig build run
<your-webserver> <html dir path(zig-out/html)>
```
## Webサイトの作成
### 新しいページの追加
ページコンポーネントは`src/pages`に配置します。配置したとおりにルーティングされます。例）`pages/about.zig` -> `localhost:port/about`

Aboutページを作成していきましょう。

`pages/about.zig`
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
### スタイリング
現在、Tailwind(Play CDN)のみ対応しています。
将来的にCSSに対応する予定です。
### コンポーネントシステム
`src/components`にコンポーネントを配置します。作成したコンポーネントは`components/components.zig`に登録する必要があります。
#### リンク
indexページとaboutページにナビゲーションを追加しましょう。
NavListコンポーネントを作成します。

`components/navList.zig`
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
NavListコンポーネントを登録します。

`components/components.zig`
```zig
~~~
pub const NavList = @import("navList.zig").NavList;
```
2つのページで使ってみましょう。例）`pages/about.zig`
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
#### レイアウトコンポーネントの作成
各ページコンポーネントの共通部分をレイアウトコンポーネントに定義しましょう。
`components/layout.zig`を編集し、NavListを追加します。
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
#### Headコンポーネントの作成
`components/head.zig`を編集し、サイトの説明文を変更しましょう。
```zig
pub fn Head(page_name: []const u8, contents: anytype) node.Node {
    const raw = node.createNode(.raw);
    const head = node.createNode(.head);
    const title = node.createNode(.title);
    const meta = node.createNode(.meta);
    const empty = node.createNode(.empty).init(.{});

    return head.init(.{
        title.init(.{page_name}),
        meta.init(.{ .description, "zFrame is Zig Web Frontend Framework." }), // fill in here!
        meta.init(.{ .charset, "utf-8" }),
        raw.init(.{
            \\<script src="https://cdn.tailwindcss.com"></script>
        }),
        empty.iterate(contents),
    });
}
```
## Web Components
通常のHTML要素と同じようにWeb Componentsを作成できます。
`.custom`でNodeを生成し、`define`で一意な名前を指定します。

TODO:CSSに対応してから全称セレクタで真っ赤に変更する

`allRed.zig`
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
## WebAssembly
