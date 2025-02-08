# zframe チュートリアル 🚀

ようこそ、**zframe** の世界へ！このチュートリアルでは、zframe を使って Web アプリケーションを作る方法を学びます。

## zframe って何？

zframe は **Zig** で開発された実験的な Web フロントエンドフレームワークです。Web Components を活用しながら、
軽量かつ効率的に WebAssembly を組み込めるのが特徴です！

他のフレームワークと違って、zframe は **純粋な Zig 言語** で開発されています。そのため、Zig のツールチェインだけで
ビルドが可能ですが、より快適に開発できるように [便利な CLI ツール](https://github.com/yamada031016/zframe/zframe-cli) も用意しています。

### Zig を学ぶならこちら！

Zig はまだ v1.0 に到達しておらず、破壊的変更が頻繁に発生します。
そのため、以下の資料を活用しつつ、最新情報に注意してください！

- [Zig 公式サイト](https://ziglang.org/ja-JP/)
- [Zig 言語リポジトリ](https://github.com/ziglang/zig)
- [Zig 言語リファレンス](https://ziglang.org/documentation/master/)
- [Zig API ドキュメント](https://ziglang.org/documentation/master/std/#)
- [zig.guide](https://zig.guide/)
- [ziglings (練習問題)](https://codeberg.org/ziglings/exercises/)

---

# 🚀 セットアップ

### 1. Zig のインストール
まずは Zig をインストールしましょう！

🔗 [Zig の Getting Started ガイド](https://ziglang.org/learn/getting-started/)

### 2. zframe CLI のセットアップ（オプション）

```sh
cd zframe/zframe-cli
zig build -Doptimize=ReleaseSmall
```

CLI をより便利に使うためのエイリアスも設定できます。
```sh
echo "alias zframe = <your dir>/zframe/zframe-cli/zig-out/bin/zfc" >> ~/.bashrc
```

CLI の動作確認をしましょう！
```sh
zfc help
```

### 3. プロジェクトの作成

```sh
zfc init zframe-tutorial
```

または、サンプルプロジェクトをクローンすることもできます！

```sh
git clone https://github.com/yamada031016/zframe-hello-world
mv zframe-hello-world zframe-tutorial
cd zframe-tutorial
rm -rf .git
```

プロジェクトができたら、早速ビルドしてみましょう！

```sh
zfc build serve
```

もしくは、
```sh
zig build run
<your-webserver> <html dir path(zig-out/html)>
```

---

# 🎨 Web サイトの作成

## 📄 新しいページの追加

`src/pages` フォルダにページコンポーネントを追加すると、そのままルーティングされます！
たとえば `pages/about.zig` を作成すると、 `localhost:port/about` でアクセスできます。

### About ページを作ってみよう！

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

---

## 🎨 スタイリング

現時点では **Tailwind(Play CDN)** にのみ対応しています。
将来的には **CSS にも対応予定** なので、お楽しみに！

---

# 🔥 コンポーネントシステム

zframe では `src/components` にコンポーネントを作成し、
それを `components/components.zig` に登録することで再利用できます。

### 🔗 ナビゲーションを追加しよう！

まずは `NavList` コンポーネントを作成します。

#### `components/navList.zig`
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

登録も忘れずに！

#### `components/components.zig`
```zig
pub const NavList = @import("navList.zig").NavList;
```

そして、ページに追加してみましょう！

#### `pages/about.zig`
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

---

## 📌 レイアウトコンポーネントを作る

各ページで共通の部分を **レイアウトコンポーネント** にまとめましょう！

#### `components/layout.zig`
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

---

## 🌍 Web Components

zframe では **Web Components** も簡単に作成できます！
`.custom` で `Node` を生成し、`define` でユニークな名前を指定しましょう。

#### `allRed.zig`
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

---

<!--# 🛠 WebAssembly-->
<!--zframe は WebAssembly を活用するのにピッタリ！-->
<!--今後、より便利な使い方も紹介していきます。-->
<!--さあ、あなたのアイデアで最高の Web アプリを作りましょう！🚀-->
