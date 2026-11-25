#include "pch.h"
#include "network/client_socket.h"
#define private public
#include "network/server_socket.h"
#undef private
#include "server/server.h"
#include "server/user/user_manager.h"

namespace asio = boost::asio;
using tcp = ServerSocket::tcp;
using udp = ServerSocket::udp;
using namespace std::chrono_literals;

// The isolated listener has no real Server singleton or account database.
// Throwing here exercises discovery response failure without private data.
Server &Server::instance() { throw std::runtime_error("synthetic discovery failure"); }
const ServerConfig &Server::config() const { throw std::logic_error("unreachable stub"); }
UserManager &Server::user_manager() const { throw std::logic_error("unreachable stub"); }
std::unordered_map<int, std::shared_ptr<ServerPlayer>> UserManager::getPlayers() const {
  throw std::logic_error("unreachable stub");
}

static void require(bool ok, const char *message) {
  if (!ok) throw std::runtime_error(message);
}

int main() {
  try {
    asio::io_context io;
    const auto loopback = asio::ip::address_v4::loopback();
    ServerSocket server(io, {loopback, 0}, {loopback, 0});
    int connections = 0;
    int packets = 0;
    int disconnects = 0;
    std::weak_ptr<ClientSocket> first;
    server.set_new_connection_callback([&](std::shared_ptr<ClientSocket> conn) {
      ++connections;
      if (connections == 1) {
        first = conn;
        conn->set_message_got_callback([conn](Packet &) {});
        conn->set_disconnected_callback([&] { ++disconnects; });
        throw std::runtime_error("synthetic connection setup failure");
      }
      conn->set_message_got_callback([&](Packet &) { ++packets; });
      conn->set_disconnected_callback([&] { ++disconnects; });
    });
    server.start();
    tcp::socket one(io), two(io);
    one.connect(server.m_acceptor.local_endpoint());
    two.connect(server.m_acceptor.local_endpoint());
    const std::array<unsigned char, 8> packet{0x84, 1, 2, 0x41, 'A', 0x42, 1, 2};
    asio::write(two, asio::buffer(packet));
    io.run_for(250ms);
    require(connections == 2 && packets == 1, "setup exception stopped TCP listener");
    require(disconnects == 1 && first.expired(), "setup exception leaked connection");
    two.close();
    io.restart();
    io.run_for(250ms);
    require(disconnects == 2, "second connection did not close normally");
    std::cout << "PASS TCP listener continues after setup exception\n";

    udp::socket peer(io, {loopback, 0});
    const auto endpoint = server.m_udp_socket.local_endpoint();
    const std::string detail = "fkGetDetail,test";
    const std::string detect = "fkDetectServer";
    peer.send_to(asio::buffer(detail), endpoint);
    peer.send_to(asio::buffer(detect), endpoint);
    io.restart();
    io.run_for(250ms);
    peer.non_blocking(true);
    boost::system::error_code ec;
    udp::endpoint sender;
    std::array<char, 16> bytes{};
    const auto len = peer.receive_from(asio::buffer(bytes), sender, 0, ec);
    require(!ec && std::string_view(bytes.data(), len) == "me", "discovery exception stopped UDP listener");
    std::cout << "PASS UDP listener continues after discovery exception\n";

    server.m_acceptor.close();
    server.m_udp_socket.close();
    io.restart();
    require(io.run_for(250ms) >= 1 && io.stopped(), "closed listeners must terminate without spinning");
    std::cout << "PASS closed listeners terminate\n";
  } catch (const std::exception &e) {
    std::cerr << "FAIL: " << e.what() << '\n';
    return 1;
  }
}
