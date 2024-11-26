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
ページコンポーネントは`src/pages`に配置します。
Aboutページを作成していきましょう。
```zig

```
### スタイリング
### コンポーネントシステム
#### リンク
indexページとaboutページにナビゲーションを追加しましょう。
NavListコンポーネントを作成します。
```zig:components/navList.zig
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
```zig:components/components.zig
~~~
pub const NavList = @import("navList.zig").NavList;
```
2つのページで使ってみましょう。
```zig
~~~
c.NavList(),
```
#### レイアウトコンポーネントの作成
各ページコンポーネントの共通部分をレイアウトコンポーネントに定義しましょう。
```zig
```
#### Headコンポーネントの作成
## Web Components
### Web Componentsの作成
## WebAssembly
### WebAssemblyの活用
