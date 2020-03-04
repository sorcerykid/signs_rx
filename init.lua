--------------------------------------------------------
-- Minetest :: Signs Redux Mod (signs_rx)
--
-- See README.txt for licensing and other information.
-- Copyright (c) 2016-2020, Leslie E. Krause
--
-- ./games/minetest_game/mods/signs_rx/init.lua
--------------------------------------------------------

local config = minetest.load_config( )

local fs = minetest.formspec_escape
local open_sign_viewer
local open_sign_editor

-----------------------

function open_sign_viewer( player_name, pos, color, scale, message, vars, is_preview )

	local page_colors = {
		gray = { canvas = "#555555FF", border = "#333333FF" },
		black = { canvas = "#000000FF", border = "#333333FF" },
		brown = { canvas = "#553300FF", border = "#221100FF" },
		teal = { canvas = "#005533FF", border = "#002111FF" },
		purple = { canvas = "#330055FF", border = "#110022FF" },
		olive = { canvas = "#335500FF", border = "#112200FF" },
		indigo = { canvas = "#003355FF", border = "#001122FF" },
		maroon = { canvas = "#550033FF", border = "#220011FF" },
		red = { canvas = "#550000FF", border = "#220000FF" },
		green = { canvas = "#005500FF", border = "#002200FF" },
		blue = { canvas = "#000055FF", border = "#000022FF" },
       	}
	local page_scales = {
		small = { width = 8.0, height = 5.5 },
		tall = { width = 8.0, height = 8.0 },
		large = { width = 11.5, height = 8.0 },
		wide = { width = 11.5, height = 5.5 },
	}

	local function get_formspec( )
		local page_width = page_scales[ scale ].width
		local page_height = page_scales[ scale ].height

		local formspec =
			string.format( "size[%0.1f,%0.1f]", page_width, is_preview and page_height - 0.5 or page_height ) ..
			default.gui_bg ..
			default.gui_bg_img ..
--			string.format( "box[0.4,0.3;%0.1f,%0.1f;%s]", page_width - 0.8, page_height - 1.7, color )

			string.format( "box[0.4,0.3;%0.1f,%0.1f;%s]",
				page_width - 0.9, page_height - 1.7, page_colors[ color ].canvas
			) ..
			string.format( "box[0.4,0.3;%0.2f,0.05;%s]",
				page_width - 0.9, "#111111"
			) ..
			string.format( "box[0.4,0.3;0.05,%0.2f;%s]",
				page_height - 1.7, "#111111"
			) ..
			string.format( "box[0.4,%0.2f;%0.2f,0.05;%s]",
				0.3 + page_height - 1.75, page_width - 0.9, "#555555"
			) ..
			string.format( "box[%0.2f,0.3;0.05,%0.2f;%s]",
				0.4 + page_width - 0.95, page_height - 1.7, "#555555"
			)

	        local min_x = 0.6
        	local min_y = 0.5
        	local max_x = min_x + page_width - 1.2
	        local max_y = min_y + page_height - 2.0

		local rows = markup.parse_message( message, vars )

		formspec = formspec .. markup.get_formspec_string( rows, min_x, min_y, max_x, max_y, page_colors[ color ].border, "#FFFFFF" )

		if not is_preview then
			formspec = formspec ..
				string.format( "label[%0.1f,%0.1f;Right-click the sign holding sneak to open the message editor.\n]",
					( page_width - 7.2 ) / 2, page_height - 1.3 ) ..
				string.format( "button_exit[%0.1f,%0.1f;2,0.3;close;Close]",
					( page_width - 2.0 ) / 2, page_height - 0.5 )
		else
			formspec = formspec ..
				string.format( "button[%0.1f,%0.1f;2,0.3;modify;Modify]",
					( page_width - 2.0 ) / 2, page_height - 1.0 )
		end

		return formspec
	end

	local function on_close( state, player, fields )
		if is_preview and fields.modify then
			open_sign_editor( player_name, pos, color, scale, message, vars )
		end
	end

	-- basic sanity check for proper inputs
	if not page_scales[ scale ] then scale = "small" end
	if not page_colors[ color ] then color = "gray" end

	minetest.create_form( nil, player_name, get_formspec( ), on_close, is_preview and minetest.FORMSPEC_SIGSTOP or nil )
end

