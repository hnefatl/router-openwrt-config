var REG_PORKBUN = NewRegistrar("porkbun_primary");
var REG_NONE = NewRegistrar("none_primary");

var DNS_PORKBUN = NewDnsProvider("porkbun_primary");
var DNS_BIND = NewDnsProvider("bind_primary", {
    "default_ns": ["keithdns.collister.xyz."]
    "default_soa": {
        "mbox": "hnefatl@gmail.com.",
        "master": "keithdns.collister.xyz.",
        "minttl": 300, // How long clients should negative cache.
    },
});

// Internal DNS on router
D("keith.collister.xyz", REG_NONE, DnsProvider(DNS_BIND),
    // Long TTL to withstand outages on my side.
    DefaultTTL("1h"),
    NAMESERVER_TTL("1h"),
    A("@", "216.239.32.21"),
    A("@", "216.239.34.21"),
    A("@", "216.239.36.21"),
    A("@", "216.239.38.21"),
    AAAA("@", "2001:4860:4802:32::15"),
    AAAA("@", "2001:4860:4802:34::15"),
    AAAA("@", "2001:4860:4802:36::15"),
    AAAA("@", "2001:4860:4802:38::15"),
    CNAME("blog", "hnefatl.github.io."),
    TXT("_atproto", "did=did:plc:yrom3tt7zwtpfes5nbuzmr6d"),
);
D("ha.keith.collister.xyz", REG_NONE, DnsProvider(DNS_BIND),
    DefaultTTL("1m"), // Short TTL so I notice quickly
    A("@", "89.34.167.102"),
    AAAA("@", "2a01:4b00:bd20:7010:230:59ff:fe28:d000"),
);
D("vpn.keith.collister.xyz", REG_NONE, DnsProvider(DNS_BIND),
    // Long TTL to withstand and fix outages.
    DefaultTTL("1h"),
    NAMESERVER_TTL("1h"),
    A("@", "89.34.167.102"),
    AAAA("@", "2a01:4b00:bd20:7001::1"),
);
D("warthog.keith.collister.xyz", REG_NONE, DnsProvider(DNS_BIND),
    A("@", "89.34.167.102"),
    AAAA("@", "2a01:4b00:bd20:7010:230:59ff:fe28:d000"),

    A("*", "89.34.167.102"),
    AAAA("*", "2a01:4b00:bd20:7010:230:59ff:fe28:d000"),
);

// External DNS on Porkbun
D("collister.xyz", REG_PORKBUN, DnsProvider(DNS_PORKBUN),
    DefaultTTL(600),
    NS("keith", "keithdns.collister.xyz."),
    // Don't stomp certificate challenges.
    IGNORE("_acme-challenge", "TXT"),

    A("@", "216.239.32.21"),
    A("@", "216.239.34.21"),
    A("@", "216.239.36.21"),
    A("@", "216.239.38.21"),
    AAAA("@", "2001:4860:4802:32::15"),
    AAAA("@", "2001:4860:4802:34::15"),
    AAAA("@", "2001:4860:4802:36::15"),
    AAAA("@", "2001:4860:4802:38::15"),

    A("keithdns", "89.34.167.102"),
    AAAA("keithdns", "2a01:4b00:bd20:7001::1"),
);

