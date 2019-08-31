module util;

extern (C) int isatty(int);
extern (C) private char* readline(const char*);
extern (C) private void add_history(char*);

string
rlw(string prompt, ref bool eof)
{
        import std.string : toStringz, fromStringz;
        import core.stdc.stdlib : free;
        char* a = readline(prompt.toStringz);
        scope (exit) a.free;
        if (!a) {
                eof = 1;
                return "";
        }
        eof = 0;
        a.add_history;
        return a.fromStringz.idup;
}

size_t
string_to_size(immutable string s)
{
        import std.conv : to, ConvException, ConvOverflowException;
        size_t ret;

        try
                ret = to!size_t(s);
        catch (ConvOverflowException)
                ret = 0;
        catch (ConvException)
                ret = 0;
        return ret;
}
