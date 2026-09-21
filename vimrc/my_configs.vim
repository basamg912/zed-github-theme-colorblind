"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Colors
"    basic.vim/extended.vim force `colorscheme desert/peaksea` and
"    `background=dark`. Remove that so the terminal's own theme
"    (GitHub light/dark automatic) controls the colors instead.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
colorscheme default
if exists('g:lightline')
  let g:lightline.colorscheme = 'default'
endif

" Without this, Vim only uses the terminal's 16-slot ANSI palette
" (ctermbg=N), and the GitHub light/dark automatic theme remaps those
" slots to its own muted tones -- so an explicit guibg=#hex below gets
" silently ignored and the "fixed" highlight color drifts with the theme.
" termguicolors makes Vim render the exact hex values instead.
if has('termguicolors')
  set termguicolors
endif

" 'default' colorscheme's Search/IncSearch is too washed out on a light
" background to notice. Force a fixed, high-contrast highlight that
" reads fine in both light and dark terminal themes.
highlight Search    ctermbg=11 ctermfg=0 guibg=#ffd633 guifg=#000000
highlight IncSearch ctermbg=9  ctermfg=0 guibg=#ff8c42 guifg=#000000


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Settings carried over from the old vimrc, not covered above
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Toggle search highlighting on/off
nnoremap <Esc><Esc> :set hlsearch!<CR>
set number relativenumber
set softtabstop=4
set nocursorline
set fileencoding=utf-8
set foldmethod=syntax
set foldlevel=999
set ttimeoutlen=50
autocmd FileType * setlocal formatoptions-=r formatoptions-=o

" Prefer 5 lines of scroll context over the awesome vimrc default of 7
set scrolloff=5

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => C++ compiler switch (coding-test GCC vs regular-dev Clang)
"    :CppCompiler gcc    -> g++-16 (GNU/libstdc++, has bits/stdc++.h,
"                           for coding-test sites that assume GCC)
"    :CppCompiler clang  -> clang++ (LLVM/libc++, for normal dev)
"    Drives both the F5 compile-and-run mapping and the ALE 'cc' linter.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:cpp_compilers = {
\   'gcc':   {'exe': 'g++-16', 'opts': '-std=c++17 -Wall -O2'},
\   'clang': {'exe': 'clang++', 'opts': '-std=c++17 -Wall -O2'},
\}

function! SetCppCompiler(name, ...) abort
  let l:silent = a:0 > 0 && a:1
  if !has_key(s:cpp_compilers, a:name)
    echoerr 'Unknown cpp compiler: ' . a:name . ' (use gcc or clang)'
    return
  endif
  let g:cpp_compiler = a:name
  let g:ale_cpp_cc_executable = s:cpp_compilers[a:name].exe
  let g:ale_cpp_cc_options = s:cpp_compilers[a:name].opts
  if &filetype ==# 'cpp' && exists(':ALELint')
    ALELint
  endif
  if !l:silent
    echo 'cpp compiler: ' . a:name . ' (' . s:cpp_compilers[a:name].exe . ')'
  endif
endfunction

command! -nargs=1 -complete=customlist,{a,l,p->keys(s:cpp_compilers)} CppCompiler call SetCppCompiler(<f-args>)

function! CompileRunCpp() abort
  let l:c = s:cpp_compilers[get(g:, 'cpp_compiler', 'gcc')]
  write
  execute '!' . l:c.exe . ' ' . l:c.opts . ' % -o %< && ./%<'
endfunction

" Overrides CompileRun()'s hardcoded g++ mapping in extended.vim
nnoremap <F5> :call CompileRunCpp()<CR>

" Default to GCC (current coding-test setup); switch anytime with
" :CppCompiler clang
call SetCppCompiler('gcc', 1)

" cpp wasn't restricted like javascript/python/go above, so ALE also ran
" clangd (Apple system clang, no bits/stdc++.h) alongside cc, producing
" a false 'file not found' error under the gcc profile. Limit cpp to cc.
let g:ale_linters.cpp = ['cc']

" Sign column colors for E/W markers
highlight ALEErrorSign ctermfg=red guifg=#e05252
highlight ALEWarningSign ctermfg=yellow guifg=#d7ba00
