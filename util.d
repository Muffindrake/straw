module util;

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
