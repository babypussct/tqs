#pragma once
struct Packet {
  int requestId, type, timeout, _len;
  int64_t timestamp;
  std::string_view command, cborData;
};
class ClientSocket : public std::enable_shared_from_this<ClientSocket> {
public:
  std::function<void()> afterSnapshot;
  std::vector<std::string> sent;
  std::weak_ptr<ClientSocket> weak_from_this() {
    auto result = std::enable_shared_from_this<ClientSocket>::weak_from_this();
    if (afterSnapshot) afterSnapshot();
    return result;
  }
  void set_message_got_callback(std::function<void(Packet &)> callback) { message = std::move(callback); }
  void set_disconnected_callback(std::function<void()> callback) { disconnect = std::move(callback); }
  const std::string &getDisconnectReason() const { return reason; }
  void send(const std::shared_ptr<std::string> payload) { sent.push_back(*payload); }
  std::function<void(Packet &)> message;
  std::function<void()> disconnect;
  std::string reason = "fixture";
};
