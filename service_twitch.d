module service_twitch;

import std.conv;
import std.format;
import std.json;
import std.net.curl;
import std.stdio;
import std.uri : encode;

import service;
import util;

import colored;

struct SVC_TTV_INFO {
        string user_id;
        string game_id;
        string status;
}

SVC_TTV_INFO[] svc_ttv_store;
string[string] svc_ttv_game_id_to_name;
string[2][string] svc_ttv_user_id_to_login_display;

private
string[]
svc_ttv_check_game_ids()
{
        import std.array : appender;
        string[] arr;
        auto ret = appender(&arr);

        foreach (i, ref e; svc_ttv_store)
                if (e.game_id !in svc_ttv_game_id_to_name)
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
        if (page.length == 0)
                return;
        page_index = 0;
inf:
        if (page_index > page.length - 1)
                return;
        url = services[SVC_TWITCH].url_api_base ~ "games?";
        auto a = appender(&url);
        foreach (i, ref e; page[page_index][0 .. $ - 1])
                a.put("id=%s&".format(e));
        a.put("id=%s".format(page[page_index][$ - 1]));
        res = url.svc_ttv_fetch_default;
        auto json = res.parseJSON;
        if ("data" !in json || json["data"].type != JSONType.array)
                throw new JSONException("invalid json");
        const auto data = "data" in json;
        foreach (i, ref e; data.array) {
                if ("id" !in e || e["id"].type != JSONType.string
                        || "name" !in e || e["name"].type != JSONType.string)
                        throw new JSONException("invalid json");
                if (e["id"].str != "")
                        svc_ttv_game_id_to_name[e["id"].str] = e["name"].str;
        }
        page_index++;
        goto inf;
}

