const net = require("net");

const ALLOWED = new Set(["188-116-24-47.sslip.io"]);

const server = net.createServer((client) => {
  let buf = Buffer.alloc(0);
  const onData = (chunk) => {
    buf = Buffer.concat([buf, chunk]);
    const end = buf.indexOf("\r\n\r\n");
    if (end < 0) {
      if (buf.length > 8192) client.destroy();
      return;
    }
    client.removeListener("data", onData);
    const line = buf.subarray(0, end).toString("latin1").split("\r\n")[0];
    const parts = line.split(" ");
    const target = (parts[1] || "").split(":");
    const host = target[0];
    const port = Number(target[1] || 443);
    if (parts[0] !== "CONNECT" || !ALLOWED.has(host) || port !== 443) {
      client.end("HTTP/1.1 403 Forbidden\r\nContent-Length: 0\r\n\r\n");
      return;
    }
    const remote = net.connect(port, host, () => {
      client.write("HTTP/1.1 200 Connection Established\r\n\r\n");
      const rest = buf.subarray(end + 4);
      if (rest.length) remote.write(rest);
      client.pipe(remote);
      remote.pipe(client);
    });
    remote.on("error", () => client.destroy());
    client.on("error", () => remote.destroy());
  };
  client.on("data", onData);
  client.on("error", () => {});
});

server.listen(18080, "0.0.0.0", () => {
  console.log("emulator proxy on 0.0.0.0:18080");
});
