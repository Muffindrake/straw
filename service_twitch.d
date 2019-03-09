module service_twitch;

import service;
import std.format;
import std.stdio;
import std.net.curl;
import std.json;
import std.uri : encode;

struct SVC_TTV_INFO {
        string username;
        string game_id;
        string game;
        string status;
}

SVC_TTV_INFO[] svc_ttv_store;
string[string] svc_ttv_games;

private
string[]
svc_ttv_check_game_ids()
{
        import std.array : appender;
        string[] arr;
        auto ret = appender(&arr);

        foreach (i, ref e; svc_ttv_store) if (e.game_id !in svc_ttv_games)
                ret.put(e.game_id);
        return arr;
}

void
svc_ttv_fetch_game_by_ids()
{
        import std.array : appender;
        import std.range : chunks;
        string url;
        size_t page_index;
        char[] res;

        auto page = svc_ttv_check_game_ids.chunks(100);
        page_index = 0;
        if (page.length == 0)
                return;
inf:
        if (page_index > page.length - 1)
                return;
        url = services[SVC_TWITCH].url_api_base ~ "games?";
        auto a = appender(&url);
        foreach (i, ref e; page[page_index][0 .. $ - 1])
                a.put("id=%s&".format(e));
        a.put("id=%s".format(page[page_index][$ - 1]));
        res = url.svc_ttv_fetch_default;
        JSONValue json = res.parseJSON;
        if ("data" !in json || json["data"].type != JSONType.array)
                throw new JSONException("invalid json");
        const (JSONValue)* data = "data" in json;
        foreach (i, ref e; data.array) {
                if ("id" !in e || e["id"].type != JSONType.string
                        || "name" !in e || e["name"].type != JSONType.string)
                        throw new JSONException("invalid json");
                svc_ttv_games[e["id"].str] = e["name"].str;
        }
        page_index++;
        goto inf;
}

void
svc_ttv_match_game_id()
{
        foreach (i, ref e; svc_ttv_store) if (e.game_id in svc_ttv_games)
                e.game = svc_ttv_games[e.game_id];
}

string
svc_ttv_fetch_user_id_from_name(immutable string name)
{
        string url;
        char[] res;

        url = "%susers?login=%s".format(services[SVC_TWITCH].url_api_base,
                        name);
        res = url.svc_ttv_fetch_default;
        JSONValue json = res.parseJSON;
        if ("data" !in json || json["data"].type != JSONType.array)
                throw new JSONException("invalid json");
        const auto data = "data" in json;
        if (!data.array.length)
                throw new JSONException("invalid json");
        if ("id" !in data.array[0]
                || data.array[0]["id"].type != JSONType.string)
                throw new JSONException("invalid json");
        return data.array[0]["id"].str;
}

private
string[]
svc_ttv_fetch_follows()
{
        import std.array : appender;
        string url;
        string page_token;
        char[] res;
        string[] follow;

        auto follows = appender(&follow);
inf:
        url = "%susers/follows?first=100&from_id=%s%s"
                        .format(services[SVC_TWITCH].url_api_base,
                                services[SVC_TWITCH].user_id,
                                page_token
                                ? "&after=%s".format(page_token) : "");
        res = url.svc_ttv_fetch_default;
        JSONValue json = res.parseJSON;
        if ("data" !in json || json["data"].type != JSONType.array)
                throw new JSONException("invalid json");
        const auto data = "data" in json;
        foreach (i, ref e; data.array) {
                if ("to_id" !in e || e["to_id"].type != JSONType.string)
                        throw new JSONException("invalid json");
                follows.put(e["to_id"].str);
        }
        if ("pagination" !in json || "cursor" !in json["pagination"]
                || json["pagination"]["cursor"].type != JSONType.string)
                page_token = null;
        else
                page_token = json["pagination"]["cursor"].str;
        if (page_token)
                goto inf;
        return follow;
}

private
char[]
svc_ttv_fetch_default(string url)
{
        import std.utf : validate;
        char[] ret;

        url = url.encode;
        auto client = HTTP(url);
        client.addRequestHeader("Client-ID", services[SVC_TWITCH].api);
        client.onReceive = (ubyte[] data) {
                ret = cast (char[]) data.dup;
                ret.validate;
                return data.length;
        };
        client.perform;
        return ret;
}

void
svc_ttv_fetch_information()
{
        import std.array : appender;
        import std.range : chunks;
        import std.string : strip;
        string[] user_follows_ids;
        size_t page_index;
        string url;
        char[] res;

        if (!services[SVC_TWITCH].user_id) {
                "error: called %s with user_id == null".writefln(__FUNCTION__);
                return;
        }
        user_follows_ids = svc_ttv_fetch_follows;
        svc_ttv_store.length = 0;
        if (!user_follows_ids.length)
                return;
        auto serv = appender(&svc_ttv_store);
        auto follows = user_follows_ids.chunks(100);
        page_index = 0;
inf:
        if (page_index > follows.length - 1)
                return;
        url = services[SVC_TWITCH].url_api_base ~ "streams?first=100&";
        auto a = appender(&url);
        foreach (i, ref e; follows[page_index][0 .. $ - 1])
                a.put("user_id=%s&".format(e));
        a.put("user_id=%s".format(follows[page_index][$ - 1]));
        res = url.svc_ttv_fetch_default;
        JSONValue json = res.parseJSON;
        if ("data" !in json || json["data"].type != JSONType.array)
                throw new JSONException("invalid json");
        const (JSONValue)* data = "data" in json;
        foreach (i, ref e; data.array) {
                if ("user_name" !in e
                        || e["user_name"].type != JSONType.string
                        || "game_id" !in e
                        || e["game_id"].type != JSONType.string
                        || "title" !in e
                        || e["title"].type != JSONType.string)
                        throw new JSONException("invalid json");
                serv.put(SVC_TTV_INFO(e["user_name"].str, e["game_id"].str,
                                null, e["title"].str.strip));
        }
        page_index++;
        goto inf;
}

void
svc_ttv_update()
{
        import std.algorithm.sorting : sort;

        services[SVC_TWITCH].user_id = services[SVC_TWITCH].user_name
                        .svc_ttv_fetch_user_id_from_name;
        svc_ttv_fetch_information;
        svc_ttv_store.sort!("a.username.toUpper < b.username.toUpper");
        svc_ttv_fetch_game_by_ids;
        svc_ttv_match_game_id;
}

string
svc_ttv_browse(size_t index)
{
        if (!svc_ttv_store.length || index > svc_ttv_store.length - 1)
                return null;
        return svc_ttv_store[index].username;
}

void
svc_ttv_listing()
{
        if (!svc_ttv_store.length) {
                "no information to list".writeln;
                return;
        }
        foreach (i, ref e; svc_ttv_store)
                "%02s %-12s <%s> %s".writefln(i, e.username, e.game, e.status);
}
