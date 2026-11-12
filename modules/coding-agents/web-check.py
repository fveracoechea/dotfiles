import ipaddress
import json
import sys


with open(sys.argv[1]) as source:
    config = json.load(source)

server = next(iter(config["apps"]["http"]["servers"].values()))
host_route = server["routes"][0]
assert host_route["match"] == [{"host": ["opencode.veracoechea.com"]}]
routes = host_route["handle"][0]["routes"]
private, denied = routes
assert private["match"] == [{"remote_ip": {"ranges": ["100.64.0.0/10"]}}]
assert "match" not in denied
assert private["group"] == denied["group"]
assert private["handle"][0]["routes"][0]["handle"] == [
    {"handler": "reverse_proxy", "upstreams": [{"dial": "127.0.0.1:4096"}]}
]
assert denied["handle"][0]["routes"][0]["handle"] == [
    {"handler": "static_response", "status_code": 403}
]

networks = [ipaddress.ip_network(value) for value in private["match"][0]["remote_ip"]["ranges"]]
for address, allowed in [
    ("100.64.0.1", True),
    ("100.127.255.254", True),
    ("10.0.0.2", False),
    ("192.168.1.2", False),
    ("127.0.0.1", False),
    ("192.0.2.1", False),
    ("8.8.8.8", False),
    ("::1", False),
]:
    assert any(ipaddress.ip_address(address) in network for network in networks) == allowed

# remote_ip uses the socket peer, not a caller-controlled forwarding header.
assert "client_ip" not in json.dumps(config)
