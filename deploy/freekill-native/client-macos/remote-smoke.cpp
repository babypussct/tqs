#include <QCoreApplication>
#include <QTimer>

#include "pch.h"
#include "client/client.h"
#include "core/packman.h"
#include "core/util.h"
#include "network/client_socket.h"
#include "network/router.h"
#include "ui/qmlbackend.h"

static QString packageSummaryJson(const QVariant &value) {
  const auto json = QJsonValue::fromVariant(value);
  if (!json.isArray()) {
    return {};
  }
  return QString::fromUtf8(
      QJsonDocument(json.toArray()).toJson(QJsonDocument::Compact));
}

int main(int argc, char **argv) {
  QCoreApplication app(argc, argv);

  const QString host = argc > 1 ? QString::fromLocal8Bit(argv[1])
                                : QStringLiteral("127.0.0.1");
  const auto port = static_cast<ushort>(argc > 2 ? QByteArray(argv[2]).toUShort()
                                                 : 9527);
  const QString username = argc > 3 ? QString::fromLocal8Bit(argv[3])
                                   : QStringLiteral("freekill-smoke");
  const QString password = argc > 4 ? QString::fromLocal8Bit(argv[4])
                                   : QStringLiteral("smoke-password");

  int result = 2;
  bool packageSyncStarted = false;
  bool packageSyncFailed = false;
  bool reconnectStarted = false;
  bool roomCreateStarted = false;
  Client *client = nullptr;
  QmlBackend backend;
  Pacman = new PackMan;
  qInfo().noquote() << "smoke cwd before client:" << QDir::currentPath()
                    << "md5:" << calcFileMD5();

  std::function<void()> startClient;

  auto finish = [&](int code) {
    result = code;
    QTimer::singleShot(100, &app, &QCoreApplication::quit);
  };

  QObject::connect(&backend, &QmlBackend::notifyUI, &app,
                   [&](const QString &command, const QVariant &data) {
                     if (command == QStringLiteral("PackageDownloadError")) {
                       packageSyncFailed = true;
                       qCritical().noquote()
                           << "package sync error:" << data.toString();
                     }
                   });

  startClient = [&]() {
    client = new Client;
    qInfo().noquote() << "smoke cwd after client:" << QDir::currentPath();

    QObject::connect(client, &Client::error_message, &app,
                     [&](const QString &message) {
                       if (packageSyncStarted && !reconnectStarted) {
                         qInfo().noquote()
                             << "expected disconnect during package sync:" << message;
                         return;
                       }
                       qCritical().noquote() << "client error:" << message;
                       finish(1);
                     });

    QObject::connect(client, &Client::notifyUI, &app,
                     [&](const QString &command, const QVariant &data) {
                       qInfo().noquote() << "client event:" << command;

                       if (command == QStringLiteral("ErrorMsg")) {
                         qCritical().noquote()
                             << "server error:" << data.toString();
                         finish(1);
                         return;
                       }

                       if (command == QStringLiteral("UpdatePackage") &&
                           !packageSyncStarted) {
                         packageSyncStarted = true;
                         const auto summary = packageSummaryJson(data);
                         if (summary.isEmpty()) {
                           qCritical().noquote()
                               << "remote client smoke: invalid package summary";
                           finish(1);
                           return;
                         }

                         qInfo().noquote()
                             << "syncing server packages with the native client";
                         Pacman->loadSummary(summary, false);

                         if (packageSyncFailed) {
                           finish(1);
                           return;
                         }

                         QTimer::singleShot(250, &app, [&]() {
                           reconnectStarted = true;
                           delete client;
                           client = nullptr;
                           startClient();
                         });
                         return;
                       }

                       if (command == QStringLiteral("EnterLobby") &&
                           !roomCreateStarted) {
                         roomCreateStarted = true;
                         const QVariantMap roomConfig = {
                             {"gameMode", "new_heg_mode"},
                             {"roomName", "codex-native-smoke"},
                             {"password", ""},
                             {"_game", QVariantMap{}},
                             {"_mode", QVariantMap{}},
                             {"disabledPack", QVariantList{}},
                             {"disabledGenerals", QVariantList{}},
                         };
                         qInfo().noquote()
                             << "creating native Hegemony smoke room";
                         client->notifyServer(
                             "CreateRoom",
                             QVariantList{
                                 "codex-native-smoke", 2, 90, roomConfig,
                             });
                       }

                       if (command == QStringLiteral("EnterRoom")) {
                         qInfo().noquote()
                             << "remote native Hegemony room smoke: PASS";
                         finish(0);
                       }
                     });

    QObject::connect(client->getRouter(), &Router::notification_got, &app,
                     [&](const QByteArray &command, const QByteArray &) {
                       qInfo().noquote() << "server packet:" << command;
                     });

    client->setLoginInfo(username, password);
    client->connectToHost(host, port);
  };

  startClient();

  QTimer::singleShot(180000, &app, [&]() {
    qCritical().noquote() << "remote client smoke: TIMEOUT";
    finish(2);
  });

  app.exec();

  if (client != nullptr) {
    client->getRouter()->getSocket()->disconnectFromHost();
    delete client;
  }
  delete Pacman;
  Pacman = nullptr;
  return result;
}
