# Adapted from TerminalPager.jl v0.8.0.
# Copyright (c) 2021-2026: Ronan Arraes Jardim Chagas
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# This adapter adds an initial source line to TerminalPager’s session loop.
import TerminalPager
using TerminalPager: Pager, PagerInput, DisplayConfig, TextViewLayout
using TerminalPager: _default_input_waiter, _display_config, _get_preference,
    _pager_content_fits, _turn_on_cursor_key_mode, _turn_on_alternate_screen_buffer,
    _clear_screen, _hide_cursor, _turn_on_mouse, _update_display_size!, _view!,
    _redraw!, _redraw_status_bar!, _wait_for_input!, _read_keystroke!, _clear_message!,
    _pager_key_process!, _coalesce_navigation!, _pager_event_process!, _restore_terminal,
    _close_input_waiter!, _with_raw_mode
const REPL = TerminalPager.REPL

function _start!(
    @nospecialize(term::REPL.Terminals.TTYTerminal),
    str::String,
    start_row::Integer;
    auto::Bool = false,
    change_freeze::Bool = true,
    display_config::Union{Nothing, DisplayConfig} = nothing,
    frozen_columns::Int = 0,
    frozen_rows::Int = 0,
    title_rows::Int = 0,
    has_help::Bool = true,
    has_visual_mode::Bool = true,
    show_ruler::Bool = false,
    show_scrollbar::Bool = _get_preference("show_scrollbar")::Bool,
    use_alternate_screen_buffer::Bool = true,
    input::Union{Nothing, PagerInput} = nothing,
    text_layout::Union{Nothing, TextViewLayout} = nothing,
    _layout_factory = TextViewLayout,
    manage_cursor_key_mode::Bool = true,
    manage_cursor::Bool = true,
    manage_mouse::Bool = true,
    _waiter_factory = _default_input_waiter,
)
    # The raw text is split only when no layout is supplied, and the result feeds both the
    # auto-fit check and the layout construction.
    source_lines = isnothing(text_layout) ? split(str, '\n') : text_layout

    # Get the display size and make sure it is type stable.
    dsize = displaysize(term.out_stream)::Tuple{Int, Int}

    if auto && _pager_content_fits(source_lines, dsize)
        print(str)
        return nothing
    end

    # Like the prompts that change them, the numbers of frozen and title rows and columns
    # cannot be negative. Otherwise, the view has more rows than the display, and a page
    # movement skips lines.
    frozen_rows = max(frozen_rows, 0)
    frozen_columns = max(frozen_columns, 0)
    title_rows = max(title_rows, 0)

    session_layout = isnothing(text_layout) ? _layout_factory(source_lines) : text_layout
    num_tokens = length(session_layout)
    session_config = isnothing(display_config) ? _display_config() : display_config
    session_input = isnothing(input) ? PagerInput(term.in_stream) : input
    session_input.stream === term.in_stream ||
        throw(ArgumentError("PagerInput must own the pager terminal input stream."))

    # Check if we should block the alternate screen buffer.
    block_alternate_screen_buffer = _get_preference("block_alternate_screen_buffer")::Bool
    use_alternate_screen_buffer &= !block_alternate_screen_buffer

    cursor_key_mode_enabled = false
    alternate_screen_enabled = false
    cursor_hidden = false
    mouse_enabled = false
    owns_waiter = false
    try
        if manage_cursor_key_mode
            cursor_key_mode_enabled = true
            _turn_on_cursor_key_mode(term.out_stream)
        end

        # Clear the screen and position the cursor at the top.
        if use_alternate_screen_buffer
            # As in `_with_raw_mode`, the flag is set before the write, so that a write that
            # partially reached the terminal is still undone.
            alternate_screen_enabled = true
            _turn_on_alternate_screen_buffer(term.out_stream)
        else
            _clear_screen(term.out_stream)
        end

        # The cursor has nothing to point at in the view. Hence, it is hidden for the whole
        # session and shown only while a command is edited. As above, the flag is set before
        # the write.
        if manage_cursor
            cursor_hidden = true
            _hide_cursor(term.out_stream)
        end

        # The mouse reporting lets the wheel scroll the text. It is a terminal state that
        # outlives the session if it is not disabled at the end.
        if manage_mouse && _get_preference("mouse")::Bool
            mouse_enabled = true
            _turn_on_mouse(term.out_stream)
        end

        # The pager is divided into a view and a command line. Everything in the view is
        # written to this buffer and then flushed to the screen.
        # The color flag must come from the session terminal, not from the global `stdout`,
        # so that a terminal built for another stream honors its own color support.
        iobuf = IOBuffer()
        hascolor = get(term.out_stream, :color, true)::Bool
        buf = IOContext(iobuf, :color => hascolor)

        features = Symbol[]
        change_freeze && push!(features, :change_freeze)
        has_help && push!(features, :help)
        has_visual_mode && push!(features, :visual_mode)

        # Initialize the pager structure.
        pagerd = Pager(;
            buf = buf,
            display_config = session_config,
            display_size = dsize,
            features = features,
            frozen_columns = frozen_columns,
            frozen_rows = frozen_rows,
            input = session_input,
            num_lines = num_tokens,
            show_ruler = show_ruler,
            show_scrollbar = show_scrollbar,
            scroll_regions = _get_preference("use_scroll_regions")::Bool,
            start_column = max(1, frozen_columns + 1),
            start_row = clamp(start_row, min(max(1, frozen_rows + 1), num_tokens), num_tokens),
            term = term,
            text_layout = session_layout,
            title_rows = title_rows,
        )

        # The waiter lets a change of the display size interrupt the wait for the input, so
        # that the screen is repainted without a keystroke. A nested session, such as the
        # help, shares the waiter of its parent through the input.
        if isnothing(session_input.waiter)
            waiter = _waiter_factory(term)

            if !isnothing(waiter)
                owns_waiter = true
                session_input.waiter = waiter
            end
        end

        # == Application Main Loop =========================================================

        while true
            # Check if the display size was changed.
            _update_display_size!(pagerd)

            # Check if we need to redraw the screen.
            if pagerd.redraw
                _view!(pagerd)
                _redraw!(pagerd)
                _redraw_status_bar!(pagerd)
            end

            # Wait for user input. A change of the display size interrupts the wait, and the
            # screen is repainted at the top of the loop.
            _wait_for_input!(pagerd) || continue

            # A message on the command line is shown until this keystroke, which is then
            # processed normally.
            k = _read_keystroke!(pagerd.input)
            _clear_message!(pagerd)
            action = _pager_key_process!(pagerd, k)
            _coalesce_navigation!(pagerd, action)
            _pager_event_process!(pagerd) || break
        end
    finally
        try
            _restore_terminal(
                term.out_stream;
                mouse = mouse_enabled,
                clear_status_row = cursor_hidden && !alternate_screen_enabled,
                show_cursor = cursor_hidden,
                alternate_screen = alternate_screen_enabled,
                cursor_key_mode = cursor_key_mode_enabled,
            )
        finally
            # The waiter is closed even if the restoration throws, so that its timer and its
            # reader task do not outlive the session.
            owns_waiter && _close_input_waiter!(session_input)
        end
    end

    return nothing
end


function source_pager(text::AbstractString, line::Integer)
    term = REPL.Terminals.TTYTerminal("", stdin, stdout, stderr)
    _with_raw_mode(term) do
        _start!(term, String(text), line)
    end
    nothing
end
