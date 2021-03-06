module hi;

import std.stdio;

import command;
import util;

import colored;

bool
input_prompt(ref char[] buf, immutable string message, immutable string p)
{
        import std.string : chop, format;
        bool eof;

        if (isatty(0))
                buf = "%s%s".format(message.bold, p.bold).rlw(eof).dup;
        else
                buf = readln.dup;
        return eof;
}

void
input_handle(ref char[] buf)
{
        import std.array : split;
        import std.conv : to, ConvException, ConvOverflowException;
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
        try switch (args[0]) {
        case cmd_user_get:
                args[1].idup.to!size_t.command_user_get;
                break;
        case cmd_user_get_with_username:
                args[1].idup.command_user_get_with_username;
                break;
        case cmd_user_set:
                args[1].idup.command_user_set;
                break;
        case cmd_getquality:
                args[1].idup.to!size_t.command_getquality;
                break;
        case cmd_getquality_with_username:
                args[1].idup.command_getquality_username;
                break;
        case cmd_browse:
                args[1].idup.to!size_t.command_browse;
                break;
        case cmd_browse_with_username:
                args[1].idup.command_browse_username;
                break;
        case cmd_setquality:
                args[1].idup.to!size_t.command_setquality;
                break;
        case cmd_setquality_string:
                args[1].idup.command_setquality_string;
                break;
        case cmd_service:
                args[1].idup.to!size_t.command_service;
                break;
        case cmd_service_with_ident:
                args[1].idup.command_service_ident;
                break;
        case cmd_usage:
                args[1].idup.command_usage;
                break;
        case cmd_run:
                args[1].idup.to!size_t.command_run;
                break;
        case cmd_run_with_username:
                args[1].idup.command_run_with_username;
                break;
        case cmd_popout:
                args[1].idup.to!size_t.command_popout;
                break;
        case cmd_popout_with_username:
                args[1].idup.command_popout_with_username;
                break;
        case cmd_chat:
                args[1].idup.to!size_t.command_chat;
                break;
        case cmd_chat_string:
                args[1].idup.command_chat_string;
                break;
        default:
                break;
        } catch (ConvOverflowException) {
                goto fail_conv;
        } catch (ConvException) {
                goto fail_conv;
        }

fail:
        if (args[0] !in commands)
                "command `%s` not found - try `help`".writefln(args[0]);
        return;
fail_conv:
        "The given index was not a valid number, or out of range.".writeln;
        return;
}
