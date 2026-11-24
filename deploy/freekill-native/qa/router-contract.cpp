#include "pch.h"
#include "network/router.h"
#include "network/client_socket.h"
#include "server/user/serverplayer.h"
#include "server/user/user_manager.h"
#include "server/server.h"
#include "core/c-wrapper.h"
#include "core/util.h"

// No real player, socket or singleton is needed to exercise the router's
// request bookkeeping and synchronous packet dispatch.
std::string ServerPlayer::getScreenName() const { std::abort(); }
int ServerPlayer::getConnId() const { std::abort(); }
Router &ServerPlayer::router() const { std::abort(); }
void ServerPlayer::onDisconnected() { std::abort(); }
Server &Server::instance() { std::abort(); }
Server::io_context &Server::context() { std::abort(); }
UserManager &Server::user_manager() const { std::abort(); }
std::weak_ptr<ServerPlayer> UserManager::findPlayerByConnId(int) const { std::abort(); }
void ClientSocket::set_message_got_callback(std::function<void(Packet &)>) { std::abort(); }
void ClientSocket::set_disconnected_callback(std::function<void()>) { std::abort(); }
const std::string &ClientSocket::getDisconnectReason() const { std::abort(); }
void ClientSocket::send(const std::shared_ptr<std::string>) { std::abort(); }
static thread_local int lastEncodedRequestId;
std::string Cbor::encodeArray(std::initializer_list<std::variant<int, unsigned int, int64_t,
    uint64_t, std::string_view, const char *, bool>> items) {
  lastEncodedRequestId = std::get<int>(*items.begin());
  return {};
}
struct TestRouter : Router {
  TestRouter() : Router(nullptr, nullptr, TYPE_SERVER) {}
  using Router::handlePacket;
};
int main() {
  int failures = 0;
  auto check = [&](bool ok, const char *name) {
    std::cout << (ok ? "PASS " : "FAIL ") << name << '\n';
    failures += !ok;
  };
  TestRouter router;
  int replies = 0;
  router.set_reply_ready_callback([&] { ++replies; });
  std::string notification;
  int notificationFlags = 0;
  router.set_notification_got_callback([&](const Packet &p) {
    notification = p.cborData;
    notificationFlags = p.type;
  });
  const auto requestType = Router::TYPE_REQUEST | Router::SRC_SERVER | Router::DEST_CLIENT;
  const auto replyType = Router::TYPE_REPLY | Router::SRC_CLIENT | Router::DEST_SERVER;
  router.request(requestType, "First", "", 10);
  const int first = lastEncodedRequestId;
  router.request(requestType, "Second", "", 10);
  const int second = lastEncodedRequestId;
  Packet reply;
  reply.requestId = first;
  reply.type = replyType;
  reply.command = "First";
  reply.cborData = "old";
  reply.timeout = 0;
  reply.timestamp = 0;
  reply._len = 4;
  router.handlePacket(reply);
  check(router.waitForReply(0) == "__notready" && replies == 0, "superseded reply ignored");
  reply.requestId = second;
  reply.command = "Second";
  reply.cborData = "new";
  router.handlePacket(reply);
  check(router.waitForReply(0) == "new", "current reply delivered");
  const int repliesAfterCurrent = replies;
  router.handlePacket(reply);
  check(replies == repliesAfterCurrent, "duplicate reply ignored");
  router.request(requestType, "Abort", "", 10);
  reply.requestId = lastEncodedRequestId;
  router.abortRequest();
  router.handlePacket(reply);
  check(router.waitForReply(0).empty() && replies == repliesAfterCurrent, "aborted reply ignored");
  router.request(requestType, "Compressed", "", 10);
  reply.requestId = lastEncodedRequestId;
  const int beforeMalformed = replies;
  reply.type = replyType | Router::COMPRESSED;
  reply.cborData = "bad";
  const int currentCompressed = reply.requestId;
  reply.requestId = first;
  router.handlePacket(reply);
  check(router.waitForReply(0) == "__notready" && replies == beforeMalformed, "stale malformed compressed reply ignored");
  reply.requestId = currentCompressed;
  router.handlePacket(reply);
  check(router.waitForReply(0) == "__notready" && replies == beforeMalformed, "malformed current reply preserves request");
  const auto compressed = qCompress_std("synthetic CBOR");
  reply.type = replyType | Router::COMPRESSED;
  reply.cborData = compressed;
  router.handlePacket(reply);
  check(router.waitForReply(0) == "synthetic CBOR", "compressed reply decoded");
  Packet notify;
  notify.requestId = -2;
  notify.type = Router::TYPE_NOTIFICATION | Router::SRC_CLIENT | Router::DEST_SERVER | Router::COMPRESSED;
  notify.command = "Synthetic";
  notify.cborData = compressed;
  notify.timeout = 0;
  notify.timestamp = 0;
  notify._len = 4;
  router.handlePacket(notify);
  check(notification == "synthetic CBOR" && !(notificationFlags & Router::COMPRESSED), "compressed notification decoded and flag cleared");
  notify.cborData = "bad";
  router.handlePacket(notify);
  check(notification == "synthetic CBOR", "malformed compressed notification ignored");
  router.request(requestType, "Expired", "", 0);
  reply.requestId = lastEncodedRequestId;
  reply.type = replyType;
  reply.cborData = "too late";
  std::this_thread::sleep_for(std::chrono::milliseconds(2));
  const int beforeExpired = replies;
  router.handlePacket(reply);
  check(router.waitForReply(0) == "__notready" && replies == beforeExpired, "expired reply ignored");
  router.request(requestType, "Unlimited", "", -1);
  reply.requestId = lastEncodedRequestId;
  reply.cborData = "unlimited";
  router.handlePacket(reply);
  check(router.waitForReply(0) == "unlimited", "negative timeout preserved");

  router.request(requestType, "Reconnect", "", 10, 1234);
  const int beforeResend = lastEncodedRequestId;
  router.request(requestType, "Reconnect", "", 10, 1234);
  const int resent = lastEncodedRequestId;
  reply.requestId = beforeResend;
  reply.cborData = "prior socket";
  router.handlePacket(reply);
  check(router.waitForReply(0) == "__notready", "resend replaces prior ID");
  reply.requestId = resent;
  reply.cborData = "current socket";
  router.handlePacket(reply);
  check(router.waitForReply(0) == "current socket", "resend accepts new ID");

  constexpr int workers = 4;
  constexpr int requestsPerWorker = 1000;
  std::array<std::vector<int>, workers> ids;
  std::array<std::thread, workers> threads;
  for (int i = 0; i < workers; ++i) {
    threads[i] = std::thread([&, i] {
      TestRouter other;
      for (int n = 0; n < requestsPerWorker; ++n) {
        other.request(requestType, "Parallel", "", 10);
        ids[i].push_back(lastEncodedRequestId);
      }
    });
  }
  for (auto &thread : threads) thread.join();
  std::set<int> unique;
  for (const auto &batch : ids) unique.insert(batch.begin(), batch.end());
  check(unique.size() == workers * requestsPerWorker, "concurrent request IDs unique");
  return failures ? 1 : 0;
}
