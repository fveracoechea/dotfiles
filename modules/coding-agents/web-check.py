import copy
import ipaddress
import json
import sys


with open(sys.argv[1]) as source:
    config = json.load(source)


def check(candidate):
    servers = candidate["apps"]["http"]["servers"]
    assert len(servers) == 1
    server = next(iter(servers.values()))
    assert len(server["routes"]) == 1
    host_route = server["routes"][0]
    assert host_route["match"] == [{"host": ["opencode.veracoechea.com"]}]
    private, denied = host_route["handle"][0]["routes"]
    assert private["match"] == [{"remote_ip": {"ranges": ["100.64.0.0/10"]}}]
    assert "match" not in denied
    assert private["group"] == denied["group"]
    assert private["handle"][0]["routes"][0]["handle"] == [
        {"handler": "reverse_proxy", "upstreams": [{"dial": "127.0.0.1:4096"}]}
    ]
    assert denied["handle"][0]["routes"][0]["handle"] == [
        {"handler": "static_response", "status_code": 403}
    ]
    # remote_ip uses the socket peer, not a caller-controlled forwarding header.
    assert "client_ip" not in json.dumps(candidate)
    return private


private = check(config)
networks = [ipaddress.ip_network(value) for value in private["match"][0]["remote_ip"]["ranges"]]
for address, allowed in [
    ("100.64.0.1", True),
    ("100.127.255.254", True),
    ("100.63.255.255", False),
    ("100.128.0.0", False),
    ("10.0.0.2", False),
    ("192.168.1.2", False),
    ("127.0.0.1", False),
    ("192.0.2.1", False),
    ("8.8.8.8", False),
    ("::1", False),
    ("fd7a:115c:a1e0::1", False),
    ("::ffff:192.168.1.2", False),
]:
    assert any(ipaddress.ip_address(address) in network for network in networks) == allowed

if "--mutations" in sys.argv:
    for name in [
        "lan", "public", "forwarded-ip", "missing-denial",
        "denial-proxy", "public-backend", "extra-route",
    ]:
        candidate = copy.deepcopy(config)
        server = next(iter(candidate["apps"]["http"]["servers"].values()))
        routes = server["routes"][0]["handle"][0]["routes"]
        if name == "lan":
            routes[0]["match"][0]["remote_ip"]["ranges"].append("192.168.0.0/16")
        elif name == "public":
            routes[0]["match"][0]["remote_ip"]["ranges"] = ["0.0.0.0/0"]
        elif name == "forwarded-ip":
            routes[0]["match"][0]["client_ip"] = routes[0]["match"][0].pop("remote_ip")
        elif name == "missing-denial":
            routes.pop()
        elif name == "denial-proxy":
            routes[1]["handle"] = copy.deepcopy(routes[0]["handle"])
        elif name == "public-backend":
            routes[0]["handle"][0]["routes"][0]["handle"][0]["upstreams"][0]["dial"] = "0.0.0.0:4096"
        elif name == "extra-route":
            server["routes"].append({"handle": [{"handler": "reverse_proxy"}]})
        try:
            check(candidate)
        except (AssertionError, ValueError):
            print(f"Rejected proxy mutation: {name}")
        else:
            raise AssertionError(f"Accepted proxy mutation: {name}")
