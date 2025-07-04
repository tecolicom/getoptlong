---
title: もう bash で getopts は一生使わなくていいと思う
tags:
  - bash
  - getopts
  - shell
  - unix
  - getoptlong
private: true
updated_at: ''
id: null
organization_url_name: null
slide: false
ignorePublish: false
---
## はじめに

Bashスクリプトでコマンドラインオプションを解析する際、`getopts`や`getopt`が定番の選択肢です。しかし、これらを使った場合でも結局は一つ一つのオプションを手動で処理する必要があり、さらに以下のような問題に直面することがあります：

- `getopts`では長いオプション（`--verbose`）が使えない
- `getopts`ではオプションと引数の順序が固定されている
- `getopt`を使えばオプションと引数の混在は可能だが、結局自分で解析が必要
- 配列やハッシュ型の引数が扱えない
- ヘルプメッセージを手動で作成し、内容を正しく保つのに手間がかかる

そんな悩みを解決してくれるのが**getoptlong.sh**です。

この名前からも分かるように、getoptlong.shはPerlの[Getopt::Long](https://perldoc.perl.org/Getopt::Long)からインスパイアされています。Getopt::Longは、GNU getoptの長いオプション記法をPerlで実装したライブラリで、宣言的なオプション定義や豊富なデータ型などの機能を提供しています。そのアイデアは他の言語にも広がり、PythonのargparseやRubyのOptionParserなど、現代的なオプション解析ライブラリの基礎となっています。getoptlong.shは、このアイデアをBashで実現しようとするものです。

### AI音声解説

README（julesに書いてもらいました）をNotebookLMに読み込ませて、getoptlong.shについて音声で紹介してもらいました。NotebookLMの音声生成は噂には聞いていましたが、実際に試してみると想像以上の出来栄えで驚きました。AIとは思えないほど自然な会話形式で、なかなか面白い仕上がりになっています。

**⚠️ 注意**: AI生成コンテンツのため、内容に勘違いや間違った表現が含まれています。正確な情報については、この記事の内容をご参照ください。

[🎧 getoptlong.sh AI音声解説 (YouTube)](https://youtu.be/lOFMD60P1DU?si=7lE07elpsEmGj6dt)

## 実例で見るgetoptlong.shの機能

まず、実際のスクリプトを見てgetoptlong.shでどのようなことができるかを確認してください。以下は、コマンドを指定回数繰り返し実行する`repeat.sh`スクリプトです：

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

. getoptlong.sh OPTS "$@"

# メッセージ表示関数
message() { [[ -v message[$1] ]] && echo "${message[$1]}" || : ; }

# 実行開始
message BEGIN
for (( i = 0; $# > 0 && i < count ; i++ )) ; do
    "$@"
    if (( count > 0 )) ; then
        [[ -v paragraph ]] && echo "$paragraph"
        if (( ${#sleep[@]} > 0 )) ; then
            time="${sleep[$(( i % ${#sleep[@]} ))]}"
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
$ ./repeat.sh -i .3,.3,.6 -c 9 echo "Test"

# 各サイクル後に改行を追加
$ ./repeat.sh -c 3 --paragraph echo "Line"

# 開始・終了メッセージを指定
$ ./repeat.sh -m BEGIN=Hello,END=Bye -c 2 date

# トレース実行（set -xが有効になる）
$ ./repeat.sh --trace -c 2 echo "Traced"
```

このスクリプトに`-h`オプションを指定すると、次のようなヘルプが表示されます：

```bash
$ ./repeat.sh --help
repeat.sh [ options ] args
    --count=#        -c#      repeat count
    --debug          -d       debug level
    --help           -h       show HELP
    --message=#=#    -m#=#    print message at BEGIN|END
    --paragraph[=#]  -p       print newline after cycle
    --sleep=#[,#]    -i#[,#]  interval time
    --trace          -x       trace execution
```

このコードで実現されている機能：

- **整数バリデーション** (`count`の`:=i`)
- **浮動小数点配列** (`sleep`の`@=f`)
- **省略可能な引数** (`paragraph`の`?`)
- **コールバック関数** (`trace`の`!`)
- **ハッシュオプション** (`message`の`%`)
- **正規表現バリデーション** (`message`の`=(^(BEGIN|END)=)`)
- **自動ヘルプ生成**
- **カンマ区切り値サポート**

## getoptlong.shの特徴

getoptlong.shは以下の機能を提供します：

- **GNU形式の長いオプション**サポート（`--help`, `--verbose`など）
- **ショートオプションの連結**（`-abc`を`-a -b -c`として解釈）
- **否定形式**（`--no-verbose`でフラグオプションを無効化）
- **柔軟なオプション順序**（PERMUTEモード）
- **豊富なデータ型**（フラグ、必須引数、省略可能な引数、配列、ハッシュ）
- **バリデーション機能**（整数、浮動小数点、正規表現）
- **コールバック関数**による柔軟な処理
- **自動ヘルプメッセージ生成**
- **複数回呼び出し**によるサブコマンド対応

## 基本的な使い方

### 1. ワンライナー形式（推奨）

最もシンプルな使い方から始めましょう。このプログラムは、フラグ（`--verbose`）、ファイル指定（`--file`）、デフォルト値付きカウント（`--count`）の3つのオプションを持ちます：

```bash
#!/usr/bin/env bash

declare -A OPTS=(
    [ verbose | v  ]=
    [ file    | f: ]=
    [ count   | c: ]=5
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

説明文を指定しなくても、実用的なヘルプメッセージが自動生成されます。オプション定義から自動的に使用方法、各オプションの説明、デフォルト値まで表示してくれます：

```bash
$ ./myscript.sh -h
myscript.sh [ options ] args
    --count=#  -c#  set COUNT (default:5)
    --file=#   -f#  set FILE
    --help     -h   show HELP
    --verbose  -v   enable VERBOSE
```

### 2. 段階的な方法

より細かい制御が必要な場合は、段階的に処理できます：

```bash
#!/usr/bin/env bash

declare -A OPTS=(
    [ output  | o: ]=output.txt
    [ format  | f: ]=json
    [ verbose | v  ]=
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
    [ verbose | v ]=          # フラグ
    [ debug   | d ]=0         # カウンター（初期値0）
)

# 使用例
$ ./script.sh -v --debug --debug
# verbose=1, debug=2
```

#### 必須引数（`:`）

```bash
declare -A OPTS=(
    [ file   | f: ]=
    [ output | o: ]=result.txt
)

# 使用例
$ ./script.sh --file input.txt
```

#### 省略可能な引数（`?`）

```bash
declare -A OPTS=(
    [ compress | c? ]=      # 引数は省略可能
)

# 使用例
$ ./script.sh --compress          # compress=""
$ ./script.sh --compress=9        # compress="9"
```

#### 配列オプション（`@`）

```bash
declare -A OPTS=(
    [ include | i@ ]=
)

# 使用例
$ ./script.sh -i "*.txt" --include "*.md"
# include=("*.txt" "*.md")

# カンマ区切りで複数の値を一度に指定することも可能
$ ./script.sh -i "*.txt,*.md,*.sh"
# include=("*.txt" "*.md" "*.sh")
```

#### ハッシュオプション（`%`）

```bash
declare -A OPTS=(
    [ define | D% ]=
)

# 使用例
$ ./script.sh --define key1=value1 -D key2=value2
# define[key1]="value1", define[key2]="value2"

# カンマ区切りで複数のkey=valueペアを一度に指定することも可能
$ ./script.sh -D "key1=value1,key2=value2,key3=value3"
# define[key1]="value1", define[key2]="value2", define[key3]="value3"
```

### カンマ区切りでの複数値設定

配列オプション（`@`）やハッシュオプション（`%`）では、カンマ区切りで複数の値を一度に設定できます。これは`DELIM`設定によるもので、デフォルトでスペース、タブ、カンマが区切り文字として認識されます。

### 変数名の指定

デフォルトでは、オプション名から自動的に変数名が決まりますが、明示的に変数名を指定することもできます：

```bash
declare -A OPTS=(
    [ count  | c :COUNT=i ]=1        # countオプションの値をCOUNT変数に格納
    [ debug  | d +DEBUG   ]=0        # debugオプションの値をDEBUG変数に格納
    [ files  | f @FILES   ]=         # filesオプションの値をFILES配列に格納
    [ config | c %CONFIG  ]=         # configオプションの値をCONFIG連想配列に格納
)

. getoptlong.sh OPTS "$@"

echo "Count: $COUNT"
echo "Debug level: $DEBUG"
echo "Files: ${FILES[@]}"
echo "Config keys: ${!CONFIG[@]}"
```

また、`PREFIX=opt_`のようにコンフィグオプションを指定すれば、各オプション名の前に`opt_`をつけた変数が使われます。

### パススルーオプション

パススルー機能（`>`）を使うと、オプションとその値をそのまま配列に収集できます：

```bash
declare -A OPTS=(
    [ docker-opt | d :>docker_args ]=     # --docker-opt の値をdocker_args配列に収集
    [ verbose    | v               ]=
)

. getoptlong.sh OPTS "$@"

# 収集されたオプションを他のコマンドに渡す
docker run "${docker_args[@]}" ubuntu
```

複数のオプションを同じ配列にまとめることも可能です：

```bash
declare -A OPTS=(
    [ input  | i :>files ]=
    [ output | o :>files ]=
    [ config | c :>files ]=
)

. getoptlong.sh OPTS "$@"

# すべてのファイル関連オプションがfiles配列に収集される
echo "All file options: ${files[@]}"
```

## バリデーション

```bash
declare -A OPTS=(
    [ port    | p :=i              ]=8080     # 整数
    [ rate    | r :=f              ]=1.5      # 浮動小数点
    [ zipcode | z :=(^[0-9]{3}-[0-9]{4}$) ]=  # 正規表現（郵便番号）
)
```

正規表現バリデーションでは、パターンを括弧で囲みます。

## コールバック関数

getoptlong.shでは、オプション名に`!`を付けることで、そのオプション名と同じ名前の関数が自動的に呼び出されます。この時、関数にはオプション名（`$1`）と値（`$2`）が引数として渡されます：

```bash
#!/usr/bin/env bash

# コールバック関数を定義
trace() { 
    [[ $2 ]] && set -x || set +x 
}

declare -A OPTS=(
    [ trace   | x ! # trace execution ]=
    [ verbose | v                      ]=
)

. getoptlong.sh OPTS "$@"

# --trace が指定されると trace 関数が自動実行される
echo "This will be traced if --trace was specified"
```



## ヘルプメッセージの自動生成

getoptlong.shは自動的にヘルプオプション（`--help`, `-h`）を追加し、オプション定義からヘルプメッセージを生成します：

```bash
declare -A OPTS=(
    [ verbose | v  # 詳細な出力を有効にする ]=
    [ file    | f: # 入力ファイルのパス     ]=
    [ count   | c: # 繰り返し回数           ]=5
)

. getoptlong.sh OPTS "$@"
```

```bash
$ ./script.sh --help
script.sh [ options ] args
    --count=#  -c#  繰り返し回数
    --file=#   -f#  入力ファイルのパス
    --help     -h   show HELP
    --verbose  -v   詳細な出力を有効にする
```

注意：ヘルプメッセージのオプションはアルファベット順にソートされて表示されます。


## 他のオプション解析ライブラリとの比較

シェルスクリプト用のオプション解析ライブラリには複数の選択肢があります。なかでも注目すべきは [getoptions](https://github.com/ko1nksm/getoptions) で、これは POSIX 互換で複数シェル対応の軽量ライブラリです。外部コマンドに依存しない純粋なシェルスクリプト実装により、dash、bash、ksh、zshなど幅広いシェルで動作します。

主要なライブラリと getoptlong.sh を比較してみましょう。

### 機能比較表

| 機能 | getopts | getoptions | getoptlong.sh |
|------|---------|------------|---------------|
| **対応シェル** | POSIX | POSIX | Bash専用 |
| **長いオプション** | ❌ | ✅ | ✅ |
| **ショートオプション連結** | ✅ | ✅ | ✅ |
| **否定形式** | ❌ | ✅ | ✅ |
| **+で始まるオプション** | ❌ | ✅ | ❌ |
| **オプション名省略** | ❌ | ✅ | ❌ |
| **サブコマンド** | ❌ | ✅ | ✅ |
| **オプション順序** | 固定 | 柔軟 | 柔軟(PERMUTE) |
| **データ型** | 文字列のみ | 文字列のみ | 豊富(配列,ハッシュ等) |
| **バリデーション** | ❌ | 限定的 | ✅(正規表現対応) |
| **ヘルプ生成** | 手動 | 自動 | 自動 |
| **コールバック** | ❌ | ✅ | ✅ |
| **設定方法** | 手続き的 | 宣言的 | 宣言的 |
| **外部依存** | なし | なし | なし |
| **学習コスト** | 低 | 中 | 中 |

### オプション定義の比較

同じ機能を実現する場合の定義例を比較してみましょう：

**getoptions**
```bash
parser_definition() {
  setup   REST help:usage -- "Example script"
  flag    FLAG    -f --flag
  param   FILE    -F --file
  option  OPTION  -o --option init:="default"
}
eval "$(getoptions parser_definition) exit 1"
```

**getoptlong.sh**
```bash
declare -A OPTS=(
    [ flag   | f  ]=
    [ file   | F: ]=
    [ option | o? ]=default
)
. getoptlong.sh OPTS "$@"
```

getoptlong.sh の方がより簡潔で、連想配列による直感的な定義が特徴です。

### 各ライブラリの特徴と選択指針

#### getoptlong.sh の強み

- **Bashの機能をフル活用**: 連想配列、配列、ハッシュをネイティブサポート
- **豊富なデータ型**: 文字列、配列、ハッシュ、正規表現バリデーション、コールバック関数
- **簡潔な記述**: ワンライナーでフル機能のオプション解析が可能
- **高度な機能**: パススルー、変数名指定、カンマ区切り値など

```bash
# getoptlong.sh の例 - 簡潔で高機能
declare -A OPTS=(
    [ config | c %=(^[A-Z_]+=.+$) ]=  # ハッシュ + 正規表現バリデーション
    [ files  | f @=f              ]=  # 配列 + 浮動小数点バリデーション  
    [ trace  | t !                ]=  # コールバック関数の自動実行
)
. getoptlong.sh OPTS "$@"
```

#### getoptions の強み

- **POSIX互換**: 幅広いシェル環境で動作する高いポータビリティ
- **純粋シェルスクリプト**: 外部コマンドに依存しない軽量実装
- **高パフォーマンス**: 高速な解析処理
- **豊富なオプション**: +オプション、オプション名省略機能

#### 比較ポイント

| 観点 | getoptions | getoptlong.sh |
|------|------------|---------------|
| **ポータビリティ** | POSIX 互換 | Bash 専用 |
| **記述量** | やや多い | 簡潔 |
| **高度な機能** | 基本的 | 豊富（配列、ハッシュ、正規表現） |
| **Bash連携** | 限定的 | ネイティブ |
| **パフォーマンス** | 高速 | 中程度 |
| **実装方式** | 純粋シェルスクリプト | Bash特化 |

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

実はgetoptlong.sh内部では`getopts`を使っています。「一生使わない」と言いつつ、結局は裏で動いているということになりますが、重要なのはあなたが直接`getopts`と格闘する必要がもうないということです。どのように使っているかを見たい酔狂な人は、コードを読んでみてください。

## 参考リンク

- [getoptlong.sh GitHub リポジトリ](https://github.com/tecolicom/getoptlong)
- [getoptions GitHub リポジトリ](https://github.com/ko1nksm/getoptions)
- より詳細な例は`ex/`ディレクトリをご確認ください

### getoptions 関連記事
- [getoptions を使って面倒なシェルスクリプトのオプション解析コードを自動生成しよう！](https://qiita.com/ko1nksm/items/a007c73c549fbd493a17)
- [シェルスクリプト(bash等)の引数解析が究極的に簡単になりました](https://qiita.com/ko1nksm/items/9ee16927b7f8899c4a9e)
- [簡単に使えるエレガントなオプション解析ライブラリ（シェルスクリプト用）](https://qiita.com/ko1nksm/items/1bcc49bef56a5c245251)
- [シェルスクリプト オプション解析 徹底解説 (getopt / getopts)](https://qiita.com/ko1nksm/items/cea7e7cfdc9e25432bab)

---

## この記事について

この記事は[Claude Code](https://claude.ai/code)によって生成されたものをそのまま掲載しています。AIによるコード生成と技術文書作成の一例として、編集を加えることなく公開しています。
