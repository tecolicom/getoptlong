# もう bash で getopts は使わない

## はじめに

Bashスクリプトでコマンドラインオプションを解析する際、標準の`getopts`や`getopt`では機能が限られていて困ったことはありませんか？

- `getopts`では長いオプション（`--verbose`）が使えない
- `getopts`ではオプションと引数の順序が固定されている
- `getopt`を使えばオプションと引数の混在は可能だが、結局自分で解析が必要
- 配列やハッシュ型の引数が扱えない
- ヘルプメッセージを手動で作成する必要がある

そんな悩みを解決してくれるのが**getoptlong.sh**です。この記事では、Bashスクリプトのオプション解析を次のレベルに引き上げてくれるライブラリの使い方を詳しく解説します。

## getoptlong.shの特徴

getoptlong.shは以下の機能を提供します：

- **GNU形式の長いオプション**サポート（`--help`, `--verbose`など）
- **柔軟なオプション順序**（PERMUTEモード）
- **豊富なデータ型**（フラグ、必須引数、省略可能な引数、配列、ハッシュ）
- **バリデーション機能**（整数、浮動小数点、正規表現）
- **コールバック関数**による柔軟な処理
- **自動ヘルプメッセージ生成**
- **複数回呼び出し**によるサブコマンド対応

## 基本的な使い方

### 1. ワンライナー形式（推奨）

最もシンプルな使い方から始めましょう：

```bash
#!/usr/bin/env bash

declare -A OPTS=(
    [verbose|v]=
    [file|f:]=
    [count|c:]=5
)

# PATHにgetoptlong.shがあれば、パスを指定する必要はありません
. getoptlong.sh OPTS "$@"

echo "verbose: $verbose"
echo "file: $file" 
echo "count: $count"
echo "remaining args: $@"
```

これだけで以下のようなオプション解析が可能になります：

```bash
$ ./myscript.sh --verbose -f input.txt --count 10 arg1 arg2
verbose: 1
file: input.txt
count: 10
remaining args: arg1 arg2
```

### 2. 段階的な方法

より細かい制御が必要な場合は、段階的に処理できます：

```bash
#!/usr/bin/env bash

declare -A OPTS=(
    [output|o:]=output.txt
    [format|f:]=json
    [verbose|v]=
)

# ライブラリの読み込み
. getoptlong.sh

# 初期化
getoptlong init OPTS

# 解析実行
getoptlong parse "$@"

# 変数の設定
eval "$(getoptlong set)"

# 使用
echo "Output: $output"
echo "Format: $format"
echo "Verbose: $verbose"
```

## オプション定義の詳細

### オプション定義の構文

```
[option_name|alias TYPE MODIFIER VALIDATION # description]=initial_value
```

各部分の説明：

- **option_name**: 長いオプション名（`--option-name`）
- **alias**: 短いオプション名（`-o`）
- **TYPE**: データ型（`+`, `:`, `?`, `@`, `%`）
- **MODIFIER**: 特殊な動作（`!`, `>`）
- **VALIDATION**: バリデーション（`=i`, `=f`, `=(正規表現)`）
- **description**: ヘルプメッセージ用の説明
- **initial_value**: 初期値

### データ型の種類

#### フラグオプション（`+`または省略）

```bash
declare -A OPTS=(
    [verbose|v]=          # フラグ
    [debug|d]=0           # カウンター（初期値0）
)

# 使用例
$ ./script.sh -v --debug --debug
# verbose=1, debug=2
```

#### 必須引数（`:`）

```bash
declare -A OPTS=(
    [file|f:]=
    [output|o:]=result.txt
)

# 使用例
$ ./script.sh --file input.txt
```

#### 省略可能な引数（`?`）

```bash
declare -A OPTS=(
    [compress|c?]=      # 引数は省略可能
)

# 使用例
$ ./script.sh --compress          # compress=""
$ ./script.sh --compress=9        # compress="9"
```

#### 配列オプション（`@`）

```bash
declare -A OPTS=(
    [include|i@]=
)

# 使用例
$ ./script.sh -i "*.txt" --include "*.md"
# include=("*.txt" "*.md")
```

#### ハッシュオプション（`%`）

```bash
declare -A OPTS=(
    [define|D%]=
)

# 使用例
$ ./script.sh --define key1=value1 -D key2=value2
# define[key1]="value1", define[key2]="value2"
```

## 高度な機能

### バリデーション

```bash
declare -A OPTS=(
    [port|p:=i]=8080                      # 整数
    [rate|r:=f]=1.5                       # 浮動小数点
    [email|e:=(^[^@]+@[^@]+\.[^@]+$)]=    # 正規表現
)
```

正規表現バリデーションでは、パターンを括弧で囲みます。

### コールバック関数

getoptlong.shでは、オプション名に`!`を付けることで、そのオプション名と同じ名前の関数が自動的に呼び出されます：

