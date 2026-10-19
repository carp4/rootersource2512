module("luci.controller.netroam", package.seeall)

I18N = require "luci.i18n"
translate = I18N.translate

function index()
	entry({"admin", "modem", "netroam"}, template("netroam/netroam"), translate("Network Selection"), 39)
	entry({"admin", "modem", "netgetconnect"}, call("action_netgetconnect"))
	entry({"admin", "modem", "netgetscan"}, call("action_netgetscan"))
	entry({"admin", "modem", "netconnect"}, call("action_netconnect"))
	entry({"admin", "modem", "netclear"}, call("action_netclear"))
end

function action_netgetconnect()
	local rv ={}
	local netw = {}
	local netmc = {}
	local netlong = {}
	local netavail = {}
	
	connect = luci.model.uci.cursor():get("modem", "modem1", "connected")
	rv['connected'] = connect
	rv["data"] = "0"
	rv["error"] = "0"
	file = io.open("/tmp/copserror", "r")
	if file ~= nil then
		rv["error"] = "1"
		file:close()
	end
	file = io.open("/tmp/copseqxx", "r")
	if file ~= nil then
		rv["data"] = "1"
		mfile = io.open("/tmp/copseqmc", "r")
		lfile = io.open("/tmp/copseqlg", "r")
		afile = io.open("/tmp/copseqav", "r")
		indx = 0
		repeat
			line = file:read("*line")
			if line == nil then
				break
			end
			mline = mfile:read("*line")
			netw[indx] = line
			netmc[indx] = mline
			lline = lfile:read("*line")
			netlong[indx] = lline
			aline = afile:read("*line")
			netavail[indx] = aline
			indx = indx +1
		until 1 == 0
		rv['network'] = netw
		rv['mccmnc'] = netmc
		rv['long'] = netlong
		rv['avail'] = netavail
		rv['indx'] = tostring(indx)
		file:close()
		mfile:close()
		lfile:close()
		afile:close()
		os.execute("rm -f /tmp/copseqxx")
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function action_netgetscan()
	os.execute("/usr/lib/netroam/getcops.sh &")
end

function action_netconnect()
	local set = luci.http.formvalue("set")
	os.execute("/usr/lib/netroam/doconnect.sh " .. set)
end

function action_netclear()
	os.execute("/usr/lib/netroam/clear.sh")
end