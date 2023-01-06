
abstract type KeyInput end
struct ArrowLeft <: KeyInput end
struct ArrowRight <: KeyInput end
struct ArrowUp <: KeyInput end
struct ArrowDown <: KeyInput end
struct DelKey <: KeyInput end
struct HomeKey <: KeyInput end
struct EndKey <: KeyInput end
struct PageUpKey <: KeyInput end
struct PageDownKey <: KeyInput end
struct Enter <: KeyInput end
struct SpaceBar <: KeyInput end
struct CharKey <: KeyInput
    char::Char
end

KEYs = Dict{Int,KeyInput}(
    13 => Enter(),
    32 => SpaceBar(),
    1000 => ArrowLeft(),
    1001 => ArrowRight(),
    1002 => ArrowUp(),
    1003 => ArrowDown(),
    1004 => DelKey(),
    1005 => HomeKey(),
    1006 => EndKey(),
    1007 => PageUpKey(),
    1008 => PageDownKey(),
)


function help(live)
    internals = live.internals

    # get the docstring for each key_press method for the live renderable
    key_methods = methods(key_press, (typeof(live), LiveDisplays.KeyInput))

    dcs = Docs.meta(LiveDisplays)
    bd = Base.Docs.Binding(LiveDisplays, :key_press)

    added_sigs = []
    function get_method_docstring(m)
        try
            sig = m.sig.types[3]
            sig ∈ added_sigs && return ""
            docstr = dcs[bd].docs[Tuple{m.sig.types[2], m.sig.types[3]}].text[1]
            push!(added_sigs, sig)
            return docstr
        catch
            return ""
        end
    end

    width = console_width()
    methods_docs = map(
        m -> RenderableText(get_method_docstring(m); width=width-10),
        key_methods
    )  

    # compose help tooltip
    messages =  [
        RenderableText(md"#### Live Renderable description"; width=width-10),
        RenderableText(getdocs(live); width=width-10),
        "",
        RenderableText(md"#### Controls "; width=width-10),
        methods_docs...
        ]


    # create full message
    help_message = Panel(
        messages; 
        width=width,
        title="$(typeof(live)) help",
        title_style="default bold blue",
        title_justify=:center,
        style="dim",
        )


    # show/hide message
    if internals.help_shown
        # hide it
        internals.help_shown = false

        # go to the top of the error message and delete everything
        h = console_height() - length(internals.prevcontentlines) - help_message.measure.h - 1
        move_to_line(stdout, h)
        cleartoend(stdout)

        # move cursor back to the top of the live to re-print it in the right position
        move_to_line(stdout, console_height() - length(internals.prevcontentlines))
    else
        # show it
        erase!(live)
        println(stdout, help_message)
        internals.help_shown = true
    end

    internals.prevcontent = nothing
    internals.prevcontentlines = String[]
end


"""
    keyboard_input(live::AbstractLiveDisplay)

Read an user keyboard input during live display.

If there are bytes available at `stdin`, read them.
If it's a special character (e.g. arrows) call `key_press`
for the `AbstractLiveDisplay` with the corresponding
`KeyInput` type. Else, if it's not `q` (reserved for exit),
use that.
If the input was `q` it signals that the display should be stopped
"""
function keyboard_input(live)::Tuple{Bool, Any}
    if bytesavailable(terminal.in_stream) > 0
        c = readkey(terminal.in_stream) |> Int

        c in keys(KEYs) && begin
            key = KEYs[Int(c)]    
            retval = key_press(live, key)
            return (key isa Enter, retval)
        end

        # fallback to char key calls
        return key_press(live, CharKey(c))
    end
    return (false, nothing)
end