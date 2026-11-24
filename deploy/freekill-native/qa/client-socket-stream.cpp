// Regression test for the pinned native ClientSocket stream decoder.
#include "pch.h"
// Exercise exact read boundaries without depending on TCP coalescing timing.
#define private public
#include "network/client_socket.h"
#undef private

using Bytes = std::vector<unsigned char>;
using Message = std::tuple<int, int, std::string, std::string, int>;

static void require(bool condition, const char *message) {
  if (!condition) throw std::runtime_error(message);
}

static void feed(ClientSocket &socket, const Bytes &bytes, size_t first, size_t last) {
  require(last - first <= sizeof(socket.m_data), "test chunk exceeds read buffer");
  std::copy(bytes.begin() + first, bytes.begin() + last, socket.m_data);
  require(socket.handleBuffer(last - first) != CBOR_DECODER_ERROR, "decoder rejected valid stream");
}

int main() {
  boost::asio::io_context io;
  using tcp = ClientSocket::tcp;
  tcp::acceptor acceptor(io, {boost::asio::ip::address_v4::loopback(), 0});
  tcp::socket peer(io);
  peer.connect(acceptor.local_endpoint());
  ClientSocket socket(acceptor.accept());
  std::vector<Message> received;
  socket.set_message_got_callback([&](Packet &p) {
    received.emplace_back(p.requestId, p.type, p.command, p.cborData, p._len);
    if (p._len == 6) require(p.timeout == 300 && p.timestamp == 65536, "six-field metadata changed");
  });

  const Bytes first{0x84, 0x01, 0x02, 0x41, 'A', 0x42, 0x01, 0x02};
  const Bytes second{0x86, 0x19, 0x01, 0x02, 0x03, 0x42, 'B', 'C', 0x43, 0x03, 0x04, 0x05,
                     0x19, 0x01, 0x2c, 0x1a, 0x00, 0x01, 0x00, 0x00};
  const Message firstMessage{1, 2, "A", std::string("\x01\x02", 2), 4};
  const Message secondMessage{258, 3, "BC", std::string("\x03\x04\x05", 3), 6};
  const std::vector<Message> expected{firstMessage, secondMessage, firstMessage};
  Bytes stream = first;
  stream.insert(stream.end(), second.begin(), second.end());
  stream.insert(stream.end(), first.begin(), first.end());

  // Every pair of boundaries, including a complete packet followed by a
  // partial header, partial CBOR field, or complete fields of another packet.
  for (size_t a = 1; a < stream.size(); ++a) {
    for (size_t b = a + 1; b <= stream.size(); ++b) {
      received.clear();
      feed(socket, stream, 0, a);
      const size_t completed = (a >= first.size()) + (a >= first.size() + second.size());
      require(received.size() == completed, "incorrect callback count after first chunk");
      feed(socket, stream, a, b);
      if (b < stream.size()) feed(socket, stream, b, stream.size());
      if (received != expected || !socket.cborBuffer.empty()) {
        std::cerr << "Failed at read boundaries " << a << ", " << b << '\n';
        return 1;
      }
    }
  }
  received.clear();
  for (size_t i = 0; i < stream.size(); ++i) feed(socket, stream, i, i + 1);
  require(received == expected && socket.cborBuffer.empty(), "bytewise reads lost or duplicated messages");
  received.clear();
  feed(socket, stream, 0, stream.size());
  require(received == expected && socket.cborBuffer.empty(), "coalesced read lost or duplicated messages");
  std::cout << "PASS ClientSocket fragmented and coalesced packet regression\n";
}
