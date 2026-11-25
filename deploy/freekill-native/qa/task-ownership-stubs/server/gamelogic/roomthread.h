#pragma once
#include <functional>
#include <thread>
class RoomThread : public std::enable_shared_from_this<RoomThread> {
public:
  int refs = 0;
  int pushes = 0;
  bool accept = true;
  int delayed = 0;
  int aborts = 0;
  std::vector<std::string> reasons;
  const std::thread::id owner = std::this_thread::get_id();
  std::function<void()> onPush;
  std::function<void()> onRetire;
  void assertOwner() { if (std::this_thread::get_id() != owner) std::abort(); }
  void increaseRefCount() { assertOwner(); ++refs; }
  void decreaseRefCount() { assertOwner(); --refs; if (onRetire) onRetire(); }
  bool pushRequest(const std::string &) { assertOwner(); ++pushes; if (onPush) onPush(); return accept; }
  void wakeUp(int, const std::string &reason) { assertOwner(); reasons.push_back(reason); if (reason == "abort") ++aborts; }
  void delay(int, int ms) { assertOwner(); delayed = ms; }
};
