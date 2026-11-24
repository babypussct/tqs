// Regression coverage for native packet framing and integer metadata.
#include "pch.h"
#define private public
#include "network/client_socket.h"
#undef private
#include <limits>

using Bytes = std::vector<unsigned char>;
static void require(bool ok, const char *message) {
  if (!ok) throw std::runtime_error(message);
}
struct Connection {
  boost::asio::io_context io;
  using tcp = ClientSocket::tcp;
  tcp::acceptor acceptor{io, {boost::asio::ip::address_v4::loopback(), 0}};
  tcp::socket peer{io};
  std::unique_ptr<ClientSocket> client;
  Connection() {
    peer.connect(acceptor.local_endpoint());
    client = std::make_unique<ClientSocket>(acceptor.accept());
  }
  cbor_decoder_status feed(const Bytes &bytes) {
    require(bytes.size() <= sizeof(client->m_data), "oversized test chunk");
    std::copy(bytes.begin(), bytes.end(), client->m_data);
    return client->handleBuffer(bytes.size());
  }
};
int main() {
  const Bytes valid{0x84, 0x01, 0x02, 0x41, 'A', 0x40};
  {
    Connection c;
    int received = 0;
    c.client->set_message_got_callback([&](Packet &p) {
      ++received;
      if (received == 1) {
        require(p.requestId == std::numeric_limits<int>::min(), "signed request ID");
        require(p.timestamp == std::numeric_limits<int64_t>::min(), "signed timestamp");
        require(p.timeout == -1, "signed timeout");
      } else {
        require(p.requestId == 1 && p.timestamp == 0 && p.timeout == 0, "four-field metadata reset");
      }
    });
    const Bytes six{0x86, 0x3a, 0x7f, 0xff, 0xff, 0xff, 0x02, 0x41, 'A', 0x40,
      0x20, 0x3b, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
    for (auto b : six) require(c.feed({b}) != CBOR_DECODER_ERROR, "valid signed metadata rejected");
    require(c.feed(valid) != CBOR_DECODER_ERROR && received == 2 && c.client->cborBuffer.empty(), "valid packet dispatch");
  }
  const std::vector<Bytes> invalid{
    {0x83}, {0x84, 0x84}, {0x84, 0xf6}, {0x84, 0x01, 0x1a, 0x80, 0, 0, 0},
    {0x84, 0x1b, 0x80, 0, 0, 0, 0, 0, 0, 0},
    {0x84, 0x01, 0x02, 0x41, 'A', 0x5a, 0, 0x40, 0, 0},
    {0x84, 0x01, 0x02, 0x41, 'A', 0x9f},
  };
  for (const auto &bytes : invalid) {
    Connection c;
    int received = 0;
    c.client->set_message_got_callback([&](Packet &) { ++received; });
    require(c.feed(bytes) == CBOR_DECODER_ERROR && received == 0, "invalid packet must be rejected before dispatch");
  }
  {
    Connection c;
    int received = 0;
    c.client->set_message_got_callback([&](Packet &p) { ++received; require(p.cborData.size() == 4*1024*1024-10, "large valid data length"); });
    constexpr size_t count = 4*1024*1024-10;
    Bytes packet{0x84, 0x01, 0x02, 0x41, 'A', 0x5a, 0, 0x3f, 0xff, 0xf6};
    packet.resize(packet.size() + count, 0);
    for (size_t pos = 0; pos < packet.size(); pos += 32768) {
      const auto end = std::min(pos + 32768, packet.size());
      require(c.feed(Bytes(packet.begin()+pos, packet.begin()+end)) != CBOR_DECODER_ERROR, "valid packet at size limit rejected");
    }
    require(received == 1 && c.client->cborBuffer.empty(), "bounded packet dispatch");
  }
  {
    Connection c;
    require(c.feed(valid) != CBOR_DECODER_ERROR, "default diagnostic must tolerate opaque data");
  }
  std::cout << "PASS native packet validation, signed metadata, framing limit and diagnostics\n";
}
