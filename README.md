# MDtoc: MarkDown ToC Vim Plugin

MDtoc is a Vim plugin intended to ease the creation of Table of Contents in
MarkDown files. It started as a simple "make a command to turn text into a
slug", then evolved into a "turn text into an anchor link", until finally
becoming a full blown plugin.

## Contents

1. [Features](#features)
2. [Installation](#installation)

## Features

The plugin offers the following commands:

* `:'<,'>Slug` is used in visual mode to convert the selected text into a slug.

* `:'<,'>Slurl` is used in visual mode to convert the  selected text into an
  anchor link pointing to a header with the same text. The idea was to copy a
  header to ToC and then convert that copy to a link.

* `:MDtoc` is used in normal mode to create the current document's ToC.  
  It parses the document from the current cursor position down to the end,
  recognises headers marked with any number of hash (`#`) signs (no `---` and
  `===` support, sorry), creates a ToC, and inserts it where the cursor is,
  also removing the existing ToC, if one already exists.

* `:MDtocd` is used in normal mode to create the current directory's ToC (the
  `d` in the name stands for "directory"). It parses the directory in which the
  file is saved and generates a joint ToC for all the files in that directory,
  skipping only the current file and those with names starting with `_` and
  `.`.

## Installation

Just put `markdown_toc.vim` in file-type plugin directory (on Linux, it is
usually `~/.vim/ftplugin/`). This will make the plugin active (and thus the
above functions available) in all documents recognised by Vim as MarkDown (but
not any others).

If you prefer to clone this repository and link the plugin from there (possibly
for modifications to the code), you can do something like this on Linux:

```bash
git clone git@github.com:vsego/markdown_toc.git
ln -sr markdown_toc/markdown_toc.vim ~/.vim/ftplugin/
```
