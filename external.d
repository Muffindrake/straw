module external;

import std.exception;
import std.format;
import std.process;

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
youtubedl_quality(immutable string query)
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
        return environment.get("DISPLAY") !is null;
}

void
mpv_run(immutable string url, immutable string quality)
{
        string terminal = configuration.terminal;
        if (terminal is null)
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
browser_run(immutable string url)
{
        browse(url);
}
