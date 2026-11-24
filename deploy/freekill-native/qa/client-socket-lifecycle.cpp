#include "pch.h"
#include "network/client_socket.h"

namespace asio = boost::asio;
using tcp = ClientSocket::tcp;
using namespace std::chrono_literals;

static void require(bool ok, const char *message) {
  if (!ok) throw std::runtime_error(message);
}

struct Connection {
  asio::io_context io;
  tcp::acceptor acceptor{io, {asio::ip::address_v4::loopback(), 0}};
  tcp::socket peer{io};
  std::shared_ptr<ClientSocket> client;

  Connection() {
    peer.connect(acceptor.local_endpoint());
    client = std::make_shared<ClientSocket>(acceptor.accept());
  }

  void sendPackets(int count) {
    const std::array<unsigned char, 8> packet{0x84, 1, 2, 0x41, 'A', 0x42, 1, 2};
    std::vector<unsigned char> bytes;
    for (int i = 0; i < count; ++i) bytes.insert(bytes.end(), packet.begin(), packet.end());
    asio::write(peer, asio::buffer(bytes));
  }

  void run() {
    io.restart();
    io.run_for(250ms);
  }
};

static void callbackException() {
  Connection c;
  int disconnects = 0;
  c.client->set_message_got_callback([self = c.client](Packet &) {
    throw std::runtime_error("synthetic packet failure");
  });
  c.client->set_disconnected_callback([&] { ++disconnects; });
  auto weak = c.client->weak_from_this();
  c.client->start();
  c.sendPackets(1);
  c.run();
  require(disconnects == 1 && !c.client->socket().is_open(), "packet exception must close once");
  c.client.reset();
  require(weak.expired(), "packet exception must release callback self-capture");
}

static void eofAndTimer() {
  Connection c;
  int disconnects = 0;
  int canceled = 0;
  c.client->set_message_got_callback([self = c.client](Packet &) {});
  c.client->set_disconnected_callback([&] { ++disconnects; });
  c.client->timerSignup = std::make_unique<asio::steady_timer>(c.io, 3min);
  c.client->timerSignup->async_wait([&](const boost::system::error_code &ec) {
    if (ec == asio::error::operation_aborted) ++canceled;
  });
  auto weak = c.client->weak_from_this();
  c.client->start();
  c.peer.close();
  c.run();
  require(disconnects == 1 && canceled == 1, "EOF must disconnect once and cancel signup timer");
  require(!c.client->socket().is_open(), "EOF must close socket");
  c.client.reset();
  require(weak.expired(), "EOF must release callback self-capture");
}

static void reentrantDisconnect() {
  Connection c;
  int disconnects = 0;
  c.client->set_disconnected_callback([&] {
    ++disconnects;
    c.client->disconnectFromHost("reentrant");
    c.client->set_disconnected_callback([&] { ++disconnects; });
    throw std::runtime_error("synthetic disconnect failure");
  });
  c.client->start();
  c.client->disconnectFromHost("original");
  c.client->disconnectFromHost("duplicate");
  c.run();
  require(disconnects == 1, "reentrant and duplicate close must notify once");
  require(c.client->getDisconnectReason() == "original", "close must preserve first reason");
  require(!c.client->socket().is_open(), "disconnect exception must not prevent closure");
}

static void callbackReplacement() {
  Connection c;
  int first = 0;
  int second = 0;
  int disconnects = 0;
  c.client->set_disconnected_callback([&] { ++disconnects; });
  c.client->set_message_got_callback([&, self = c.client](Packet &) {
    ++first;
    self->set_message_got_callback([&](Packet &) { ++second; });
    require(self->socket().is_open(), "replacing active callback must preserve its captures");
  });
  c.client->start();
  c.sendPackets(3);
  c.run();
  require(first == 1 && second == 2, "coalesced packets must use updated callback");
  c.peer.close();
  c.run();
  require(disconnects == 1, "callback replacement must retain disconnect handling");
}

