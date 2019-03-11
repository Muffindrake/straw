module command;

import setting;
import service;
import std.stdio;

enum {
        cmd_browse = "surf",
        cmd_browse_with_username = "surfn",
        cmd_fetch = "f",
        cmd_fetch_list = "fl",
        cmd_getquality = "getq",
        cmd_getquality_with_username = "getqn",
        cmd_help = "help",
        cmd_list = "l",
        cmd_listconfig = "lc",
        cmd_listquality = "lq",
        cmd_quit = "quit",
        cmd_run = "run",
        cmd_run_with_username = "runs",
        cmd_service = "svc",
        cmd_service_list = "svcl",
        cmd_service_with_ident = "svcn",
        cmd_setconfig = "setc",
        cmd_setquality = "setq",
        cmd_setquality_string = "setqs",
        cmd_usage = "usage",
        cmd_user_get = "info",
        cmd_user_set = "user"
}

struct CMD {
        size_t argc;
        string help;
}

CMD[string] commands;
static this()
{
commands[cmd_browse] = CMD(1,
        "open a web page using a valid index on the service website");
commands[cmd_browse_with_username] = CMD(1,
        "open a web page using any given username on the service website");
commands[cmd_fetch] = CMD(0, "fetch online information");
commands[cmd_fetch_list] = CMD(0,
        "fetch online information and then list the streams");
commands[cmd_getquality] = CMD(1,
        "obtain quality information for a given stream using an index");
commands[cmd_getquality_with_username] = CMD(1,
        "obtain quality information for a given stream using a username");
commands[cmd_help] = CMD(0, "list commands");
commands[cmd_list] = CMD(0,
        "list online streams using last fetched information");
commands[cmd_listconfig] = CMD(0, "list configuration options");
commands[cmd_listquality] = CMD(0,
        "obtain list of youtube-dl quality settings given in config file");
commands[cmd_quit] = CMD(0, "exit, quit, goodbye");
commands[cmd_run] = CMD(1, "run stream in video player using given index");
commands[cmd_run_with_username] = CMD(1,
        "run stream in video player using a username");
commands[cmd_service] = CMD(1, "change service to given index");
commands[cmd_service_list] = CMD(0, "list services");
commands[cmd_service_with_ident] = CMD(1, "change service to given name");
commands[cmd_setconfig] = CMD(2, "set a configuration option to a value");
commands[cmd_setquality] = CMD(1, "set configuration quality by index");
commands[cmd_setquality_string] = CMD(1,
        "set configuration quality using string");
commands[cmd_usage] = CMD(1, "display usage information for a given command");
commands[cmd_user_get] = CMD(1, "display channel information");
commands[cmd_user_set] = CMD(1, "set current username on service");
}

void
command_listconfig()
{
        import std.stdio : writefln;
        import std.format : format;
        auto cfg = configuration;

        "%s %s: %s".writefln(
                        typeof (cfg.terminal).stringof,
                        cfg.terminal.stringof,
                        cfg.terminal is null
                                ? "(null)" : `"%s"`.format(cfg.terminal));
        "%s %s: %s".writefln(
                        typeof (cfg.quality).stringof,
                        cfg.quality.stringof,
                        cfg.quality is null
                                ? "(null)" : `"%s"`.format(cfg.quality));
}

void
command_quit()
{
        import external : EXIT;

        throw new EXIT(0);
}

void
command_help()
{
        foreach (ref i, ref e; commands)
                "%6s: %s arg - %s".writefln(i, e.argc, e.help);
}

void
command_usage(immutable string command)
{
        if (command in commands) {
                CMD tmp = commands[command];
                "%6s: %s arg - %s".writefln(command, tmp.argc, tmp.help);
        } else {
                "command `%s` not found - try `help` for a listing"
                                .writefln(command);
        }
}

void
command_listquality()
{
        import quality;

        foreach (i, ref e; quality_table)
                "%02d\t%s".writefln(i, e);
}

void
command_setquality(size_t index)
{
        import quality;

        if (!quality_table.length || index > quality_table.length - 1) {
                "no such index %s in quality table of length %s"
                                .writefln(index, quality_table.length);
                return;
        }
        quality_table[index].command_setquality_string;
}

void
command_setquality_string(immutable string quality)
{
        configuration.quality = quality;
        "quality `%s` successfully set".writefln(quality);
}

void
command_service(size_t index)
{
        if (!services.length || index > services.length - 1) {
                "no such index %s in service table of length %s"
                                .writefln(index, services.length);
                return;
        }
        configuration.service_current = index;
        "service set to `%s`".writefln(services[index].ident);
}

void
command_service_ident(immutable string ident)
{
        foreach (i, ref e; services) if (e.ident == ident) {
                configuration.service_current = i;
                "service set to `%s`".writefln(ident);
                return;
        }
        "no such ident `%s` in service table".writefln(ident);

}

void
command_service_list()
{
        foreach (i, ref e; services)
                "%02d\t%s (%s)".writefln(i, e.name, e.ident);
}

void
command_browse_username(immutable string name)
{
        import std.process : browse;
        import external;
        string url;

        url = services[configuration.service_current].username_to_url(name);
        "opening link `%s` in default web browser".writefln(url);
        url.browser_run;
}

void
command_getquality(size_t index)
{
        import quality;

        string s = services[configuration.service_current].browse(index);
        if (!s) {
                "no such index %s in the service store".writefln(index);
                return;
        }
        s.command_getquality_username;
}

void
command_getquality_username(immutable string name)
{
        import external;
        string url;

        url = services[configuration.service_current].username_to_url(name);
        "fetching quality for `%s`".writefln(url);
        url.youtubedl_quality.write;
}

void
command_user_set(immutable string name)
{
        services[configuration.service_current].user_name = name;
        services[configuration.service_current].user_id = null;
        "username set to `%s`".writefln(name);
}

void
command_browse(size_t index)
{
        string s = services[configuration.service_current].browse(index);
        if (!s) {
                "no such index %s in the service store".writefln(index);
                return;
        }
        s.command_browse_username;
}

void
command_fetch()
{
        import std.exception;
        import std.json : JSONException;

        try
                services[configuration.service_current].fetch();
        catch (JSONException e) {
                "failure fetching information: %s".writefln(e.msg);
                return;
        }
        "successfully fetched service information".writeln;
}

void
command_listing()
{
        services[configuration.service_current].listing();
}

void
command_fetch_list()
{
        command_fetch;
        command_listing;
}

void
command_run(size_t index)
{
        immutable string s = services[configuration.service_current]
                        .browse(index);
        if (!s) {
                "no such index %s in current service store".writefln(index);
                return;
        }
        s.command_run_with_username;
}

void
command_run_with_username(immutable string name)
{
        import external;
        string url = services[configuration.service_current]
                        .username_to_url(name);

        "running stream %s in external video player".writefln(url);
        url.mpv_run(configuration.quality);
}

void
command_user_get(immutable string name)
{
        services[configuration.service_current].info(name);
}
