----------------------------------------------------------------------------
-- $Id: CRCLib.lua 223 2006-05-16 04:58:16Z Miravlix $
--
-- WoW CRC32 library
----------------------------------------------------------------------------

local VERSION = 0.2
CRCLib_debug = false

--
--[[ CRCLib: Embedded Sub-Library Loader ]]--
--

local isBetterInstanceLoaded = (
	-- Check if the existing version is just as good
	CRCLib and
	CRCLib.version >= VERSION
)

--[[ Sea.wow.CIB: Embedded Post-Sub-Library Loader ]]--

if not isBetterInstanceLoaded then
	CRCLib = {}
	CRCLib.version = VERSION
------------------------------------------------------------------------
-- zero-compression zip writer from nullzip.lua ver 0.9.5, by KHMan
------------------------------------------------------------------------
-- Selected Notes:
-- * Note: these notes are for the 4-bit per round lookup xor...
-- * the output is limited to primitive header blocks (no zip64 records)
-- * CRC is disappointingly slow, is there any other way to do it?
-- * writes out data at about 100K/sec on an Athlon 2500+
--   (100 calls to nullzip_test() 4.5K sxw writing test in 10 sec)
------------------------------------------------------------------------

-- auto-select proper functions to use based on availability of the
-- bitwise function library; then checks function vars just to be sure
local bxor, band, bshr

-- Disabled due to WoW bitlib working strangely

--if type(bit) == "table" then
--  bxor = bit.bxor
--  band = bit.band
--  bshr = bit.rshift
--end

if not bxor or not band or not bshr then
	bxor = nil
end

------------------------------------------------------------------------
-- Compute bitwise xor using a 4 bit-at-a-time table lookup. Is there
-- any faster xor-calculating algorithm on vanilla Lua? Or a CRC
-- algorithm that doesn't use (or use fewer) xor (or bitwise) ops?
-- * strings and handling lookups in byte chunks is not faster
-- * a 64K lookup table is 40% faster
-- * a 64K string byte-lookup is 50% faster
-- * building 64K tables is slow, but perhaps can load a binary file...
------------------------------------------------------------------------

local xor_lookup, xor_init, xor
if not bxor then
	xor_lookup = {}

	function xor_init()
		local idx = 0
		for x = 0, 15 do
			for y = 0, 15 do
				local bz = 1
				local xx = x; local yy = y
				xor_lookup[idx] = 0
				for z = 1, 4 do
					if math.fmod(xx, 2) ~= math.fmod(yy, 2) then
						xor_lookup[idx] = xor_lookup[idx] + bz
					end
					xx = math.floor(xx / 2); yy = math.floor(yy / 2)
					bz = bz * 2
				end
				idx = idx + 1
			end
		end
	end

	function xor(x, y, size)
		local z = 0
		local nz = 1
		size = size or 8
		for n = 1, size do
			local nx = math.fmod(x, 16); x = (x - nx) / 16
			local ny = math.fmod(y, 16); y = (y - ny) / 16
			z = xor_lookup[nx * 16 + ny] * nz + z
			nz = nz * 16
		end
		return z
  end

	xor_init()
end--if not bxor

------------------------------------------------------------------------
-- Straight adaptation of CRC32 code from RFC 1952 (from ISO 3309/ITU-T
-- V.42). The crc should be initialized to zero. Pre- and post-
-- conditioning (one's complement) is performed within
-- nullzip_update_crc so it shouldn't be done by the caller.
------------------------------------------------------------------------

local nullzip_crc_table         -- table of CRCs of all 8-bit messages

------------------------------------------------------------------------
-- nullzip_make_crc_table: make the table for a fast CRC.
-- Can be replaced by the precomputed table instead.
-- Usage: crc = nullzip_crc(data)
------------------------------------------------------------------------

local nullzip_make_crc_table
if bxor then
	nullzip_make_crc_table =
		function()
			local CONST1 = tonumber("EDB88320", 16)
			nullzip_crc_table = {}
			for n = 0, 255 do
				local c = n
				for k = 0, 7 do
					if bit.mod(c, 2) == 1 then
						-- c = 0xedb88320L ^ (c >> 1);
						c = bxor(CONST1, bshr(c, 1))
					else
						c = bshr(c, 1)
					end
				end
				nullzip_crc_table[n] = c
			end
		end
	else--if not bxor
	nullzip_make_crc_table =
		function()
			local CONST1 = tonumber("EDB88320", 16)
			nullzip_crc_table = {}
			for n = 0, 255 do
				local c = n
				for k = 0, 7 do
					if math.fmod(c, 2) == 1 then
						-- c = 0xedb88320L ^ (c >> 1);
						c = xor(CONST1, math.floor(c / 2))
					else
						c = math.floor(c / 2)
					end
				end
				nullzip_crc_table[n] = c
			end
		end
end--if bxor

------------------------------------------------------------------------
-- nullzip_update_crc: update a running crc with a specified buffer
-- Usage: crc = nullzip_update_crc(original_crc, data)
------------------------------------------------------------------------

local nullzip_update_crc
if bxor then
	nullzip_update_crc =
		function(original_crc, data)
			local CONST1 = tonumber("FFFFFFFF", 16)
			local c = bxor(original_crc, CONST1)
			if not nullzip_crc_table then
				nullzip_make_crc_table()
			end
			for n = 1, string.len(data) do
				-- c = crc_table[(c ^ buf[n]) & 0xff] ^ (c >> 8);
				c = bxor(nullzip_crc_table[band(bxor(c, string.byte(data, n)), 255)],
					 bshr(c, 8))
			end
			return bxor(c, CONST1)
		end
	else--if not bxor
	nullzip_update_crc =
		function(original_crc, data)
			local CONST1 = tonumber("FFFFFFFF", 16)
			local c = xor(original_crc, CONST1)
			if not nullzip_crc_table then
				nullzip_make_crc_table()
			end
			for n = 1, string.len(data) do
				-- c = crc_table[(c ^ buf[n]) & 0xff] ^ (c >> 8);
				c = xor(nullzip_crc_table[xor(c, string.byte(data, n), 2)],
					math.floor(c / 256))
			end
			return xor(c, CONST1)
		end
end--if bxor

--
-- CRCLib exported functions
--
function CRCLib.crc(data)
	return nullzip_update_crc(0, data)
end

end