```bash
#!/usr/bin/env bash

# コールバック関数を定義
trace() { 
    [[ $2 ]] && set -x || set +x 
}

declare -A OPTS=(
    [trace|x! # trace execution]=
    [verbose|v]=
)

. getoptlong.sh OPTS "$@"

# --trace が指定されると trace 関数が自動実行される
echo "This will be traced if --trace was specified"
```

### パススルー機能

他のコマンドに引数を渡したい場合：

```bash
declare -A OPTS=(
    [docker-opts|d:>docker_args]=
    [verbose|v]=
)

. getoptlong.sh OPTS "$@"

# docker_argsに収集されたオプションを使用
docker run "${docker_args[@]}" ubuntu
```


## ヘルプメッセージの自動生成

getoptlong.shは自動的にヘルプオプション（`--help`, `-h`）を追加し、オプション定義からヘルプメッセージを生成します：

```bash
declare -A OPTS=(
    [verbose|v # 詳細な出力を有効にする]=
    [file|f: # 入力ファイルのパス]=
    [count|c: # 繰り返し回数]=5
)

. getoptlong.sh OPTS "$@"
```

```bash
$ ./script.sh --help
Usage: script.sh [options]

Options:
  -c, --count <arg>      繰り返し回数 (default: 5)
  -f, --file <arg>       入力ファイルのパス
  -h, --help             show help
  -v, --verbose          詳細な出力を有効にする
```

注意：ヘルプメッセージのオプションはアルファベット順にソートされて表示されます。

## 実践例：repeat.shスクリプト

実際のユースケースとして、コマンドを指定回数繰り返し実行するスクリプトを見てみましょう。これはex/repeat.shを基にしています：

```bash
#!/usr/bin/env bash

set -eu

declare -A OPTS=(
    [ count     | c :=i # repeat count              ]=1
    [ sleep     | i @=f # interval time             ]=
    [ paragraph | p ?   # print newline after cycle ]=
    [ trace     | x !   # trace execution           ]=
    [ debug     | d     # debug level               ]=0
    [ message   | m %=(^(BEGIN|END)=) # print message at BEGIN|END ]=
)

# コールバック関数
trace() { [[ $2 ]] && set -x || set +x ; }

. "$(dirname $0)"/../getoptlong.sh OPTS "$@"

# デバッグ情報の表示
column=$(command -v column) || column=cat
(( debug >= 3 )) && dumpopt=(--all) filter=$column
(( debug >= 2 )) && getoptlong dump ${dumpopt[@]} | ${filter:-cat} >&2

# 最初の引数が数字の場合はカウントとして使用
[[ ${1:-} =~ ^[0-9]+$ ]] && count=$1 && shift

# メッセージ表示関数
message() { [[ -v message[$1] ]] && echo "${message[$1]}" || : ; }

# 実行開始
message BEGIN
for (( i = 0; $# > 0 && i < count ; i++ )) ; do
    (( debug > 0 )) && echo "# [ ${@@Q} ]" >&2
    "$@"
    if (( count > 0 )) ; then
        [[ -v paragraph ]] && echo "$paragraph"
        if (( ${#sleep[@]} > 0 )) ; then
            time="${sleep[$(( i % ${#sleep[@]} ))]}"
            (( debug > 0 )) && echo "# sleep $time" >&2
            sleep $time
        fi
    fi
done
message END
```

このスクリプトの使用例：

```bash
# 基本的な使用（dateコマンドを3回実行）
$ ./repeat.sh --count 3 date

# スリープ間隔を指定して実行
$ ./repeat.sh -c 5 --sleep 1.5 echo "Hello"

# 複数のスリープ間隔を指定（順番に使用される）
$ ./repeat.sh -c 4 --sleep 1 --sleep 2 --sleep 0.5 echo "Test"

# 各サイクル後に改行を追加
$ ./repeat.sh -c 3 --paragraph echo "Line"

# 開始・終了メッセージを指定
$ ./repeat.sh --message BEGIN="Starting process" --message END="Process complete" -c 2 date

# トレース実行（set -xが有効になる）
$ ./repeat.sh --trace -c 2 echo "Traced"

# デバッグレベルを指定
$ ./repeat.sh --debug 2 -c 3 echo "Debug mode"

# 数値を最初の引数として指定（countの代替）
$ ./repeat.sh 5 echo "Five times"
```

この例では、getoptlong.shの多くの機能が活用されています：

- **整数バリデーション** (`count`の`=i`)
- **浮動小数点バリデーション** (`sleep`の`@=f`)
- **配列オプション** (`sleep`で複数値を受け取り)
- **省略可能な引数** (`paragraph`の`?`)
- **コールバック関数** (`trace`の`!`)
- **ハッシュオプション** (`message`の`%`)
- **正規表現バリデーション** (`message`の`=(^(BEGIN|END)=)`)

## 他のオプション解析ライブラリとの比較

シェルスクリプト用のオプション解析ライブラリには複数の選択肢があります。主要なものと getoptlong.sh を比較してみましょう。

