module hi;

import command;

bool
input_prompt(ref char[] buf, immutable string message, immutable string p)
{
        import std.stdio : write, readln;
        import std.string : chop;
        bool ret;

        message.write;
        p.write;
        ret = !buf.readln;
        if (ret)
                buf = "".dup;
        else
                buf = buf.chop;
        return ret;
}

void
input_handle(ref char[] buf)
{
        import std.array : split;
        import std.stdio;
        import std.conv : to;
        char[][] args = buf.split(' ');

        if (!args.length)
                return;
        switch (args[0]) {
        case cmd_help: command_help; break;
        case cmd_listquality: command_listquality; break;
        case cmd_listconfig: command_listconfig; break;
        case cmd_quit: command_quit; break;
        case cmd_service_list: command_service_list; break;
        case cmd_fetch: command_fetch; break;
        case cmd_list: command_listing; break;
        case cmd_fetch_list: command_fetch_list; break;
        default: break;
        }
        if (args.length < 2)
                goto fail;
        switch (args[0]) {
        case cmd_user_set:
                args[1].idup.command_user_set;
                break;
        case cmd_getquality_with_username:
                args[1].idup.command_getquality_username;
                break;
        case cmd_browse:
                to!size_t(args[1]).command_browse;
                break;
        case cmd_browse_with_username:
                args[1].idup.command_browse_username;
                break;
        case cmd_setquality:
                to!size_t(args[1]).command_setquality;
                break;
        case cmd_setquality_string:
                args[1].idup.command_setquality_string;
                break;
        case cmd_service:
                to!size_t(args[1]).command_service;
                break;
        case cmd_service_with_ident:
                args[1].idup.command_service_ident;
                break;
        case cmd_usage:
                args[1].idup.command_usage;
                break;
        case cmd_run:
                to!size_t(args[1]).command_run;
                break;
        case cmd_run_with_username:
                args[1].idup.command_run_with_username;
                break;
        default:
                break;
        }

fail:
        if (args[0] !in commands)
                "command `%s` not found - try `help`".writefln(args[0]);
}
