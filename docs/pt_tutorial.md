# zframe Tutorial 🚀

Bem-vindo ao mundo do **zframe**! Neste tutorial, você aprenderá a criar aplicações web usando o zframe.

## O que é o zframe?

zframe é um **framework experimental de frontend web** desenvolvido em **Zig**. Ele aproveita os Web Components e permite integração perfeita com WebAssembly, mantendo-se leve e eficiente!

Ao contrário de outros frameworks, o zframe é desenvolvido inteiramente em **Zig puro**, o que significa que você pode compilá-lo usando apenas o toolchain do Zig. No entanto, para tornar o desenvolvimento mais conveniente, também há uma [ferramenta de linha de comando (CLI)](https://github.com/yamada031016/zframe-dev-utils) disponível.

### Quer aprender Zig?

O Zig ainda não alcançou a versão 1.0 e frequentemente sofre mudanças drásticas. Mantenha-se atualizado com esses recursos:

- [Site Oficial do Zig](https://ziglang.org/ja-JP/)
- [Repositório da Linguagem Zig](https://github.com/ziglang/zig)
- [Referência da Linguagem Zig](https://ziglang.org/documentation/master/)
- [Documentação da API Zig](https://ziglang.org/documentation/master/std/#)
- [zig.guide](https://zig.guide/)
- [ziglings (Exercícios práticos)](https://codeberg.org/ziglings/exercises/)

---

# 🚀 Configuração

### 1. Instalar o Zig
Primeiro, instale o Zig!

🔗 [Guia de Introdução ao Zig](https://ziglang.org/learn/getting-started/)

### 2. Configurar a CLI do zframe (Opcional)

```sh
cd zframe/zframe-cli
zig build -Doptimize=ReleaseSmall
```

Para facilitar o uso da CLI, defina um alias:
```sh
echo "alias zframe = <seu diretório>/zframe-dev-utils/zig-out/bin/zfc" >> ~/.bashrc
```

Verifique se a CLI está funcionando:
```sh
zfc help
```

### 3. Criar um Projeto

```sh
zfc init zframe-tutorial
```

Ou clone um projeto de exemplo:

```sh
git clone https://github.com/yamada031016/zframe-hello-world
mv zframe-hello-world zframe-tutorial
cd zframe-tutorial
rm -rf .git
```

Agora que seu projeto está pronto, vamos compilá-lo!

```sh
zfc build serve
```

Alternativamente:
```sh
zig build run
<seu-servidor-web> <caminho-do-html(zig-out/html)>
```

---

# 🎨 Criando um Site

## 📄 Adicionando uma Nova Página

Coloque os componentes da página na pasta `src/pages`, e eles serão roteados automaticamente! Por exemplo, criar `pages/about.zig` tornará a página acessível em `localhost:porta/about`.

### Vamos Criar uma Página Sobre!

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

## 🎨 Estilização

Atualmente, **somente Tailwind (Play CDN)** é suportado.
**Suporte para CSS está planejado para o futuro**, então fique ligado!

---

# 🔥 Sistema de Componentes

No zframe, os componentes são colocados em `src/components` e registrados em `components/components.zig` para reutilização.

### 🔗 Adicionando Navegação

Primeiro, crie um componente `NavList`.

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

Não se esqueça de registrá-lo!

#### `components/components.zig`
```zig
pub const NavList = @import("navList.zig").NavList;
```

Agora, vamos adicioná-lo a uma página!

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

## 📌 Criando um Componente de Layout

Para gerenciar estruturas comuns entre as páginas, vamos criar um **componente de layout**!

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

O zframe torna fácil criar **Web Components**!
Use `.custom` para gerar um `Node` e `define` para atribuir um nome único.

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

# 🛠 WebAssembly

O zframe é perfeito para aproveitar o WebAssembly!
Fique ligado para mais guias sobre usos avançados.

Agora é hora de trazer suas ideias à vida e construir um site incrível! 🚀