### 機能比較表

| 機能 | getopts | getoptions | argparse | getoptlong.sh |
|------|---------|------------|-----------|---------------|
| **対応シェル** | POSIX | POSIX | POSIX | Bash専用 |
| **長いオプション** | ❌ | ✅ | ✅ | ✅ |
| **サブコマンド** | ❌ | ✅ | ✅ | ✅ |
| **オプション順序** | 固定 | 柔軟 | 柔軟 | 柔軟(PERMUTE) |
| **データ型** | 文字列のみ | 文字列のみ | 基本型 | 豊富(配列,ハッシュ等) |
| **バリデーション** | ❌ | 限定的 | ✅ | ✅(正規表現対応) |
| **ヘルプ生成** | 手動 | 自動 | 自動 | 自動 |
| **コールバック** | ❌ | ✅ | ❌ | ✅ |
| **設定方法** | 手続き的 | 宣言的 | 宣言的 | 宣言的 |
| **学習コスト** | 低 | 中 | 中 | 中 |

### getoptlong.sh の特徴

#### :thumbsup: 利点

**Bashの機能を最大限活用**
- 連想配列を使った直感的なオプション定義
- Bashの配列機能をネイティブサポート
- Bashの変数展開や算術演算との自然な連携

**豊富なデータ型と機能**
```bash
# 他のライブラリでは実現困難な高度な機能
declare -A OPTS=(
    [config|c%=(^[A-Z_]+=.+$)]=  # ハッシュ + 正規表現バリデーション
    [files|f@=f]=                # 配列 + 浮動小数点バリデーション  
    [trace|t!]=                  # コールバック関数の自動実行
    [pass|p:>external_args]=     # パススルー機能
)
```

**ワンライナーでの簡単導入**
```bash
# 1行でフル機能のオプション解析
. getoptlong.sh OPTS "$@"
```

#### :thumbsdown: 制限事項

**ポータビリティの制約**
- Bash 4.0+ 必須（連想配列が必要）
- 他のシェル（sh, zsh, fish等）では動作しない
- 組み込みシステムなどでBashが使えない環境では利用不可

**学習コスト**
- 独自の構文（`[name|alias:type=validation]`）
- Bashの機能を理解している必要がある

### getoptions との比較

[getoptions](https://github.com/ko1nksm/getoptions) は POSIX 互換で軽量なライブラリです：

**getoptions の例**
```bash
parser() {
  setup   REST help:usage -- "Example script"
  flag    FLAG    -f --flag
  param   FILE    -F --file
  option  OPTION  -o --option on:"default"
}
eval "$(getoptions parser parse "$0")"
parse "$@"
eval "set -- $REST"
```

**getoptlong.sh の例**
```bash
declare -A OPTS=(
    [flag|f]=
    [file|F:]=
    [option|o?]=default
)
. getoptlong.sh OPTS "$@"
```

**比較ポイント**

| 観点 | getoptions | getoptlong.sh |
|------|------------|---------------|
| **ポータビリティ** | POSIX 互換 | Bash 専用 |
| **記述量** | やや多い | 簡潔 |
| **高度な機能** | 基本的 | 豊富（配列、ハッシュ、正規表現） |
| **Bash連携** | 限定的 | ネイティブ |
| **パフォーマンス** | 高速 | 中程度 |

### 選択の指針

**getoptlong.sh が適している場合：**
- Bash環境が確定している
- 豊富なデータ型が必要（配列、ハッシュ）
- 複雑なバリデーションが必要
- 開発効率を重視
- Bashの機能を活用したい

**他のライブラリが適している場合：**
- 複数のシェル環境で動作させたい
- 軽量性・高速性を重視
- ポータビリティが重要
- 既存のPOSIXスクリプトに組み込みたい

## まとめ

getoptlong.shを使うことで、Bashスクリプトでも本格的なコマンドラインツールと同等のオプション解析が可能になります。特に以下の点で従来の`getopts`から大幅に改善されます：

1. **開発効率の向上**: ワンライナーで高機能なオプション解析
2. **ユーザビリティの向上**: 長いオプション、自動ヘルプ、柔軟な引数順序
3. **保守性の向上**: 型安全性、バリデーション、構造化されたオプション定義

Bash専用という制約はありますが、その分Bashの機能を最大限活用できる設計になっています。複雑なBashスクリプトを書く際は、ぜひgetoptlong.shの導入を検討してみてください。スクリプトの品質とユーザー体験が大幅に向上するはずです。

## 参考リンク

- [getoptlong.sh GitHub リポジトリ](https://github.com/tecolicom/getoptlong)
- [getoptions GitHub リポジトリ](https://github.com/ko1nksm/getoptions)
- より詳細な例は`ex/`ディレクトリをご確認ください

---

## この記事について

この記事は[Claude Code](https://claude.ai/code)によって生成されたものをそのまま掲載しています。AIによるコード生成と技術文書作成の一例として、編集を加えることなく公開しています。