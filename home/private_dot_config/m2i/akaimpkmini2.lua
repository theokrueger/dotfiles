--[[ Imported c++ Functions ]]--
--initialise()
--keypress( XK_keycode )
--keydown( XK_keycode )
--keyup( XK_keycode )
--buttonpress( n )
--buttondown( n )
--buttonup( n )
--mousemove( x, y )
--mousepos( x, y )
--midi_send( { status, data1, data2 } )
--exec( 'command' )
--
--[[ Imported Global Variables ]]--
--wm_class
--autoconnect
--
--[[ Functions you must create ]]
--midi_recv( status, data1, data2 )
--loop()

------------------------

--[[ Defines ]]--
-- types: dn = digital note (on/off), kn = knob (0-127),
local map = {
        -- keyboard
        -- white keys
        [0x30] = {
                keytype = 'dn',
                key = 38,
        },
        [0x32] = {
                keytype = 'dn',
                key = 39,
        },
        [0x34] = {
                keytype = 'dn',
                key = 40,
        },
        [0x35] = {
                keytype = 'dn',
                key = 41,
        },
        [0x37] = {
                keytype = 'dn',
                key = 42,
        },
        [0x39] = {
                keytype = 'dn',
                key = 43,
        },
        [0x3b] = {
                keytype = 'dn',
                key = 44,
        },
        [0x3c] = {
                keytype = 'dn',
                key = 52,
        },
        [0x3e] = {
                keytype = 'dn',
                key = 53,
        },
        [0x40] = {
                keytype = 'dn',
                key = 54,
        },
        [0x41] = {
                keytype = 'dn',
                key = 55,
        },
        [0x43] = {
                keytype = 'dn',
                key = 56,
        },
        [0x45] = {
                keytype = 'dn',
                key = 57,
        },
        [0x47] = {
                keytype = 'dn',
                key = 58,
        },
        [0x48] = {
                keytype = 'dn',
                key = 59,
        },
        -- black keys
        [0x31] = {
                keytype = 'dn',
                key = 24,
        },
        [0x33] = {
                keytype = 'dn',
                key = 25,
        },
        [0x36] = {
                keytype = 'dn',
                key = 26,
        },
        [0x38] = {
                keytype = 'dn',
                key = 27,
        },
        [0x3a] = {
                keytype = 'dn',
                key = 28,
        },
        [0x3d] = {
                keytype = 'dn',
                key = 29,
        },
        [0x3f] = {
                keytype = 'dn',
                key = 30,
        },
        [0x42] = {
                keytype = 'dn',
                key = 31,
        },
        [0x44] = {
                keytype = 'dn',
                key = 32,
        },
        [0x46] = {
                keytype = 'dn',
                key = 33,
        },
        -- pad
        [0x20] = {
                keytype = 'dn',
                key = 10,
        },
        [0x21] = {
                keytype = 'dn',
                key = 11,
        },
        [0x22] = {
                keytype = 'dn',
                key = 12,
        },
        [0x23] = {
                keytype = 'dn',
                key = 13,
        },
        [0x24] = {
                keytype = 'dn',
                key = 14,
        },
        [0x25] = {
                keytype = 'dn',
                key = 15,
        },
        [0x26] = {
                keytype = 'dn',
                key = 16,
        },
        [0x27] = {
                keytype = 'dn',
                key = 17,
        },
        -- knobs
        [0x01] = {
                keytype = 'kn',
                fn = function(data)
                        print('knob at '.. tostring(data))
                end,
        },
}

--[[ global settings ]]--
-- autoconnect: can be true, false, or a named jack port. default = true
autoconnect = true

--[[ Pattern matcher for messages ]]--
--
-- Both pattern and message share the same structure: {status, data1, data2}.
-- For any element of the pattern is equal -1, corresponding element of the
-- message is ignored / considered equal. Third element is often used for
-- continuous measurements such as acceleration, thus in addition to being -1,
-- it can also be nil, i.e. omitted entirely, making it for a table of two
-- elements, like this: {0xb0, 0x15} instead of this: {0xb0, 0x15, -1}.
local typehandler = {
        -- digital note (down/up)
        dn = function(b, d)
                if d > 0 then
                        keydown(b.key - 8)
                else
                        keyup(b.key - 8)
                end
        end,
        -- knob
        kn = function(b, d)
                b.fn(d)
        end,
}
function match_key(message)
        local b = map[message.button]
        if message.status == 0x00 or b == nil then return end
        typehandler[b.keytype](b, message.data)
end

--[[ initialisation function ]]--
-- run immediately after the application launches and connects to the device
function script_init()
        print( "nothing to initialise" )
end

function loop()
        --detectwindow()
end

--[[ Input Event Handler ]]--
function midi_recv( status, data1, data2 )
        local message = {
                status = status,
                button = data1,
                data  = data2,
        }
        match_key(message)
end
