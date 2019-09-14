import std.stdio;
import setting;
import service;
import util;

void
entrance()
{
        import hi;
        import std.format : format;
        import std.string : strip;
        char[] buf;
        bool end;
inf:
        end = buf.input_prompt(services[configuration.service_current].ident,
                "> ");
        if (end) {
                if (isatty(0))
                        writeln;
                return;
        }
        buf = buf.strip;
        input_handle(buf);
        goto inf;
}

int
main(string[] args)
{
        import external : EXIT;
        import command;
        import quality;

        configuration.service_current = SVC_TWITCH;
        configuration.quality = quality_table[1];
        configuration.terminal = "urxvt";
        configuration.weechat_ttv_buffer = "irc.server.twitch";
        services[SVC_TWITCH].user_name = "muffindrake";
        try
                entrance;
        catch (EXIT)
                return 0;
        return 0;
}
