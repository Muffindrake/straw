module service;

struct SVC {
        immutable string name;
        immutable string name_short;
        immutable string ident;
        immutable string url_api_base;
        string api;
        string user_name;
        string user_id;

        string delegate(string) username_to_url;
        void function() update;
        string function(size_t) browse;
        void function() fetch;
        void function() listing;
}

enum {
        SVC_TWITCH,
        SVC_PICARTO
}

SVC[] services = [
SVC_TWITCH: {
        name: "Twitch.tv",
        name_short: "TTV",
        ident: "twitch",
        url_api_base: "https://api.twitch.tv/helix/",
        api: "onsyu6idu0o41dl4ixkofx6pqq7ghn",
        username_to_url: (string name) {
                import std.format : format;
                import std.string : strip;
                import std.uri : encode;
                return "https://twitch.tv/" ~ name.dup.strip.encode;
        }
},
SVC_PICARTO: {
        name: "Picarto.TV",
        name_short: "PTV",
        ident: "picarto",
        url_api_base: "https://api.picarto.tv/v1/",
        username_to_url: (string name) {
                import std.format : format;
                import std.string : strip;
                import std.uri : encode;
                return "https://picarto.tv/" ~ name.dup.strip.encode;
        }
}
];

static this()
{
        import service_twitch;

        services[SVC_TWITCH].update = &svc_ttv_update;
        services[SVC_TWITCH].browse = &svc_ttv_browse;
        services[SVC_TWITCH].fetch = &svc_ttv_update;
        services[SVC_TWITCH].listing = &svc_ttv_listing;
}