function open_sign_editor( player_name, pos, color, scale, message, vars )
	local page_colors = { "gray", "black", "brown", "teal", "purple", "olive", "indigo", "maroon", "red", "green", "blue" }
	local page_scales = { "small", "large", "tall", "wide" }

	-- debug function to analyze string input (via console)
	local function hex_dump( buf )
		for i=1, math.ceil( #buf / 16 ) * 16 do
			if ( i - 1 ) % 16 == 0 then io.write( string.format( '%08X   ', i - 1 ) ) end
			io.write( i > #buf and '   ' or string.format( '%02x ', buf:byte( i ) ) )
			if i % 8 == 0 then io.write( ' ' ) end
			if i % 16 == 0 then io.write( buf:sub( i - 16 + 1, i ):gsub( '%s', '.' ), '\n' ) end
		end
	end

	local function sanitize( buf )
		return string.trim( string.gsub( buf, ".", { ["\r"] = "\n", ["\t"] = " ", ["\f"] = "?", ["\b"] = "?" } ) ) .. "\n"
	end

	local function get_formspec( )
		local formspec =
			"size[8,9]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			"textarea[0.3,0.4;8,4.5;message;Enter the message to display on the sign (1500 character limit);" .. minetest.formspec_escape( message ) .. "]" ..
			"label[0.1,4.7;Sign Color:]" ..
			"dropdown[1.5,4.6;2.5,1;color;" .. table.concat( page_colors, "," ) .. ";" .. table.get_index( page_colors, color, 1 ) .. "]" ..
			"label[4.0,4.7;Sign Scale:]" ..
			"dropdown[5.5,4.6;2.5,1;scale;" .. table.concat( page_scales, "," ) .. ";" .. table.get_index( page_scales, scale, 1 ) .. "]" ..
			"label[0.1,5.5;Layout & Formatting Tags:\n]" ..
			"label[0.3,6.0;" .. minetest.formspec_escape( "[q=black][/q] = black text\n[q=red][/q] = red text\n[q=green][/q] = green text\n[q=blue][/q] = blue text\n[r] or [r=#] = next row (depth)" ) .. "]" ..
			"label[4.0,6.0;" .. minetest.formspec_escape( "[q=gray][/q] = gray text\n[q=cyan][/q] = cyan text\n[q=magenta][/q] = magenta text\n[q=yellow][/q] = yellow text\n[c] or [c=#] = next column (width)" ) .. "]" ..
			"label[0.1,8.4;Converter:]" ..
			"dropdown[1.5,8.3;2.5,1;converter;Version 2,Version 1;1]" ..
			"button[4.0,8.5;2,0.3;preview;Preview]" ..
			"button_exit[6.0,8.5;2,0.3;publish;Publish]"

		return formspec
	end

	local function on_close( state, player, fields )

		if fields.preview or fields.publish then
			if not fields.message or not fields.color or not fields.scale then
				return
			elseif fields.message ~= "" and string.len( fields.message ) < config.min_sign_message_length then
				minetest.chat_send_player( player_name, "The specified message is too short." )
				return
			elseif string.len( fields.message ) > config.max_sign_message_length then
				minetest.chat_send_player( player_name, "The specified message is too long." )
				return
			end

			message = sanitize( fields.message )

			if fields.preview then
				open_sign_viewer( player_name, pos, fields.color, fields.scale, message, vars, true )
			
			elseif fields.publish then
				if minetest.is_protected( pos, player_name ) then
					minetest.record_protection_violation( pos, player_name )
					return
				end

				local meta = minetest.get_meta( pos )
				local infotext = message == "" and config.default_sign_message or message

				--hex_dump( infotext )

				if fields.converter == "Version 1" then
					infotext = string.gsub( infotext, "([^,;:/])%s*\n%s*", "%1 / " )
					infotext = string.gsub( infotext, "%s*%[[rbhc].-%]%s*", "\n" )
					infotext = string.gsub( infotext, "%[q.-%]", "" )
					infotext = string.gsub( infotext, "%[/q%]", "" )
					infotext = string.gsub( infotext, "%%{.-}", "(func)" )
					infotext = string.gsub( infotext, "%$([a-zA-Z0-9]+)", "(%1)" )
					infotext = string.gsub( infotext, "%[[i][^%]]*%].-%s", "(item) " )
					infotext = string.gsub( infotext, "%[[s][^%]]*%].-%s", "(skin) " )
					infotext = string.trim( infotext )
				elseif fields.converter == "Version 2" then
					-- basic housekeeping of newlines
					infotext = string.gsub( infotext, ":%s*\n%s*", ": " )
					infotext = string.gsub( infotext, "%*%s*\n%s*", "* " )
					infotext = string.gsub( infotext, "%s*\n%s*", " " )
	
					infotext = string.gsub( infotext, "%s*%[[rbh][^%]]*%]%s*", "\n" )		-- always move next row to new line
					infotext = string.gsub( infotext, "\n%s*%[c[^%]]*%]%s*", "\n" )			-- keep cell after colon on same line
					infotext = string.gsub( infotext, ":%s*%[c[^%]]*%]%s*", ": " )			-- keep cell after colon on same line
					infotext = string.gsub( infotext, "%s*%[c[^%]]*%]%s*", " / " )			-- otherwise separate cell with slash
					infotext = string.gsub( infotext, "%[q[^%]]*%]", "" )				-- strip out formatting codes
					infotext = string.gsub( infotext, "%[/q%]", "" )
					infotext = string.gsub( infotext, "%%{.-}", "(func)" )				-- delimit functions by parentheses
					infotext = string.gsub( infotext, "%$([a-zA-Z0-9]+)", "(%1)" )			-- delimit variables by parentheses
					infotext = string.gsub( infotext, "%[[i][^%]]*%].-%s", "(item) " )
					infotext = string.gsub( infotext, "%[[s][^%]]*%].-%s", "(skin) " )
					infotext = string.trim( infotext )
				end

				minetest.log( "action", player_name .. " wrote \"" .. string.gsub( message, "[\n\t]", "" ) .. "\" to sign at " .. minetest.pos_to_string( pos ) )
				meta:set_string( "infotext", "\"" .. infotext .. "\"" )
				meta:set_string( "text", message )
				meta:set_string( "color", fields.color )
				meta:set_string( "scale", fields.scale )
			end
		end
	end

	minetest.create_form( nil, player_name, get_formspec( ), on_close, minetest.FORMSPEC_SIGSTOP )
end

-----------------------

default.register_sign = function ( material, desc, def )
	minetest.register_node( ":default:sign_wall_" .. material, {
		description = desc .. " Sign",
		drawtype = "nodebox",
		tiles = { "default_sign_wall_" .. material .. ".png" },
		inventory_image = "default_sign_" .. material .. ".png",
		wield_image = "default_sign_" .. material .. ".png",
		paramtype = "light",
		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		is_ground_content = false,
		walkable = false,
		node_box = {
			type = "wallmounted",
			wall_top    = {-0.4375, 0.4375, -0.3125, 0.4375, 0.5, 0.3125},
			wall_bottom = {-0.4375, -0.5, -0.3125, 0.4375, -0.4375, 0.3125},
			wall_side   = {-0.5, -0.3125, -0.4375, -0.4375, 0.3125, 0.4375},
		},
		groups = def.groups,
		legacy_wallmounted = true,
		sounds = def.sounds,
		override_sneak = true,

		on_construct = function( pos )
			local meta = minetest.get_meta( pos )
			meta:set_int( "oldtime", os.time( ) )
			meta:set_int( "newtime", os.time( ) )
			meta:set_string( "infotext", string.format( "\"%s\"", config.default_sign_message ) )
			meta:set_string( "text", config.default_sign_message )
			meta:set_string( "scale", "small" )
			meta:set_string( "color", "gray" )
		end,

		on_punch = function ( pos, node, puncher )
			local player_name = puncher:get_player_name( )
			if minetest.is_protected( pos, player_name ) then
				minetest.record_protection_violation( pos, player_name )
				return
			end
			local meta = minetest.get_meta( pos )
			if meta:get_string( "formspec" ) ~= "" then
				meta:set_string( "formspec", "" )
				minetest.chat_send_player( player_name, "Update successful! This sign can now be viewed and edited." )
			end
		end,

		on_rightclick = function ( pos, node, clicker )
			local player_name = clicker:get_player_name( )
			local meta = minetest.get_meta( pos )

			if meta:get_string( "formspec" ) ~= "" then
				minetest.chat_send_player( player_name, "This sign is no longer supported. Punch the sign to update it." )
				return
			end

			local message = meta:get_string( "text" )
			local color = meta:get_string( "color" )
			local scale = meta:get_string( "scale" )
			local vars = markup.get_builtin_vars( player_name )

			if clicker:get_player_control( ).sneak and not minetest.is_protected( pos, player_name ) then
				return open_sign_editor( player_name, pos, color, scale, message, vars )
			else
				return open_sign_viewer( player_name, pos, color, scale, message, vars, false )
			end
		end,
	} )
end

default.register_sign( "wood", "Wooden", {
	sounds = default.node_sound_wood_defaults( ),
	groups = { choppy = 2, attached_node = 1, flammable = 2, oddly_breakable_by_hand = 3 }
} )

default.register_sign( "steel", "Steel", {
	sounds = default.node_sound_metal_defaults( ),
	groups = { cracky = 2, attached_node = 1 }
} )
