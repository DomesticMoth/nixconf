function fish_prompt
  set st $status
  set -l uid (id -u $USER)

  set -g __fish_git_prompt_showupstream auto
  set gitinfo (fish_git_prompt)
  echo ""
  set_color -o yellow
  echo -n "[ "
  set_color -o green
  echo -n (whoami)
  set_color -o red
  echo -n @
  set_color -o blue
  echo -n (hostname)
  set_color -o yellow
  echo -n " ] ["
  set_color -o green
  echo -n ' '(prompt_pwd)
  set_color -o yellow
  echo -n " ]"
  if [ -n "$gitinfo" ]
    echo -n $gitinfo
  end
  echo ""
  
  set_color -o yellow
  if test -n "$IN_NIX_SHELL"
    echo -n "[nix] "
  end
  if [ $uid -eq 0 ]
    set_color -o red
    echo -n "#"
  else
    set_color -o green
    echo -n "\$"
  end
  
  if test $st -eq 0
    set_color -o green
  else
    set_color -o red
    echo -n "$st"
  end
  echo -n "❯❯ "
  set_color $fish_color_normal
end

#function fish_greeting
#  export TERM=xterm-256color # fix https://github.com/thestinger/termite/issues/630
#end
