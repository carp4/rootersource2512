
module("luci.controller.basic", package.seeall)

I18N = require "luci.i18n"
translate = I18N.translate

function index()
	entry({"admin", "basic"}, firstchild(), translate("Wizard"), 1).dependent=false
	entry({"admin", "basic", "wizard"}, template("basic/wizard"), _(translate("Setup Wizard")), 1)

	entry({"admin", "basic", "getwizard"}, call("action_getwizard"))
	entry({"admin", "basic", "setwizard"}, call("action_setwizard"))
	entry({"admin", "basic", "setlang"}, call("action_setlang"))
end

function file_exists(name)
	local f=io.open(name,"r")
	if f~=nil then io.close(f) return true else return false end
end

function action_getwizard()
	local rv = {}
	
	rv['wizard'] = luci.model.uci.cursor():get("wizard", "basic", "wizard")
	if rv['wizard'] == "0" then
		if file_exists("/tmp/wiztest") then
			rv['wizard'] = "1"
		end
	end
	
	os.execute("/usr/lib/basic/getwizard.sh")
	rv['radnum'] = luci.model.uci.cursor():get("wizard", "wizard", "radionum")
	rv['ssid0'] = luci.model.uci.cursor():get("wizard", "wizard", "ssid0")
	rv['password0'] = luci.model.uci.cursor():get("wizard", "wizard", "password0")
	if rv['radnum'] == "2" then
		rv['ssid1'] = luci.model.uci.cursor():get("wizard", "wizard", "ssid1")
		rv['password1'] = luci.model.uci.cursor():get("wizard", "wizard", "password1")
	end
	rv['lang'] = luci.model.uci.cursor():get("luci", "main", "lang")
	rv['currzone'] = luci.model.uci.cursor():get("wizard", "wizard", "zone")
	
	file = io.open("/etc/config/zerotier", "r")
	if file == nil then
		rv['zerotier'] = "0"
	else
		rv['zerotier'] = "1"
		rv['remote'] = luci.model.uci.cursor():get("zerotier", "zerotier", "enabled")
		rv["netid"] = luci.model.uci.cursor():get("zerotier", "zerotier", "join")
		file:close()
	end
	
	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function action_setwizard()
	local rv = {}
	local set = luci.http.formvalue("set")
	os.execute("/usr/lib/basic/setwizard.sh " .. set)
end

function action_setlang()
	local rv = {}
	local set = luci.http.formvalue("set")
	os.execute("/usr/lib/basic/setlang.sh \"" .. set .. "\"")
end