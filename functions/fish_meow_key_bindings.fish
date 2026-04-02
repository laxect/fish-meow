# IMPORTANT!!!
#
# When defining your own bindings using fish_meow_command, be aware that it can break
# stuff sometimes.
#
# It is safe to define a binding consisting of a lone call to fish_meow_command.
# Calls to other functions and executables are allowed along with it, granted they don't mess
# with fish's commandline buffer.
#
# Mixing multiple fish_meow_commandline and commandline calls in one binding MAY trigger issues.
# Nothing serious, but don't be surprised. Just test it.

function fish_meow_key_bindings --description 'meow-like key bindings for fish'
    if contains -- -h $argv
        or contains -- --help $argv
        echo "Sorry but this function doesn't support -h or --help"
        return 1
    end

    # Erase all bindings if not explicitly requested otherwise to
    # allow for hybrid bindings.
    # This needs to be checked here because if we are called again
    # via the variable handler the argument will be gone.
    set -l rebind true
    if test "$argv[1]" = --no-erase
        set rebind false
        set -e argv[1]
    else
        bind --erase --all --preset # clear earlier bindings, if any
    end

    # Allow just calling this function to correctly set the bindings.
    # Because it's a rather discoverable name, users will execute it
    # and without this would then have subtly broken bindings.
    if test "$fish_key_bindings" != fish_meow_key_bindings
        and test "$rebind" = true
        # Allow the user to set the variable universally.
        set -q fish_key_bindings
        or set -g fish_key_bindings
        # This triggers the handler, which calls us again and ensures the user_key_bindings
        # are executed.
        set fish_key_bindings fish_meow_key_bindings
        return
    end

    set -l init_mode insert

    if contains -- $argv[1] insert default visual
        set init_mode $argv[1]
    else if set -q argv[1]
        # We should still go on so the bindings still get set.
        echo "Unknown argument $argv" >&2
    end

    # Inherit shared key bindings.
    # Do this first so meow-bindings win over default.
    for mode in insert default visual
        __fish_shared_key_bindings -s -M $mode
    end

    bind -s --preset -M insert \r execute
    bind -s --preset -M insert \n execute

    bind -s --preset -M insert "" self-insert

    # Space and other command terminators expand abbrs _and_ inserts itself.
    bind -s --preset -M insert " " self-insert expand-abbr
    bind -s --preset -M insert ";" self-insert expand-abbr
    bind -s --preset -M insert "|" self-insert expand-abbr
    bind -s --preset -M insert "&" self-insert expand-abbr
    bind -s --preset -M insert "^" self-insert expand-abbr
    bind -s --preset -M insert ">" self-insert expand-abbr
    bind -s --preset -M insert "<" self-insert expand-abbr
    # Closing a command substitution expands abbreviations
    bind -s --preset -M insert ")" self-insert expand-abbr
    # Ctrl-space inserts space without expanding abbrs
    bind -s --preset -M insert ctrl-space 'commandline -i " "'

    # Switching to insert mode
    for mode in default visual
        bind -s --preset -M $mode -m insert \cc end-selection cancel-commandline repaint-mode
        bind -s --preset -M $mode -m insert \n end-selection execute
        bind -s --preset -M $mode -m insert \r end-selection execute
        bind -s --preset -M $mode -m insert A end-selection insert-line-under repaint-mode
        bind -s --preset -M $mode -m insert I end-selection insert-line-over repaint-mode
        # FIXME i/a should keep selection, maybe
        bind -s --preset -M $mode i "fish_meow_command insert_mode"
        bind -s --preset -M $mode a "fish_meow_command append_mode"
    end

    # Switching from insert mode
    # Note if we are paging, we want to stay in insert mode
    # See #2871
    bind -s --preset -M insert \e "if commandline -P; commandline -f cancel; else; set fish_bind_mode default; commandline -f begin-selection repaint-mode; end"

    # Switching between normal and visual mode
    # Meow doesn't have a distinct visual mode in the same way, but we'll use it for selection
    for key in \e
        bind -s --preset -M visual -m default $key repaint-mode
    end

    # Motion and actions in normal/select mode
    for mode in default visual
        if test $mode = default
            set -f n_begin_selection begin-selection # only begin-selection if current mode is Normal
            set -f ns_move_extend move
            set -f commandline_v_repaint ""
        else
            set -f n_begin_selection
            set -f ns_move_extend extend
            set -f commandline_v_repaint "commandline -f repaint-mode"
        end

        for key in (seq 0 9)
            bind -s --preset -M $mode $key "fish_bind_count $key"
        end
        for key in h \e\[D \eOD
            bind -s --preset -M $mode $key "fish_meow_command "$ns_move_extend"_char_left"
        end
        bind -s --preset -M $mode left "fish_meow_command "$ns_move_extend"_char_left"
        for key in l \e\[C \eOC
            bind -s --preset -M $mode $key "fish_meow_command "$ns_move_extend"_char_right"
        end
        bind -s --preset -M $mode right "fish_meow_command "$ns_move_extend"_char_right"
        for key in k \e\[A \eOA
            bind -s --preset -M $mode $key "fish_meow_command char_up"
        end
        bind -s --preset -M $mode up "fish_meow_command char_up"
        for key in j \e\[B \eOB
            bind -s --preset -M $mode $key "fish_meow_command char_down"
        end
        bind -s --preset -M $mode down "fish_meow_command char_down"

        # Meow Expansion
        bind -s --preset -M $mode H "fish_meow_command extend_char_left"
        bind -s --preset -M $mode L "fish_meow_command extend_char_right"
        bind -s --preset -M $mode K "fish_meow_command extend_char_up"
        bind -s --preset -M $mode J "fish_meow_command extend_char_down"

        bind -s --preset -M $mode e "fish_meow_command next_word_start"
        bind -s --preset -M $mode b "fish_meow_command prev_word_start"
        bind -s --preset -M $mode w "fish_meow_command next_word_end"
        bind -s --preset -M $mode E "fish_meow_command next_long_word_start"
        bind -s --preset -M $mode B "fish_meow_command prev_long_word_start"
        bind -s --preset -M $mode W "fish_meow_command next_long_word_end"

        bind -s --preset -M $mode t "fish_meow_command till_next_char"
        bind -s --preset -M $mode f "fish_meow_command find_next_char"
        bind -s --preset -M $mode T "fish_meow_command till_prev_char"
        bind -s --preset -M $mode F "fish_meow_command find_prev_char"

        bind -s --preset -M $mode t,escape ""
        bind -s --preset -M $mode f,escape ""
        bind -s --preset -M $mode T,escape ""
        bind -s --preset -M $mode F,escape ""

        for key in enter ctrl-j
            bind -s --preset -M $mode t,$key "fish_meow_command till_next_cr"
            bind -s --preset -M $mode f,$key "fish_meow_command find_next_cr"
            bind -s --preset -M $mode T,$key "fish_meow_command till_prev_cr"
            bind -s --preset -M $mode F,$key "fish_meow_command find_prev_cr"
        end

        # Meow uses Q and X for goto line
        bind -s --preset -M $mode Q "fish_meow_command goto_line"
        bind -s --preset -M $mode X "fish_meow_command goto_line"

        # Cancel selection
        bind -s --preset -M $mode g "commandline -f end-selection repaint-mode"

        # Search/Visit
        bind -s --preset -M $mode v "commandline -f history-search-backward"
        bind -s --preset -M $mode n "commandline -f history-search-backward"
        # FIXME properly implement meow-search and meow-visit if possible

        # Selection/Expansion
        bind -s --preset -M $mode "," "fish_meow_command inner_of_thing"
        bind -s --preset -M $mode "." "fish_meow_command bounds_of_thing"
        bind -s --preset -M $mode "[" "fish_meow_command beginning_of_thing"
        bind -s --preset -M $mode "]" "fish_meow_command end_of_thing"

        # Kill/Change
        bind -s --preset -M $mode s "fish_meow_command delete_selection; set fish_bind_mode insert; commandline -f repaint-mode"
        bind -s --preset -M $mode z "commandline -f end-selection repaint-mode" # pop selection

        # FIXME alt-. doesn't work with t/T
        # FIXME alt-. doesn't work with [ftFT][\n\r]
        bind -s --preset -M $mode \e. repeat-jump

        # FIXME reselect after undo/redo
        bind -s --preset -M $mode u undo begin-selection
        bind -s --preset -M $mode U redo begin-selection

        bind -s --preset -M $mode -m replace_one r repaint-mode

        bind -s --preset -M $mode -m default d "fish_meow_command delete_selection; $commandline_v_repaint"
        bind -s --preset -M $mode -m default D "fish_meow_command backward_delete; $commandline_v_repaint"
        bind -s --preset -M $mode -m insert c "fish_meow_command delete_selection; commandline -f end-selection repaint-mode"

        bind -s --preset -M $mode -m default y "fish_meow_command yank"
        bind -s --preset -M $mode p "fish_meow_command paste_after"
        # P (paste_before) is not bound; Meow uses P for a different purpose not yet implemented.

        # Meow uses x for line selection (moved to the top of loop/mode specific)
        if test $mode = default
            bind -s --preset -M $mode -m visual x "fish_meow_command select_line"
        end

        bind -s --preset -M $mode \; "fish_meow_command reverse_selection"

        bind -s --preset -M $mode % "fish_meow_command select_all"

    end

    # FIXME should replace the whole selection
    # FIXME should be able to go back to visual mode
    bind -s --preset -M replace_one -m default '' delete-char self-insert backward-char repaint-mode
    bind -s --preset -M replace_one -m default \r 'commandline -f delete-char; commandline -i \n; commandline -f backward-char; commandline -f repaint-mode'
    bind -s --preset -M replace_one -m default \e cancel repaint-mode

    ## FIXME Insert mode keys

    ## Old config from vi:

    # Vi moves the cursor back if, after deleting, it is at EOL.
    # To emulate that, move forward, then backward, which will be a NOP
    # if there is something to move forward to.
    bind -s --preset -M insert delete delete-char forward-single-char backward-char
    bind -s --preset -M default delete delete-char forward-single-char backward-char

    # Backspace deletes a char in insert mode, but not in normal/default mode.
    bind -s --preset -M insert backspace backward-delete-char
    bind -s --preset -M default backspace backward-char
    bind -s --preset -M insert \ch backward-delete-char
    bind -s --preset -M default \ch backward-char
    bind -s --preset -M insert \x7f backward-delete-char
    bind -s --preset -M default \x7f backward-char
    bind -s --preset -M insert shift-delete backward-delete-char # shifted delete
    bind -s --preset -M default shift-delete backward-delete-char # shifted delete

    #    bind -s --preset '~' togglecase-char forward-single-char
    #    bind -s --preset gu downcase-word
    #    bind -s --preset gU upcase-word
    #
    #    bind -s --preset J end-of-line delete-char
    #    bind -s --preset K 'man (commandline -t) 2>/dev/null; or echo -n \a'
    #

    # same vim 'pasting' note as upper
    bind -s --preset '"*p' forward-char "commandline -i ( xsel -p; echo )[1]"
    bind -s --preset '"*P' "commandline -i ( xsel -p; echo )[1]"

    #
    # visual mode
    #

    # bind -s --preset -M visual -m insert c kill-selection end-selection repaint-mode
    # bind -s --preset -M visual -m insert s kill-selection end-selection repaint-mode
    bind -s --preset -M visual -m default '"*y' "fish_clipboard_copy; commandline -f end-selection repaint-mode"
    bind -s --preset -M visual -m default '~' togglecase-selection end-selection repaint-mode

    # Set the cursor shape
    # After executing once, this will have defined functions listening for the variable.
    # Therefore it needs to be before setting fish_bind_mode.
    fish_vi_cursor
    set -g fish_cursor_selection_mode inclusive

    set fish_bind_mode $init_mode

end
