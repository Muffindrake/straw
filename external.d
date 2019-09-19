module external;

import std.exception;
import std.format;
import std.process;
import std.stdio;

import setting;

class EXIT : Exception {
        int rc;

        @safe pure nothrow this(int rc, string file = __FILE__,
                size_t line = __LINE__)
        {
                super(null, file, line);
                this.rc = rc;
        }
}

char[]
youtubedl_quality(string query)
{
        import std.process : escapeShellFileName;

        return ("youtube-dl --socket-timeout 20"
                        ~ " -F %s".format(query.dup.escapeShellFileName)
                        ~ " 2>/dev/null"
                        ~ " | sed"
                        ~ " -e '/^\\[.*/d'"
                        ~ " -e '/^format code.*/d'"
                        ~ " -e '/^ERROR.*/d'"
                        ~ " | awk '{print $3, $4, $1}'").executeShell[1].dup;
}

bool
session_graphical()
{
        return !!environment.get("DISPLAY");
}

void
mpv_run(string url, string quality)
{
        string terminal = configuration.terminal;
        if (!terminal)
                terminal = "xterm";
        if (session_graphical)
                (`nohup %s -e mpv "%s" --ytdl-format="%s"`
                                .format(terminal, url, quality)
                                ~ " >/dev/null 2>&1 &").spawnShell;
        else
                (`mpv "%s" --ytdl-format="%s"`.format(url, quality))
                                .spawnShell;
}

void
browser_run(string url)
{
        browse(url);
}

void
weechat_chat_join(string buffer, string channel)
{
        File f;
        string fifo_path = environment.get("WEECHAT_HOME", environment["HOME"] ~ "/.weechat");

        fifo_path ~= "/weechat_fifo";
        try {
                f = File(fifo_path, "w");
        } catch (ErrnoException e) {
                `Unable to open %s: %s`.writefln(fifo_path, e);
                return;
        }
        try {
                f.writefln("%s */join #%s", buffer, channel);
        } catch (ErrnoException e) {
                `An error has occurred when writing to %s: %s`.writefln(fifo_path, e);
                return;
        }
}
