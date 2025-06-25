# getoptlong.sh

`getoptlong.sh` is a Bash library for parsing command-line options in
shell scripts. It provides a flexible way to handle options including
followings.

- Clear and expressive option syntax
- Supports both short options (e.g., `-h`) and long options (e.g.,
  `--help`)
- Allows options and non-option arguments to be freely mixed on the
  command line (PERMUTE)
- Supports flag type incremental option as well as required arguments,
  optional arguments, array-type, and hash-type options
- Provides validation for integer, floating-point, and custom regular
  expression patterns
- Enables registration of callback functions for each option for
  flexible processing
- Supports multiple calls, which enables to use different options in
  subcommands or perform own option analysis within functions
- Automatic generation of help option and help messages. Help option
  is implemented without explicit definition. Help message is
  generated from the option definition.

## Table of Contents

- [1. はじめに (Introduction)](#1-はじめに-introduction)
- [2. 基本的な使い方 (Basic Usage)](#2-基本的な使い方-basic-usage)
  - [2.1. ライブラリの読み込み](#21-ライブラリの読み込み)
  - [2.2. オプション定義配列の作成](#22-オプション定義配列の作成)
  - [2.3. getoptlong の初期化](#23-getoptlong-の初期化)
  - [2.4. コマンドライン引数のパース](#24-コマンドライン引数のパース)
  - [2.5. パース結果の変数へのセット](#25-パース結果の変数へのセット)
  - [2.6. 変数へのアクセスと利用](#26-変数へのアクセスと利用)
- [3. オプション定義の詳細 (Detailed Option Definition)](#3-オプション定義の詳細-detailed-option-definition)
  - [3.1. 基本構文](#31-基本構文)
  - [3.2. オプションの型と型指定子](#32-オプションの型と型指定子)
    - [3.2.1. フラグオプション (接尾辞なし, または `+`)](#321-フラグオプション-接尾辞なし-または-)
    - [3.2.2. 必須引数オプション (':')](#322-必須引数オプション--)
    - [3.2.3. オプション引数オプション ('?')](#323-オプション引数オプション--)
    - [3.2.4. 配列オプション ('@')](#324-配列オプション--)
    - [3.2.5. ハッシュオプション ('%')](#325-ハッシュオプション--)
    - [3.2.6. コールバックオプション ('!')](#326-コールバックオプション--)
  - [3.3. 値のバリデーション](#33-値のバリデーション)
    - [3.3.1. 整数バリデーション (`=i`)](#331-整数バリデーション-i)
    - [3.3.2. 浮動小数点数バリデーション (`=f`)](#332-浮動小数点数バリデーション-f)
    - [3.3.3. カスタム正規表現バリデーション (`=(<regex>)`](#333-カスタム正規表現バリデーション-regex)
- [4. ヘルプメッセージの生成とカスタマイズ (Help Message Generation and Customization)](#4-ヘルプメッセージの生成とカスタマイズ-help-message-generation-and-customization)
  - [4.1. 自動ヘルプオプション](#41-自動ヘルプオプション)
  - [4.2. ヘルプメッセージの内容](#42-ヘルプメッセージの内容)
    - [4.2.1. オプションの説明文 (コメント `#`)](#421-オプションの説明文-コメント-)
    - [4.2.2. 型に基づく自動メッセージ](#422-型に基づく自動メッセージ)
    - [4.2.3. 初期値 (デフォルト値) の表示](#423-初期値-デフォルト値-の表示)
    - [4.2.4. フラグオプションのカウンターとしての扱い](#424-フラグオプションのカウンターとしての扱い)
  - [4.3. ヘルプメッセージ全体の書式](#43-ヘルプメッセージ全体の書式)
    - [4.3.1. 使用法 (Synopsis) のカスタマイズ (`USAGE` 設定)](#431-使用法-synopsis-のカスタマイズ-usage-設定)
    - [4.3.2. `getoptlong help` コマンドによる手動表示](#432-getoptlong-help-コマンドによる手動表示)
  - [4.4. ヘルプメッセージの構造](#44-ヘルプメッセージの構造)
- [5. 高度なトピック (Advanced Topics)](#5-高度なトピック-advanced-topics)
  - [5.1. コールバック関数の詳細](#51-コールバック関数の詳細)
    - [5.1.1. 通常のコールバック (後処理)](#511-通常のコールバック-後処理)
    - [5.1.2. 事前処理コールバック (`--before` / `-b`)](#512-事前処理コールバック---before---b)
    - [5.1.3. コールバック関数内でのエラー処理](#513-コールバック関数内でのエラー処理)
    - [5.1.4. コールバックを使ったカスタムバリデーション](#514-コールバックを使ったカスタムバリデーション)
  - [5.2. Destination の指定](#52-destination-の指定)
  - [5.3. オプションのパススルー機能](#53-オプションのパススルー機能)
  - [5.4. 実行時設定の変更 (`getoptlong configure`)](#54-実行時設定の変更-getoptlong-configure)
  - [5.5. 内部状態のダンプ (`getoptlong dump`)](#55-内部状態のダンプ-getoptlong-dump)
- [6. 外部コマンドとしての利用 (Standalone Usage)](#6-外部コマンドとしての利用-standalone-usage)
- [7. コマンドリファレンス (Command Reference)](#7-コマンドリファレンス-command-reference)
  - [7.1. `getoptlong init <opts_array_name> [CONFIGURATIONS...]`](#71-getoptlong-init-opts_array_name-configurations)
  - [7.2. `getoptlong parse "$@"`](#72-getoptlong-parse--)
  - [7.3. `getoptlong set`](#73-getoptlong-set)
  - [7.4. `getoptlong callback [-b|--before] <opt_name> [callback_function] ...`](#74-getoptlong-callback--b---before-opt_name-callback_function--)
  - [7.5. `getoptlong configure <CONFIG_PARAM=VALUE> ...`](#75-getoptlong-configure-config_paramvalue--)
  - [7.6. `getoptlong dump [-a|--all]`](#76-getoptlong-dump--a---all)
  - [7.7. `getoptlong help <SYNOPSIS>`](#77-getoptlong-help-synopsis)
- [8. 実践的な例 (Practical Examples)](#8-実践的な例-practical-examples)
  - [8.1. 必須オプションとオプション引数の組み合わせ](#81-必須オプションとオプション引数の組み合わせ)
  - [8.2. サブコマンドを持つスクリプト (簡易版)](#82-サブコマンドを持つスクリプト-簡易版)
  - [8.3. `ex/` ディレクトリのサンプルスクリプト](#83-ex-ディレクトリのサンプルスクリプト)
- [9. 設定キーの一覧 (Configuration Keys)](#9-設定キーの一覧-configuration-keys)
- [10. 関連情報 (See Also)](#10-関連情報-see-also)

## 1. はじめに (Introduction)
`getoptlong.sh` is a Bash library designed for parsing command-line options
within shell scripts. It offers a robust and flexible alternative to the
built-in `getopts` command, providing support for GNU-style long options,
option permutation, various argument types (required, optional, array, hash),
data validation, callback mechanisms, and automatic help message generation.
Its goal is to simplify the often complex task of command-line argument
processing in Bash, making scripts more user-friendly and maintainable.

## 2. 基本的な使い方 (Basic Usage)

`getoptlong.sh` を使ってスクリプトのコマンドラインオプションを処理するための基本的な手順は以下の通りです。

### 2.1. ライブラリの読み込み

まず、`getoptlong.sh` ファイルをスクリプト内から `source` コマンド (または `.` コマンド) を使って読み込みます。

```bash
. /path/to/getoptlong.sh # getoptlong.sh の実際のパスに置き換えてください
# または、getoptlong.sh が実行パスにあれば
# . getoptlong.sh
```

### 2.2. オプション定義配列の作成

次に、スクリプトで受け付けるオプションを Bash の連想配列として定義します。
配列名は任意ですが、慣習的に `OPTS` がよく使われます。 各オプションのキーの
書式や指定できる型については、「3. オプション定義の詳細」セクションを
参照してください。

```bash
declare -A OPTS=(
    [help      |h          # ヘルプメッセージを表示する ]=
    [verbose   |v+         # 詳細度を上げる (累積)     ]=0
    [output    |o:         # 出力ファイルを指定        ]=/dev/stdout
    [config    |c?         # 設定ファイルを指定 (任意) ]=
    [library   |L@         # ライブラリパスを追加      ]=()
    [define    |D%         # 変数を定義 (例: key=val)  ]=()
)
```
**注意:** ヘルプオプション (`--help`, `-h`) は、明示的に定義しなくても
`getoptlong.sh` によって自動的に追加され、ヘルプメッセージを表示して終了する
動作になります。この挙動は `HELP` 設定でカスタマイズ可能です (詳細は
「7.1. `getoptlong init ...`」および「4. ヘルプメッセージの生成とカスタマイズ」
を参照)。上記例のように明示的に定義することもできます。

### 2.3. getoptlong の初期化

定義したオプション配列を `getoptlong init` コマンドに渡して、ライブラリを初期化します。

```bash
getoptlong init OPTS
```
初期化時には、オプションのパース動作を制御する様々な設定パラメータを同時に指定することも
可能です。詳細は「7.1. `getoptlong init ...`」を参照してください。

例: オプション以外の引数を `ARGS` 配列に格納し、パースエラー時にスクリプトを終了させないようにする
```bash
declare -a ARGS # PERMUTE で指定する配列を事前に宣言しておくと良い
getoptlong init OPTS PERMUTE=ARGS EXIT_ON_ERROR=0
```

### 2.4. コマンドライン引数のパース

`getoptlong parse` コマンドにスクリプトの全引数 (`"$@"`) を渡して、定義に
基づいてコマンドライン引数をパースさせます。

```bash
if ! getoptlong parse "$@"; then
    # パースエラー時の処理 (EXIT_ON_ERROR=0 の場合)
    echo "引数のパースに失敗しました。" >&2
    getoptlong help "使用法: $(basename "$0") [オプション] 引数..." # エラー時にヘルプ表示
    exit 1
fi
```
`getoptlong parse` は、パースに成功した場合は終了コード `0` を、失敗した
場合は `0` 以外を返します。`EXIT_ON_ERROR` が `1` (デフォルト) の場合は、
パースエラー時に自動的にスクリプトが終了します。

### 2.5. パース結果の変数へのセット

`getoptlong parse` が成功した後、`getoptlong set` コマンドの出力を `eval` で
実行することで、パースされたオプションの値が対応するシェル変数に設定されます。

```bash
eval "$(getoptlong set)"
```
これにより、例えば `OPTS` 配列で `[output|o:]` と定義されたオプションが
`--output /tmp/out` として渡された場合、シェル変数 `$output` に `/tmp/out`
という値が設定されます。

*   フラグオプション (例: `[verbose|v]`) が指定されると、対応する変数 (例: `$verbose`) に `1` が設定されます。
*   カウンターオプション (例: `[debug|d+]`) が指定されると、指定された回数だけ変数値がインクリメントされます。
*   配列オプション (例: `[library|L@]`) の値は Bash 配列 (例: `"${library[@]}"`) に格納されます。
*   ハッシュオプション (例: `[define|D%]`) の値は Bash 連想配列 (例: `declare -A define_vars="${define[@]}"`) に格納されます。
*   オプション名に含まれるハイフン (`-`) は、変数名ではアンダースコア (`_`) に変換されます (例: `--long-option` は `$long_option`)。

### 2.6. 変数へのアクセスと利用

上記の手順で設定された変数をスクリプト内で利用して、オプションに基づいた処理を行います。

```bash
# ヘルプオプションが (自動または手動で) 処理された場合、
# 通常 getoptlong parse または getoptlong set の段階でスクリプトは終了しているが、
# 明示的にチェックすることもできる (カスタムヘルプ処理など)。
if [[ -n "${help:-}" ]]; then
    # (getoptlong help が呼ばれていれば通常ここには到達しない)
    # カスタムのヘルプ表示処理など
    exit 0
fi

echo "詳細出力レベル: ${verbose:-0}" # 未設定なら 0 を表示

if [[ "$output" != "/dev/stdout" ]]; then
    echo "出力先: $output"
fi

if [[ -n "${config:-}" ]]; then # config が空文字列または未設定でないか
    echo "設定ファイル: $config を読み込みます..."
    # source "$config" やその他の処理
elif [[ -v config ]]; then # config オプションが指定されたが値がない場合 (空文字列が設定される)
    echo "設定ファイルが指定されましたが、パスがありません。"
else
    echo "デフォルト設定を使用します。"
fi

if (( ${#library[@]} > 0 )); then
    echo "ライブラリパス:"
    for libpath in "${library[@]}"; do
        echo "  - $libpath"
    done
fi

if (( ${#define[@]} > 0 )); then
    echo "定義された変数:"
    for key in "${!define[@]}"; do
        echo "  - $key = ${define[$key]}"
    done
fi

# getoptlong init で PERMUTE=ARGS を指定した場合、
# オプション以外の引数が ARGS 配列に格納される。
# declare -a ARGS を事前にしておくこと。
if declare -p ARGS &>/dev/null && [[ "$(declare -p ARGS)" =~ "declare -a" ]]; then
    if (( ${#ARGS[@]} > 0 )); then
        echo "残りの引数 (${#ARGS[@]}個):"
        for arg in "${ARGS[@]}"; do
            echo "  - $arg"
        done
    fi
fi
```

## 3. オプション定義の詳細 (Detailed Option Definition)

`getoptlong.sh` で使用するコマンドラインオプションは、Bash の連想配列を用いて定義します。このセクションでは、その詳細な定義方法と、利用可能なオプションの型について説明します。

### 3.1. 基本構文

オプションは、連想配列のキーとして定義します。キーの文字列は以下の形式を取ります。

`[long_name|short_name <type_char>[<value_rule_char>][=<validation_type>]]`

そして、そのキーに対する値として、オプションの初期値を指定します。また、キー文字列の `#` 以降はコメントとして扱われ、自動生成されるヘルプメッセージの説明文として利用されます。

例:
```bash
declare -A OPTS=(
    # LONG NAME   SHORT NAME
    # |           | TYPE CHAR
    # |           | | VALUE RULE CHAR
    # |           | | | VALIDATION TYPE
    # |           | | | |   DESCRIPTION                 INITIAL VALUE
    # |           | | | |   |                           |
    [verbose    |v          # 詳細な情報を出力する      ]=
    [level      |l+         # ログレベルを設定 (累積)   ]=0
    [output     |o:         # 出力ファイルを指定        ]=/dev/stdout
    [mode       |m?         # 動作モード (省略可能)     ]=
    [include    |i@=s       # インクルードパス (複数可) ]=() # =s は文字列型を示す (実際にはバリデーション無し)
    [define     |D%         # 定義 (KEY=VALUE形式)    ]=()
    [execute    |x!         # コマンドを実行            ]=my_execute_function
    [count      |c:=i       # 処理回数 (整数)         ]=1
    [ratio      |r:=f       # 比率 (小数)             ]=0.5
    [id         |n:=(^[a-z0-9_]+$) # ID (英数字と_)    ]=default_id
)
```

*   **long_name:** `--` の後に続く長いオプション名 (例: `verbose`)。ハイフンを含むことも可能です (例: `very-verbose`)。
*   **short_name:** `-` の後に続く短いオプション名 (例: `v`)。通常は1文字です。
*   `long_name` と `short_name` は `|` (パイプ) で区切ります。どちらか一方のみを定義することも可能です。
*   **type_char (型指定子):** オプションが引数を取るか、どのように引数を扱うかなどを指定します。詳細は後述します。
*   **value_rule_char (値規則指定子):** (現在は `+` のみ。主にフラグ用)
*   **validation_type (バリデーション型):** 引数の値を検証する型を指定します。詳細は後述します。`=s` は文字列を示しますが、実質的にはバリデーションなしと同じです。
*   **description (説明文):** `#` の後に記述し、ヘルプメッセージに利用されます。
*   **INITIAL VALUE (初期値):** `=` の後に指定し、オプションがコマンドラインで指定されなかった場合のデフォルト値となります。指定しない場合、型によって挙動が異なります。

パース後、オプションに対応する変数がシェル環境に設定されます。変数名は通常
`long_name` に基づき、ハイフン (`-`) はアンダースコア (`_`) に
変換されます (例: `--very-verbose` は `$very_verbose` 変数)。`short_name`
しか定義されていない場合は `short_name` が変数名になります。`PREFIX`
設定により、これらの変数名に接頭辞を付けることも可能です。

### 3.2. オプションの型と型指定子

#### 3.2.1. フラグオプション (接尾辞なし, または `+`)

引数を取らないスイッチとして機能します。

*   **定義例:**
    *   `[verbose|v # 詳細表示]`
    *   `[debug|d+ # デバッグレベル (累積)]`
*   **値の指定方法:** `-v`, `--verbose`
*   **変数への格納:**
    *   接尾辞なし (`verbose`):
        *   初期値: 指定がなければ空文字列 `""`。
        *   オプション指定時: `1` が設定されます。
        *   複数回指定時: `1` のままです。
        *   `--no-verbose` のように `no-` プレフィックスを付けて指定すると、変数の値は空文字列 `""` にリセットされます。
    *   `+` 付き (`debug`): カウンターとして機能します。
        *   初期値: 指定がなければ `0`。数値で初期値を設定することも可能 (例: `]=0`)。
        *   オプション指定時: 変数の値が `1` ずつ増加します。
        *   `--no-debug` のように `no-` プレフィックスを付けて指定すると、変数の値は `0` にリセットされます (初期値が数値の場合)。
*   **ユースケース:** 機能のON/OFF、詳細度の段階的増加。

#### 3.2.2. 必須引数オプション (`:`)

必ず値を必要とするオプションです。

*   **定義例:** `[output|o: # 出力ファイル]`
*   **値の指定方法:**
    *   ロングオプション: `--output=value`, `--output value`
    *   ショートオプション: `-ovalue`, `-o value`
    *   注意: ショートオプションで `-o=value` の形式はサポートされません。
*   **変数への格納:** 指定された値がそのまま変数 (例: `$output`) に文字列として格納されます。
*   **初期値:** 指定がなければエラーとなりますが、定義時に初期値を設定できます (例: `]=/dev/stdout`)。
*   **ユースケース:** ファイルパス、必須パラメータの指定。

#### 3.2.3. オプション引数オプション (`?`)

値を取ることも、取らないことも可能なオプションです。

*   **定義例:** `[mode|m? # 動作モード]`
*   **値の指定方法:**
    *   ロングオプション:
        *   `--mode=value`: 変数 `$mode` に `value` が設定されます。
        *   `--mode`: 変数 `$mode` に空文字列 `""` が設定されます。
    *   ショートオプション:
        *   `-m`: 変数 `$mode` に空文字列 `""` が設定されます。
        *   注意: ショートオプションで `-mvalue` のように直接値を続ける形式はサポートされません。値を指定したい場合はロングオプションを使用してください。
*   **変数への格納:**
    *   値が指定された場合: その値が変数に格納されます。
    *   値なしでオプションが指定された場合: 空文字列 `""` が変数に格納されます。
    *   オプションが指定されなかった場合: 変数は未設定のままです (定義時に初期値を設定していない場合)。`${variable+_}` や `[[ -v variable ]]` で存在確認が可能です。
*   **初期値:** 定義時に設定可能です (例: `]=default_mode`)。
*   **ユースケース:** 省略可能な設定値、特定の場合のみ有効なパラメータ。

#### 3.2.4. 配列オプション (`@`)

複数の値を配列として受け取ります。

*   **定義例:** `[include|I@ # インクルードパス]`
*   **値の指定方法:**
    *   オプションを複数回指定: `--include /path/a --include /path/b`, `-I /path/a -I /path/b`
    *   単一のオプションで複数値を指定 (区切り文字は `DELIM` 設定で制御。デフォルトはカンマ、スペース、タブ):
        *   `--include /path/a,/path/b`
        *   `--include "/path/a /path/b"`
        *   `-I /path/a,/path/b`
*   **変数への格納:** 指定された値が Bash の配列 (例: `"${include[@]}"`) に格納されます。
*   **初期値:** 通常は空の配列です。定義時に初期値を設定することも可能です (例: `]=(/default/path1 /default/path2)`)。
*   **ユースケース:** 複数の入力ファイル、複数の設定項目。

#### 3.2.5. ハッシュオプション (`%`)

`キー=値` のペアを連想配列 (ハッシュ) として受け取ります。

*   **定義例:** `[define|D% # マクロ定義 (例: KEY=VALUE)]`
*   **値の指定方法:**
    *   オプションを複数回指定: `--define OS=Linux --define VER=1.0`, `-D OS=Linux -D VER=1.0`
    *   単一のオプションで複数ペアを指定 (区切り文字は `DELIM` 設定で制御。デフォルトはカンマ):
        *   `--define OS=Linux,VER=1.0`
        *   `-D OS=Linux,VER=1.0`
    *   値 (`=VALUE`) を省略した場合、`=1` が指定されたものとして扱われます (例: `--define DEBUG` は `DEBUG=1` と解釈)。
*   **変数への格納:** 指定されたキーと値が Bash の連想配列 (例: `declare -A define_map="${define[@]}"; echo "${define_map[OS]}"`) に格納されます。
*   **初期値:** 通常は空の連想配列です。定義時に初期値を設定することも可能です (例: `]=([USER]=$(whoami))`)。
*   **ユースケース:** 環境変数的な設定、キーと値のペアで管理したい情報。

#### 3.2.6. コールバックオプション (`!`)

オプションがパースされた際に、指定されたコールバック関数を呼び出します。この `!` 指定子は、上記の全てのオプション型 (`+`, `:`, `?`, `@`, `%`) に追加で付与できます。

*   **定義例:**
    *   `[execute|x! # コマンドを実行]` (フラグ型コールバック)
    *   `[config|c:! # 設定ファイルを読み込む]` (必須引数型コールバック)
*   **挙動:**
    *   オプションがコマンドラインで指定されると、関連付けられたコールバック関数が実行されます。
    *   デフォルトでは、コールバック関数名はオプションのロング名と同じになります (ハイフンはアンダースコアに変換)。`getoptlong callback` コマンドで任意の関数名を指定することも可能です。
    *   コールバック関数の呼び出しタイミングや引数については、「7.4. `getoptlong callback ...`」および「5.1. コールバック関数の詳細」を参照してください。
*   **ユースケース:** オプションパース時のカスタムアクション実行、複雑な値の処理、即時的な設定変更。

### 3.3. 値のバリデーション

オプションに渡される引数の値を検証する機能があります。バリデーションは、オプション定義の末尾に `=<validation_type>` を追加することで指定します。

#### 3.3.1. 整数バリデーション (`=i`)

引数が整数であるか検証します。

*   **定義例:** `[count|c:=i # 処理回数]`
*   **挙動:** 引数が整数でない場合、エラーメッセージを表示してスクリプトは終了します (デフォルト動作、`EXIT_ON_ERROR=1` の場合)。
*   配列オプション (`@=i`) やハッシュオプション (`%=i` の値部分) にも適用可能です。

#### 3.3.2. 浮動小数点数バリデーション (`=f`)

引数が浮動小数点数であるか検証します。

*   **定義例:** `[ratio|r:=f # 比率]`
*   **挙動:** 引数が浮動小数点数でない場合 (例: `123.45` はOK、`1.2e-3` は非対応の場合あり)、エラーメッセージを表示してスクリプトは終了します。
*   配列オプション (`@=f`) やハッシュオプション (`%=f` の値部分) にも適用可能です。

#### 3.3.3. カスタム正規表現バリデーション (`=(<regex>)`)

引数が指定された Bash の拡張正規表現 (ERE) にマッチするか検証します。正規表現は `=` の直後の `(` から、対応する最後の `)` までです。

*   **定義例:**
    *   `[mode|m:=(^(fast|slow|debug)$)]` (fast, slow, debug のいずれか)
    *   `[name|N@=(^[A-Za-z_]+$)]` (各要素が英字とアンダースコアのみ)
    *   `[param|P%:=(^[a-z_]+=[0-9]+$)]` (キーが小文字英字と_、値が数字のペア)
*   **挙動:** 引数が正規表現にマッチしない場合、エラーメッセージを表示してスクリプトは終了します。
*   配列オプションやハッシュオプションにも適用可能です。配列の場合は各要素が、ハッシュの場合は各 `キー=値` のペア全体が正規表現にマッチするか検証されます。

## 4. ヘルプメッセージの生成とカスタマイズ (Help Message Generation and Customization)
`getoptlong.sh` は、スクリプトの利用方法をユーザーに示すためのヘルプメッセージを
自動的に生成する強力な機能を提供します。これにより、開発者はヘルプテキストを
手動で管理する手間を大幅に削減できます。生成されるヘルプメッセージは、
オプションのロング名（存在しない場合はショート名）のアルファベット順に表示されます。

### 4.1. 自動ヘルプオプション

*   **`--help` および `-h`:**
    オプション定義配列 (`OPTS`) で明示的に `help` や `h` という名前のオプションを
    定義していない場合でも、`getoptlong.sh` は自動的に `--help` (および `-h`)
    オプションを認識します。これらのオプションがコマンドラインで指定されると、
    生成されたヘルプメッセージが表示され、スクリプトは自動的に終了します。

*   **デフォルトのヘルプオプション定義のカスタマイズ (`HELP` 設定):**
    この自動的に追加されるヘルプオプションの定義（オプション名、説明文）は、
    `getoptlong init` 時の `HELP` パラメータ、またはオプション定義配列内の `&HELP`
    キーでカスタマイズできます。
    *   **`getoptlong init` で指定:**
        ```bash
        getoptlong init OPTS HELP="myhelp|H#このスクリプトのカスタムヘルプを表示します"
        ```
        この場合、`--myhelp` または `-H` がヘルプオプションとして機能します。
    *   **オプション定義配列で指定 (`&HELP`):**
        ```bash
        declare -A OPTS=(
            [&HELP]="show-usage|u#使い方ガイド"
            # ... 他のオプション定義 ...
        )
        getoptlong init OPTS
        ```
        この場合、`--show-usage` または `-u` がヘルプオプションになります。配列内の `&HELP` 指定は `init` 時の `HELP` パパラメータよりも優先されます。
    *   `HELP` や `&HELP` を指定しない場合のデフォルトは `help|h#show help` です。

### 4.2. ヘルプメッセージの内容

#### 4.2.1. オプションの説明文 (コメント `#`)

ヘルプメッセージに表示される各オプションの説明文は、オプション定義配列で、
各オプション定義のキー文字列の末尾に `#` に続けて記述します。

```bash
declare -A OPTS=(
    [output|o:   # 出力先のファイルパスを指定します。 ]=/dev/stdout
    [verbose|v+  # 詳細なログを有効にします (複数指定でレベル上昇)。 ]=0
)
```
上記のように定義すると、ヘルプメッセージには以下のような形式で表示されます（表示順はオプション名ソート後）。

```
  -o, --output <value>     出力先のファイルパスを指定します。 (default: /dev/stdout)
  -v, --verbose            詳細なログを有効にします (複数指定でレベル上昇)。 (default: 0)
```

#### 4.2.2. 型に基づく自動メッセージ

オプション定義で `#` による説明文が提供されていない場合、`getoptlong.sh` は
オプションの型情報（引数を取るか、引数の型は何かなど）に基づいて、基本的な
説明を自動生成します。
例えば：
*   `[input|i:]` (説明なし) → `  -i, --input <value>        Requires an argument.`
*   `[force|f]` (説明なし) → `  -f, --force                Flag option.`
長くて分かりやすいロングオプション名（例: `--backup-location` のように）を
使用すると、自動生成されるメッセージの可読性が向上します。

#### 4.2.3. 初期値 (デフォルト値) の表示

オプション定義時に初期値を指定している場合 (例: `[count|c:=i]=1`)、
そのデフォルト値はヘルプメッセージ内で `(default: <value>)` のように表示されます。

```bash
declare -A OPTS=(
    [mode|m?     # 動作モードを指定 (fast, normal, slow) ]=normal
    [retries|r:=i # 最大リトライ回数 ]=3
)
```
ヘルプメッセージ表示例:
```
  -m, --mode [<value>]     動作モードを指定 (fast, normal, slow) (default: normal)
  -r, --retries <value>    最大リトライ回数 (default: 3)
```

#### 4.2.4. フラグオプションのカウンターとしての扱い

フラグオプション (型指定子なし、または `+`) に数値の初期値を指定すると
(例: `[debug|d+]=0`)、そのオプションはカウンターとして扱われます。
ヘルプメッセージにもその初期値が表示されます。

### 4.3. ヘルプメッセージ全体の書式

#### 4.3.1. 使用法 (Synopsis) のカスタマイズ (`USAGE` 設定)

ヘルプメッセージの先頭に表示されるスクリプトの使用法を示す行 (Synopsis) は、
`USAGE` パラメータでカスタマイズできます。

*   **`getoptlong init` で指定:**
    ```bash
    getoptlong init OPTS USAGE="使用法: myscript [オプション] <入力ファイル> <出力ファイル>"
    ```
*   **オプション定義配列で指定 (`&USAGE`):**
    ```bash
    declare -A OPTS=(
        [&USAGE]="Usage: $(basename "$0") [OPTIONS] SOURCE DEST"
        # ... 他のオプション定義 ...
    )
    getoptlong init OPTS
    ```
    配列内の `&USAGE` 指定は `init` 時の `USAGE` パラメータよりも優先されます。
*   `USAGE` が指定されていない場合、デフォルトではSynopsis行は表示されません (ただし、`getoptlong help` コマンドに引数を渡した場合は別)。

#### 4.3.2. `getoptlong help` コマンドによる手動表示

スクリプト内の任意の場所から `getoptlong help` コマンドを実行することで、
ヘルプメッセージを手動で表示させることができます。

```bash
if [[ "$1" == "--show-manual" ]]; then
    getoptlong help "これは $(basename "$0") の詳しいマニュアルです。"
    exit 0
fi
```
`getoptlong help` に引数を渡すと、その文字列がヘルプメッセージの最初の行
(Synopsis) として使用されます。これは、`USAGE` や `&USAGE` の設定よりも
優先されます。引数を渡さない場合、`USAGE` (または `&USAGE`) の設定が使用され、
それもなければSynopsisなしでオプションリストが表示されます。

### 4.4. ヘルプメッセージの構造

生成されるヘルプメッセージは、一般的に以下の構造を持ちます。

1.  **Synopsis 行:** (USAGE 設定または `getoptlong help` の引数で指定された場合)
2.  **オプションリスト:**
    *   各オプションは、ショートオプション (もしあれば)、ロングオプション (もしあれば)、引数のプレースホルダ (例: `<value>`)、そして説明文の順で表示されます。
    *   オプションはロング名のアルファベット順にソートされます。ロング名がない場合はショート名でソートされます。
    *   説明文には、初期値 (`(default: ...)`) が含まれることがあります。

```
(Synopsis 行、例: Usage: myscript [options] <file>)

Options:
  -h, --help                 Show this help message and exit.
  -f, --file <path>          Specify the input file. (default: input.txt)
      --force                Force operation without confirmation.
  -n, --count <number>       Number of times to operate. (integer, default: 1)
  -v, --verbose              Enable verbose output. (counter, default: 0)
      --version              Show version information.
```
(上記はあくまでヘルプメッセージの一般的な例です。実際の表示はオプション定義や設定によって変わります。)

## 5. 高度なトピック (Advanced Topics)
このセクションでは、`getoptlong.sh` のより進んだ使い方や便利な機能について解説します。

### 5.1. コールバック関数の詳細

コールバック関数を使用すると、特定のオプションがパースされたタイミングで任意のシェル関数を実行できます。これにより、単純な値の設定以上の複雑な処理をオプションパースに組み込むことが可能です。
コールバック関数は、オプション定義時に `!` サフィックスを付けるか、`getoptlong callback` コマンドで登録します。

#### 5.1.1. 通常のコールバック (後処理)

デフォルトでは、コールバック関数はオプションの値が内部的に設定された**後**に呼び出されます。

*   **呼び出し形式:** `callback_function "option_name" "option_value" [registered_arg1 registered_arg2 ...]`
    *   `$1`: オプションのロング名 (例: `my-option`)。
    *   `$2`: パースされたオプションの値。フラグの場合は `1` (または `no-` 付きの場合は空文字列)、引数を取るオプションの場合はその値。配列やハッシュの場合は、最後にパースされた要素またはペア。
    *   `$3...`: `getoptlong callback <opt_name> <func_name> arg1 arg2...` のように登録時に追加引数を指定した場合、それらが渡されます。

*   **例:**
    ```bash
    declare -A OPTS=(
        [process-item|p:! # アイテムを処理する]=
    )

    process_item_callback() {
        local opt_name="$1"
        local item_id="$2"
        echo "コールバック: オプション '$opt_name' が値 '$item_id' で指定されました。"
        # ここで item_id を使った処理を実行
        if [[ ! -f "$item_id" ]]; then
            echo "エラー: ファイル '$item_id' が見つかりません。" >&2
            # exit 1 # 必要に応じてエラー終了
        fi
    }
    # getoptlong callback process-item process_item_callback # デフォルトで登録されるが明示も可能
    # getoptlong callback process-item process_item_callback "追加引数1" # 追加引数も渡せる

    getoptlong init OPTS
    getoptlong parse "$@" && eval "$(getoptlong set)"
    ```

#### 5.1.2. 事前処理コールバック (`--before` / `-b`) (★新機能)

`getoptlong callback` コマンドに `--before` (または `-b`) オプションを
指定することで、オプションの値が内部的に設定される**前**にコールバック関数を
呼び出すことができます。これは `getoptlong.sh` の比較的新しい機能です。

*   **呼び出し形式:** `callback_function "option_name" [registered_arg1 registered_arg2 ...]`
    *   `$1`: オプションのロング名。
    *   `$2...`: `getoptlong callback -b <opt_name> <func_name> arg1 arg2...` のように登録時に追加引数を指定した場合、それらが渡されます。
    *   **注意:** 事前処理コールバックには、オプションの値は渡されません。値の処理が目的ではなく、値が設定される前の状態変更や準備処理に適しています。

*   **ユースケース:**
    *   配列オプションの値を処理前にクリアする。
    *   特定のオプションが指定された場合に、他のデフォルト値を動的に変更する。
    *   状態の初期化処理。

*   **例: 配列オプションを事前クリア**
    ```bash
    declare -A OPTS=(
        [append-list|a@ # リストに追加 (指定の都度クリア可) ]=()
    )

    clear_append_list() {
        echo "コールバック(--before): append_list (${append_list[*]}) をクリアします。"
        append_list=() # グローバル変数を直接操作
    }
    # append_list オプションがパースされる直前に clear_append_list を呼び出す
    getoptlong callback --before append-list clear_append_list

    getoptlong init OPTS
    # 例: ./myscript.sh --append-list x --append-list y
    # clear_append_list が2回呼ばれ、最終的に append_list には "y" のみが入る。
    # もし --before を使わなければ、"x" "y" の両方が入る。
    getoptlong parse "$@" && eval "$(getoptlong set)"

    echo "最終的な append_list: ${append_list[*]}"
    ```

#### 5.1.3. コールバック関数内でのエラー処理

コールバック関数内でエラーが発生した場合、標準エラーにメッセージを出力し、
非ゼロの終了ステータスで `exit` することが一般的です。これにより、
`getoptlong.sh` のエラー処理機構 (例えば `EXIT_ON_ERROR`) と連携できます。

#### 5.1.4. コールバックを使ったカスタムバリデーション

オプション定義のバリデーション機能 (`=i`, `=f`, `=(regex)`) で対応できない
複雑な検証は、コールバック関数を使って実装できます。通常コールバック（後処理）で
値を受け取り、検証ロジックを実行します。

### 5.2. Destination の指定 (★新機能)

通常、パースされたオプションの値は、オプションのロング名（またはショート名）に基づいて自動的に決定される変数に格納されます。`DESTINATION` 設定 (比較的新しい機能) を使用すると、これらの値を指定した連想配列に格納することができます。

*   **設定方法:** `getoptlong init OPTS DESTINATION=<array_name>`
    *   `<array_name>` には、値を格納する連想配列の名前を指定します。この配列は事前に `declare -A <array_name>` で宣言しておく必要があります。

*   **挙動:**
    *   オプション `--option value` がパースされると、`$option` という変数名の代わりに `<array_name>[option]` に値が格納されます。
    *   オプション名に含まれるハイフンはアンダースコアに変換されません。そのままのオプション名がキーとなります。(例: `--my-option` は `<array_name>[my-option]`)
    *   フラグ、カウンター、配列、ハッシュなど、すべてのオプション型で同様に動作します。
    *   **重要:** 配列型やハッシュ型オプションの場合、`<array_name>[option_name]` には、
        実際の配列/ハッシュを保持する**グローバル変数名が文字列として格納される**か、
        あるいは配列/ハッシュが**シリアライズされた文字列として格納される**ことがあります。これは `getoptlong.sh` の具体的な実装によります。アクセスする際は、
        `getoptlong dump -a` や `getoptlong set` の出力を確認し、
        適切にデリファレンスまたはデシリアライズしてください。単純な `${<array_name>[option_name][index]}` のようなアクセスが直接機能しない場合があります。

*   **例:**
    ```bash
    declare -A MyVars
    declare -A OPTS=(
        [user-name|u: # ユーザー名]=
        [enable-feature|f # フィーチャーを有効化]=
        [ids|i@=i # IDリスト]=()
    )

    getoptlong init OPTS DESTINATION=MyVars
    getoptlong parse --user-name "jules" --enable-feature --ids 10 --ids 20
    eval "$(getoptlong set)"

    echo "ユーザー名: ${MyVars[user-name]}"
    echo "フィーチャー有効: ${MyVars[enable-feature]}" # "1" が格納される

    # MyVars[ids] の内容を確認 (getoptlong dump -a などで)
    # 例: もし MyVars[ids] が "MyVars_ids" という文字列を格納し、
    # 実際の配列が $MyVars_ids にある場合:
    # declare -n ids_ref="${MyVars[ids]}"
    # echo "IDリスト: ${ids_ref[@]}"
    # そうでない場合、MyVars[ids] の内容に応じた処理が必要
    if declare -p "${MyVars[ids]}" &>/dev/null && [[ "$(declare -p "${MyVars[ids]}")" =~ "declare -a" ]]; then
        declare -n ids_ref="${MyVars[ids]}"
        echo "IDリスト (参照経由): ${ids_ref[@]}"
    elif [[ -n "${MyVars[ids]}" ]]; then
         echo "IDリスト (MyVars[ids] の値): ${MyVars[ids]}"
         echo "注意: これは配列名またはシリアライズされた値の可能性があります。"
    fi
    ```

*   **ユースケース:**
    *   オプション由来の変数を特定の名前空間（連想配列）にまとめることで、グローバルなシェル変数の汚染を防ぐ。
    *   複数の `getoptlong` インスタンスを使い分ける際に、それぞれの結果を区別しやすくする。

### 5.3. オプションのパススルー機能

スクリプトが受け取ったオプションの一部を、そのまま別の内部コマンドや外部コマンドに渡したい場合があります (この機能の実現方法は `getoptlong.sh` のバージョンや設計により異なる可能性があります)。

*   **`PERMUTE` と `--` (ダブルダッシュ):**
    *   `getoptlong init OPTS PERMUTE=RESTARGS` のように `PERMUTE` を設定すると、
        オプションとして解釈されなかった引数 (非オプション引数) は指定した配列
        (`RESTARGS`) に順序通り格納されます。
    *   コマンドライン引数の中に `--` (ダブルダッシュ) が現れると、それ以降の引数は
        すべてオプションとして解釈されず、そのまま `PERMUTE` で指定した配列 (または
        デフォルトの `GOL_ARGV`) に格納されます。これは、後続のコマンドにオプションを渡す際の標準的な方法です。

*   **未定義オプションの扱い:**
    *   デフォルトでは、`OPTS` 配列に定義されていないオプションが渡されるとエラーになります (`EXIT_ON_ERROR=1` の場合)。
    *   `EXIT_ON_ERROR=0` に設定し、`getoptlong parse` の返り値をチェックする
        ことで、未定義オプションを含む引数リストを処理できます。`getoptlong.sh` が「未定義オプションを無視して特定の配列に集める」という直接的な機能を持つわけではありません。この場合、`PERMUTE` と `--` を利用するか、パースの前処理として引数リストを自分で加工する必要があります。

*   **パススルーの実現方法 (一般的なアプローチ):**
    1.  **`--` を利用する:** スクリプトのユーザーに、下流のコマンドへ渡したいオプション群の前に `--` を置いてもらうよう指示します。
        ```bash
        # ./myscript.sh --my-opt val -- --downstream-opt --another val
        declare -a PassThroughArgs
        getoptlong init OPTS PERMUTE=PassThroughArgs
        getoptlong parse "$@" && eval "$(getoptlong set)"
        # PassThroughArgs には "--downstream-opt" "--another" "val" が格納される (PERMUTE利用時)
        # other_command "${PassThroughArgs[@]}"
        ```

    2.  **ラッパースクリプトとしての利用と手動分割:** スクリプトが特定のコマンドのラッパーである場合、自身のオプションを処理した後、残りの引数や特定の変換を加えた引数をそのコマンドに渡します。`--` を使って明示的に分離するのが堅牢です。
        ```bash
        # ./mywrapper.sh --wrapper-opt -- cmd_to_wrap --cmd-opt arg
        declare -a AllArgs=("$@")
        declare -a ScriptArgs
        declare -a CommandToWrapArgs

        found_double_dash=0
        for i in "${!AllArgs[@]}"; do
            if [[ "${AllArgs[$i]}" == "--" ]]; then
                ScriptArgs=("${AllArgs[@]:0:$i}")
                CommandToWrapArgs=("${AllArgs[@]:((i+1))}")
                found_double_dash=1
                break
            fi
        done

        if (( found_double_dash == 0 )); then
            # '--' がない場合は、全てスクリプト引数として解釈しようとするか、エラーにするか設計による
            echo "エラー: '--' に続けてラップするコマンドの引数を指定してください。" >&2
            exit 1
            # ScriptArgs=("${AllArgs[@]}") # または全てスクリプト引数とみなす場合
        fi

        getoptlong init OPTS # OPTS には --wrapper-opt のようなオプションを定義
        getoptlong parse "${ScriptArgs[@]}" && eval "$(getoptlong set)"

        # ここで $wrapper_opt などを使用
        # そして CommandToWrapArgs をラップ対象コマンドに渡す
        # cmd_to_wrap "${CommandToWrapArgs[@]}"
        ```

### 5.4. 実行時設定の変更 (`getoptlong configure`)

`getoptlong init` で設定したパラメータの一部は、`getoptlong configure` コマンドを使って後から変更できます。

*   **コマンド:** `getoptlong configure <CONFIG_PARAM=VALUE> ...`
*   **例:**
    ```bash
    getoptlong init OPTS EXIT_ON_ERROR=1
    # ... 何らかの処理 ...
    # 一時的にエラーで終了しないようにする
    getoptlong configure EXIT_ON_ERROR=0
    # 以下のパースはエラーで終了しない (parse の返り値で成否を判定)
    if ! getoptlong parse "${some_args[@]}"; then
        echo "Warning: Parsing some_args failed but script continues." >&2
    fi
    # 元に戻す
    getoptlong configure EXIT_ON_ERROR=1
    ```
*   **注意:** `PREFIX` やオプション定義そのものに影響するようなパラメータは、
    `init` 後に変更しても期待通りに動作しない場合があります。主にパースの挙動を制御するフラグ (`EXIT_ON_ERROR`, `SILENT`, `DEBUG`, `DELIM`) の変更に用いるのが安全です。

### 5.5. 内部状態のダンプ (`getoptlong dump`)

デバッグ目的で、`getoptlong.sh` が内部で保持しているオプションの定義情報や現在の値を確認したい場合があります。`getoptlong dump` コマンドを使用します。

*   **コマンド:**
    *   `getoptlong dump`: パースされたオプション名と、それに対応するシェル変数名および現在の値を表示します。
    *   `getoptlong dump -a` または `getoptlong dump --all`: すべての内部管理パラメータや、より詳細なオプション情報を表示します。

*   **例:**
    ```bash
    declare -A OPTS=([file|f:]=foobar.txt [verbose|v+]=0)
    getoptlong init OPTS
    getoptlong parse --verbose --file new.txt -v

    # 変数 $file と $verbose の状態などを表示
    getoptlong dump >&2
    # 出力例 (形式は実際の実装による):
    # file (file) = 'new.txt'
    # verbose (verbose) = '2'

    eval "$(getoptlong set)"
    echo "File is: $file, Verbose level is: $verbose"
    ```
*   **ユースケース:**
    *   オプションが正しくパースされているかの確認。
    *   変数が期待通りに設定されているかのデバッグ。
    *   コールバック関数内で現在のオプション状態を確認する。

## 6. 外部コマンドとしての利用 (Standalone Usage)
`getoptlong.sh` は主にライブラリとして `source` して使いますが、将来的に
限定的な外部コマンドとしての機能が提供される可能性も考えられます (この機能の
具体的な実装は現時点ではありません)。

もし `getoptlong.sh` が外部コマンドとして何らかの機能（例: バージョン表示、
簡易パーステストなど）を提供するようになった場合、その使用方法はこのセクションに
記述されます。

**現状の主な利用方法:**
スクリプト内で `source getoptlong.sh` としてライブラリ機能を呼び出し、オプション定義、初期化、パース、変数セットの手順で使用します。

## 7. コマンドリファレンス (Command Reference)

`getoptlong.sh` が提供する主要なコマンド（関数）について説明します。

### 7.1. `getoptlong init <opts_array_name> [CONFIGURATIONS...]`
ライブラリを初期化し、オプション定義と設定をロードします。このコマンドは、`getoptlong parse` を呼び出す前に必ず実行する必要があります。

*   **`<opts_array_name>`**: (必須) オプション定義を含む Bash 連想配列の名前を指定します (例: `OPTS`)。
*   **`[CONFIGURATIONS...]`**: 省略可能な設定パラメータを `KEY=VALUE` 形式で指定します。主な設定は以下の通りです。
    *   **`PERMUTE=<array_name>`**:
        オプションとして解釈されなかった引数 (非オプション引数) を格納する Bash 通常配列の名前を指定します。
        例えば `PERMUTE=REMAINING_ARGS` とした場合、`myscript --opt arg1 arg2` の
        `arg1` と `arg2` が `REMAINING_ARGS` 配列に格納されます。
        指定しない場合、または空文字列を指定した場合、最初の非オプション引数でパースが
        停止します (POSIXLY_CORRECT のような挙動)。
        デフォルトは `GOL_ARGV` (ライブラリ内部の配列名、通常ユーザーは意識しない)。
    *   **`PREFIX=<string>`**:
        `getoptlong set` で設定される変数名に付与する接頭辞を指定します。例えば `PREFIX=MYAPP_` とし、オプション `--option` があれば、変数 `$MYAPP_option` が設定されます。
        デフォルトは空文字列 (接頭辞なし)。
    *   **`DESTINATION=<array_name>` (★新機能)**:
        パースされたオプションの値を、指定した連想配列 `<array_name>` に格納します。キーはオプションのロング名（またはショート名が定義されていればショート名、ロング名優先）です。
        例えば `DESTINATION=OptValues` とし、オプション `--my-opt val` があれば
        `OptValues[my-opt]="val"` のように格納されます。
        `PREFIX` 設定は、この `DESTINATION` 配列のキー名には適用されません。
        配列型・ハッシュ型オプションの具体的な格納方法とアクセスについては、
        「5.2. Destination の指定」を参照してください。
        この配列は事前に `declare -A <array_name>` で宣言しておく必要があります。
    *   **`HELP=<SPEC>`**:
        自動的に追加されるヘルプオプションの定義を指定します。`<SPEC>` はオプション定義配列のキーと同様の書式です (例: `myhelp|H#カスタムヘルプ`)。
        デフォルトは `help|h#show help`。
    *   **`EXIT_ON_ERROR=<BOOL>`**:
        パースエラー発生時にスクリプトを終了するかどうか (`1` で終了、`0` で終了しない)。
        デフォルトは `1` (終了する)。`0` の場合、`getoptlong parse` の返り値でエラーを判定する必要があります。
    *   **`DELIM=<string>`**:
        配列オプション (`@`) やハッシュオプション (`%`) で、単一の引数文字列内にある
        複数の値やペアを区切るための文字セットを指定します。
        デフォルトはスペース、タブ、カンマ (Bash の IFS に近い挙動)。例えば `DELIM=,:` とするとカンマとコロンで区切ります。
    *   **`SILENT=<BOOL>`**:
        エラーメッセージの出力を抑制するかどうか (`1` で抑制、`0` で表示)。
        デフォルトは `0` (表示する)。
    *   **`DEBUG=<BOOL>`**:
        デバッグメッセージの出力を有効にするかどうか (`1` で有効、`0` で無効)。
        デフォルトは `0` (無効)。

### 7.2. `getoptlong parse "$@"`
定義されたオプションに従って、コマンドライン引数をパースします。

*   **`"$@"`**: (必須) スクリプトに渡された全ての引数をそのまま渡します。ダブルクォートで囲むことが重要です。
*   **返り値**:
    *   パースに成功した場合は終了コード `0` を返します。
    *   パースに失敗した場合 (未定義オプション、必須引数の欠如など) は非ゼロの終了コードを返します。
    *   `EXIT_ON_ERROR=1` (デフォルト) の場合、パースエラー時にこのコマンドは
        スクリプトを終了させるため、返り値のチェックは通常不要です。
    *   `EXIT_ON_ERROR=0` の場合は、このコマンドの返り値をチェックしてエラー処理を行う必要があります。

### 7.3. `getoptlong set`
パースされたオプションの値に基づいて、対応するシェル変数を設定するための一連の `eval` 可能なシェルコマンド文字列を標準出力に生成します。

*   通常、`eval "$(getoptlong set)"` のようにして使用します。これにより、オプションに対応する変数が現在のシェル環境に設定されます。
    (例: `--file /tmp/f` → `file="/tmp/f"`)

### 7.4. `getoptlong callback [-b|--before] <opt_name> [callback_function] ...`
指定したオプションにコールバック関数を登録、または既に登録されているコールバックの設定を変更します。

*   **`-b` または `--before` (★新機能)**:
    このフラグを指定すると、コールバック関数はオプションの値が内部的に設定される**前**に呼び出されます。
    事前処理コールバックにはオプションの値は渡されません。詳細は「5.1.2. 事前処理コールバック」を参照してください。
*   **`<opt_name>`**: (必須) コールバックを登録するオプションのロング名 (例: `my-option`)。
*   **`[callback_function]`**:
    呼び出すシェル関数の名前。
    省略した場合、または `-` を指定した場合は、`<opt_name>` から自動的に生成される
    関数名（ハイフン `-` をアンダースコア `_` に変換したもの。例: `my_option`）が
    デフォルトのコールバック関数名となります。
    オプション定義時に `!` サフィックスを付けていれば、このデフォルト名で自動的にコールバックが登録されます。
*   **`[...]`**: (オプション) コールバック関数に渡される追加の固定引数。これらの引数は、コールバック関数呼び出し時に、オプション名とオプション値 (通常コールバックの場合) の後に渡されます。

### 7.5. `getoptlong configure <CONFIG_PARAM=VALUE> ...`
`getoptlong init` で設定されたグローバルな設定パラメータの値を、パース処理の途中などで動的に変更します。

*   **`<CONFIG_PARAM=VALUE>`**: (必須) `getoptlong init` で指定可能な設定パラメータとその新しい値を指定します (例: `EXIT_ON_ERROR=0`)。
*   **注意**: すべてのパラメータが実行時変更に適しているわけではありません。主にパースの振る舞いを制御するフラグ (`EXIT_ON_ERROR`, `SILENT`, `DEBUG`, `DELIM`) の変更が安全です。`PREFIX` やオプション定義そのものに関わるようなパラメータは、`init` 後に
    変更しても期待通りに動作しない可能性があります。

### 7.6. `getoptlong dump [-a|--all]`
`getoptlong.sh` の内部状態（オプション定義、現在の値、設定など）を標準エラー出力にダンプ（表示）します。主にデバッグ目的で使用します。

*   **`-a` または `--all`**:
    指定すると、より詳細な内部情報（管理パラメータなどを含む）を表示します。指定しない場合は、主にパースされたオプション名とそれに対応するシェル変数名、現在の値などが表示されます。

### 7.7. `getoptlong help <SYNOPSIS>`
定義されたオプションに基づいて整形されたヘルプメッセージを標準出力に生成・表示します。

*   **`<SYNOPSIS>`**: (オプション) ヘルプメッセージの先頭に表示するスクリプトの使用法を示す文字列。
    ここで指定した文字列は、`USAGE` や `&USAGE` 設定よりも優先されます。
    省略した場合、`USAGE` (または `&USAGE`) 設定があればそれが使用され、
    それもなければ Synopsis 行なしでオプションリストが表示されます。
*   自動ヘルプオプション (`--help`, `-h`) が呼び出された際には、このコマンドが内部的に実行されます。

## 8. 実践的な例 (Practical Examples)

これまでのセクションで `getoptlong.sh` の各機能について説明してきましたが、
ここではいくつかの実践的な例や、より複雑なシナリオでの利用方法を示します。また、
`ex/` ディレクトリにはさらに多くのサンプルスクリプトが含まれていますので、そちらも参照してください。

### 8.1. 必須オプションとオプション引数の組み合わせ

```bash
#!/bin/bash

# getoptlong.sh のパスが通っているか、カレントディレクトリにあることを想定
if ! . getoptlong.sh; then echo "エラー: getoptlong.sh が見つかりません。" >&2; exit 1; fi

# オプション定義
declare -A OPTS=(
    [input|i:    # 入力ファイルを指定 (必須) ]=
    [output|o:   # 出力ファイルを指定 (必須) ]=
    [format|f?   # 出力フォーマット (任意、指定時は値を期待) ]= # 値なし指定は非推奨
    [compress|c  # 出力を圧縮する (フラグ) ]=
    [level|l:=i  # 圧縮レベル (整数、compress指定時のみ有効) ]=1
    [verbose|v+  # 詳細表示レベル ]=0
    [&USAGE]="Usage: $(basename "$0") -i <input> -o <output> [-f <format>] [-c [-l <level>]] [-v]"
    [&HELP]="process-data|H#データ処理スクリプトのヘルプ"
)

# コールバック関数 (例: format が指定されたら大文字にする)
# format オプションに ! をつけていないので、getoptlong callback で登録する必要がある
format_callback() {
    local opt_name="$1"
    local val="$2"
    if [[ -n "$val" ]]; then
        format="${val^^}" # format 変数 (グローバル) を直接大文字に書き換える
        (( verbose > 0 )) && echo "Debug: Format set to '$format' via callback." >&2
    else
        echo "Warning: Format option used without a value." >&2
    fi
}
getoptlong callback format format_callback

# getoptlong 初期化
getoptlong init OPTS

# 引数パース
if ! getoptlong parse "$@"; then
    exit 1
fi
eval "$(getoptlong set)"

# 必須オプションのチェック
if [[ -z "$input" ]] || [[ -z "$output" ]]; then
    echo "エラー: 入力ファイル (-i) と出力ファイル (-o) は必須です。" >&2
    getoptlong help # エラー時はヘルプ表示
    exit 1
fi

# メイン処理
echo "入力ファイル: $input"
echo "出力ファイル: $output"

if [[ -v format ]]; then # format オプションが使用されたか (値あり/値なし空文字)
    if [[ -n "$format" ]]; then
        echo "出力フォーマット: $format"
    else
        echo "出力フォーマット: (指定なし)" # --format のみの場合
    fi
fi

if [[ -n "$compress" ]]; then
    echo "圧縮: 有効 (レベル: $level)"
    # 圧縮処理...
else
    echo "圧縮: 無効"
fi

echo "詳細表示レベル: $verbose"

# ...実際の処理...
echo "処理完了。"
```
**この例のポイント:**
*   必須オプション (`input`, `output`) のチェック。
*   オプション引数 (`format`) の扱いや、コールバックによる値の加工。
*   フラグオプション (`compress`) と、それに関連する別のオプション (`level`) の組み合わせ。
*   `&USAGE` と `&HELP` を使ったヘルプメッセージのカスタマイズ。

### 8.2. サブコマンドを持つスクリプト (簡易版)

`getoptlong.sh` は複数回 `init` と `parse` を呼び出すことができます。これを利用して、サブコマンドごとに異なるオプションセットを定義・処理することが可能です。

```bash
#!/bin/bash
if ! . getoptlong.sh; then echo "エラー: getoptlong.sh が見つかりません。" >&2; exit 1; fi

# グローバルオプション
declare -A GlobalOPTS=(
    [verbose|v+ # 詳細表示 ]=0
    [help|h     # ヘルプ表示 ]=
)
getoptlong init GlobalOPTS
declare -a RemainingArgs
# グローバルオプションのみをパース。エラーでは終了せず、残りをRemainingArgsへ。
getoptlong configure EXIT_ON_ERROR=0 PERMUTE=RemainingArgs
getoptlong parse "$@"
eval "$(getoptlong set)" # グローバルオプション用の変数をセット

# グローバルなヘルプが要求されたか、サブコマンドがない場合は全体のヘルプ
if [[ -n "$help" ]] || (( ${#RemainingArgs[@]} == 0 )); then
    echo "Usage: $(basename "$0") [global_options] <subcommand> [subcommand_options]"
    echo ""
    echo "Global Options:"
    getoptlong help # GlobalOPTS のヘルプ
    echo ""
    echo "Subcommands:"
    echo "  commit    Record changes to the repository"
    echo "  push      Update remote refs along with associated objects"
    exit 0
fi

subcommand="${RemainingArgs[0]}"
# RemainingArgs からサブコマンド自身を取り除いたものをサブコマンド引数とする
SubcommandArgs=("${RemainingArgs[@]:1}")

case "$subcommand" in
    commit)
        declare -A CommitOPTS=(
            [message|m: # コミットメッセージ ]=
            [all|a      # 全ての変更をステージ ]=
            [help|h     # commitサブコマンドのヘルプ ]= # サブコマンドごとのヘルプ
        )
        getoptlong init CommitOPTS # 新しいオプションセットで再初期化
        # サブコマンド引数のみをパース
        if ! getoptlong parse "${SubcommandArgs[@]}"; then exit 1; fi
        eval "$(getoptlong set)" # commit 用の変数をセット

        if [[ -n "$help" ]]; then # サブコマンドのヘルプ
             getoptlong help "Usage: $(basename "$0") commit [options]"
             exit 0
        fi

        echo "Subcommand: commit"
        [[ -n "$message" ]] && echo "  Message: $message"
        [[ -n "$all" ]] && echo "  All: enabled"
        (( verbose > 0 )) && echo "  Verbose (global): $verbose"
        # git commit の実行など
        ;;
    push)
        declare -A PushOPTS=(
            [remote|r:  # リモートリポジトリ ]=origin
            [force|f   # 強制プッシュ       ]=
            [help|h    # pushサブコマンドのヘルプ ]=
        )
        getoptlong init PushOPTS
        if ! getoptlong parse "${SubcommandArgs[@]}"; then exit 1; fi
        eval "$(getoptlong set)"

        if [[ -n "$help" ]]; then
             getoptlong help "Usage: $(basename "$0") push [options]"
             exit 0
        fi

        echo "Subcommand: push"
        echo "  Remote: ${remote}"
        [[ -n "$force" ]] && echo "  Force: enabled"
        (( verbose > 0 )) && echo "  Verbose (global): $verbose"
        # git push の実行など
        ;;
    *)
        echo "エラー: 不明なサブコマンド '$subcommand'" >&2
        getoptlong init GlobalOPTS # ヘルプ表示のためにグローバルOPTSに戻す
        getoptlong help "Usage: $(basename "$0") [global_options] <subcommand> [subcommand_options]"
        exit 1
        ;;
esac
```
**この例のポイント:**
*   グローバルオプションとサブコマンド固有オプションの分離。
*   `getoptlong init` と `parse` を複数回呼び出し。
*   `PERMUTE` を使ってサブコマンドとその引数を分離。
*   サブコマンドごとのヘルプ表示の考慮 (`help|h` を各OPTSで定義)。
*   **注意:** この例は基本的な考え方を示すもので、実際のサブコマンド処理はさらに多くのエッジケースやエラーハンドリングを考慮する必要があります。`ex/subcmd.sh` にもより詳細な例があります。

### 8.3. `ex/` ディレクトリのサンプルスクリプト

`getoptlong.sh` のリポジトリには、`ex/` ディレクトリ以下に様々な機能を示すサンプルスクリプトが含まれています。これらは、より具体的な利用例や高度なテクニックを学ぶ上で非常に役立ちます。

*   **`ex/repeat.sh`**: 様々なオプションタイプ（配列、ハッシュ、インクリメンタルなフラグなど）の基本的な使い方を示します。
*   **`ex/prefix.sh`**: `PREFIX` 設定の利用例。
*   **`ex/cmap`**: 色付けマッパー。複雑なオプションパース、コールバック、データ処理の良い例です。
*   **`ex/cmap-prefix`**: `cmap` に `PREFIX` を適用した例。
*   **`ex/md`**: Markdown パーサーのサンプル。
*   **`ex/silent.sh`**: `SILENT` 設定の利用例。
*   **`ex/subcmd.sh`**: サブコマンドを持つスクリプトのより洗練された例。グローバルオプションとローカルオプションの扱いや、ヘルプの共通化などを含みます。

これらのサンプルを実際に動かしてみたり、コードを読んでみることをお勧めします。

## 9. 設定キーの一覧 (Configuration Keys)

オプション定義配列 (`OPTS`) 内で、通常のオプション定義とは別に、`&KEY=VALUE`
という形式の特別なキーを使って `getoptlong.sh` の動作を設定することができます。
これらの設定は、`getoptlong init` コマンドの引数で同名の設定を指定するよりも優先されます。

*   **`&HELP=<SPEC>`**
    *   説明: 自動生成されるヘルプオプションの定義をカスタマイズします。`<SPEC>` は通常のオプション定義と同様の書式 (例: `myhelp|H#カスタムヘルプ`) です。
    *   デフォルト: `help|h#show help`
    *   参照: 「4.1. 自動ヘルプオプション」

*   **`&USAGE=<string>`**
    *   説明: ヘルプメッセージの先頭に表示される使用法 (Synopsis) の文字列を指定します。
    *   デフォルト: 指定なし (Synopsis は表示されない)
    *   参照: 「4.3.1. 使用法 (Synopsis) のカスタマイズ (`USAGE` 設定)」

*   **その他の設定キー:**
    *   現時点のドキュメントでは上記以外の `&KEY` 形式の設定は明記されていませんが、
        ライブラリのバージョンによっては他の設定（例: `&DELIM`, `&PREFIX` など）も
        サポートされる可能性があります。正確な情報については、利用している `getoptlong.sh` のバージョンに対応するドキュメントやソースコードを確認してください。

## 10. 関連情報 (See Also)

`getoptlong.sh` と同様の目的を持つ他のツールや、関連する情報源です。

-   **GNU `getopt`**: C ライブラリの `getopt_long` 関数のコマンドラインユーティリティ版。複雑なオプションのパースに使われますが、シェルスクリプトでの利用は一手間必要な場合があります。
-   **Bash `getopts`**: Bash の組み込みコマンド。POSIX スタイルのショートオプションのみをサポートし、ロングオプションやオプションの自由な順序（permutation）には対応していません。
-   **Perl `Getopt::Long`**: Perl で非常に広く使われているコマンドラインオプション解析モジュール。`getoptlong.sh` はこのモジュールに影響を受けている部分があります。
-   **Python `argparse`**: Python の標準ライブラリで、コマンドライン引数をパースするための強力なモジュールです。
-   [`getoptions` (ko1nksm/getoptions)](https://github.com/ko1nksm/getoptions): Another powerful option parser for shell scripts, which inspired some features in `getoptlong.sh`.
-   [`argh` (adrienverge/argh)](https://github.com/adrienverge/argh): A minimalist argument handler for bash.

[end of README.md]
