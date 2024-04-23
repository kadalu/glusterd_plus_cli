import std.stdio;
import std.getopt;
import std.format;
import std.typecons;

import vibe.http.client;
import vibe.stream.operations;
import vibe.data.json;

import peers;

const PROG_HELP = "Usage: glusterp [options] COMMAND

A modern CLI for Gluster FS management using
the ReST APIs provided by Glusterd Plus.";

const PEER_HELP = "Usage: glusterp peer [options] COMMAND

Manage Gluster FS Peers";

const PEER_LIST_HELP = "Usage: glusterp peer list [options]

List of Gluster FS Peers";

// Hash map to store the cli handler function and the help message
// Ex:
// ---
// SubCommandsList subcmds = ["list": tuple(&listHandler, "List Command Help")];
// ---
alias SubCommandsList = Tuple!(int function(GetoptResult globalOpts, string[] args), string)[string];

class GlusterP
{
    mixin peersFunctions;
}

struct GlobalFlags
{
    bool jsonOutput;
    bool helpWanted;
}

GlobalFlags gflags;

void glusterpOptionsPrinter(string message, Option[] globalOptions,
        Option[] options, SubCommandsList subcmds = null)
{
    writeln(message);

    if (globalOptions.length > 0)
        writeln("\nGlobal Options:");

    foreach (opt; globalOptions)
    {
        auto flagName = format("%s %s", opt.optShort, opt.optLong);
        writefln("  %15s  %s%s", flagName, opt.required ? " Required: " : " ", opt.help);
    }

    if (options.length > 1)
        writeln("\nOptions:");

    foreach (opt; options)
    {
        if (opt.optShort == "-h")
            continue;

        auto flagName = format("%s %s", opt.optShort, opt.optLong);
        writefln("  %15s  %s%s", flagName, opt.required ? " Required: " : " ", opt.help);
    }

    if (subcmds)
    {
        writeln("\nCommands:");
        foreach (cmdName, cmd; subcmds)
        {
            writefln("  %15s  %s", cmdName, cmd[1]);
        }
    }
}

int subcmdPeerList(GetoptResult globalOpts, string[] args)
{
    auto opts = getopt(args,);

    if (gflags.helpWanted)
    {
        glusterpOptionsPrinter(PEER_LIST_HELP, globalOpts.options, opts.options);
        return 1;
    }

    auto client = new GlusterP;
    return client.listPeers();
}

int subcmdPeer(GetoptResult globalOpts, string[] args)
{
    SubCommandsList subcmds = [
        "list": tuple(&subcmdPeerList, "List of Gluster FS Peers")
    ];

    if (args.length < 3)
    {
        if (!gflags.helpWanted)
            writeln("Error: subcommand not specified\n");

        glusterpOptionsPrinter(PEER_HELP, globalOpts.options, null, subcmds);
        return 1;
    }

    auto cmd = (args[2] in subcmds);

    if (cmd is null)
    {
        writeln("Error: Unknown sub-command\n");
        glusterpOptionsPrinter(PEER_HELP, globalOpts.options, null, subcmds);
        return 1;
    }
    return (*cmd)[0](globalOpts, args);
}

int main(string[] args)
{
    auto globalOpts = getopt(args, std.getopt.config.passThrough, "json",
            "Json Output", &gflags.jsonOutput);

    gflags.helpWanted = globalOpts.helpWanted;

    SubCommandsList subcmds = [
        "peer": tuple(&subcmdPeer, "Manage Gluster FS Peers")
    ];

    if (args.length < 2)
    {
        if (!globalOpts.helpWanted)
            writeln("Error: subcommand not specified\n");

        glusterpOptionsPrinter(PROG_HELP, globalOpts.options, null, subcmds);
        return 1;
    }

    auto cmd = (args[1] in subcmds);

    if (cmd is null)
    {
        writeln("Error: Unknown sub-command\n");
        glusterpOptionsPrinter(PROG_HELP, globalOpts.options, null, subcmds);
        return 1;
    }
    return (*cmd)[0](globalOpts, args);
}
