#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "canvas/DrawingCanvas.h"

int main(int argc, char *argv[])
{
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    QGuiApplication app(argc, argv);
    qmlRegisterType<DrawingCanvas>("OmenNotes.Canvas", 1, 0, "DrawingCanvas");
    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("OmenNotes", "Main");

    return QCoreApplication::exec();
}