static void pendingReadLifetime() {
  Connection c;
  int disconnects = 0;
  c.client->set_disconnected_callback([&] { ++disconnects; });
  auto weak = c.client->weak_from_this();
  c.client->start();
  c.run();
  c.client.reset();
  require(!weak.expired(), "pending read must retain buffer ownership");
  c.peer.close();
  c.run();
  require(weak.expired() && disconnects == 1, "pending reader must release socket after EOF");
}

static void releaseLastOwner() {
  Connection c;
  auto weak = c.client->weak_from_this();
  int disconnects = 0;
  c.client->set_disconnected_callback([&] {
    ++disconnects;
    c.client.reset();
    require(!weak.expired(), "socket must survive its active disconnect callback");
  });
  c.client->disconnectFromHost("last owner");
  require(disconnects == 1 && weak.expired(), "synchronous close must release last owner after callback");
}

static void closeDuringPacket() {
  Connection c;
  int packets = 0;
  int disconnects = 0;
  c.client->set_disconnected_callback([&] { ++disconnects; });
  c.client->set_message_got_callback([&, self = c.client](Packet &) {
    ++packets;
    self->disconnectFromHost("packet requested close");
    self->set_message_got_callback([self](Packet &) {});
  });
  c.client->start();
  c.sendPackets(3);
  c.run();
  require(packets == 1 && disconnects == 1, "close during packet must stop coalesced dispatch");
  require(c.client->getDisconnectReason() == "packet requested close", "close must preserve packet reason");
  auto weak = c.client->weak_from_this();
  c.client.reset();
  require(weak.expired(), "closed socket must reject callback self-ownership");
}

static void gracefulQueue(bool halfClose) {
  Connection c;
  int disconnects = 0;
  c.client->set_disconnected_callback([&] { ++disconnects; });
  c.client->start();
  c.client->send(std::make_shared<std::string>("first"));
  c.client->send(std::make_shared<std::string>("second"));
  c.client->disconnectFromHost("graceful");
  if (halfClose) c.peer.shutdown(tcp::socket::shutdown_send);
  c.run();
  std::array<char, 11> bytes{};
  boost::system::error_code ec;
  c.peer.non_blocking(true);
  const auto count = asio::read(c.peer, asio::buffer(bytes), ec);
  require(count == bytes.size() && !ec && std::string_view(bytes.data(), bytes.size()) == "firstsecond", "graceful close must drain ordered output");
  require(disconnects == 1 && !c.client->socket().is_open(), "graceful close must finish once");
}

static void sendFailure() {
  Connection c;
  int disconnects = 0;
  c.client->set_disconnected_callback([&] { ++disconnects; });
  c.client->start();
  c.client->send(std::make_shared<std::string>(1024 * 1024, 'x'));
  c.client->send(std::make_shared<std::string>("pending"));
  c.peer.set_option(asio::socket_base::linger(true, 0));
  c.peer.close();
  c.run();
  require(disconnects == 1 && !c.client->socket().is_open(), "send failure must close once");
  auto weak = c.client->weak_from_this();
  c.client.reset();
  require(weak.expired(), "failed send must release pending operations");
}

int main() {
  try {
    callbackException();
    std::cout << "PASS packet exception cleanup\n";
    eofAndTimer();
    std::cout << "PASS EOF and signup timer\n";
    reentrantDisconnect();
    std::cout << "PASS reentrant and throwing disconnect callback\n";
    callbackReplacement();
    std::cout << "PASS coalesced packet callback replacement\n";
    pendingReadLifetime();
    std::cout << "PASS pending read lifetime\n";
    releaseLastOwner();
    std::cout << "PASS synchronous last owner release\n";
    closeDuringPacket();
    std::cout << "PASS close during coalesced packet dispatch\n";
    gracefulQueue(false);
    gracefulQueue(true);
    std::cout << "PASS graceful queued writes and peer half-close\n";
    sendFailure();
    std::cout << "PASS failed writes cleanup\n";
  } catch (const std::exception &e) {
    std::cerr << "FAIL: " << e.what() << '\n';
    return 1;
  }
}
