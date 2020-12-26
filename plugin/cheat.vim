if exists('g:loaded_nvim_cheat') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_nvim_cheat = 1

command! -nargs=* Cheat lua require'nvim-cheat':new_cheat(false, [[<args>]])
command! -nargs=* CheatWithoutComments lua require'nvim-cheat':new_cheat(true, [[<args>]])
