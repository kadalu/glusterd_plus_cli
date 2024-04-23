import std.stdio;

struct Peer
{
    string id, address, state;
}

mixin template peersFunctions()
{
    int listPeers()
    {
        auto res = requestHTTP("http://localhost:3000/api/v1/peers", (scope req) {
            req.method = HTTPMethod.GET;
        });

        auto data = res.bodyReader.readAllUTF8();

        if (gflags.jsonOutput)
        {
            write(data);
            return 0;
        }

        Peer[] peers = deserializeJson!(Peer[])(data);

        writefln("%-20s  %-36s  %s", "Address", "ID", "State");
        foreach (peer; peers)
        {
            writefln("%-20s  %-36s  %s", peer.address, peer.id, peer.state);
        }
        return 0;
    }
}