string
svc_ttv_fetch_user_id_from_name(string name)
{
        string url;
        char[] res;

        url = "%susers?login=%s".format(services[SVC_TWITCH].url_api_base,
                        name);
        res = url.svc_ttv_fetch_default;
        auto json = res.parseJSON;
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
        auto json = res.parseJSON;
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
void
svc_ttv_fetch_user_logins_displays()
{
        import std.array : appender;
        import std.range : chunks;
        string url;
        char[] res;
        size_t page_index;

        auto page = svc_ttv_store.chunks(100);
        if (!page.length)
                return;
        page_index = 0;
inf:
        if (page_index > page.length - 1)
                return;
        url = services[SVC_TWITCH].url_api_base ~ "users?";
        auto a = appender(&url);
        foreach (i, ref e; page[page_index][0 .. $ - 1])
                a.put("id=%s&".format(e.user_id));
        a.put("id=%s".format(page[page_index][$ - 1].user_id));
        res = url.svc_ttv_fetch_default;
        auto json = res.parseJSON;
        if ("data" !in json || json["data"].type != JSONType.array)
                throw new JSONException("invalid json");
        const auto data = "data" in json;
        foreach (i, ref e; data.array) {
                if ("id" !in e || e["id"].type != JSONType.string
                        || "login" !in e
                        || e["login"].type != JSONType.string
                        || "display_name" !in e
                        || e["display_name"].type != JSONType.string)
                        throw new JSONException("invalid json");
                else
                        svc_ttv_user_id_to_login_display[e["id"].str]
                                = [e["login"].str, e["display_name"].str];
        }
        page_index++;
        goto inf;

}

private
char[]
svc_ttv_fetch_default(string url)
{
        import std.utf : validate;
        import core.thread : Thread;
        import core.time : seconds;
        char[] ret;
        string after;
        size_t timeout;

        url = url.encode;
retry:
        timeout = 0;
        auto client = HTTP();
        client.addRequestHeader("Client-ID", services[SVC_TWITCH].api);
        try
                ret = url.get(client);
        catch (HTTPStatusException e)
                if (e.status == 429) {
                        /* the twitch API resets the entire token bucket of 30
                         * per client id after a minute */
                        /* 10 seconds should be fair time for users without
                         * ~1000 follows */
                        timeout = 10;
                        "note: rate limited, waiting %s seconds before retry"
                                        .writefln(timeout);
                        Thread.sleep(seconds(10));
                        goto retry;
                } else {
                        throw e;
                }
        ret.validate;
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
        auto json = res.parseJSON;
        if ("data" !in json || json["data"].type != JSONType.array)
                throw new JSONException("invalid json");
        const auto data = "data" in json;
        foreach (i, ref e; data.array) {
                if ("user_id" !in e
                        || e["user_id"].type != JSONType.string
                        || "game_id" !in e
                        || e["game_id"].type != JSONType.string
                        || "title" !in e
                        || e["title"].type != JSONType.string)
                        throw new JSONException("invalid json");
                serv.put(SVC_TTV_INFO(e["user_id"].str, e["game_id"].str,
                                e["title"].str.strip));
        }
        page_index++;
        goto inf;
}

void
svc_ttv_update()
{
        import std.algorithm.sorting : sort;
        import std.uni : toLower;

        services[SVC_TWITCH].user_id = services[SVC_TWITCH].user_name
                        .svc_ttv_fetch_user_id_from_name;
        svc_ttv_fetch_information;
        svc_ttv_fetch_game_by_ids;
        svc_ttv_fetch_user_logins_displays;
        svc_ttv_store.sort!(
                (ref auto a, ref auto b) =>
                        svc_ttv_user_id_to_login_display[a.user_id][0].toLower
                        <
                        svc_ttv_user_id_to_login_display[b.user_id][0].toLower
                );
}

string
svc_ttv_browse(size_t index)
{
        if (!svc_ttv_store.length || index > svc_ttv_store.length - 1)
                return "";
        if (svc_ttv_store[index].user_id !in svc_ttv_user_id_to_login_display)
                return "";
        return svc_ttv_user_id_to_login_display
                [svc_ttv_store[index].user_id][0];
}

void
svc_ttv_listing()
{
        import std.uni : toLower;
        import std.string : column;
        string login;
        string disp;
        string game;
        string user;
        alias user_id_map = svc_ttv_user_id_to_login_display;
        alias game_id_map = svc_ttv_game_id_to_name;

        if (!svc_ttv_store.length) {
                "no information to list".writeln;
                return;
        }
        foreach (i, ref e; svc_ttv_store) {
                if (e.user_id in user_id_map) {
                        login = user_id_map[e.user_id][0];
                        if (!login)
                                login = "N/A";
                        disp = user_id_map[e.user_id][1];
                        if (!disp)
                                disp = "N/A";
                } else {
                        login = "N/A";
                        disp = "N/A";
                }
                if (e.game_id in game_id_map)
                        game = game_id_map[e.game_id];
                else
                        game = "N/A";
                user = (login.toLower != disp.toLower
                        ? "%s(%s)".format(disp, login)
                        : disp);
                if (isatty(0))
                        "%02s %s <%s> %s".writefln(i.text.underlined, user,
                                        game.bold, e.status);
                else
                        "%02s %s <%s> %s".writefln(i, user, game, e.status);
        }
}

void
svc_ttv_info(string name)
{
        string url;
        char[] res;

        url = "%susers?login=%s".format(services[SVC_TWITCH].url_api_base,
                        name.encode);
        res = url.svc_ttv_fetch_default;
        auto json = res.parseJSON;
        if ("data" !in json || json["data"].type != JSONType.array)
                throw new JSONException("invalid json");
        const auto data = "data" in json;
        if (!data.array.length)
                return;
        foreach (ref i, ref e; data.array[0].object)
                "%18s: %s".writefln(i, e.type == JSONType.string
                                ? e.str : e.toString);
}

void
svc_ttv_store_clear()
{
        svc_ttv_store.length = 0;
}

size_t
svc_ttv_online_count()
{
        return svc_ttv_store.length;
}

void
svc_ttv_popout(string name)
{
        import std.process : browse;
        ("https://player.twitch.tv/?channel=" ~ name.encode).browse;
}

void
svc_ttv_chat(string name)
{
        import setting : configuration;
        import external : weechat_chat_join;
        import std.process : browse;

        if (configuration.ttv_webchat)
                "https://www.twitch.tv/popout/%s/chat?popout=".format(name.encode).browse;
        else
                weechat_chat_join(configuration.weechat_ttv_buffer, name);
}
