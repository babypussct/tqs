#include "network/router.h"
#include "network/client_socket.h"
#include "server/user/serverplayer.h"
#include "server/server.h"
#include "core/c-wrapper.h"
#include <future>

enum class Transition { None, Detach, Transfer, Replace, Rebind };

bool scenario(Transition transition, bool pauseEncoding, bool request) {
  ServerPlayer original(1), replacement(2);
  auto socket = std::make_shared<ClientSocket>();
  auto newSocket = std::make_shared<ClientSocket>();
  original.router().setSocket(socket);
  std::promise<void> captured, release;
  auto capturedFuture = captured.get_future();
  auto releaseFuture = release.get_future();
  auto pause = [&] { captured.set_value(); releaseFuture.wait(); };
  if (pauseEncoding) Cbor::beforeEncode = pause;
  else socket->afterSnapshot = pause;
  auto &main = Server::instance().context();
  main.restart();
  auto work = boost::asio::make_work_guard(main);
  std::thread worker([&] {
    if (request) original.router().request(0, "SyntheticOldRoomRequest", "fixture", 10);
    else original.router().notify(0, "SyntheticOldRoomMessage", "fixture");
    work.reset();
  });
  if (capturedFuture.wait_for(std::chrono::seconds(5)) != std::future_status::ready) std::abort();
  switch (transition) {
    case Transition::None: break;
    case Transition::Detach: original.router().setSocket(nullptr); break;
    case Transition::Transfer:
      original.router().setSocket(nullptr);
      replacement.router().setSocket(socket);
      break;
    case Transition::Replace: original.router().setSocket(newSocket); break;
    case Transition::Rebind:
      original.router().setSocket(nullptr);
      original.router().setSocket(socket);
      break;
  }
  release.set_value();
  main.run();
  worker.join();
  socket->afterSnapshot = {};
  Cbor::beforeEncode = {};
  const bool expectedOld = transition == Transition::None;
  bool ok = (socket->sent.size() == static_cast<size_t>(expectedOld)) && newSocket->sent.empty();
  // Ensure the replacement binding accepts subsequent notifications.
  Router &current = transition == Transition::Transfer ? replacement.router() : original.router();
  auto currentSocket = current.getSocket();
  if (currentSocket) {
    const auto before = currentSocket->sent.size();
    main.restart();
    boost::asio::post(main, [&]{ current.notify(0, "SyntheticNewRoomMessage", "fixture"); });
    main.run();
    ok = ok && currentSocket->sent.size() == before + 1 && currentSocket->sent.back() == "SyntheticNewRoomMessage";
  }
  return ok;
}

bool callbackScenario() {
  auto &users = Server::instance().user_manager().players;
  auto original = std::make_shared<ServerPlayer>(1);
  auto replacement = std::make_shared<ServerPlayer>(2);
  users[1] = original;
  users[2] = replacement;
  auto socket = std::make_shared<ClientSocket>();
  auto &router = original->router();
  int notifications = 0, replies = 0, newNotifications = 0;
  router.set_notification_got_callback([&](const Packet &) { ++notifications; });
  router.set_reply_ready_callback([&] { ++replies; });
  replacement->router().set_notification_got_callback([&](const Packet &) { ++newNotifications; });
  router.setSocket(socket);
  auto previousMessage = socket->message;
  auto previousDisconnect = socket->disconnect;
  Packet notification{};
  notification.type = Router::TYPE_NOTIFICATION;
  notification.cborData = "fixture";
  previousMessage(notification);
  auto &main = Server::instance().context();
  auto request = [&] {
    main.restart();
    boost::asio::post(main, [&] { router.request(0, "SyntheticRequest", "fixture", 10); });
    main.run();
    return Cbor::lastRequestId;
  };
  const int oldId = request();
  router.setSocket(nullptr);
  router.setSocket(socket);
  previousMessage(notification);
  previousDisconnect();
  Packet reply{};
  reply.type = Router::TYPE_REPLY;
  reply.requestId = oldId;
  reply.cborData = "stale";
  socket->message(reply);
  bool ok = notifications == 1 && original->disconnects == 0 && replies == 0 && router.waitForReply(0) == "__notready";
  reply.requestId = request();
  reply.cborData = "current";
  socket->message(reply);
  ok = ok && replies == 1 && router.waitForReply(0) == "current";
  auto reboundMessage = socket->message;
  auto reboundDisconnect = socket->disconnect;
  router.setSocket(nullptr);
  ok = ok && router.waitForReply(0) == "current";
  replacement->router().setSocket(socket);
  original.reset();
  reboundMessage(notification);
  reboundDisconnect();
  socket->message(notification);
  ok = ok && notifications == 1 && newNotifications == 1 && replacement->disconnects == 0;
  socket->disconnect();
  ok = ok && replacement->disconnects == 1 && !replacement->router().getSocket();
  users.clear();
  return ok;
}

int main() {
  int failed = 0;
  for (auto request : {false, true}) {
    for (auto encoding : {false, true}) {
      for (auto transition : {Transition::None, Transition::Detach, Transition::Transfer, Transition::Replace, Transition::Rebind}) {
        bool ok = scenario(transition, encoding, request);
        std::cout << (ok ? "PASS " : "FAIL ") << (request ? "request" : "notification")
          << " pause=" << (encoding ? "encode" : "send") << " transition=" << static_cast<int>(transition) << '\n';
        failed += !ok;
      }
    }
  }
  const bool callbacks = callbackScenario();
  std::cout << (callbacks ? "PASS " : "FAIL ") << "callback ownership, stale reply, reconnect, transfer and destruction\n";
  failed += !callbacks;
  return failed ? 1 : 0;
}
