if [ -z "$TMUX" ]; then
    tmux attach -t hunting || tmux new -s hunting
fi
