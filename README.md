# nvim-cheat.sh

[cheat.sh](https://github.com/chubin/cheat.sh) integration for neovim.

nvim-cheat.sh provides elegant UI and remove complexity of url handling and
special symbols for users.

## Screenshots

![](https://user-images.githubusercontent.com/26287448/103154931-3ba71d00-47c1-11eb-9844-2c706e5d9b09.gif)

## Installation

Install with your favorite plugin manager. For example with vim-plug:

```lua
Plug 'RishabhRD/popfix'
Plug 'RishabhRD/nvim-cheat.sh'
```

## Working

The plugin exports 4 commands:

- Cheat
- CheatWithoutComments
- CheatList
- CheatListWithoutComments

Each command accepts 0 or more arguments. Arguments decide the initial prompt
text.

CheatWithoutComments search the query but don't display the (optional) comments.

Example:
```vim
:Cheat
:Cheat cpp reverse number
:CheatWithoutComments
:CheatWithoutComments cpp reverse number
```

First and third command opens the prompt to search with and without comments
respectively.

Second and fourth command opens the prompt with initial prompt text
``cpp reverse number`` to search with and without comments respectively.

CheatList and CheatListWithoutComments provides fuzzy finding from all available symbols.


## How to query

Plugin behavior is similar to cheat.sh behavior.

The first word should be the language for query. (e.g. cpp)

Rest of words define the query. (e.g. sum of digits)

An example query:

```
cpp sum of digits
```

Try to put the language name matching vim filetype for the corresponding
language. This would also enable syntax highlighting for result.
Example: using ``javascript`` for javascript language would produce syntax
highlighting. However, using ``js`` for javascript would not as vim recognise
``javascript`` as filetype not ``js``.

For having different results for the same query append \1,  \2, etc to query similar to
classic cheat.sh.

Example: ``cpp read file\1``

## Keymaps

Keymaps for prompt are:

In insert mode:

- **\<CR\>** : Open result in floating window.
- **\<C-x\>** : Open result in horizontal split.
- **\<C-t\>** : Open result in a new tab.
- **\<C-v\>** : Open result in a vertical split.
- **\<C-y\>** : Open result in floating window.
- **\<C-c\>** : Close window without any action.
- **\<C-p\>** : Previous in history
- **\<C-n\>** : Next in history

In normal mode:

- **\<CR\>** : Open result in floating window.
- **\<C-x\>** : Open result in horizontal split.
- **\<C-t\>** : Open result in a new tab.
- **\<C-v\>** : Open result in a vertical split.
- **\<C-c\>** : Close window without any action.
- **\<Esc\>** : Close window without any action.
- **q** : Close window without any action.
- **k** : Previous in history
- **j** : Next in history
