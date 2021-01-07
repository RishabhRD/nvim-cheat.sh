if exists('g:loaded_nvim_cheat') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_nvim_cheat = 1

command! -nargs=* Cheat lua require'nvim-cheat':new_cheat(false, [[<args>]])
command! -nargs=* CheatWithoutComments lua require'nvim-cheat':new_cheat(true, [[<args>]])
command! -nargs=* CheatList lua require'nvim-cheat.cheatList':new_cheat_list(false, [[<args>]])
command! -nargs=* CheatListWithoutComments lua require'nvim-cheat.cheatList':new_cheat_list(true, [[<args>]])
